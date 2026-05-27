const express = require('express');
const pool = require('../config/db'); // PG Pool

const router = express.Router();

/**
 * GET /api/bookings/active-locations
 * Returns minimal location info for active/ongoing/assigned bookings.
 */
router.get('/bookings/active-locations', async (req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT id, booking_code, tourist_name, status, start_date
       FROM booking_summary
       WHERE status IN ('confirmed', 'assigned', 'ongoing')
       ORDER BY start_date ASC`
    );

    const baseLat = 9.0108;  // Addis Ababa approx
    const baseLng = 38.7613;

    const locations = result.rows.map((row, index) => ({
      id: row.id,
      booking_code: row.booking_code,
      tourist_name: row.tourist_name,
      status: row.status,
      start_date: row.start_date,
      latitude: baseLat + index * 0.01,
      longitude: baseLng + index * 0.01,
    }));

    res.json(locations);
  } catch (err) {
    next(err);
  }
});

/**
 * Simple UUID v4/v1 format check
 */
const isUuid = (value) => {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
    value
  );
};

/**
 * GET /api/bookings/:id/location
 * Returns a single booking location.
 */
router.get('/bookings/:id/location', async (req, res, next) => {
  try {
    const { id } = req.params;

    // If id is not a valid UUID, avoid querying Postgres with bad syntax
    if (!isUuid(id)) {
      return res.status(400).json({ message: 'Invalid booking id format' });
    }

    const result = await pool.query(
      `SELECT id, booking_code, tourist_name, status, start_date
       FROM booking_summary
       WHERE id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Booking not found' });
    }

    const row = result.rows[0];

    const location = {
      id: row.id,
      booking_code: row.booking_code,
      tourist_name: row.tourist_name,
      status: row.status,
      start_date: row.start_date,
      latitude: 9.0108,
      longitude: 38.7613,
    };

    res.json(location);
  } catch (err) {
    next(err);
  }
});

module.exports = router;