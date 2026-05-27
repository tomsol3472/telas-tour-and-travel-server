const db = require('./config/db');

async function testGetUsers() {
  try {
    console.log('🧪 Testing getAllUsers query...\n');

    const query = `
      SELECT u.id, u.email, u.phone, u.user_role as role, u.status, u.created_at,
             u.profile_picture_url, u.preferred_language,
             p.first_name, p.last_name, p.middle_name, p.nationality, p.city, p.country,
             p.is_diaspora_verified, p.verification_tier,
             t.travel_frequency, t.total_bookings,
             d.license_number as driver_license, d.years_experience as driver_experience, d.is_available as driver_available,
             g.guide_license_number as guide_license, g.daily_rate as guide_rate, g.is_available as guide_available
      FROM users u
      LEFT JOIN user_profiles p ON u.id = p.user_id
      LEFT JOIN tourists t ON u.id = t.user_id
      LEFT JOIN drivers d ON u.id = d.user_id
      LEFT JOIN guides g ON u.id = g.user_id
      ORDER BY u.created_at DESC
    `;

    console.log('Executing query...');
    const result = await db.query(query);

    console.log(`✅ Query successful! Found ${result.rows.length} users\n`);

    if (result.rows.length > 0) {
      console.log('Sample user data:');
      const sample = result.rows[0];
      console.log({
        id: sample.id,
        email: sample.email,
        role: sample.role,
        status: sample.status,
        first_name: sample.first_name,
        last_name: sample.last_name
      });
    }

    console.log('\n✅ getAllUsers query works correctly!');
    process.exit(0);

  } catch (error) {
    console.error('❌ Error testing getAllUsers:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  }
}

testGetUsers();
