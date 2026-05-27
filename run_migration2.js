const db = require('./config/db');

async function migrate() {
    try {
        await db.query(`ALTER TABLE bookings ADD COLUMN funds_allocated BOOLEAN DEFAULT FALSE;`);
        console.log('Migration successful');
        process.exit(0);
    } catch (e) {
        console.error('Migration failed:', e);
        process.exit(1);
    }
}

migrate();
