const db = require('./config/db');
async function run() {
  try {
    const resGuides = await db.query(`SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'guides';`);
    console.log("GUIDES:", resGuides.rows);
    const resDrivers = await db.query(`SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'drivers';`);
    console.log("DRIVERS:", resDrivers.rows);
    const resVehicles = await db.query(`SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'vehicles';`);
    console.log("VEHICLES:", resVehicles.rows);
  } catch(e) {
    console.error(e);
  } finally {
    process.exit();
  }
}
run();
