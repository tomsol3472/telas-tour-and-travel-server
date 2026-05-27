const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  password: 'tom3472sol',
  host: 'localhost',
  port: 5432,
  database: 'TelasUpdateDB'
});

async function checkBookings() {
  try {
    console.log('🔍 Checking existing bookings...');
    
    const result = await pool.query(`
      SELECT id, booking_code, status, assigned_guide_id, assigned_driver_id, guide_name, driver_name
      FROM bookings 
      ORDER BY created_at DESC 
      LIMIT 10
    `);

    if (result.rows.length === 0) {
      console.log('❌ No bookings found in database');
    } else {
      console.log(`✅ Found ${result.rows.length} bookings:`);
      result.rows.forEach((booking, index) => {
        console.log(`\n${index + 1}. Booking ID: ${booking.id}`);
        console.log(`   Code: ${booking.booking_code}`);
        console.log(`   Status: ${booking.status}`);
        console.log(`   Guide: ${booking.guide_name || 'Not assigned'} (${booking.assigned_guide_id || 'No ID'})`);
        console.log(`   Driver: ${booking.driver_name || 'Not assigned'} (${booking.assigned_driver_id || 'No ID'})`);
      });
    }

    // Check if the specific ID exists
    const specificId = '12ac405e-385d-4df4-8bed-f3bbe1cd8880';
    console.log(`\n🔍 Checking for specific booking ID: ${specificId}`);
    
    const specificResult = await pool.query(
      'SELECT id, booking_code FROM bookings WHERE id::text = $1 OR booking_code = $1',
      [specificId]
    );

    if (specificResult.rows.length === 0) {
      console.log('❌ Booking with that ID/code not found');
    } else {
      console.log('✅ Found booking:', specificResult.rows[0]);
    }

  } catch (error) {
    console.error('❌ Database error:', error.message);
  } finally {
    await pool.end();
  }
}

checkBookings();