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

async function testAPIResponse() {
  console.log('🧪 Testing API Response vs Database Data\n');

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

    // Get a confirmed booking from database
    const dbResult = await pool.query(`
      SELECT booking_code, guide_name, driver_name, status 
      FROM bookings 
      WHERE status = 'confirmed' AND guide_name IS NOT NULL 
      LIMIT 1
    `);

    if (dbResult.rows.length === 0) {
      console.log('❌ No confirmed bookings with assignments found');
      return;
    }

    const booking = dbResult.rows[0];
    console.log('📊 Database Data:');
    console.log(`   Booking: ${booking.booking_code}`);
    console.log(`   Status: ${booking.status}`);
    console.log(`   Guide Name: "${booking.guide_name}"`);
    console.log(`   Driver Name: "${booking.driver_name}"`);

    // Test API response
    console.log('\n🌐 API Response:');
    try {
      const apiResponse = await axios.get(`${API_BASE}/bookings/${booking.booking_code}`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      const apiBooking = apiResponse.data.booking;
      console.log(`   Booking: ${apiBooking.booking_code}`);
      console.log(`   Status: ${apiBooking.status}`);
      console.log(`   Guide Name: "${apiBooking.guide_name}"`);
      console.log(`   Driver Name: "${apiBooking.driver_name}"`);
      console.log(`   Has Guide: ${apiBooking.has_guide}`);
      console.log(`   Has Driver: ${apiBooking.has_driver}`);
      console.log(`   Is Fully Assigned: ${apiBooking.is_fully_assigned}`);

      // Compare
      console.log('\n🔍 Comparison:');
      const guideMatch = booking.guide_name === apiBooking.guide_name;
      const driverMatch = booking.driver_name === apiBooking.driver_name;
      const statusMatch = booking.status === apiBooking.status;

      console.log(`   Guide Name Match: ${guideMatch ? '✅' : '❌'}`);
      console.log(`   Driver Name Match: ${driverMatch ? '✅' : '❌'}`);
      console.log(`   Status Match: ${statusMatch ? '✅' : '❌'}`);

      if (!guideMatch || !driverMatch) {
        console.log('\n🚨 MISMATCH DETECTED!');
        console.log('   Database has correct data but API returns different data');
        console.log('   This suggests an issue in the DataSyncService or controller');
      } else {
        console.log('\n✅ DATA MATCHES!');
        console.log('   The issue might be in the frontend display logic');
      }

    } catch (apiError) {
      console.log('❌ API Error:', apiError.response?.status, apiError.response?.statusText);
      console.log('   Details:', apiError.response?.data);
    }

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  } finally {
    await pool.end();
  }
}

testAPIResponse();