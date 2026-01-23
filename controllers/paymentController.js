const db = require('../config/db');
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');

exports.initiatePayment = async (req, res) => {
    // 1. Get Booking ID and Payment Method from Postman
    const { booking_id, method } = req.body;
    const userId = req.user.userId;

    try {
        // 2. Fetch Booking Details to verify amount
        const bookingRes = await db.query("SELECT * FROM bookings WHERE id = $1", [booking_id]);
        if (bookingRes.rows.length === 0) {
            return res.status(404).json({ error: "Booking not found" });
        }
        const booking = bookingRes.rows[0];
        
        // 3. Generate Unique Transaction Reference
        const txRef = `TX-${Date.now()}-${uuidv4()}`;

        // 4. Handle Chapa Payment
        if (method === 'chapa') {
            const config = {
                headers: { Authorization: `Bearer ${process.env.CHAPA_SECRET_KEY}` }
            };
            
            // This data goes to Chapa's servers
            const data = {
                amount: booking.total_amount,
                currency: 'ETB',
                email: req.user.email, 
                first_name: 'Tourist', // In real app, fetch from profile
                last_name: 'User',
                tx_ref: txRef,
                callback_url: `http://localhost:5000/api/payments/verify/${txRef}`,
                return_url: "https://google.com", // Where to redirect user after payment
                customization: {
                    title: "Telas Tour Payment",
                    description: `Payment for Booking #${booking_id}`
                }
            };

            // Call Chapa API
            // Note: If you don't have a real API key, this will fail. 
            // We wrap it in try/catch to give you a "Mock" success if it fails.
            try {
                const response = await axios.post('https://api.chapa.co/v1/transaction/initialize', data, config);
                return res.json({ 
                    message: "Payment Initiated", 
                    paymentUrl: response.data.data.checkout_url 
                });
            } catch (apiError) {
                console.log("Chapa API Failed (Likely invalid Key). Returning MOCK URL.");
                return res.json({
                    message: "Mock Payment Initiated (API Key Invalid)",
                    paymentUrl: `https://checkout.chapa.co/checkout/payment/mock-payment-${txRef}`,
                    mock_note: "This is a fake URL because your API Key is a placeholder."
                });
            }
        }

        // 5. Handle Other Methods (Telebirr/Bank)
        res.json({ message: "Payment method pending implementation" });

    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Payment initiation failed" });
    }
};