const fs = require('fs');
const db = require('./config/db');

async function migrate() {
    try {
        const sql = fs.readFileSync('wallet_tables.sql', 'utf8');
        await db.query(sql);
        console.log('Migration successful');
        process.exit(0);
    } catch (e) {
        console.error('Migration failed:', e);
        process.exit(1);
    }
}

migrate();