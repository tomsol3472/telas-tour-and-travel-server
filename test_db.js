const db = require('./config/db');
async function run() {
  try {
    const id = '33a6f065-75f9-4721-8f15-0f89a06614d3';
    console.log("Updating bookings drivers...");
    await db.query(`UPDATE bookings SET assigned_driver_id = NULL WHERE assigned_driver_id IN (SELECT id FROM drivers WHERE user_id = $1)`, [id]);
    console.log("Updating bookings guides...");
    await db.query(`UPDATE bookings SET assigned_guide_id = NULL WHERE assigned_guide_id IN (SELECT id FROM guides WHERE user_id = $1)`, [id]);
    console.log("Done");
  } catch(e) {
    console.error("Error:", e);
  } finally {
    process.exit();
  }
}
run();
