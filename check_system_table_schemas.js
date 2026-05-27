const db = require('./config/db');

async function checkSystemTableSchemas() {
  try {
    console.log('Checking system table schemas...\n');

    const systemTables = [
      'system_configurations',
      'system_performance_metrics', 
      'backup_history',
      'audit_logs',
      'emergency_alerts'
    ];

    for (const table of systemTables) {
      console.log(`=== ${table.toUpperCase()} TABLE ===`);
      
      const result = await db.query(`
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = $1 AND table_schema = 'public'
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

    // Check payment status enum values
    console.log('=== PAYMENT STATUS ENUM VALUES ===');
    const enumResult = await db.query(`
      SELECT enumlabel 
      FROM pg_enum 
      WHERE enumtypid = (
        SELECT oid 
        FROM pg_type 
        WHERE typname = 'payment_status_enum'
      )
    `);
    
    if (enumResult.rows.length > 0) {
      console.log('Payment status enum values:');
      enumResult.rows.forEach(row => console.log(`  - ${row.enumlabel}`));
    } else {
      console.log('Payment status enum not found');
    }
    
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

checkSystemTableSchemas();