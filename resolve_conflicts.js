const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  password: 'tom3472sol',
  host: 'localhost',
  port: 5432,
  database: 'TelasUpdateDB'
});

async function resolveConflicts() {
  console.log('🔧 RESOLVING STAFF CONFLICTS\n');
  console.log('=' .repeat(60));

  try {
    // 1. Find all conflicts
    console.log('\n1️⃣ Identifying conflicts...');
    
    const conflicts = await pool.query(`
      WITH staff_assignments AS (
        SELECT 
          'guide' as staff_type,
          assigned_guide_id as staff_id,
          guide_name as staff_name,
          id as booking_id,
          booking_code,
          start_date,
          end_date,
          status
        FROM bookings 
        WHERE assigned_guide_id IS NOT NULL 
          AND status IN ('confirmed', 'pending', 'assigned', 'ongoing')
        
        UNION ALL
        
        SELECT 
          'driver' as staff_type,
          assigned_driver_id as staff_id,
          driver_name as staff_name,
          id as booking_id,
          booking_code,
          start_date,
          end_date,
          status
        FROM bookings 
        WHERE assigned_driver_id IS NOT NULL 
          AND status IN ('confirmed', 'pending', 'assigned', 'ongoing')
      )
      SELECT 
        a1.staff_type,
        a1.staff_id,
        a1.staff_name,
        a1.booking_id as booking1_id,
        a1.booking_code as booking1,
        a2.booking_id as booking2_id,
        a2.booking_code as booking2,
        a1.start_date as start1,
        a1.end_date as end1,
        a2.start_date as start2,
        a2.end_date as end2,
        a1.status as status1,
        a2.status as status2
      FROM staff_assignments a1
      JOIN staff_assignments a2 ON a1.staff_id = a2.staff_id 
        AND a1.staff_type = a2.staff_type
        AND a1.booking_code < a2.booking_code
      WHERE 
        (a1.start_date <= a2.end_date AND a1.end_date >= a2.start_date)
      ORDER BY a1.staff_name, a1.start_date
    `);

    if (conflicts.rows.length === 0) {
      console.log('✅ No conflicts found!');
      return;
    }

    console.log(`⚠️  Found ${conflicts.rows.length} conflicts`);

    // 2. Group conflicts by staff
    const conflictsByStaff = {};
    conflicts.rows.forEach(conflict => {
      const key = `${conflict.staff_type}_${conflict.staff_id}`;
      if (!conflictsByStaff[key]) {
        conflictsByStaff[key] = {
          staff_type: conflict.staff_type,
          staff_id: conflict.staff_id,
          staff_name: conflict.staff_name,
          bookings: new Set()
        };
      }
      conflictsByStaff[key].bookings.add(conflict.booking1);
      conflictsByStaff[key].bookings.add(conflict.booking2);
    });

    // 3. Resolve each staff's conflicts
    console.log('\n2️⃣ Resolving conflicts...\n');

    for (const [key, staffConflict] of Object.entries(conflictsByStaff)) {
      console.log(`📋 ${staffConflict.staff_type}: ${staffConflict.staff_name}`);
      console.log(`   Conflicting bookings: ${Array.from(staffConflict.bookings).join(', ')}`);

      // Get all bookings for this staff
      const staffBookings = await pool.query(`
        SELECT id, booking_code, start_date, end_date, status, created_at
        FROM bookings
        WHERE ${staffConflict.staff_type === 'guide' ? 'assigned_guide_id' : 'assigned_driver_id'} = $1
          AND status IN ('confirmed', 'pending', 'assigned', 'ongoing')
        ORDER BY created_at ASC
      `, [staffConflict.staff_id]);

      // Keep the first booking (oldest), reassign others
      const keepBooking = staffBookings.rows[0];
      const reassignBookings = staffBookings.rows.slice(1);

      console.log(`   ✅ Keeping: ${keepBooking.booking_code} (created first)`);

      for (const booking of reassignBookings) {
        console.log(`   🔄 Reassigning: ${booking.booking_code}`);

        // Find alternative staff
        const alternativeStaff = await pool.query(`
          SELECT s.id, u.email as name
          FROM ${staffConflict.staff_type}s s
          JOIN users u ON s.user_id = u.id
          WHERE s.is_available = true
            AND s.id != $1
            AND NOT EXISTS (
              SELECT 1 FROM bookings b
              WHERE ${staffConflict.staff_type === 'guide' ? 'b.assigned_guide_id' : 'b.assigned_driver_id'} = s.id
                AND b.status IN ('confirmed', 'pending', 'assigned', 'ongoing')
                AND (
                  (b.start_date <= $2 AND b.end_date >= $2) OR
                  (b.start_date <= $3 AND b.end_date >= $3) OR
                  (b.start_date >= $2 AND b.end_date <= $3)
                )
            )
          ORDER BY s.rating DESC, s.years_experience DESC
          LIMIT 1
        `, [staffConflict.staff_id, booking.start_date, booking.end_date]);

        if (alternativeStaff.rows.length > 0) {
          const newStaff = alternativeStaff.rows[0];
          
          // Update booking with new staff
          const updateField = staffConflict.staff_type === 'guide' ? 
            'assigned_guide_id = $1, guide_name = $2' : 
            'assigned_driver_id = $1, driver_name = $2';

          await pool.query(`
            UPDATE bookings
            SET ${updateField}, updated_at = CURRENT_TIMESTAMP
            WHERE id = $3
          `, [newStaff.id, newStaff.name, booking.id]);

          console.log(`      → Assigned to: ${newStaff.name}`);
        } else {
          // No alternative found, unassign
          const updateField = staffConflict.staff_type === 'guide' ? 
            'assigned_guide_id = NULL, guide_name = NULL' : 
            'assigned_driver_id = NULL, driver_name = NULL';

          await pool.query(`
            UPDATE bookings
            SET ${updateField}, status = 'pending', updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
          `, [booking.id]);

          console.log(`      → Unassigned (no alternative available)`);
        }
      }

      console.log('');
    }

    // 4. Verify conflicts are resolved
    console.log('3️⃣ Verifying resolution...\n');

    const remainingConflicts = await pool.query(`
      WITH staff_assignments AS (
        SELECT 
          'guide' as staff_type,
          assigned_guide_id as staff_id,
          guide_name as staff_name,
          booking_code,
          start_date,
          end_date
        FROM bookings 
        WHERE assigned_guide_id IS NOT NULL 
          AND status IN ('confirmed', 'pending', 'assigned', 'ongoing')
        
        UNION ALL
        
        SELECT 
          'driver' as staff_type,
          assigned_driver_id as staff_id,
          driver_name as staff_name,
          booking_code,
          start_date,
          end_date
        FROM bookings 
        WHERE assigned_driver_id IS NOT NULL 
          AND status IN ('confirmed', 'pending', 'assigned', 'ongoing')
      )
      SELECT COUNT(*) as conflict_count
      FROM staff_assignments a1
      JOIN staff_assignments a2 ON a1.staff_id = a2.staff_id 
        AND a1.staff_type = a2.staff_type
        AND a1.booking_code < a2.booking_code
      WHERE 
        (a1.start_date <= a2.end_date AND a1.end_date >= a2.start_date)
    `);

    const remainingCount = parseInt(remainingConflicts.rows[0].conflict_count);

    if (remainingCount === 0) {
      console.log('✅ All conflicts resolved!');
    } else {
      console.log(`⚠️  ${remainingCount} conflicts still remain`);
      console.log('   These may require manual intervention');
    }

    // 5. Summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 RESOLUTION SUMMARY\n');
    
    console.log(`Initial conflicts: ${conflicts.rows.length}`);
    console.log(`Remaining conflicts: ${remainingCount}`);
    console.log(`Resolved: ${conflicts.rows.length - remainingCount}`);

    if (remainingCount === 0) {
      console.log('\n🎉 SUCCESS! All staff conflicts have been resolved.');
      console.log('   Each staff member is now assigned to non-overlapping bookings.');
    }

    console.log('\n' + '='.repeat(60));

  } catch (error) {
    console.error('\n❌ Resolution failed:', error.message);
    console.error(error.stack);
  } finally {
    await pool.end();
  }
}

// Run resolution
resolveConflicts().catch(console.error);
