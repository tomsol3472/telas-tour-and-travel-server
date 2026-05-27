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
const JWT_SECRET = 'super_secure_random_string_2024'; // From .env

async function testAssignmentWithAuth() {
  console.log('🧪 Testing Assignment Persistence with Authentication\n');

  try {
    // Step 1: Get or create a test user
    console.log('1️⃣ Setting up test user...');
    
    let testUser;
    const userCheck = await pool.query(`
      SELECT id, email FROM users WHERE email = 'test@admin.com' LIMIT 1
    `);

    if (userCheck.rows.length === 0) {
      console.log('Creating test admin user...');
      const createUser = await pool.query(`
        INSERT INTO users (email, phone, password_hash, user_role, status) 
        VALUES ('test@admin.com', '0911000000', '$2b$10$dummy.hash.for.testing', 'admin', 'active')
        RETURNING id, email, user_role
      `);
      testUser = createUser.rows[0];
    } else {
      testUser = userCheck.rows[0];
      console.log('Using existing test user');
    }

    console.log(`✅ Test user: ${testUser.email} (${testUser.id})`);

    // Step 2: Create JWT token
    console.log('\n2️⃣ Creating JWT token...');
    const token = jwt.sign(
      { userId: testUser.id },
      JWT_SECRET,
      { expiresIn: '1h' }
    );
    console.log('✅ JWT token created');

    // Step 3: Get test booking and staff
    console.log('\n3️⃣ Getting test data...');
    
    const booking = await pool.query(`
      SELECT id, booking_code, assigned_guide_id, assigned_driver_id, guide_name, driver_name
      FROM bookings 
      ORDER BY created_at DESC 
      LIMIT 1
    `);

    if (booking.rows.length === 0) {
      console.log('❌ No bookings found for testing');
      return;
    }

    const testBooking = booking.rows[0];
    console.log(`✅ Test booking: ${testBooking.booking_code} (${testBooking.id})`);

    // Get or create test guide and driver
    let testGuide = await pool.query(`
      SELECT g.id, u.email as name 
      FROM guides g 
      JOIN users u ON g.user_id = u.id 
      WHERE g.is_available = true 
      LIMIT 1
    `);
    
    if (testGuide.rows.length === 0) {
      console.log('No available guides found');
      return;
    }

    let testDriver = await pool.query(`
      SELECT d.id, u.email as name 
      FROM drivers d 
      JOIN users u ON d.user_id = u.id 
      WHERE d.is_available = true 
      LIMIT 1
    `);
    
    if (testDriver.rows.length === 0) {
      console.log('No available drivers found');
      return;
    }

    const guide = testGuide.rows[0];
    const driver = testDriver.rows[0];

    console.log(`✅ Test guide: ${guide.name} (${guide.id})`);
    console.log(`✅ Test driver: ${driver.name} (${driver.id})`);

    // Step 4: Test assignment API
    console.log('\n4️⃣ Testing assignment API...');
    
    const assignmentData = {
      assigned_guide_id: guide.id,
      assigned_driver_id: driver.id,
      status: 'confirmed'
    };

    console.log('Assignment data:', assignmentData);

    try {
      const response = await axios.patch(
        `${API_BASE}/bookings/${testBooking.booking_code}`,
        assignmentData,
        {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          },
          timeout: 10000
        }
      );

      console.log('✅ Assignment API call successful!');
      console.log('Response status:', response.status);
      console.log('Updated booking:', {
        id: response.data.booking.id,
        booking_code: response.data.booking.booking_code,
        guide_name: response.data.booking.guide_name,
        driver_name: response.data.booking.driver_name,
        assigned_guide_id: response.data.booking.assigned_guide_id,
        assigned_driver_id: response.data.booking.assigned_driver_id,
        status: response.data.booking.status
      });

    } catch (error) {
      console.log('❌ Assignment API call failed:', error.response?.status, error.response?.statusText);
      console.log('Error details:', error.response?.data);
      if (error.response?.data?.details) {
        console.log('SQL Error:', error.response.data.details);
      }
    }

    // Step 5: Verify persistence in database
    console.log('\n5️⃣ Verifying persistence in database...');
    
    const verifyResult = await pool.query(`
      SELECT booking_code, assigned_guide_id, assigned_driver_id, guide_name, driver_name, status
      FROM bookings 
      WHERE id::text = $1 OR booking_code = $1
    `, [testBooking.id]);

    if (verifyResult.rows.length > 0) {
      const updated = verifyResult.rows[0];
      console.log('✅ Database verification:');
      console.log(`   Guide: ${updated.guide_name} (${updated.assigned_guide_id})`);
      console.log(`   Driver: ${updated.driver_name} (${updated.assigned_driver_id})`);
      console.log(`   Status: ${updated.status}`);

      // Check if assignments persisted
      if (updated.assigned_guide_id && updated.assigned_driver_id) {
        console.log('🎉 SUCCESS: Assignments persisted correctly!');
      } else {
        console.log('⚠️  WARNING: Some assignments may not have persisted');
      }
    }

    // Step 6: Test retrieval API
    console.log('\n6️⃣ Testing retrieval API...');
    
    try {
      const getResponse = await axios.get(
        `${API_BASE}/bookings/${testBooking.booking_code}`,
        {
          headers: {
            'Authorization': `Bearer ${token}`
          },
          timeout: 5000
        }
      );

      console.log('✅ Retrieval API successful');
      const retrieved = getResponse.data.booking;
      console.log('Retrieved booking assignments:');
      console.log(`   Guide: ${retrieved.guide_name} (${retrieved.assigned_guide_id})`);
      console.log(`   Driver: ${retrieved.driver_name} (${retrieved.assigned_driver_id})`);
      
      if (retrieved.guide_name && retrieved.driver_name) {
        console.log('🎉 SUCCESS: Assignments are visible in API response!');
      }

    } catch (error) {
      console.log('❌ Retrieval API failed:', error.response?.status);
      console.log('Error:', error.response?.data);
    }

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  } finally {
    await pool.end();
  }
}

testAssignmentWithAuth();