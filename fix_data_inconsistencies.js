const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  password: 'tom3472sol',
  host: 'localhost',
  port: 5432,
  database: 'TelasUpdateDB'
});

async function fixDataInconsistencies() {
  console.log('🔧 FIXING DATA INCONSISTENCIES\n');
  console.log('=' .repeat(60));

  try {
    // 1. Find bookings with guide_id but no guide_name
    console.log('\n1️⃣ Fixing bookings with guide_id but no guide_name...');
    
    const missingGuideNames = await pool.query(`
      SELECT b.id, b.booking_code, b.assigned_guide_id, u.email as guide_name
      FROM bookings b
      JOIN guides g ON b.assigned_guide_id = g.id
      JOIN users u ON g.user_id = u.id
      WHERE b.assigned_guide_id IS NOT NULL AND b.guide_name IS NULL
    `);

    if (missingGuideNames.rows.length > 0) {
      console.log(`   Found ${missingGuideNames.rows.length} bookings to fix`);
      
      for (const booking of missingGuideNames.rows) {
        await pool.query(`
          UPDATE bookings 
          SET guide_name = $1
          WHERE id = $2
        `, [booking.guide_name, booking.id]);
        
        console.log(`   ✅ Fixed ${booking.booking_code}: guide_name = "${booking.guide_name}"`);
      }
    } else {
      console.log('   ✅ No issues found');
    }

    // 2. Find bookings with driver_id but no driver_name
    console.log('\n2️⃣ Fixing bookings with driver_id but no driver_name...');
    
    const missingDriverNames = await pool.query(`
      SELECT b.id, b.booking_code, b.assigned_driver_id, u.email as driver_name
      FROM bookings b
      JOIN drivers d ON b.assigned_driver_id = d.id
      JOIN users u ON d.user_id = u.id
      WHERE b.assigned_driver_id IS NOT NULL AND b.driver_name IS NULL
    `);

    if (missingDriverNames.rows.length > 0) {
      console.log(`   Found ${missingDriverNames.rows.length} bookings to fix`);
      
      for (const booking of missingDriverNames.rows) {
        await pool.query(`
          UPDATE bookings 
          SET driver_name = $1
          WHERE id = $2
        `, [booking.driver_name, booking.id]);
        
        console.log(`   ✅ Fixed ${booking.booking_code}: driver_name = "${booking.driver_name}"`);
      }
    } else {
      console.log('   ✅ No issues found');
    }

    // 3. Find bookings with name but no ID (orphaned names)
    console.log('\n3️⃣ Checking for orphaned names...');
    
    const orphanedGuides = await pool.query(`
      SELECT id, booking_code, guide_name
      FROM bookings
      WHERE guide_name IS NOT NULL AND assigned_guide_id IS NULL
    `);

    if (orphanedGuides.rows.length > 0) {
      console.log(`   ⚠️  Found ${orphanedGuides.rows.length} bookings with guide_name but no guide_id`);
      orphanedGuides.rows.forEach(booking => {
        console.log(`      ${booking.booking_code}: "${booking.guide_name}"`);
      });
      console.log('   These should be manually reviewed and reassigned');
    } else {
      console.log('   ✅ No orphaned guide names');
    }

    const orphanedDrivers = await pool.query(`
      SELECT id, booking_code, driver_name
      FROM bookings
      WHERE driver_name IS NOT NULL AND assigned_driver_id IS NULL
    `);

    if (orphanedDrivers.rows.length > 0) {
      console.log(`   ⚠️  Found ${orphanedDrivers.rows.length} bookings with driver_name but no driver_id`);
      orphanedDrivers.rows.forEach(booking => {
        console.log(`      ${booking.booking_code}: "${booking.driver_name}"`);
      });
      console.log('   These should be manually reviewed and reassigned');
    } else {
      console.log('   ✅ No orphaned driver names');
    }

    // 4. Verify all confirmed bookings have assignments
    console.log('\n4️⃣ Checking confirmed bookings for assignments...');
    
    const confirmedWithoutAssignments = await pool.query(`
      SELECT booking_code, status, guide_name, driver_name
      FROM bookings
      WHERE status = 'confirmed' 
        AND (guide_name IS NULL OR driver_name IS NULL)
    `);

    if (confirmedWithoutAssignments.rows.length > 0) {
      console.log(`   ⚠️  Found ${confirmedWithoutAssignments.rows.length} confirmed bookings without full assignments:`);
      confirmedWithoutAssignments.rows.forEach(booking => {
        console.log(`      ${booking.booking_code}:`);
        console.log(`        Guide: ${booking.guide_name || 'MISSING'}`);
        console.log(`        Driver: ${booking.driver_name || 'MISSING'}`);
      });
      console.log('   These should be assigned staff immediately');
    } else {
      console.log('   ✅ All confirmed bookings have full assignments');
    }

    // 5. Summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 FIX SUMMARY\n');
    
    const totalFixed = missingGuideNames.rows.length + missingDriverNames.rows.length;
    const totalIssues = orphanedGuides.rows.length + orphanedDrivers.rows.length + 
                       confirmedWithoutAssignments.rows.length;

    console.log(`✅ Fixed: ${totalFixed} bookings`);
    console.log(`⚠️  Requires manual review: ${totalIssues} bookings`);

    if (totalFixed > 0) {
      console.log('\n🎉 Data inconsistencies have been fixed!');
      console.log('   All bookings now have proper guide_name and driver_name values');
    }

    if (totalIssues > 0) {
      console.log('\n⚠️  Some bookings require manual attention:');
      if (orphanedGuides.rows.length > 0 || orphanedDrivers.rows.length > 0) {
        console.log('   - Orphaned names (name without ID) should be cleared or reassigned');
      }
      if (confirmedWithoutAssignments.rows.length > 0) {
        console.log('   - Confirmed bookings without assignments need staff assigned');
      }
    }

    console.log('\n' + '='.repeat(60));

  } catch (error) {
    console.error('\n❌ Fix failed:', error.message);
    console.error(error.stack);
  } finally {
    await pool.end();
  }
}

// Run fix
fixDataInconsistencies().catch(console.error);
