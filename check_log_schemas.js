const db = require('./config/db');
async function check() {
  try {
    for (const t of ['web_traffic_logs', 'system_app_logs', 'support_tickets', 'ticket_messages']) {
      const r = await db.query(`SELECT column_name, data_type FROM information_schema.columns WHERE table_name=$1 AND table_schema='public' ORDER BY ordinal_position`, [t]);
      console.log(`\n=== ${t} ===`);
      r.rows.forEach(c => console.log(`  - ${c.column_name} (${c.data_type})`));
    }
    process.exit(0);
  } catch(e) { console.error(e.message); process.exit(1); }
}
check();