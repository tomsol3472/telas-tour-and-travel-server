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
              NEW.otp_expires_at := CURRENT_TIMESTAMP + INTERVAL '10 minutes';
          END IF;
          RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `);

    console.log('Creating trigger...');
    await db.query(`
      DROP TRIGGER IF EXISTS set_otp_on_insert ON users;
      CREATE TRIGGER set_otp_on_insert
      BEFORE INSERT ON users
      FOR EACH ROW
      EXECUTE FUNCTION generate_otp_code();
    `);

    console.log('✅ Trigger successfully created on the production database!');
  } catch (e) {
    console.error('❌ Error:', e.message);
  } finally {
    db.pool.end();
  }
}

fixTrigger();
