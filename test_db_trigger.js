const db = require('./config/db');

async function checkDb() {
  try {
    const res1 = await db.query("SELECT * FROM pg_trigger WHERE tgname = 'set_otp_trigger' OR tgname = 'generate_otp_trigger'");
    console.log('Triggers found:', res1.rows.map(r => r.tgname));
    
    const res2 = await db.query("SELECT email, otp_code FROM users ORDER BY created_at DESC LIMIT 5");
    console.log('Recent Users OTP:', res2.rows);
  } catch (e) {
    console.error(e.message);
  } finally {
    db.pool.end();
  }
}

checkDb();
