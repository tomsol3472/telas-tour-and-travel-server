const db = require('./config/db');
async function run() {
  try {
    const id = '02667157-3f8d-4370-a4cf-9551d7f5c025';
    const res = await db.query(`SELECT * FROM chat_conversations WHERE created_by = $1`, [id]);
    console.log(res.rows);
  } catch(e) {
    console.error(e);
  } finally {
    process.exit();
  }
}
run();
