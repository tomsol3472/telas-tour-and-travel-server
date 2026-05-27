const db = require('./config/db');
async function run() {
  try {
    const res = await db.query(`
      SELECT column_name, is_nullable
      FROM information_schema.columns 
      WHERE table_name IN ('chat_conversations', 'chat_messages', 'ticket_messages', 'reviews')
      AND column_name IN ('created_by', 'sender_id', 'reviewee_id', 'responded_by');
    `);
    console.log(res.rows);
  } catch(e) {
    console.error(e);
  } finally {
    process.exit();
  }
}
run();
