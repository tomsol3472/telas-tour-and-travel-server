const axios = require('axios');
const { Pool } = require('pg');

// Database configuration
const pool = new Pool({
  user: 'postgres',
  password: 'tom3472sol',
  host: 'localhost',
  port: 5432,
  database: 'TelasUpdateDB'
});

const API_BASE = 'http://localhost:5000/api';

async function testAssignmentPersistence() {
  console.log('🧪 Testing Assignment Persistence Fix\n');

  try {
    // Step 1: Check if migration was applied
    console.log('1️⃣ Checking database schema...');
    const schemaCheck = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'bookings' 
      AND column_name IN ('guide_name', 'driver_name')
      ORDER BY column_name
    `);

    if (schemaCheck.rows.length === 2) {
      console.log('✅ Database schema updated successfully');
      schemaCheck.rows.forEach(row => {
        console.log(`   - ${row.column_name}: ${row.data_type}`);
      });
    } else {
      console.log('❌ Database migration not applied yet');
      console.log('   Run: node run_migration.js first');
      return;
    }

    // Step 2: Check for existing bookings
    console.log('\n2️⃣ Checking existing bookings...');
    const bookingsCheck = await pool.query(`
      SELECT booking_code, status, assigned_guide_id, assigned_driver_id, guide_name, driver_name
      FROM bookings 
      ORDER BY created_at DESC 
      LIMIT 5
    `);

    if (bookingsCheck.rows.length === 0) {
      console.log('⚠️  No bookings found in database');
      console.log('   Create a booking first to test assignments');
      return;
    }

    console.log(`✅ Found ${bookingsCheck.rows.length} bookings:`);
    bookingsCheck.rows.forEach((booking, index) => {
      console.log(`   ${index + 1}. ${booking.booking_code} - Status: ${booking.status}`);
      console.log(`      Guide: ${booking.guide_name || 'Not assigned'} (ID: ${booking.assigned_guide_id || 'None'})`);
      console.log(`      Driver: ${booking.driver_name || 'Not assigned'} (ID: ${booking.assigned_driver_id || 'None'})`);
    });

    // Step 3: Check for guides and drivers
    console.log('\n3️⃣ Checking available guides and drivers...');
    
    const guidesCheck = await pool.query('SELECT id, name FROM guides LIMIT 3');
    const driversCheck = await pool.query('SELECT id, name FROM drivers LIMIT 3');

    if (guidesCheck.rows.length === 0) {
      console.log('⚠️  No guides found - creating test guide...');
      await pool.query(`
        INSERT INTO guides (id, name, email, phone, status) 
        VALUES (gen_random_uuid(), 'Test Guide', 'guide@test.com', '+251911234567', 'active')
        ON CONFLICT DO NOTHING
      `);
    }

    if (driversCheck.rows.length === 0) {
      console.log('⚠️  No drivers found - creating test driver...');
      await pool.query(`
        INSERT INTO drivers (id, name, email, phone, status) 
        VALUES (gen_random_uuid(), 'Test Driver', 'driver@test.com', '+251911234568', 'active')
        ON CONFLICT DO NOTHING
      `);
    }

    // Refresh the data
    const guides = await pool.query('SELECT id, name FROM guides LIMIT 3');
    const drivers = await pool.query('SELECT id, name FROM drivers LIMIT 3');

    console.log(`✅ Available guides: ${guides.rows.length}`);
    guides.rows.forEach(guide => console.log(`   - ${guide.name} (${guide.id})`));
    
    console.log(`✅ Available drivers: ${drivers.rows.length}`);
    drivers.rows.forEach(driver => console.log(`   - ${driver.name} (${driver.id})`));

    // Step 4: Test server connectivity
    console.log('\n4️⃣ Testing server connectivity...');
    try {
      const healthCheck = await axios.get(`${API_BASE}/health`, { timeout: 5000 });
      console.log('✅ Server is running');
    } catch (error) {
      if (error.code === 'ECONNREFUSED') {
        console.log('❌ Server is not running');
        console.log('   Start server with: npm start or node server.js');
        return;
      } else {
        console.log('⚠️  Server running but /health endpoint not found (this is OK)');
      }
    }

    // Step 5: Provide test instructions
    console.log('\n5️⃣ Manual Test Instructions:');
    console.log('=====================================');
    
    const testBooking = bookingsCheck.rows[0];
    const testGuide = guides.rows[0];
    const testDriver = drivers.rows[0];

    console.log('\n📋 Test Assignment API Call:');
    console.log(`curl -X PATCH "${API_BASE}/bookings/${testBooking.booking_code}" \\`);
    console.log(`  -H "Content-Type: application/json" \\`);
    console.log(`  -H "Authorization: Bearer YOUR_JWT_TOKEN" \\`);
    console.log(`  -d '{`);
    console.log(`    "assigned_guide_id": "${testGuide.id}",`);
    console.log(`    "assigned_driver_id": "${testDriver.id}"`);
    console.log(`  }'`);

    console.log('\n📋 Test Retrieval API Call:');
    console.log(`curl -X GET "${API_BASE}/bookings/${testBooking.booking_code}" \\`);
    console.log(`  -H "Authorization: Bearer YOUR_JWT_TOKEN"`);

    console.log('\n📋 Direct Database Test:');
    console.log('-- Before assignment:');
    console.log(`SELECT booking_code, guide_name, driver_name FROM bookings WHERE booking_code = '${testBooking.booking_code}';`);
    
    console.log('\n-- Update assignment directly in DB:');
    console.log(`UPDATE bookings SET `);
    console.log(`  assigned_guide_id = '${testGuide.id}', `);
    console.log(`  guide_name = '${testGuide.name}', `);
    console.log(`  assigned_driver_id = '${testDriver.id}', `);
    console.log(`  driver_name = '${testDriver.name}' `);
    console.log(`WHERE booking_code = '${testBooking.booking_code}';`);

    console.log('\n-- Verify persistence:');
    console.log(`SELECT booking_code, guide_name, driver_name FROM bookings WHERE booking_code = '${testBooking.booking_code}';`);

    console.log('\n✅ Test setup complete! The assignment persistence fix is ready to test.');

  } catch (error) {
    console.error('❌ Test setup failed:', error.message);
  } finally {
    await pool.end();
  }
}

// Run the test
testAssignmentPersistence();