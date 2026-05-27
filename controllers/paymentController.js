const db = require('../config/db');
const axios = require('axios');
const financialCalculations = require('../services/financialCalculations');

/**
 * Initialize Chapa Payment
 * Called from mobile app when user initiates payment
 */
exports.initializeChapaPayment = async (req, res) => {
    try {
        const { bookingId, tx_ref, amount, status } = req.body;

        console.log('=== Initialize Chapa Payment ===');
        console.log('Request body:', JSON.stringify(req.body, null, 2));

        // Validate required fields
        if (!bookingId || !tx_ref || !amount) {
            console.log('❌ Missing required fields');
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: bookingId, tx_ref, amount',
                received: { bookingId, tx_ref, amount }
            });
        }

        // Check if booking exists (support both UUID and booking_code)
        let bookingCheck;
        
        // Check if bookingId is a UUID (contains hyphens in UUID format)
        const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(bookingId);
        
        console.log('Booking ID type:', isUUID ? 'UUID' : 'Booking Code');
        console.log('Booking ID value:', bookingId);
        
        if (isUUID) {
            bookingCheck = await db.query(
                'SELECT id, total_amount, final_amount, payment_status FROM bookings WHERE id = $1',
                [bookingId]
            );
        } else {
            // Assume it's a booking_code
            bookingCheck = await db.query(
                'SELECT id, total_amount, final_amount, payment_status FROM bookings WHERE booking_code = $1',
                [bookingId]
            );
        }

        console.log('Booking query result:', bookingCheck.rows.length, 'rows');

        if (bookingCheck.rows.length === 0) {
            console.log('❌ Booking not found');
            return res.status(404).json({
                success: false,
                message: 'Booking not found',
                bookingId: bookingId,
                searchedBy: isUUID ? 'UUID' : 'booking_code'
            });
        }

        const booking = bookingCheck.rows[0];
        console.log('✓ Booking found:', booking.id);
        console.log('Booking amount:', booking.total_amount);
        console.log('Payment amount:', amount);

        // Verify amount matches booking (allow small differences due to floating point)
        const bookingAmount = parseFloat(booking.total_amount || booking.final_amount);
        const paymentAmount = parseFloat(amount);
        
        if (Math.abs(bookingAmount - paymentAmount) > 0.01) {
            console.log('❌ Amount mismatch');
            return res.status(400).json({
                success: false,
                message: 'Payment amount does not match booking amount',
                bookingAmount: bookingAmount,
                paymentAmount: paymentAmount
            });
        }

        // Check if payment transaction already exists
        const existingPayment = await db.query(
            'SELECT id FROM payments WHERE booking_id = $1 AND tx_ref = $2',
            [booking.id, tx_ref]
        );

        if (existingPayment.rows.length > 0) {
            console.log('⚠ Payment already exists:', existingPayment.rows[0].id);
            return res.json({
                success: true,
                message: 'Payment transaction already recorded',
                paymentId: existingPayment.rows[0].id,
                tx_ref: tx_ref
            });
        }

        // Insert payment record (use the actual UUID from booking)
        console.log('Inserting payment record...');
        const paymentResult = await db.query(
            `INSERT INTO payments (booking_id, amount, method, status, tx_ref, created_at)
             VALUES ($1, $2, $3, $4, $5, NOW())
             RETURNING id`,
            [booking.id, amount, 'chapa', status || 'pending', tx_ref]
        );

        console.log('✓ Payment record created:', paymentResult.rows[0].id);

        res.json({
            success: true,
            message: 'Payment transaction initialized',
            paymentId: paymentResult.rows[0].id,
            tx_ref: tx_ref
        });

    } catch (error) {
        console.error('❌ Initialize Chapa Payment Error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to initialize payment',
            error: error.message,
            stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
        });
    }
};

/**
 * Verify Chapa Payment
 * Called after user completes payment on Chapa
 */
exports.verifyChapaPayment = async (req, res) => {
    try {
        const { tx_ref, status, amount, charge } = req.body;

        if (!tx_ref) {
            return res.status(400).json({
                success: false,
                message: 'Transaction reference is required'
            });
        }

        // Verify payment with Chapa API
        const chapaResponse = await axios.get(
            `https://api.chapa.co/v1/transaction/verify/${tx_ref}`,
            {
                headers: {
                    Authorization: `Bearer ${process.env.CHAPA_SECRET_KEY}`
                }
            }
        );

        const chapaData = chapaResponse.data;

        if (chapaData.status !== 'success') {
            return res.status(400).json({
                success: false,
                message: 'Payment verification failed',
                chapaStatus: chapaData.status
            });
        }

        const paymentData = chapaData.data;

        // Update payment record in database
        const updateResult = await db.query(
            `UPDATE payments 
             SET status = $1, 
                 verified_at = NOW(),
                 chapa_response = $2
             WHERE tx_ref = $3
             RETURNING id, booking_id`,
            [paymentData.status, JSON.stringify(paymentData), tx_ref]
        );

        if (updateResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Payment record not found'
            });
        }

        const payment = updateResult.rows[0];

        // If payment is successful, update booking status
        if (paymentData.status === 'success') {
            await db.query(
                `UPDATE bookings 
                 SET payment_status = 'paid', 
                     status = 'confirmed',
                     updated_at = NOW()
                 WHERE id = $1`,
                [payment.booking_id]
            );
            
            // Trigger fund allocation to guide/driver wallets
            require('./walletController').allocateBookingFunds(payment.booking_id).catch(console.error);
        }

        res.json({
            success: true,
            message: 'Payment verified successfully',
            payment: {
                id: payment.id,
                bookingId: payment.booking_id,
                status: paymentData.status,
                amount: paymentData.amount,
                currency: paymentData.currency,
                tx_ref: tx_ref
            }
        });

    } catch (error) {
        console.error('Verify Chapa Payment Error:', error);
        
        // Check if it's an Axios error
        if (error.response) {
            return res.status(error.response.status).json({
                success: false,
                message: 'Chapa verification failed',
                error: error.response.data
            });
        }

        res.status(500).json({
            success: false,
            message: 'Failed to verify payment',
            error: error.message
        });
    }
};

/**
 * Chapa Webhook Callback
 * Automatically called by Chapa when payment status changes
 */
exports.chapaCallback = async (req, res) => {
    try {
        const webhookData = req.body;
        
        console.log('=== Chapa Webhook Received ===');
        console.log('Timestamp:', new Date().toISOString());
        console.log('Data:', JSON.stringify(webhookData, null, 2));

        const { tx_ref, status, amount, currency, charge } = webhookData;

        if (!tx_ref) {
            console.error('Webhook missing tx_ref');
            return res.status(400).json({ success: false, message: 'Missing tx_ref' });
        }

        // Update payment status
        const updateResult = await db.query(
            `UPDATE payments 
             SET status = $1,
                 verified_at = NOW(),
                 chapa_response = $2
             WHERE tx_ref = $3
             RETURNING id, booking_id`,
            [status, JSON.stringify(webhookData), tx_ref]
        );

        if (updateResult.rows.length === 0) {
            console.error('Payment not found for tx_ref:', tx_ref);
            return res.status(404).json({ success: false, message: 'Payment not found' });
        }

        const payment = updateResult.rows[0];

        // Update booking if payment successful
        if (status === 'success') {
            await db.query(
                `UPDATE bookings 
                 SET payment_status = 'paid',
                     status = 'confirmed',
                     updated_at = NOW()
                 WHERE id = $1`,
                [payment.booking_id]
            );
            
            console.log(`Booking ${payment.booking_id} marked as paid`);
            
            // Trigger fund allocation to guide/driver wallets
            require('./walletController').allocateBookingFunds(payment.booking_id).catch(console.error);
        }

        // Always return 200 to acknowledge receipt
        res.json({
            success: true,
            message: 'Webhook processed successfully'
        });

    } catch (error) {
        console.error('Webhook processing error:', error);
        
        // Still return 200 to prevent Chapa from retrying
        res.json({
            success: false,
            message: 'Webhook processing failed',
            error: error.message
        });
    }
};

/**
 * Get Payment Status
 * Check payment status for a booking
 */
exports.getPaymentStatus = async (req, res) => {
    try {
        const { bookingId } = req.params;

        // Support both UUID and booking_code
        const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(bookingId);
        
        let result;
        if (isUUID) {
            result = await db.query(
                `SELECT p.*, b.total_amount, b.payment_status as booking_payment_status, b.booking_code
                 FROM payments p
                 JOIN bookings b ON p.booking_id = b.id
                 WHERE p.booking_id = $1
                 ORDER BY p.created_at DESC
                 LIMIT 1`,
                [bookingId]
            );
        } else {
            result = await db.query(
                `SELECT p.*, b.total_amount, b.payment_status as booking_payment_status, b.booking_code
                 FROM payments p
                 JOIN bookings b ON p.booking_id = b.id
                 WHERE b.booking_code = $1
                 ORDER BY p.created_at DESC
                 LIMIT 1`,
                [bookingId]
            );
        }

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'No payment found for this booking'
            });
        }

        res.json({
            success: true,
            payment: result.rows[0]
        });

    } catch (error) {
        console.error('Get Payment Status Error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get payment status',
            error: error.message
        });
    }
};

/**
 * Legacy initiate payment endpoint (for backward compatibility)
 */
exports.initiatePayment = async (req, res) => {
    const { booking_id, method } = req.body;
    const userId = req.user.userId;

    try {
        // Fetch Booking Details (support both UUID and booking_code)
        let bookingRes;
        
        const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(booking_id);
        
        if (isUUID) {
            bookingRes = await db.query("SELECT * FROM bookings WHERE id = $1", [booking_id]);
        } else {
            bookingRes = await db.query("SELECT * FROM bookings WHERE booking_code = $1", [booking_id]);
        }
        
        if (bookingRes.rows.length === 0) {
            return res.status(404).json({ error: "Booking not found" });
        }
        const booking = bookingRes.rows[0];
        
        // Generate Unique Transaction Reference (use booking UUID)
        const txRef = `TELAS-${Date.now()}-${booking.id}`;

        // Handle Chapa Payment
        if (method === 'chapa') {
            const config = {
                headers: { Authorization: `Bearer ${process.env.CHAPA_SECRET_KEY}` }
            };
            
            const data = {
                amount: booking.total_amount,
                currency: 'ETB',
                email: req.user.email, 
                first_name: req.user.first_name || 'Tourist',
                last_name: req.user.last_name || 'User',
                tx_ref: txRef,
                callback_url: `${process.env.API_URL || 'http://localhost:5000'}/api/payments/chapa/callback`,
                return_url: "myapp://payment-success",
                customization: {
                    title: "Telas Tour Payment",
                    description: `Payment for Booking ${booking.booking_code}`
                }
            };

            try {
                const response = await axios.post('https://api.chapa.co/v1/transaction/initialize', data, config);
                
                // Save payment record (use booking UUID)
                await db.query(
                    `INSERT INTO payments (booking_id, amount, method, status, tx_ref, created_at)
                     VALUES ($1, $2, $3, $4, $5, NOW())`,
                    [booking.id, booking.total_amount, 'chapa', 'pending', txRef]
                );

                return res.json({ 
                    success: true,
                    message: "Payment Initiated", 
                    paymentUrl: response.data.data.checkout_url,
                    tx_ref: txRef
                });
            } catch (apiError) {
                console.error("Chapa API Error:", apiError.response?.data || apiError.message);
                return res.status(500).json({
                    success: false,
                    error: "Failed to initialize Chapa payment",
                    details: apiError.response?.data || apiError.message
                });
            }
        }

        res.status(400).json({ error: "Payment method not supported" });

    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Payment initiation failed" });
    }
};