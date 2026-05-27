const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  password: 'tom3472sol',
  host: 'localhost',
  port: 5432,
  database: 'TelasUpdateDB'
});

async function checkIdIssue() {
  try {
    const problematicId = '5cee148d-439c-422b-b3ca-515a7c847d25';
    
    console.log('Checking ID:', problematicId);
    
    // Check if it's a driver ID
    const driverCheck = await pool.query('SELECT id, user_id FROM drivers WHERE id = $1', [problematicId]);
    console.log('As driver ID:', driverCheck.rows);
    
    // Check if it's a user ID
    const userCheck = await pool.query('SELECT id, user_id FROM drivers WHERE user_id = $1', [problematicId]);
    console.log('As user ID:', userCheck.rows);
    
    // Check guides too
    const guideId = '85b671d7-a4e8-4192-b911-306ac6b46b2c';
    const guideCheck = await pool.query('SELECT id, user_id FROM guides WHERE id = $1', [guideId]);
    console.log('Guide as guide ID:', guideCheck.rows);
    
    const guideUserCheck = await pool.query('SELECT id, user_id FROM guides WHERE user_id = $1', [guideId]);
    console.log('Guide as user ID:', guideUserCheck.rows);
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await pool.end();
  }
}

checkIdIssue();