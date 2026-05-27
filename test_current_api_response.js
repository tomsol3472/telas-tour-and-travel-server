const axios = require('axios');

async function testCurrentAPIResponse() {
  console.log('🧪 Testing CURRENT API Response (before restart)\n');

  try {
    // Make a request that will trigger a conflict
    // Using a fake token - we just want to see the error format
    const response = await axios.patch(
      'http://localhost:5000/api/bookings/TEL-2605-000004',
      {
        assigned_guide_id: 'some-guide-id'
      },
      {
        headers: {
          'Authorization': 'Bearer fake-token-for-testing'
        }
      }
    );

    console.log('Response:', response.data);

  } catch (error) {
    if (error.response) {
      console.log('📊 CURRENT API ERROR RESPONSE:\n');
      console.log('Status:', error.response.status);
      console.log('\nFull Response:');
      console.log(JSON.stringify(error.response.data, null, 2));
      
      console.log('\n📋 What frontend is trying to access:');
      console.log('error.response.data.error:', error.response.data.error);
      console.log('error.response.data.message:', error.response.data.message);
      console.log('error.response.data.details:', error.response.data.details);
      console.log('error.response.data.conflicts:', error.response.data.conflicts);
      
      if (error.response.data.conflicts && error.response.data.conflicts.length > 0) {
        console.log('\nFirst conflict:');
        console.log(JSON.stringify(error.response.data.conflicts[0], null, 2));
      } else {
        console.log('\n⚠️  No conflicts array or empty!');
      }
      
      console.log('\n🔍 This is what the frontend sees RIGHT NOW');
      console.log('   The "undefined" is coming from trying to access a property that doesn\'t exist');
      
    } else if (error.request) {
      console.log('❌ No response from server');
      console.log('   Is the server running on http://localhost:5000?');
    } else {
      console.log('❌ Error:', error.message);
    }
  }
}

testCurrentAPIResponse();
