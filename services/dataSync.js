/**
 * Data Synchronization Service
 * Ensures frontend gets properly formatted booking data with assignments
 */

const db = require('../config/db');

class DataSyncService {
  /**
   * Get bookings with properly formatted assignment data for frontend
   */
  static async getBookingsForFrontend(filters = {}) {
    try {
      const { status, date_from, date_to, limit = 50, offset = 0, user_id } = filters;
      
      let whereClause = 'WHERE 1=1';
      const params = [];
      let paramCount = 0;

      // Filter by user if provided (for user-specific bookings)
      if (user_id) {
        paramCount++;
        whereClause += ` AND t.user_id = $${paramCount}`;
        params.push(user_id);
      }

      if (status) {
        paramCount++;
        whereClause += ` AND b.status = $${paramCount}`;
        params.push(status);
      }

      if (date_from) {
        paramCount++;
        whereClause += ` AND b.start_date >= $${paramCount}`;
        params.push(date_from);
      }

      if (date_to) {
        paramCount++;
        whereClause += ` AND b.start_date <= $${paramCount}`;
        params.push(date_to);
      }

      paramCount++;
      const limitClause = ` LIMIT $${paramCount}`;
      params.push(parseInt(limit));

      paramCount++;
      const offsetClause = ` OFFSET $${paramCount}`;
      params.push(parseInt(offset));

      const result = await db.query(`
        SELECT 
          b.*,
          tp.name as package_name,
          tp.name as tour_name,
          
          -- Guide information
          b.guide_name,
          b.assigned_guide_id,
          gu.email as guide_email,
          gu.phone as guide_phone,
          
          -- Driver information  
          b.driver_name,
          b.assigned_driver_id,
          du.email as driver_email,
          du.phone as driver_phone,
          
          -- Vehicle information
          v.make as vehicle_make,
          v.model as vehicle_model,
          v.plate_number as vehicle_plate,
          
          -- Tourist information
          tu.email as tourist_name,
          tu.email as tourist_email,
          tu.phone as tourist_phone,
          
          -- Custom tour name fallback
          COALESCE(b.custom_tour_name, tp.name, 'Custom Tour') as display_tour_name
          
        FROM bookings b
        LEFT JOIN tour_packages tp ON b.package_id = tp.id
        LEFT JOIN tourists t ON b.tourist_id = t.id
        LEFT JOIN users tu ON t.user_id = tu.id
        LEFT JOIN guides g ON b.assigned_guide_id = g.id
        LEFT JOIN users gu ON g.user_id = gu.id
        LEFT JOIN drivers d ON b.assigned_driver_id = d.id
        LEFT JOIN users du ON d.user_id = du.id
        LEFT JOIN vehicles v ON b.assigned_vehicle_id = v.id
        ${whereClause}
        ORDER BY b.start_date ASC, b.created_at DESC
        ${limitClause}
        ${offsetClause}
      `, params);

      // Format the data for frontend consumption
      const formattedBookings = result.rows.map(booking => ({
        ...booking,
        
        // Ensure these fields are always present for frontend table
        guide_name: booking.guide_name || null,
        driver_name: booking.driver_name || null,
        
        // Provide fallback display names
        tourist_name: booking.tourist_name || booking.tourist_email || 'Unknown',
        tour_name: booking.display_tour_name,
        
        // Assignment status flags for frontend logic
        has_guide: !!(booking.assigned_guide_id && booking.guide_name),
        has_driver: !!(booking.assigned_driver_id && booking.driver_name),
        is_fully_assigned: !!(booking.assigned_guide_id && booking.guide_name && 
                             booking.assigned_driver_id && booking.driver_name),
        
        // Formatted dates
        start_date_formatted: booking.start_date ? 
          new Date(booking.start_date).toLocaleDateString('en-GB', { 
            day: '2-digit', 
            month: 'short', 
            year: 'numeric' 
          }) : null,
          
        // Status with proper formatting
        status_display: booking.status ? 
          booking.status.charAt(0).toUpperCase() + booking.status.slice(1) : 'Pending'
      }));

      return {
        bookings: formattedBookings,
        total: result.rows.length
      };

    } catch (error) {
      console.error('❌ Error in getBookingsForFrontend:', error);
      throw error;
    }
  }

  /**
   * Get single booking with full assignment details
   */
  static async getBookingWithAssignments(bookingId) {
    try {
      const result = await db.query(`
        SELECT 
          b.*,
          tp.name as package_name,
          tp.name as tour_name,
          
          -- Guide information with full details
          b.guide_name,
          b.assigned_guide_id,
          gu.email as guide_email,
          gu.phone as guide_phone,
          g.rating as guide_rating,
          g.years_experience as guide_experience,
          
          -- Driver information with full details
          b.driver_name,
          b.assigned_driver_id,
          du.email as driver_email,
          du.phone as driver_phone,
          d.rating as driver_rating,
          d.years_experience as driver_experience,
          
          -- Vehicle information
          v.make as vehicle_make,
          v.model as vehicle_model,
          v.plate_number as vehicle_plate,
          v.year as vehicle_year,
          
          -- Tourist information
          tu.email as tourist_name,
          tu.email as tourist_email,
          tu.phone as tourist_phone
          
        FROM bookings b
        LEFT JOIN tour_packages tp ON b.package_id = tp.id
        LEFT JOIN tourists t ON b.tourist_id = t.id
        LEFT JOIN users tu ON t.user_id = tu.id
        LEFT JOIN guides g ON b.assigned_guide_id = g.id
        LEFT JOIN users gu ON g.user_id = gu.id
        LEFT JOIN drivers d ON b.assigned_driver_id = d.id
        LEFT JOIN users du ON d.user_id = du.id
        LEFT JOIN vehicles v ON b.assigned_vehicle_id = v.id
        WHERE b.id::text = $1 OR b.booking_code = $1
      `, [bookingId]);

      if (result.rows.length === 0) {
        return null;
      }

      const booking = result.rows[0];

      return {
        ...booking,
        
        // Ensure assignment fields are properly set
        guide_name: booking.guide_name || null,
        driver_name: booking.driver_name || null,
        
        // Assignment status
        has_guide: !!(booking.assigned_guide_id && booking.guide_name),
        has_driver: !!(booking.assigned_driver_id && booking.driver_name),
        is_fully_assigned: !!(booking.assigned_guide_id && booking.guide_name && 
                             booking.assigned_driver_id && booking.driver_name),
        
        // Staff details for display
        guide_details: booking.assigned_guide_id ? {
          id: booking.assigned_guide_id,
          name: booking.guide_name,
          email: booking.guide_email,
          phone: booking.guide_phone,
          rating: booking.guide_rating,
          experience: booking.guide_experience
        } : null,
        
        driver_details: booking.assigned_driver_id ? {
          id: booking.assigned_driver_id,
          name: booking.driver_name,
          email: booking.driver_email,
          phone: booking.driver_phone,
          rating: booking.driver_rating,
          experience: booking.driver_experience
        } : null,
        
        vehicle_details: booking.vehicle_make ? {
          make: booking.vehicle_make,
          model: booking.vehicle_model,
          plate: booking.vehicle_plate,
          year: booking.vehicle_year
        } : null
      };

    } catch (error) {
      console.error('❌ Error in getBookingWithAssignments:', error);
      throw error;
    }
  }

  /**
   * Refresh assignment data after update
   */
  static async refreshBookingAssignments(bookingId) {
    try {
      // Get the updated booking
      const booking = await this.getBookingWithAssignments(bookingId);
      
      if (!booking) {
        throw new Error('Booking not found');
      }

      // Emit real-time update via WebSocket
      const socketService = require('./socketService');
      const io = socketService.getIo();
      
      io.to(`booking_${bookingId}`).emit('booking_updated', {
        booking_id: bookingId,
        booking_code: booking.booking_code,
        guide_name: booking.guide_name,
        driver_name: booking.driver_name,
        has_guide: booking.has_guide,
        has_driver: booking.has_driver,
        is_fully_assigned: booking.is_fully_assigned,
        status: booking.status,
        updated_at: new Date().toISOString()
      });

      // Also emit to general updates channel for table refreshes
      io.emit('bookings_updated', {
        type: 'assignment_update',
        booking_id: bookingId,
        booking_code: booking.booking_code,
        changes: {
          guide_name: booking.guide_name,
          driver_name: booking.driver_name,
          status: booking.status
        }
      });

      return booking;

    } catch (error) {
      console.error('❌ Error refreshing booking assignments:', error);
      throw error;
    }
  }
}

module.exports = DataSyncService;