// ...existing code...
const express = require('express');
const pool = require('../config/db'); // adjust if your pool is in a different path

const router = express.Router();

/**
 * GET /api/booking-summary
 * Returns aggregated booking data from the booking_summary VIEW.
 * booking_summary is assumed to be created in database.sql.
 */
const getDates = (req) => {
  const { range, startDate, endDate } = req.query;
  let start = null;
  let end = new Date();
  
  if (range === 'custom' && startDate && endDate) {
    return { start: new Date(startDate), end: new Date(endDate) };
  }
  
  if (range === 'week') start = new Date(end.getTime() - 7 * 24 * 60 * 60 * 1000);
  else if (range === 'quarter') start = new Date(end.getTime() - 90 * 24 * 60 * 60 * 1000);
  else if (range === 'year') start = new Date(end.getTime() - 365 * 24 * 60 * 60 * 1000);
  else start = new Date(end.getTime() - 30 * 24 * 60 * 60 * 1000); // month default
  
  return { start, end };
};

router.get('/booking-summary', async (req, res, next) => {
  try {
    const { start, end } = getDates(req);
    const result = await pool.query(
      'SELECT * FROM booking_summary WHERE booking_date >= $1 AND booking_date <= $2 ORDER BY booking_date DESC',
      [start.toISOString().split('T')[0], end.toISOString().split('T')[0]]
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

router.get('/analytics', async (req, res, next) => {
  try {
    const { start, end } = getDates(req);
    const startStr = start.toISOString().split('T')[0];
    const endStr = end.toISOString().split('T')[0];

    // Destinations
    const destRes = await pool.query(`
      SELECT 
        tp.name as name, 
        COUNT(b.id)::int as bookings, 
        COALESCE(SUM(b.final_amount), 0)::int as revenue
      FROM bookings b
      JOIN tour_packages tp ON b.package_id = tp.id
      WHERE b.start_date >= $1 AND b.start_date <= $2
      GROUP BY tp.name
      ORDER BY bookings DESC
    `, [startStr, endStr]);

    // Seasonal Trends (by Month)
    const seasonalRes = await pool.query(`
      SELECT 
        TO_CHAR(b.start_date, 'Mon YYYY') as month,
        COUNT(b.id)::int as bookings
      FROM bookings b
      WHERE b.start_date >= $1 AND b.start_date <= $2
      GROUP BY TO_CHAR(b.start_date, 'Mon YYYY'), DATE_TRUNC('month', b.start_date)
      ORDER BY DATE_TRUNC('month', b.start_date) ASC
    `, [startStr, endStr]);

    const seasonalTrends = seasonalRes.rows.map(r => ({
      month: r.month,
      season: r.bookings > 5 ? 'Peak' : 'Off-Peak',
      bookings: r.bookings
    }));

    res.json({
      destinations: destRes.rows.map(d => ({ ...d, growth: 0 })),
      seasonalTrends,
      demographics: { ageGroups: [], nationalities: [], travelStyles: [] },
      bookingJourney: []
    });
  } catch (err) {
    next(err);
  }
});

router.get('/admin/dashboard-stats', async (req, res, next) => {
  try {
    const activeToursResult = await pool.query(`SELECT COUNT(*) FROM bookings WHERE status IN ('confirmed', 'assigned', 'ongoing')`);
    const pendingResult = await pool.query(`SELECT COUNT(*) FROM users WHERE status = 'pending'`);
    const revenueResult = await pool.query(`SELECT COALESCE(SUM(amount), 0) as total FROM payments WHERE payment_status = 'paid' AND DATE_TRUNC('day', paid_at) = DATE_TRUNC('day', CURRENT_DATE)`);
    const driversResult = await pool.query(`SELECT COUNT(*) FROM drivers WHERE is_available = true`);

    res.json({
      success: true,
      data: {
        activeTours: parseInt(activeToursResult.rows[0].count),
        pendingApprovals: parseInt(pendingResult.rows[0].count),
        todayRevenue: parseFloat(revenueResult.rows[0].total),
        availableDrivers: parseInt(driversResult.rows[0].count)
      }
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
// ...existing code...