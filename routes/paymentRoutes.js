const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { protect } = require('../middleware/auth');

// POST /api/payments/init
router.post('/init', protect, paymentController.initiatePayment);

module.exports = router;