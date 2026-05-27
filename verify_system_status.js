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

async function verifySystemStatus() {
  console.log('🔍 SYSTEM STATUS VERIFICATION\n');
  console.log('=' .repeat(60));

  const issues = [];
  const successes = [];

  try {
    // 1. Check database schema
    console.log('\n1️⃣ Checking Database Schema...');
    
    const schemaCheck = await pool.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'bookings' 
        AND column_name IN ('guide_name', 'driver_name', 'assigned_guide_id', 'assigned_driver_id')
      ORDER BY column_name
    `);

    if (schemaCheck.rows.length === 4) {
      console.log('✅ Database schema correct');
      console.log('   - guide_name column exists');
      console.log('   - driver_name column exists');
      console.log('   - assigned_guide_id column exists');
      console.log('   - assigned_driver_id column exists');
      successes.push('Database schema');
    } else {
      console.log('❌ Database schema incomplete');
      issues.push('Missing columns in bookings table');
    }

    // 2. Check for data consistency
    console.log('\n2️⃣ Checking Data Consistency...');
    
    const inconsistentData = await pool.query(`
      SELECT 
        booking_code,
        assigned_guide_id,
        guide_name,
        assigned_driver_id,
        driver_name,
        status
      FROM bookings
      WHERE 
        (assigned_guide_id IS NOT NULL AND guide_name IS NULL) OR
        (assigned_driver_id IS NOT NULL AND driver_name IS NULL)
      LIMIT 5
    `);

    if (inconsistentData.rows.length > 0) {
      console.log(`⚠️  Found ${inconsistentData.rows.length} bookings with inconsistent data:`);
      inconsistentData.rows.forEach(booking => {
        console.log(`   ${booking.booking_code}:`);
        if (booking.assigned_guide_id && !booking.guide_name) {
          console.log(`     - Has guide_id but no guide_name`);
        }
        if (booking.assigned_driver_id && !booking.driver_name) {
          console.log(`     - Has driver_id but no driver_name`);
        }
      });
      issues.push('Data inconsistency detected');
    } else {
      console.log('✅ All bookings have consistent assignment data');
      successes.push('Data consistency');
    }

    // 3. Check for conflicts
    console.log('\n3️⃣ Checking for Staff Conflicts...');
    
    const conflicts = await pool.query(`
      WITH staff_assignments AS (
        SELECT 
          'guide' as staff_type,
          assigned_guide_id as staff_id,
          guide_name as staff_name,
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
        a1.staff_name,
        a1.booking_code as booking1,
        a2.booking_code as booking2,
        a1.start_date as start1,
        a1.end_date as end1,
        a2.start_date as start2,
        a2.end_date as end2
      FROM staff_assignments a1
      JOIN staff_assignments a2 ON a1.staff_id = a2.staff_id 
        AND a1.staff_type = a2.staff_type
        AND a1.booking_code < a2.booking_code
      WHERE 
        (a1.start_date <= a2.end_date AND a1.end_date >= a2.start_date)
      ORDER BY a1.staff_name, a1.start_date
    `);

    if (conflicts.rows.length > 0) {
      console.log(`⚠️  Found ${conflicts.rows.length} staff conflicts:`);
      conflicts.rows.forEach(conflict => {
        console.log(`   ${conflict.staff_type}: ${conflict.staff_name}`);
        console.log(`     ${conflict.booking1}: ${conflict.start1} to ${conflict.end1}`);
        console.log(`     ${conflict.booking2}: ${conflict.start2} to ${conflict.end2}`);
      });
      issues.push('Staff conflicts detected');
    } else {
      console.log('✅ No staff conflicts detected');
      successes.push('No conflicts');
    }

    // 4. Test API endpoints
    console.log('\n4️⃣ Testing API Endpoints...');
    
    // Get test user token
    const userResult = await pool.query(`
      SELECT id, email FROM users WHERE user_role IN ('admin', 'agency_staff') LIMIT 1
    `);

    if (userResult.rows.length === 0) {
      console.log('⚠️  No admin user found for API testing');
      issues.push('No admin user available');
    } else {
      const testUser = userResult.rows[0];
      const token = jwt.sign({ userId: testUser.id }, JWT_SECRET, { expiresIn: '1h' });

      // Test 4a: Get bookings
      try {
        const bookingsResponse = await axios.get(`${API_BASE}/bookings`, {
          headers: { 'Authorization': `Bearer ${token}` }
        });
        console.log(`✅ GET /bookings - ${bookingsResponse.data.bookings.length} bookings returned`);
        
        // Check if bookings have proper flags
        const sampleBooking = bookingsResponse.data.bookings[0];
        if (sampleBooking) {
          const hasFlags = 'has_guide' in sampleBooking && 'has_driver' in sampleBooking;
          if (hasFlags) {
            console.log('   ✅ Bookings include assignment flags');
            successes.push('API returns proper flags');
          } else {
            console.log('   ⚠️  Bookings missing assignment flags');
            issues.push('Missing assignment flags in API response');
          }
        }
      } catch (error) {
        console.log(`❌ GET /bookings failed: ${error.message}`);
        issues.push('GET /bookings endpoint error');
      }

      // Test 4b: Available staff endpoint
      try {
        const availableResponse = await axios.get(`${API_BASE}/bookings/staff/available`, {
          params: {
            startDate: '2026-05-25',
            endDate: '2026-05-30'
          },
          headers: { 'Authorization': `Bearer ${token}` }
        });
        console.log(`✅ GET /bookings/staff/available - Working`);
        console.log(`   Guides: ${availableResponse.data.available_staff.guides.count}`);
        console.log(`   Drivers: ${availableResponse.data.available_staff.drivers.count}`);
        successes.push('Available staff API');
      } catch (error) {
        console.log(`❌ GET /bookings/staff/available failed: ${error.response?.status || error.message}`);
        issues.push('Available staff endpoint error');
      }

      // Test 4c: Get a specific booking
      const testBooking = await pool.query(`
        SELECT booking_code FROM bookings LIMIT 1
      `);

      if (testBooking.rows.length > 0) {
        try {
          const bookingResponse = await axios.get(
            `${API_BASE}/bookings/${testBooking.rows[0].booking_code}`,
            { headers: { 'Authorization': `Bearer ${token}` } }
          );
          
          const booking = bookingResponse.data.booking;
          console.log(`✅ GET /bookings/:id - Working`);
          console.log(`   Booking: ${booking.booking_code}`);
          console.log(`   Guide: ${booking.guide_name || 'Unassigned'}`);
          console.log(`   Driver: ${booking.driver_name || 'Unassigned'}`);
          console.log(`   Flags: has_guide=${booking.has_guide}, has_driver=${booking.has_driver}`);
          successes.push('Get booking by ID API');
        } catch (error) {
          console.log(`❌ GET /bookings/:id failed: ${error.message}`);
          issues.push('Get booking by ID error');
        }
      }
    }

    // 5. Check services
    console.log('\n5️⃣ Checking Services...');
    
    const services = [
      'services/conflictDetectionService.js',
      'services/assignmentNotificationService.js',
      'services/dataSync.js',
      'services/socketService.js'
    ];

    const fs = require('fs');
    const path = require('path');

    services.forEach(service => {
      const servicePath = path.join(__dirname, service);
      if (fs.existsSync(servicePath)) {
        console.log(`✅ ${service} exists`);
        successes.push(service);
      } else {
        console.log(`❌ ${service} missing`);
        issues.push(`Missing ${service}`);
      }
    });

    // 6. Check for pending notifications
    console.log('\n6️⃣ Checking Notifications System...');
    
    const notificationsCheck = await pool.query(`
      SELECT COUNT(*) as total,
             COUNT(CASE WHEN is_read = false THEN 1 END) as unread,
             COUNT(CASE WHEN notification_type = 'assignment_request' THEN 1 END) as assignment_requests
      FROM notifications
      WHERE created_at > NOW() - INTERVAL '7 days'
    `);

    const notifStats = notificationsCheck.rows[0];
    console.log(`✅ Notifications system active`);
    console.log(`   Total (last 7 days): ${notifStats.total}`);
    console.log(`   Unread: ${notifStats.unread}`);
    console.log(`   Assignment requests: ${notifStats.assignment_requests}`);
    successes.push('Notifications system');

    // 7. Summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 SUMMARY\n');
    
    console.log(`✅ Successes: ${successes.length}`);
    successes.forEach(success => console.log(`   ✓ ${success}`));
    
    console.log(`\n❌ Issues: ${issues.length}`);
    if (issues.length > 0) {
      issues.forEach(issue => console.log(`   ✗ ${issue}`));
    } else {
      console.log('   None - System is fully operational! 🎉');
    }

    console.log('\n' + '='.repeat(60));
    
    if (issues.length === 0) {
      console.log('\n🎉 ALL SYSTEMS OPERATIONAL');
      console.log('\nThe assignment system is working correctly:');
      console.log('  ✅ Database schema complete');
      console.log('  ✅ Data consistency maintained');
      console.log('  ✅ No staff conflicts');
      console.log('  ✅ All API endpoints working');
      console.log('  ✅ All services in place');
      console.log('  ✅ Notifications system active');
      console.log('\nIf frontend still shows "Unassigned":');
      console.log('  1. Hard refresh the frontend (Ctrl+Shift+R)');
      console.log('  2. Clear browser cache');
      console.log('  3. Check frontend data binding');
      console.log('  4. Verify API calls are using correct endpoints');
    } else {
      console.log('\n⚠️  ISSUES DETECTED');
      console.log('\nRecommended actions:');
      
      if (issues.includes('Data inconsistency detected')) {
        console.log('  1. Run data sync script to fix inconsistent bookings');
      }
      if (issues.includes('Staff conflicts detected')) {
        console.log('  2. Review and reassign conflicting bookings');
      }
      if (issues.some(i => i.includes('API'))) {
        console.log('  3. Check server logs for API errors');
      }
    }

  } catch (error) {
    console.error('\n❌ Verification failed:', error.message);
    console.error(error.stack);
  } finally {
    await pool.end();
  }
}

// Run verification
verifySystemStatus().catch(console.error);
