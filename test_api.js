const axios = require('axios');

const API_BASE = 'http://localhost:5000/api';
const TEST_BOOKING_ID = '12ac405e-385d-4df4-8bed-f3bbe1cd8880';

async function testAPI() {
  console.log('🧪 Testing Booking API Endpoints\n');

  try {
    // Test 1: GET booking by ID (should work without auth for testing)
    console.log('1️⃣ Testing GET /api/bookings/:id');
    try {
      const getResponse = await axios.get(`${API_BASE}/bookings/${TEST_BOOKING_ID}`, {
        timeout: 5000
      });
      console.log('✅ GET request successful');
      console.log('Response:', getResponse.data);
    } catch (error) {
      console.log('❌ GET request failed:', error.response?.status, error.response?.statusText);
      console.log('Error details:', error.response?.data);
      
      if (error.response?.status === 401) {
        console.log('🔐 Authentication required - this is expected');
      }
    }

    // Test 2: PATCH booking (will fail due to auth, but should show different error)
    console.log('\n2️⃣ Testing PATCH /api/bookings/:id');
    try {
      const patchResponse = await axios.patch(`${API_BASE}/bookings/${TEST_BOOKING_ID}`, {
        assigned_guide_id: 'test-guide-id',
        guide_name: 'Test Guide'
      }, {
        timeout: 5000,
        headers: {
          'Content-Type': 'application/json'
        }
      });
      console.log('✅ PATCH request successful');
      console.log('Response:', patchResponse.data);
    } catch (error) {
      console.log('❌ PATCH request failed:', error.response?.status, error.response?.statusText);
      console.log('Error details:', error.response?.data);
      
      if (error.response?.status === 401) {
        console.log('🔐 Authentication required - this is expected');
      } else if (error.response?.status === 404) {
        console.log('🚨 404 Error - Route not found or booking doesn\'t exist');
      }
    }

    // Test 3: Check if server is running
    console.log('\n3️⃣ Testing server connectivity');
    try {
      const serverTest = await axios.get(`${API_BASE}/bookings`, {
        timeout: 5000
      });
      console.log('✅ Server is responding');
    } catch (error) {
      if (error.response?.status === 401) {
        console.log('✅ Server is responding (auth required)');
      } else if (error.code === 'ECONNREFUSED') {
        console.log('❌ Server is not running');
        console.log('   Start server with: npm start or node server.js');
      } else {
        console.log('⚠️  Server issue:', error.message);
      }
    }

    // Test 4: Test with booking code instead of UUID
    console.log('\n4️⃣ Testing with booking code TEL-2605-000015');
    try {
      const codeResponse = await axios.get(`${API_BASE}/bookings/TEL-2605-000015`, {
        timeout: 5000
      });
      console.log('✅ Booking code request successful');
    } catch (error) {
      console.log('❌ Booking code request failed:', error.response?.status);
      if (error.response?.status === 401) {
        console.log('🔐 Authentication required - this is expected');
      }
    }

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testAPI();