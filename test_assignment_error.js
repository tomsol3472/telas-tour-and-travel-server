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

async function testAssignmentError() {
  console.log('🧪 Testing Assignment Error\n');

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

    // Get a pending booking
    const bookingResult = await pool.query(`
      SELECT id, booking_code, start_date, end_date 
      FROM bookings 
      WHERE status = 'pending' 
      LIMIT 1
    `);

    if (bookingResult.rows.length === 0) {
      console.log('❌ No pending bookings found');
      return;
    }

    const booking = bookingResult.rows[0];
    console.log(`📋 Testing assignment for booking: ${booking.booking_code}`);

    // Get available staff
    const guideResult = await pool.query(`
      SELECT g.id, u.email as name 
      FROM guides g 
      JOIN users u ON g.user_id = u.id 
      WHERE g.is_available = true 
      LIMIT 1
    `);

    const driverResult = await pool.query(`
      SELECT d.id, u.email as name 
      FROM drivers d 
      JOIN users u ON d.user_id = u.id 
      WHERE d.is_available = true 
      LIMIT 1
    `);

    if (guideResult.rows.length === 0 || driverResult.rows.length === 0) {
      console.log('❌ No available staff found');
      return;
    }

    const guide = guideResult.rows[0];
    const driver = driverResult.rows[0];

    console.log(`👤 Guide: ${guide.name} (${guide.id})`);
    console.log(`🚗 Driver: ${driver.name} (${driver.id})`);

    // Try to assign
    console.log('\n🔄 Attempting assignment...');
    
    try {
      const response = await axios.patch(
        `${API_BASE}/bookings/${booking.booking_code}`,
        {
          assigned_guide_id: guide.id,
          assigned_driver_id: driver.id,
          status: 'confirmed'
        },
        {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        }
      );

      console.log('✅ Assignment successful!');
      console.log(`   Guide: ${response.data.booking.guide_name}`);
      console.log(`   Driver: ${response.data.booking.driver_name}`);
      console.log(`   Status: ${response.data.booking.status}`);

    } catch (error) {
      console.log('❌ Assignment failed!');
      console.log(`   Status: ${error.response?.status}`);
      console.log(`   Error: ${error.response?.data?.error}`);
      console.log(`   Details: ${error.response?.data?.details}`);
      
      if (error.response?.data?.code) {
        console.log(`   SQL Code: ${error.response.data.code}`);
      }

      // Show full error for debugging
      console.log('\n📋 Full error response:');
      console.log(JSON.stringify(error.response?.data, null, 2));
    }

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  } finally {
    await pool.end();
  }
}

testAssignmentError();