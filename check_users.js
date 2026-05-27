const db = require('./config/db');

async function check() {
  try {
    const res = await db.query("SELECT email, otp_code, otp_expires, created_at FROM users ORDER BY created_at DESC LIMIT 5");
    console.log(res.rows);
  } catch(e) {
    console.error(e);
  } finally {
    db.pool.end();
  }
}

check();
