const db = require('../config/db');

class ConflictDetectionService {
  /**
   * Check if staff member has conflicting assignments
   */
  static async checkStaffConflicts(staffId, staffType, startDate, endDate, excludeBookingId = null) {
    try {
      const staffIdField = staffType === 'guide' ? 'assigned_guide_id' : 'assigned_driver_id';
      
      let query = `
        SELECT 
          booking_code, 
          start_date, 
          end_date, 
          status,
          ${staffType === 'guide' ? 'guide_name' : 'driver_name'} as staff_name
        FROM bookings 
        WHERE ${staffIdField} = $1 
          AND status IN ('confirmed', 'pending', 'assigned', 'ongoing')
          AND (
            (start_date <= $2 AND end_date >= $2) OR  -- Overlaps start
            (start_date <= $3 AND end_date >= $3) OR  -- Overlaps end
            (start_date >= $2 AND end_date <= $3)     -- Contained within
          )
      `;
      
      const params = [staffId, startDate, endDate];
      
      if (excludeBookingId) {
        query += ` AND id != $4`;
        params.push(excludeBookingId);
      }
      
      query += ` ORDER BY start_date`;
      
      const result = await db.query(query, params);
      
      return {
        hasConflicts: result.rows.length > 0,
        conflicts: result.rows,
        staffId,
        staffType,
        conflictCount: result.rows.length
      };
      
    } catch (error) {
      console.error('❌ Error checking staff conflicts:', error);
      throw error;
    }
  }

  /**
   * Get available staff excluding those with conflicts
   */
  static async getAvailableStaff(staffType, startDate, endDate, excludeStaffIds = []) {
    try {
      const staffTable = staffType === 'guide' ? 'guides' : 'drivers';
      const staffIdField = staffType === 'guide' ? 'assigned_guide_id' : 'assigned_driver_id';
      
      // Get all active staff
      let baseQuery = `
        SELECT 
          s.id, 
          u.id as user_id,
          u.email as name, 
          s.rating, 
          s.years_experience, 
          s.is_available
        FROM ${staffTable} s
        JOIN users u ON s.user_id = u.id
        WHERE s.is_available = true 
          AND u.status = 'active'
      `;
      
      const params = [];
      
      if (excludeStaffIds.length > 0) {
        baseQuery += ` AND s.id != ALL($1)`;
        params.push(excludeStaffIds);
      }
      
      const allStaff = await db.query(baseQuery, params);
      
      // Check each staff member for conflicts
      const availableStaff = [];
      
      for (const staff of allStaff.rows) {
        const conflictCheck = await this.checkStaffConflicts(
          staff.id, 
          staffType, 
          startDate, 
          endDate
        );
        
        if (!conflictCheck.hasConflicts) {
          availableStaff.push({
            ...staff,
            conflicts: [],
            score: this.calculateStaffScore(staff)
          });
        } else {
          // Staff has a scheduling conflict and is correctly filtered out
          // console.log(`ℹ️  ${staffType} ${staff.name} is busy during this time (has ${conflictCheck.conflictCount} conflicts)`);
        }
      }
      
      // Sort by score (best first)
      availableStaff.sort((a, b) => b.score - a.score);
      
      return availableStaff;
      
    } catch (error) {
      console.error('❌ Error getting available staff:', error);
      throw error;
    }
  }

  /**
   * Calculate staff score for auto-assignment
   */
  static calculateStaffScore(staff) {
    let score = 0;
    
    // Rating (0-5) → 0-40 points
    score += (staff.rating || 0) * 8;
    
    // Experience (years) → up to 30 points (capped at 15 years)
    score += Math.min(staff.years_experience || 0, 15) * 2;
    
    // Availability bonus
    if (staff.is_available) {
      score += 30;
    }
    
    return Math.round(score);
  }

  /**
   * Auto-assign best available staff to booking
   */
  static async autoAssignStaff(bookingId, startDate, endDate, excludeStaffIds = []) {
    try {
      console.log(`🤖 Auto-assigning staff for booking ${bookingId}`);
      
      // Get available guides and drivers
      const availableGuides = await this.getAvailableStaff('guide', startDate, endDate, excludeStaffIds.guides || []);
      const availableDrivers = await this.getAvailableStaff('driver', startDate, endDate, excludeStaffIds.drivers || []);
      
      console.log(`   Available guides: ${availableGuides.length}`);
      console.log(`   Available drivers: ${availableDrivers.length}`);
      
      if (availableGuides.length === 0 && availableDrivers.length === 0) {
        return {
          success: false,
          error: 'No available staff found',
          guide: null,
          driver: null
        };
      }
      
      const bestGuide = availableGuides[0] || null;
      const bestDriver = availableDrivers[0] || null;
      
      // Update the booking
      const updateResult = await db.query(`
        UPDATE bookings 
        SET 
          assigned_guide_id = $1,
          assigned_driver_id = $2,
          guide_name = $3,
          driver_name = $4,
          status = 'pending',
          updated_at = CURRENT_TIMESTAMP
        WHERE id = $5 OR booking_code = $5
        RETURNING *
      `, [
        bestGuide?.id || null,
        bestDriver?.id || null,
        bestGuide?.name || null,
        bestDriver?.name || null,
        bookingId
      ]);
      
      if (updateResult.rows.length === 0) {
        throw new Error('Booking not found');
      }
      
      console.log(`✅ Auto-assigned: Guide=${bestGuide?.name || 'None'}, Driver=${bestDriver?.name || 'None'}`);
      
      return {
        success: true,
        guide: bestGuide,
        driver: bestDriver,
        booking: updateResult.rows[0],
        conflicts_avoided: {
          guides: excludeStaffIds.guides?.length || 0,
          drivers: excludeStaffIds.drivers?.length || 0
        }
      };
      
    } catch (error) {
      console.error('❌ Error in auto-assignment:', error);
      throw error;
    }
  }

  /**
   * Validate assignment before saving
   */
  static async validateAssignment(staffId, staffType, startDate, endDate, bookingId = null) {
    try {
      const conflictCheck = await this.checkStaffConflicts(
        staffId, 
        staffType, 
        startDate, 
        endDate, 
        bookingId
      );
      
      if (conflictCheck.hasConflicts) {
        return {
          valid: false,
          error: `${staffType} has conflicting assignments`,
          conflicts: conflictCheck.conflicts,
          message: `${staffType} is already assigned to ${conflictCheck.conflictCount} other booking(s) during this period`
        };
      }
      
      return {
        valid: true,
        conflicts: [],
        message: `${staffType} is available for assignment`
      };
      
    } catch (error) {
      console.error('❌ Error validating assignment:', error);
      throw error;
    }
  }

  /**
   * Get staff workload summary
   */
  static async getStaffWorkload(staffId, staffType, dateRange = 30) {
    try {
      const staffIdField = staffType === 'guide' ? 'assigned_guide_id' : 'assigned_driver_id';
      const endDate = new Date();
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - dateRange);
      
      const result = await db.query(`
        SELECT 
          COUNT(*) as total_bookings,
          COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed_bookings,
          COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_bookings,
          COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_bookings,
          MIN(start_date) as earliest_booking,
          MAX(end_date) as latest_booking
        FROM bookings 
        WHERE ${staffIdField} = $1 
          AND start_date >= $2 
          AND start_date <= $3
      `, [staffId, startDate.toISOString().split('T')[0], endDate.toISOString().split('T')[0]]);
      
      return {
        staffId,
        staffType,
        dateRange,
        workload: result.rows[0]
      };
      
    } catch (error) {
      console.error('❌ Error getting staff workload:', error);
      throw error;
    }
  }
}

module.exports = ConflictDetectionService;