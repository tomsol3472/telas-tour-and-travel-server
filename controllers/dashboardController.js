const db = require('../config/db');

// @desc    Get admin dashboard overview
// @route   GET /api/dashboard/overview
// @access  Admin
exports.getDashboardOverview = async (req, res) => {
  try {
    const overview = {};

    // User statistics
    const userStats = await db.query(`
      SELECT 
        user_role,
        COUNT(*) as count,
        COUNT(CASE WHEN status = 'active' THEN 1 END) as active_count
      FROM users
      GROUP BY user_role
    `);
    overview.users = userStats.rows;

    // Booking statistics
    const bookingStats = await db.query(`
      SELECT 
        status,
        COUNT(*) as count,
        SUM(total_amount) as total_revenue
      FROM bookings
      WHERE created_at >= NOW() - INTERVAL '30 days'
      GROUP BY status
    `);
    overview.bookings = bookingStats.rows;

    // Payment statistics
    const paymentStats = await db.query(`
      SELECT 
        payment_status,
        COUNT(*) as count,
        SUM(amount) as total_amount
      FROM payments
      WHERE created_at >= NOW() - INTERVAL '30 days'
      GROUP BY payment_status
    `);
    overview.payments = paymentStats.rows;

    // Recent activity
    const recentActivity = await db.query(`
      SELECT 
        al.action,
        al.entity_type,
        al.created_at,
        u.email as user_email
      FROM audit_logs al
      LEFT JOIN users u ON al.user_id = u.id
      ORDER BY al.created_at DESC
      LIMIT 10
    `);
    overview.recent_activity = recentActivity.rows;

    // System health summary - use bookings/users counts as proxy
    const systemHealth = await db.query(`
      SELECT 
        (SELECT COUNT(*) FROM bookings WHERE status = 'pending') as pending_bookings,
        (SELECT COUNT(*) FROM users WHERE status = 'active') as active_users,
        (SELECT COUNT(*) FROM emergency_alerts WHERE status = 'active') as active_alerts
    `);
    overview.system_health = systemHealth.rows[0];

    // Performance metrics summary - from system_performance_metrics view
    const performanceMetrics = await db.query(`
      SELECT 
        total_bookings,
        pending_bookings,
        active_users,
        active_connections,
        db_size_formatted
      FROM system_performance_metrics
      LIMIT 1
    `);
    overview.performance = performanceMetrics.rows[0] || {};

    res.status(200).json({
      success: true,
      data: overview
    });
  } catch (error) {
    console.error('Error fetching dashboard overview:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch dashboard overview',
      details: error.message
    });
  }
};

// @desc    Get revenue analytics
// @route   GET /api/dashboard/revenue
// @access  Admin
exports.getRevenueAnalytics = async (req, res) => {
  try {
    const { timeframe = '30d' } = req.query;
    
    let interval = '30 days';
    let groupBy = 'DATE(created_at)';
    
    if (timeframe === '7d') {
      interval = '7 days';
      groupBy = 'DATE(created_at)';
    } else if (timeframe === '12m') {
      interval = '12 months';
      groupBy = 'DATE_TRUNC(\'month\', created_at)';
    }

    // Revenue over time
    const revenueOverTime = await db.query(`
      SELECT 
        ${groupBy} as period,
        SUM(amount) as revenue,
        COUNT(*) as transaction_count
      FROM payments
      WHERE payment_status = 'paid'
        AND created_at >= NOW() - INTERVAL '${interval}'
      GROUP BY ${groupBy}
      ORDER BY period
    `);

    // Revenue by tour type
    const revenueByTour = await db.query(`
      SELECT 
        tp.package_code as package_name,
        SUM(p.amount) as revenue,
        COUNT(p.id) as bookings
      FROM payments p
      JOIN bookings b ON p.booking_id = b.id
      JOIN tour_packages tp ON b.package_id = tp.id
      WHERE p.payment_status = 'paid'
        AND p.created_at >= NOW() - INTERVAL '${interval}'
      GROUP BY tp.package_code
      ORDER BY revenue DESC
      LIMIT 10
    `);

    // Top performing staff
    const topStaff = await db.query(`
      SELECT 
        u.email as staff_name,
        u.user_role as role,
        COUNT(b.id) as total_bookings,
        SUM(p.amount) as total_revenue
      FROM users u
      LEFT JOIN guides g ON u.id = g.user_id
      LEFT JOIN drivers d ON u.id = d.user_id
      LEFT JOIN bookings b ON (g.id = b.assigned_guide_id OR d.id = b.assigned_driver_id)
      LEFT JOIN payments p ON b.id = p.booking_id AND p.payment_status = 'paid'
      WHERE u.user_role IN ('guide', 'driver')
        AND p.created_at >= NOW() - INTERVAL '${interval}'
      GROUP BY u.id, u.email, u.user_role
      HAVING COUNT(b.id) > 0
      ORDER BY total_revenue DESC
      LIMIT 10
    `);

    res.status(200).json({
      success: true,
      data: {
        timeframe,
        revenue_over_time: revenueOverTime.rows,
        revenue_by_tour: revenueByTour.rows,
        top_staff: topStaff.rows
      }
    });
  } catch (error) {
    console.error('Error fetching revenue analytics:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch revenue analytics',
      details: error.message
    });
  }
};

// @desc    Get user analytics
// @route   GET /api/dashboard/users
// @access  Admin
exports.getUserAnalytics = async (req, res) => {
  try {
    const { timeframe = '30d' } = req.query;
    
    let interval = '30 days';
    if (timeframe === '7d') interval = '7 days';
    if (timeframe === '12m') interval = '12 months';

    // User registrations over time
    const registrations = await db.query(`
      SELECT 
        DATE(created_at) as date,
        user_role,
        COUNT(*) as count
      FROM users
      WHERE created_at >= NOW() - INTERVAL '${interval}'
      GROUP BY DATE(created_at), user_role
      ORDER BY date
    `);

    // User activity
    const activity = await db.query(`
      SELECT 
        COUNT(CASE WHEN last_login >= NOW() - INTERVAL '24 hours' THEN 1 END) as active_24h,
        COUNT(CASE WHEN last_login >= NOW() - INTERVAL '7 days' THEN 1 END) as active_7d,
        COUNT(CASE WHEN last_login >= NOW() - INTERVAL '30 days' THEN 1 END) as active_30d,
        COUNT(*) as total_users
      FROM users
      WHERE status = 'active'
    `);

    // User demographics
    const demographics = await db.query(`
      SELECT 
        p.nationality,
        COUNT(*) as count
      FROM users u
      JOIN user_profiles p ON u.id = p.user_id
      WHERE u.user_role = 'tourist'
        AND p.nationality IS NOT NULL
      GROUP BY p.nationality
      ORDER BY count DESC
      LIMIT 10
    `);

    res.status(200).json({
      success: true,
      data: {
        timeframe,
        registrations: registrations.rows,
        activity: activity.rows[0],
        demographics: demographics.rows
      }
    });
  } catch (error) {
    console.error('Error fetching user analytics:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch user analytics',
      details: error.message
    });
  }
};

// @desc    Get booking analytics
// @route   GET /api/dashboard/bookings
// @access  Admin
exports.getBookingAnalytics = async (req, res) => {
  try {
    const { timeframe = '30d' } = req.query;
    
    let interval = '30 days';
    if (timeframe === '7d') interval = '7 days';
    if (timeframe === '12m') interval = '12 months';

    // Booking trends
    const trends = await db.query(`
      SELECT 
        DATE(created_at) as date,
        status,
        COUNT(*) as count
      FROM bookings
      WHERE created_at >= NOW() - INTERVAL '${interval}'
      GROUP BY DATE(created_at), status
      ORDER BY date
    `);

    // Popular destinations
    const destinations = await db.query(`
      SELECT 
        tp.package_code as package_name,
        COUNT(b.id) as booking_count,
        AVG(b.total_amount) as avg_amount
      FROM bookings b
      JOIN tour_packages tp ON b.package_id = tp.id
      WHERE b.created_at >= NOW() - INTERVAL '${interval}'
      GROUP BY tp.package_code
      ORDER BY booking_count DESC
      LIMIT 10
    `);

    // Booking conversion funnel
    const funnel = await db.query(`
      SELECT 
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
        COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed,
        COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled
      FROM bookings
      WHERE created_at >= NOW() - INTERVAL '${interval}'
    `);

    res.status(200).json({
      success: true,
      data: {
        timeframe,
        trends: trends.rows,
        popular_destinations: destinations.rows,
        conversion_funnel: funnel.rows[0]
      }
    });
  } catch (error) {
    console.error('Error fetching booking analytics:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch booking analytics',
      details: error.message
    });
  }
};

module.exports = exports;