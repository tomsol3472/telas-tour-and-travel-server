const db = require('./config/db');

async function checkStaffDocuments() {
  try {
    console.log('=== GUIDES TABLE DOCUMENT COLUMNS ===');
    const guidesResult = await db.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'guides' 
        AND (column_name LIKE '%photo%' OR column_name LIKE '%document%' OR column_name LIKE '%license%' OR column_name LIKE '%cert%')
      ORDER BY column_name
    `);
    guidesResult.rows.forEach(col => console.log(`- ${col.column_name} (${col.data_type})`));
    
    console.log('\n=== DRIVERS TABLE DOCUMENT COLUMNS ===');
    const driversResult = await db.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'drivers' 
        AND (column_name LIKE '%photo%' OR column_name LIKE '%document%' OR column_name LIKE '%license%' OR column_name LIKE '%cert%')
      ORDER BY column_name
    `);
    driversResult.rows.forEach(col => console.log(`- ${col.column_name} (${col.data_type})`));
    
    // Check sample data
    console.log('\n=== SAMPLE GUIDE DATA ===');
    const sampleGuide = await db.query(`
      SELECT id, user_id, guide_license_number, license_photo_url, 
             license_issue_date, license_expiry_date, has_first_aid_cert, first_aid_expiry
      FROM guides 
      LIMIT 1
    `);
    if (sampleGuide.rows.length > 0) {
      console.log('Sample guide:', sampleGuide.rows[0]);
    } else {
      console.log('No guides found');
    }
    
    console.log('\n=== SAMPLE DRIVER DATA ===');
    const sampleDriver = await db.query(`
      SELECT id, user_id, license_number, license_photo_url,
             license_issue_date, license_expiry_date
      FROM drivers 
      LIMIT 1
    `);
    if (sampleDriver.rows.length > 0) {
      console.log('Sample driver:', sampleDriver.rows[0]);
    } else {
      console.log('No drivers found');
    }
    
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

checkStaffDocuments();