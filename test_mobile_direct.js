const axios = require('axios');

async function testMobileDirect() {
  try {
    console.log('🔍 Testing mobile endpoint directly...\n');
    
    const response = await axios.get('http://localhost:5000/api/packages/mobile');
    console.log('✅ Success:', response.data);
  } catch (error) {
    console.log('❌ Error details:');
    if (error.response) {
      console.log('Status:', error.response.status);
      console.log('Data:', error.response.data);
      console.log('Headers:', error.response.headers);
    } else if (error.request) {
      console.log('No response received:', error.request);
    } else {
      console.log('Error:', error.message);
    }
  }
}

testMobileDirect();