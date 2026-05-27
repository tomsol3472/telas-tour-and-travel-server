const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api';

// You'll need to replace this with a valid admin token
const ADMIN_TOKEN = 'your_admin_token_here';

const api = axios.create({
  baseURL: BASE_URL,
  headers: {
    'Authorization': `Bearer ${ADMIN_TOKEN}`,
    'Content-Type': 'application/json'
  }
});

async function testEndpoints() {
  console.log('🧪 Testing Settings and Maintenance API Endpoints...\n');

  const tests = [
    // Settings endpoints
    { name: 'Get System Configurations', method: 'get', url: '/settings/system' },
    { name: 'Get Performance Metrics', method: 'get', url: '/settings/performance' },
    { name: 'Get Web Traffic Logs', method: 'get', url: '/settings/traffic?timeframe=24h' },
    { name: 'Get Audit Logs', method: 'get', url: '/settings/audit' },
    { name: 'Get System Logs', method: 'get', url: '/settings/system/logs' },
    
    // Maintenance endpoints
    { name: 'Get System Health', method: 'get', url: '/maintenance/health' },
    { name: 'Get Backup History', method: 'get', url: '/maintenance/backups' },
    { name: 'Get Database Stats', method: 'get', url: '/maintenance/database/stats' },
    { name: 'Get System Alerts', method: 'get', url: '/maintenance/alerts' },
    
    // Dashboard endpoints
    { name: 'Get Dashboard Overview', method: 'get', url: '/dashboard/overview' },
    { name: 'Get Revenue Analytics', method: 'get', url: '/dashboard/revenue?timeframe=30d' },
    { name: 'Get User Analytics', method: 'get', url: '/dashboard/users?timeframe=30d' },
    { name: 'Get Booking Analytics', method: 'get', url: '/dashboard/bookings?timeframe=30d' },
    
    // Support endpoints
    { name: 'Get Support Tickets', method: 'get', url: '/support/tickets' },
  ];

  let passed = 0;
  let failed = 0;

  for (const test of tests) {
    try {
      const response = await api[test.method](test.url);
      if (response.data.success) {
        console.log(`✅ ${test.name}`);
        passed++;
      } else {
        console.log(`❌ ${test.name} - Response not successful`);
        failed++;
      }
    } catch (error) {
      if (error.response) {
        console.log(`❌ ${test.name} - ${error.response.status}: ${error.response.data.error || error.response.statusText}`);
      } else {
        console.log(`❌ ${test.name} - ${error.message}`);
      }
      failed++;
    }
  }

  console.log(`\n📊 Test Results: ${passed} passed, ${failed} failed out of ${tests.length} tests`);
  
  if (failed === 0) {
    console.log('🎉 All API endpoints are working correctly!');
  } else if (failed === tests.length) {
    console.log('⚠️  All tests failed. This might be due to:');
    console.log('   1. Invalid or missing admin token');
    console.log('   2. Server not running on port 5000');
    console.log('   3. Authentication middleware blocking requests');
    console.log('\n💡 To fix: Update ADMIN_TOKEN in this file with a valid admin JWT token');
  }
}

// Check if server is running first
axios.get('http://localhost:5000/api/health')
  .then(() => {
    console.log('✅ Server is running on port 5000\n');
    return testEndpoints();
  })
  .catch((error) => {
    if (error.code === 'ECONNREFUSED') {
      console.log('❌ Server is not running on port 5000');
      console.log('💡 Start the server with: node server.js');
    } else {
      console.log('⚠️  Health check endpoint not found, proceeding with tests...\n');
      testEndpoints();
    }
  })
  .finally(() => {
    process.exit(0);
  });
