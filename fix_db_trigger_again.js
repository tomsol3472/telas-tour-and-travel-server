const db = require('./config/db');

async function fixTrigger() {
  try {
    console.log('Creating trigger function...');
    await db.query(`
      CREATE OR REPLACE FUNCTION generate_otp_code()
      RETURNS TRIGGER AS $$
      BEGIN
          IF NEW.otp_code IS NULL THEN
              -- Generate a 6 digit random number
              NEW.otp_code := lpad(floor(random() * 900000 + 100000)::text, 6, '0');
              NEW.otp_expires := CURRENT_TIMESTAMP + INTERVAL '10 minutes';
          END IF;
          RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `);

    console.log('✅ Trigger successfully fixed!');
  } catch (e) {
    console.error('❌ Error:', e.message);
  } finally {
    db.pool.end();
  }
}

fixTrigger();
