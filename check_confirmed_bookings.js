const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  password: 'tom3472sol',
  host: 'localhost',
  port: 5432,
  database: 'TelasUpdateDB'
});

async function checkConfirmedBookings() {
  try {
    console.log('🔍 Checking confirmed bookings...');
    
    const result = await pool.query(`
      SELECT 
        booking_code, 
        guide_name, 
        driver_name, 
        assigned_guide_id, 
        assigned_driver_id, 
        status 
      FROM bookings 
      WHERE status = 'confirmed' 
      ORDER BY created_at DESC 
      LIMIT 5
    `);

    if (result.rows.length === 0) {
      console.log('❌ No confirmed bookings found');
    } else {
      console.log(`✅ Found ${result.rows.length} confirmed bookings:`);
      result.rows.forEach((booking, index) => {
        console.log(`\n${index + 1}. Booking: ${booking.booking_code}`);
        console.log(`   Status: ${booking.status}`);
        console.log(`   Guide Name: "${booking.guide_name || 'NULL'}"`);
        console.log(`   Driver Name: "${booking.driver_name || 'NULL'}"`);
        console.log(`   Guide ID: ${booking.assigned_guide_id || 'NULL'}`);
        console.log(`   Driver ID: ${booking.assigned_driver_id || 'NULL'}`);
        
        // Check if this is the display issue
        if (booking.status === 'confirmed' && (!booking.guide_name || !booking.driver_name)) {
          console.log(`   🚨 ISSUE: Status is confirmed but names are missing!`);
        }
      });
    }

    // Also check all bookings to see the pattern
    console.log('\n🔍 Checking all recent bookings...');
    const allResult = await pool.query(`
      SELECT 
        booking_code, 
        guide_name, 
        driver_name, 
        assigned_guide_id, 
        assigned_driver_id, 
        status 
      FROM bookings 
      ORDER BY created_at DESC 
      LIMIT 10
    `);

    allResult.rows.forEach((booking, index) => {
      const hasGuide = booking.guide_name ? '✅' : '❌';
      const hasDriver = booking.driver_name ? '✅' : '❌';
      console.log(`${index + 1}. ${booking.booking_code} | Status: ${booking.status} | Guide: ${hasGuide} | Driver: ${hasDriver}`);
    });

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await pool.end();
  }
}

checkConfirmedBookings();