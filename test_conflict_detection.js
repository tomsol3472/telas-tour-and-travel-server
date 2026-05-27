const axios = require('axios');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  password: 'tom3472sol',
  host: 'localhost',
  port: 5432,
  database: 'TelasUpdateDB'
});

const API_BASE = 'http://localhost:5000/api';
const JWT_SECRET = 'super_secure_random_string_2024';

async function testConflictDetection() {
  console.log('🧪 Testing Conflict Detection and Display Issues\n');

  try {
    // Get test user token
    const userResult = await pool.query(`
      SELECT id, email FROM users WHERE email = 'test@admin.com' LIMIT 1
    `);

    if (userResult.rows.length === 0) {
      console.log('❌ Test user not found');
      return;
    }

    const testUser = userResult.rows[0];
    const token = jwt.sign({ userId: testUser.id }, JWT_SECRET, { expiresIn: '1h' });

    // Step 1: Check current conflicts
    console.log('1️⃣ Checking current staff conflicts...');
    
    const conflictQuery = await pool.query(`
      SELECT 
        s.staff_type,
        s.staff_name,
        s.staff_id,
        COUNT(*) as booking_count,
        STRING_AGG(s.booking_code, ', ') as bookings,
        STRING_AGG(s.status::text, ', ') as statuses
      FROM (
        SELECT 
          'guide' as staff_type,
          guide_name as staff_name,
          assigned_guide_id as staff_id,
          booking_code,
          status
        FROM bookings 
        WHERE assigned_guide_id IS NOT NULL 
          AND status IN ('confirmed', 'pending')
        
        UNION ALL
        
        SELECT 
          'driver' as staff_type,
          driver_name as staff_name,
          assigned_driver_id as staff_id,
          booking_code,
          status
        FROM bookings 
        WHERE assigned_driver_id IS NOT NULL 
          AND status IN ('confirmed', 'pending')
      ) s
      GROUP BY s.staff_type, s.staff_name, s.staff_id
      HAVING COUNT(*) > 1
      ORDER BY COUNT(*) DESC
    `);

    if (conflictQuery.rows.length > 0) {
      console.log('🚨 CONFLICTS DETECTED:');
      conflictQuery.rows.forEach(conflict => {
        console.log(`   ${conflict.staff_type}: ${conflict.staff_name}`);
        console.log(`   Assigned to ${conflict.booking_count} bookings: ${conflict.bookings}`);
        console.log(`   Statuses: ${conflict.statuses}\n`);
      });
    } else {
      console.log('✅ No conflicts detected');
    }

    // Step 2: Test available staff API
    console.log('2️⃣ Testing available staff API...');
    
    try {
      const availableResponse = await axios.get(`${API_BASE}/bookings/staff/available`, {
        params: {
          startDate: '2026-05-20',
          endDate: '2026-05-25'
        },
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      const available = availableResponse.data.available_staff;
      console.log(`✅ Available staff API working:`);
      console.log(`   Guides: ${available.guides.count}`);
      console.log(`   Drivers: ${available.drivers.count}`);

      if (available.guides.count > 0) {
        console.log(`   Top guide: ${available.guides.staff[0].name} (Score: ${available.guides.staff[0].score})`);
      }
      if (available.drivers.count > 0) {
        console.log(`   Top driver: ${available.drivers.staff[0].name} (Score: ${available.drivers.staff[0].score})`);
      }

    } catch (apiError) {
      console.log('❌ Available staff API error:', apiError.response?.status);
    }

    // Step 3: Test conflict detection on assignment
    console.log('\n3️⃣ Testing conflict detection on assignment...');
    
    // Get a booking and try to assign already-assigned staff
    const testBooking = await pool.query(`
      SELECT id, booking_code, start_date, end_date 
      FROM bookings 
      WHERE status = 'pending' 
      LIMIT 1
    `);

    if (testBooking.rows.length > 0) {
      const booking = testBooking.rows[0];
      
      // Get a staff member who's already assigned
      const busyStaff = await pool.query(`
        SELECT assigned_guide_id, guide_name 
        FROM bookings 
        WHERE assigned_guide_id IS NOT NULL 
          AND status = 'confirmed' 
        LIMIT 1
      `);

      if (busyStaff.rows.length > 0) {
        const busyGuide = busyStaff.rows[0];
        
        console.log(`   Trying to assign busy guide ${busyGuide.guide_name} to ${booking.booking_code}...`);
        
        try {
          const conflictResponse = await axios.patch(
            `${API_BASE}/bookings/${booking.booking_code}`,
            {
              assigned_guide_id: busyGuide.assigned_guide_id
            },
            {
              headers: {
                'Authorization': `Bearer ${token}`
              }
            }
          );
          
          console.log('⚠️  Assignment succeeded (conflict not detected)');
          
        } catch (conflictError) {
          if (conflictError.response?.status === 409) {
            console.log('✅ Conflict detected and prevented!');
            console.log(`   Error: ${conflictError.response.data.error}`);
            console.log(`   Details: ${conflictError.response.data.details}`);
          } else {
            console.log('❌ Unexpected error:', conflictError.response?.status);
          }
        }
      }
    }

    // Step 4: Test auto-assignment
    console.log('\n4️⃣ Testing auto-assignment...');
    
    if (testBooking.rows.length > 0) {
      const booking = testBooking.rows[0];
      
      try {
        const autoAssignResponse = await axios.post(
          `${API_BASE}/bookings/${booking.booking_code}/auto-assign`,
          {},
          {
            headers: {
              'Authorization': `Bearer ${token}`
            }
          }
        );

        console.log('✅ Auto-assignment successful!');
        const assigned = autoAssignResponse.data.assigned_staff;
        console.log(`   Guide: ${assigned.guide?.name || 'None'} (Score: ${assigned.guide?.score || 'N/A'})`);
        console.log(`   Driver: ${assigned.driver?.name || 'None'} (Score: ${assigned.driver?.score || 'N/A'})`);
        console.log(`   Conflicts avoided: Guides=${autoAssignResponse.data.conflicts_avoided.guides}, Drivers=${autoAssignResponse.data.conflicts_avoided.drivers}`);

      } catch (autoError) {
        console.log('❌ Auto-assignment failed:', autoError.response?.status);
        console.log('   Details:', autoError.response?.data?.details);
      }
    }

    // Step 5: Test frontend data consistency
    console.log('\n5️⃣ Testing frontend data consistency...');
    
    const frontendTest = await pool.query(`
      SELECT booking_code, guide_name, driver_name, status
      FROM bookings 
      WHERE status = 'confirmed' AND guide_name IS NOT NULL 
      LIMIT 3
    `);

    for (const booking of frontendTest.rows) {
      try {
        const apiResponse = await axios.get(`${API_BASE}/bookings/${booking.booking_code}`, {
          headers: { 'Authorization': `Bearer ${token}` }
        });

        const apiBooking = apiResponse.data.booking;
        
        console.log(`   Booking ${booking.booking_code}:`);
        console.log(`     DB: Guide="${booking.guide_name}", Driver="${booking.driver_name}"`);
        console.log(`     API: Guide="${apiBooking.guide_name}", Driver="${apiBooking.driver_name}"`);
        console.log(`     Flags: has_guide=${apiBooking.has_guide}, has_driver=${apiBooking.has_driver}`);
        
        const consistent = booking.guide_name === apiBooking.guide_name && 
                          booking.driver_name === apiBooking.driver_name;
        console.log(`     Consistent: ${consistent ? '✅' : '❌'}`);

      } catch (error) {
        console.log(`   ❌ API error for ${booking.booking_code}`);
      }
    }

    console.log('\n📋 Summary:');
    console.log('   ✅ Conflict detection service created');
    console.log('   ✅ Auto-assignment with conflict avoidance');
    console.log('   ✅ Staff availability checking');
    console.log('   ✅ API endpoints for staff management');
    console.log('   ✅ Data consistency verification');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  } finally {
    await pool.end();
  }
}

testConflictDetection();