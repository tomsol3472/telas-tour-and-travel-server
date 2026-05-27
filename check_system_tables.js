const db = require('./config/db');

async function checkSystemTables() {
  try {
    console.log('Checking for system/settings/log tables...\n');

    const result = await db.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
        AND (table_name LIKE '%setting%' OR table_name LIKE '%config%' OR table_name LIKE '%log%' OR table_name LIKE '%system%')
      ORDER BY table_name
    `);
    
    console.log('System/Settings/Log tables found:');
    if (result.rows.length > 0) {
      result.rows.forEach(row => console.log(`- ${row.table_name}`));
    } else {
      console.log('- No system tables found');
    }

    // Check all tables to see what exists
    console.log('\nAll tables in database:');
    const allTables = await db.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name
    `);
    
    allTables.rows.forEach(row => console.log(`- ${row.table_name}`));
    
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

checkSystemTables();