/**
 * Debug Payment Issue
 * This script helps identify what's causing the 400 error
 */

const axios = require('axios');
require('dotenv').config();

const API_URL = process.env.API_URL || 'http://localhost:5000';

// INSTRUCTIONS:
// 1. Get your JWT token by logging in
// 2. Get a booking code from your mobile app
// 3. Update the values below
// 4. Run: node debug-payment.js

const TEST_DATA = {
    authToken: 'YOUR_JWT_TOKEN_HERE', // Replace with actual token
    bookingCode: 'TEL-2605-000007', // Replace with actual booking code
    amount: 17500 // Replace with actual amount
};

async function debugPayment() {
    console.log('=== Payment Debug Tool ===\n');
    
    // Step 1: Check if booking exists
    console.log('Step 1: Checking if booking exists...');
    try {
        const bookingResponse = await axios.get(
            `${API_URL}/api/bookings`,
            {
                headers: {
                    'Authorization': `Bearer ${TEST_DATA.authToken}`
                }
            }
        );
        
        console.log('✓ Bookings endpoint accessible');
        console.log('Total bookings:', bookingResponse.data.length || 'N/A');
        
        // Find the specific booking
        const booking = bookingResponse.data.find(b => 
            b.booking_code === TEST_DATA.bookingCode || 
            b.id === TEST_DATA.bookingCode
        );
        
        if (booking) {
            console.log('✓ Booking found!');
            console.log('  - ID:', booking.id);
            console.log('  - Code:', booking.booking_code);
            console.log('  - Amount:', booking.total_amount || booking.final_amount);
            console.log('  - Status:', booking.status);
            console.log('  - Payment Status:', booking.payment_status);
            
            // Update test data with correct values
            TEST_DATA.bookingId = booking.id;
            TEST_DATA.amount = booking.total_amount || booking.final_amount;
        } else {
            console.log('✗ Booking not found with code:', TEST_DATA.bookingCode);
            console.log('Available bookings:');
            bookingResponse.data.slice(0, 5).forEach(b => {
                console.log(`  - ${b.booking_code} (${b.id})`);
            });
        }
    } catch (error) {
        console.log('✗ Failed to fetch bookings');
        console.log('Error:', error.response?.data || error.message);
    }
    
    console.log('\n');
    
    // Step 2: Test payment initialization
    console.log('Step 2: Testing payment initialization...');
    
    const tx_ref = `TELAS-${Date.now()}-${TEST_DATA.bookingCode}`;
    
    const paymentData = {
        bookingId: TEST_DATA.bookingCode,
        tx_ref: tx_ref,
        amount: TEST_DATA.amount,
        status: 'pending'
    };
    
    console.log('Request data:', JSON.stringify(paymentData, null, 2));
    
    try {
        const response = await axios.post(
            `${API_URL}/api/payments/chapa/initialize`,
            paymentData,
            {
                headers: {
                    'Authorization': `Bearer ${TEST_DATA.authToken}`,
                    'Content-Type': 'application/json'
                }
            }
        );
        
        console.log('✓ Payment initialization successful!');
        console.log('Response:', JSON.stringify(response.data, null, 2));
    } catch (error) {
        console.log('✗ Payment initialization failed');
        console.log('Status:', error.response?.status);
        console.log('Error:', JSON.stringify(error.response?.data, null, 2));
        
        if (error.response?.status === 400) {
            console.log('\n🔍 Diagnosis:');
            const errorData = error.response.data;
            
            if (errorData.message?.includes('Missing required fields')) {
                console.log('- Some required fields are missing or undefined');
                console.log('- Check that bookingId, tx_ref, and amount are all provided');
            } else if (errorData.message?.includes('not found')) {
                console.log('- Booking not found in database');
                console.log('- Make sure the booking code is correct');
            } else if (errorData.message?.includes('amount does not match')) {
                console.log('- Payment amount does not match booking amount');
                console.log('- Booking amount:', errorData.bookingAmount);
                console.log('- Payment amount:', errorData.paymentAmount);
            } else {
                console.log('- Unknown 400 error');
                console.log('- Check server logs for more details');
            }
        }
    }
    
    console.log('\n');
    
    // Step 3: Test direct Chapa payment
    console.log('Step 3: Testing direct Chapa payment...');
    
    try {
        const response = await axios.post(
            `${API_URL}/api/payments/init`,
            {
                booking_id: TEST_DATA.bookingCode,
                method: 'chapa'
            },
            {
                headers: {
                    'Authorization': `Bearer ${TEST_DATA.authToken}`,
                    'Content-Type': 'application/json'
                }
            }
        );
        
        console.log('✓ Direct payment initialization successful!');
        console.log('Response:', JSON.stringify(response.data, null, 2));
        
        if (response.data.paymentUrl) {
            console.log('\n🔗 Payment URL:', response.data.paymentUrl);
        }
    } catch (error) {
        console.log('✗ Direct payment initialization failed');
        console.log('Status:', error.response?.status);
        console.log('Error:', JSON.stringify(error.response?.data, null, 2));
    }
    
    console.log('\n=== Debug Complete ===');
}

// Run if executed directly
if (require.main === module) {
    if (TEST_DATA.authToken === 'YOUR_JWT_TOKEN_HERE') {
        console.log('⚠️  Please update TEST_DATA in the script first!');
        console.log('1. Login to get JWT token');
        console.log('2. Get booking code from mobile app');
        console.log('3. Update TEST_DATA values in this script');
        console.log('4. Run: node debug-payment.js\n');
    } else {
        debugPayment().catch(console.error);
    }
}

module.exports = { debugPayment };
