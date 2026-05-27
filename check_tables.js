const db = require('./config/db');

async function checkTables() {
  try {
    const result = await db.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
        AND table_name IN ('notifications', 'chat_conversations', 'chat_participants', 'chat_messages')
      ORDER BY table_name
    `);
    console.log('Existing notification/chat tables:', result.rows.map(r => r.table_name));
    
    // Check if any tables are missing
    const expectedTables = ['notifications', 'chat_conversations', 'chat_participants', 'chat_messages'];
    const existingTables = result.rows.map(r => r.table_name);
    const missingTables = expectedTables.filter(table => !existingTables.includes(table));
    
    if (missingTables.length > 0) {
      console.log('Missing tables:', missingTables);
    } else {
      console.log('✅ All notification and chat tables exist');
    }
    
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

checkTables();