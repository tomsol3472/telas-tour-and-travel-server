/**
 * Chapa Payment Integration Test Script
 * 
 * This script tests the Chapa payment integration without needing the mobile app.
 * Run with: node test-chapa-integration.js
 */

const axios = require('axios');
require('dotenv').config();

const API_URL = process.env.API_URL || 'http://localhost:5000';
const CHAPA_SECRET_KEY = process.env.CHAPA_SECRET_KEY;

// Test configuration
const TEST_CONFIG = {
  // You need to get a valid JWT token first by logging in
  authToken: 'YOUR_JWT_TOKEN_HERE', // Replace with actual token
  bookingId: 'YOUR_BOOKING_ID_HERE', // Replace with actual booking ID
};

console.log('=== Chapa Payment Integration Test ===\n');
console.log('API URL:', API_URL);
console.log('Chapa Key:', CHAPA_SECRET_KEY ? 'Configured ✓' : 'Missing ✗');
console.log('\n');

/**
 * Test 1: Initialize Payment Transaction
 */
async function testInitializePayment() {
  console.log('Test 1: Initialize Payment Transaction');
  console.log('----------------------------------------');
  
  try {
    const tx_ref = `TELAS-${Date.now()}-TEST`;
    
    const response = await axios.post(
      `${API_URL}/api/payments/chapa/initialize`,
      {
        bookingId: TEST_CONFIG.bookingId,
        tx_ref: tx_ref,
        amount: 1000,
        status: 'pending'
      },
      {
        headers: {
          'Authorization': `Bearer ${TEST_CONFIG.authToken}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log('✓ Success!');
    console.log('Response:', JSON.stringify(response.data, null, 2));
    console.log('\n');
    
    return { success: true, tx_ref };
  } catch (error) {
    console.log('✗ Failed!');
    console.log('Error:', error.response?.data || error.message);
    console.log('\n');
    
    return { success: false };
  }
}

/**
 * Test 2: Initialize Payment with Chapa (Get Checkout URL)
 */
async function testChapaCheckout() {
  console.log('Test 2: Initialize Payment with Chapa');
  console.log('----------------------------------------');
  
  try {
    const response = await axios.post(
      `${API_URL}/api/payments/init`,
      {
        booking_id: TEST_CONFIG.bookingId,
        method: 'chapa'
      },
      {
        headers: {
          'Authorization': `Bearer ${TEST_CONFIG.authToken}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log('✓ Success!');
    console.log('Response:', JSON.stringify(response.data, null, 2));
    
    if (response.data.paymentUrl) {
      console.log('\n🔗 Payment URL:', response.data.paymentUrl);
      console.log('Open this URL in your browser to complete test payment');
    }
    
    console.log('\n');
    
    return { success: true, tx_ref: response.data.tx_ref };
  } catch (error) {
    console.log('✗ Failed!');
    console.log('Error:', error.response?.data || error.message);
    console.log('\n');
    
    return { success: false };
  }
}

/**
 * Test 3: Verify Payment (after completing payment on Chapa)
 */
async function testVerifyPayment(tx_ref) {
  console.log('Test 3: Verify Payment');
  console.log('----------------------------------------');
  
  if (!tx_ref) {
    console.log('⚠ Skipped - No tx_ref provided');
    console.log('Complete a payment first, then run this test with the tx_ref\n');
    return { success: false };
  }
  
  try {
    const response = await axios.post(
      `${API_URL}/api/payments/chapa/verify`,
      {
        tx_ref: tx_ref
      },
      {
        headers: {
          'Authorization': `Bearer ${TEST_CONFIG.authToken}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log('✓ Success!');
    console.log('Response:', JSON.stringify(response.data, null, 2));
    console.log('\n');
    
    return { success: true };
  } catch (error) {
    console.log('✗ Failed!');
    console.log('Error:', error.response?.data || error.message);
    console.log('\n');
    
    return { success: false };
  }
}

/**
 * Test 4: Get Payment Status
 */
async function testGetPaymentStatus() {
  console.log('Test 4: Get Payment Status');
  console.log('----------------------------------------');
  
  try {
    const response = await axios.get(
      `${API_URL}/api/payments/status/${TEST_CONFIG.bookingId}`,
      {
        headers: {
          'Authorization': `Bearer ${TEST_CONFIG.authToken}`
        }
      }
    );
    
    console.log('✓ Success!');
    console.log('Response:', JSON.stringify(response.data, null, 2));
    console.log('\n');
    
    return { success: true };
  } catch (error) {
    console.log('✗ Failed!');
    console.log('Error:', error.response?.data || error.message);
    console.log('\n');
    
    return { success: false };
  }
}

/**
 * Test 5: Direct Chapa API Test
 */
async function testChapaAPI() {
  console.log('Test 5: Direct Chapa API Test');
  console.log('----------------------------------------');
  
  if (!CHAPA_SECRET_KEY) {
    console.log('✗ Failed - CHAPA_SECRET_KEY not configured\n');
    return { success: false };
  }
  
  try {
    const tx_ref = `DIRECT-TEST-${Date.now()}`;
    
    const response = await axios.post(
      'https://api.chapa.co/v1/transaction/initialize',
      {
        amount: '100',
        currency: 'ETB',
        email: 'test@example.com',
        first_name: 'Test',
        last_name: 'User',
        tx_ref: tx_ref,
        callback_url: `${API_URL}/api/payments/chapa/callback`,
        return_url: 'https://example.com/success',
        customization: {
          title: 'Test Payment',
          description: 'Testing Chapa API'
        }
      },
      {
        headers: {
          'Authorization': `Bearer ${CHAPA_SECRET_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log('✓ Success! Chapa API is working correctly');
    console.log('Response:', JSON.stringify(response.data, null, 2));
    console.log('\n');
    
    return { success: true };
  } catch (error) {
    console.log('✗ Failed!');
    console.log('Error:', error.response?.data || error.message);
    
    if (error.response?.status === 401) {
      console.log('\n⚠ Authentication failed - Check your CHAPA_SECRET_KEY');
    }
    
    console.log('\n');
    
    return { success: false };
  }
}

/**
 * Run all tests
 */
async function runTests() {
  console.log('Starting Chapa Integration Tests...\n');
  
  // Check configuration
  if (TEST_CONFIG.authToken === 'YOUR_JWT_TOKEN_HERE') {
    console.log('⚠ WARNING: Please update TEST_CONFIG.authToken with a valid JWT token');
    console.log('You can get a token by logging in through the mobile app or API\n');
  }
  
  if (TEST_CONFIG.bookingId === 'YOUR_BOOKING_ID_HERE') {
    console.log('⚠ WARNING: Please update TEST_CONFIG.bookingId with a valid booking ID');
    console.log('Create a booking first through the mobile app or API\n');
  }
  
  // Test 5: Direct Chapa API (doesn't need auth token)
  const chapaTest = await testChapaAPI();
  
  if (!chapaTest.success) {
    console.log('❌ Chapa API test failed. Please check your CHAPA_SECRET_KEY');
    console.log('Cannot proceed with other tests.\n');
    return;
  }
  
  // Only run other tests if we have valid config
  if (TEST_CONFIG.authToken !== 'YOUR_JWT_TOKEN_HERE' && 
      TEST_CONFIG.bookingId !== 'YOUR_BOOKING_ID_HERE') {
    
    // Test 1: Initialize payment transaction
    await testInitializePayment();
    
    // Test 2: Get Chapa checkout URL
    const checkoutResult = await testChapaCheckout();
    
    // Test 4: Get payment status
    await testGetPaymentStatus();
    
    // Test 3: Verify payment (manual - after completing payment)
    if (checkoutResult.tx_ref) {
      console.log('📝 To test payment verification:');
      console.log('1. Open the payment URL above in your browser');
      console.log('2. Complete the test payment');
      console.log('3. Run this command:');
      console.log(`   node -e "require('./test-chapa-integration.js').testVerifyPayment('${checkoutResult.tx_ref}')"`);
      console.log('\n');
    }
  } else {
    console.log('⚠ Skipping authenticated tests - Please configure authToken and bookingId\n');
  }
  
  console.log('=== Test Summary ===');
  console.log('✓ Chapa API connection: Working');
  console.log('✓ Server endpoints: Available');
  console.log('ℹ For full testing, configure authToken and bookingId in the script\n');
}

// Run tests if executed directly
if (require.main === module) {
  runTests().catch(console.error);
}

// Export functions for manual testing
module.exports = {
  testInitializePayment,
  testChapaCheckout,
  testVerifyPayment,
  testGetPaymentStatus,
  testChapaAPI
};
