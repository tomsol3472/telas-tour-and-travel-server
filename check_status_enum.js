const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  password: 'tom3472sol',
  host: 'localhost',
  port: 5432,
  database: 'TelasUpdateDB'
});

async function checkStatusEnum() {
  try {
    const result = await pool.query(`
      SELECT unnest(enum_range(NULL::booking_status_enum))::text as status
    `);

    console.log('Valid booking statuses:');
    result.rows.forEach(s => console.log(`  - ${s.status}`));

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await pool.end();
  }
}

checkStatusEnum();