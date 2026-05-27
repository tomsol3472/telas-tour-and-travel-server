const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  password: 'tom3472sol',
  host: 'localhost',
  port: 5432,
  database: 'TelasUpdateDB'
});

async function checkGuides() {
  try {
    // Check if guides table exists
    const tableCheck = await pool.query(`
      SELECT table_name FROM information_schema.tables 
      WHERE table_name IN ('guides', 'drivers')
    `);
    
    console.log('Available tables:', tableCheck.rows.map(t => t.table_name));

    if (tableCheck.rows.some(t => t.table_name === 'guides')) {
      const guidesSchema = await pool.query(`
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'guides' 
        ORDER BY ordinal_position
      `);
      
      console.log('\nGuides table columns:');
      guidesSchema.rows.forEach(col => {
        console.log(`- ${col.column_name}: ${col.data_type}`);
      });

      // Check existing data
      const guidesData = await pool.query('SELECT * FROM guides LIMIT 3');
      console.log(`\nExisting guides: ${guidesData.rows.length}`);
      guidesData.rows.forEach(guide => {
        console.log('Guide:', guide);
      });
    }

    if (tableCheck.rows.some(t => t.table_name === 'drivers')) {
      const driversSchema = await pool.query(`
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'drivers' 
        ORDER BY ordinal_position
      `);
      
      console.log('\nDrivers table columns:');
      driversSchema.rows.forEach(col => {
        console.log(`- ${col.column_name}: ${col.data_type}`);
      });

      // Check existing data
      const driversData = await pool.query('SELECT * FROM drivers LIMIT 3');
      console.log(`\nExisting drivers: ${driversData.rows.length}`);
      driversData.rows.forEach(driver => {
        console.log('Driver:', driver);
      });
    }

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await pool.end();
  }
}

checkGuides();