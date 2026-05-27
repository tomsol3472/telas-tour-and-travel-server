const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');
const { verifyToken, checkRole } = require('../middleware/authMiddleware');

// Dashboard Overview Routes
router.get('/overview', verifyToken, checkRole(['admin']), dashboardController.getDashboardOverview);

// Analytics Routes
router.get('/revenue', verifyToken, checkRole(['admin']), dashboardController.getRevenueAnalytics);
router.get('/users', verifyToken, checkRole(['admin']), dashboardController.getUserAnalytics);
router.get('/bookings', verifyToken, checkRole(['admin']), dashboardController.getBookingAnalytics);

module.exports = router;