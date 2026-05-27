const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const { protect } = require('../middleware/auth');

// POST /api/bookings
// The 'protect' middleware ensures only logged-in users can access this
router.post('/', protect, bookingController.createBooking);

// GET /api/bookings - Get user's own bookings
router.get('/', protect, bookingController.getUserBookings);

// GET /api/bookings/admin/all - Get all bookings with assignments (admin endpoint)
router.get('/admin/all', protect, bookingController.getAllBookingsWithAssignments);

// GET /api/bookings/staff/availability - Check staff availability
router.get('/staff/availability', protect, bookingController.checkStaffAvailability);

// GET /api/bookings/staff/available - Get available staff for date range
router.get('/staff/available', protect, bookingController.getAvailableStaff);

// POST /api/bookings/emergency
router.post('/emergency', protect, bookingController.triggerEmergency);

// POST /api/bookings/confirm-assignment - Staff confirms/declines assignment
router.post('/confirm-assignment', protect, bookingController.confirmAssignment);

// GET /api/bookings/:id
router.get('/:id', protect, bookingController.getBookingById);

// PUT/PATCH /api/bookings/:id - Update booking assignments
router.patch('/:id', protect, bookingController.updateBooking);
router.put('/:id', protect, bookingController.updateBooking);

// POST /api/bookings/:id/auto-assign - Auto-assign available staff
router.post('/:id/auto-assign', protect, bookingController.autoAssignStaff);

module.exports = router;