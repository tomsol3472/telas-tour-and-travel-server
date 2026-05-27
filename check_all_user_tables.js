const db = require('./config/db');

async function checkAllUserTables() {
  try {
    console.log('Checking all user-related table schemas...\n');

    const tables = ['users', 'user_profiles', 'tourists', 'guides', 'drivers'];

    for (const table of tables) {
      console.log(`=== ${table.toUpperCase()} TABLE ===`);
      
      const result = await db.query(`
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = $1
        ORDER BY ordinal_position
      `, [table]);

      if (result.rows.length === 0) {
        console.log(`  ⚠️  Table '${table}' does not exist`);
      } else {
        result.rows.forEach(col => {
          console.log(`  - ${col.column_name} (${col.data_type}) ${col.is_nullable === 'YES' ? 'NULL' : 'NOT NULL'}`);
        });
      }
      console.log('');
    }

    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

checkAllUserTables();