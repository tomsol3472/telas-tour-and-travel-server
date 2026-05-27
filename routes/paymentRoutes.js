const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { protect } = require('../middleware/auth');

// Legacy endpoint (for backward compatibility)
router.post('/init', protect, paymentController.initiatePayment);

// Chapa payment endpoints
router.post('/chapa/initialize', protect, paymentController.initializeChapaPayment);
router.post('/chapa/verify', protect, paymentController.verifyChapaPayment);
router.post('/chapa/callback', paymentController.chapaCallback); // No auth - called by Chapa
router.get('/status/:bookingId', protect, paymentController.getPaymentStatus);

module.exports = router;