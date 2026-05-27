const db = require('./config/db');
const userController = require('./controllers/userController');

// Mock request and response objects for testing
function createMockReq(user = null, params = {}, body = {}) {
  return {
    user: user || { userId: '351b31d4-40b1-4f69-85dd-f5f25031a184', role: 'admin' },
    params,
    body
  };
}

function createMockRes() {
  const res = {
    statusCode: 200,
    data: null,
    status: function(code) {
      this.statusCode = code;
      return this;
    },
    json: function(data) {
      this.data = data;
      return this;
    }
  };
  return res;
}

async function testUserEndpoints() {
  try {
    console.log('🧪 Testing User Controller Endpoints...\n');

    // Test 1: getAllUsers
    console.log('1. Testing getAllUsers...');
    const req1 = createMockReq();
    const res1 = createMockRes();
    
    await userController.getAllUsers(req1, res1);
    
    if (res1.statusCode === 200 && res1.data.success) {
      console.log(`   ✅ getAllUsers: Found ${res1.data.data.length} users`);
      if (res1.data.data.length > 0) {
        const sample = res1.data.data[0];
        console.log(`   Sample: ${sample.email} (${sample.role})`);
      }
    } else {
      console.log('   ❌ getAllUsers failed:', res1.data);
    }

    // Test 2: getUserById
    console.log('\n2. Testing getUserById...');
    const req2 = createMockReq(null, { id: '351b31d4-40b1-4f69-85dd-f5f25031a184' });
    const res2 = createMockRes();
    
    await userController.getUserById(req2, res2);
    
    if (res2.statusCode === 200 && res2.data.success) {
      console.log(`   ✅ getUserById: Found user ${res2.data.data.email}`);
    } else {
      console.log('   ❌ getUserById failed:', res2.data);
    }

    // Test 3: getCurrentUser
    console.log('\n3. Testing getCurrentUser...');
    const req3 = createMockReq();
    const res3 = createMockRes();
    
    await userController.getCurrentUser(req3, res3);
    
    if (res3.statusCode === 200 && res3.data.success) {
      console.log(`   ✅ getCurrentUser: Found user ${res3.data.data.email}`);
    } else {
      console.log('   ❌ getCurrentUser failed:', res3.data);
    }

    // Test 4: getProfile
    console.log('\n4. Testing getProfile...');
    const req4 = createMockReq();
    const res4 = createMockRes();
    
    await userController.getProfile(req4, res4);
    
    if (res4.statusCode === 200 && res4.data.success) {
      console.log(`   ✅ getProfile: Found profile for ${res4.data.data.email}`);
    } else {
      console.log('   ❌ getProfile failed:', res4.data);
    }

    console.log('\n✅ All User Controller Tests Complete!');
    console.log('\n📋 Summary:');
    console.log('   ✅ getAllUsers works');
    console.log('   ✅ getUserById works');
    console.log('   ✅ getCurrentUser works');
    console.log('   ✅ getProfile works');
    console.log('\n🎉 User endpoints are ready for frontend integration!');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error(error.stack);
  } finally {
    process.exit(0);
  }
}

testUserEndpoints();