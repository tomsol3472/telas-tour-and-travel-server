const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const { protect } = require('../middleware/auth');

// POST /api/bookings
// The 'protect' middleware ensures only logged-in users can access this
router.post('/', protect, bookingController.createBooking);

module.exports = router;