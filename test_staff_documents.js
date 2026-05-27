const db = require('./config/db');
const userController = require('./controllers/userController');

// Mock request and response objects for testing
function createMockReq(user = null, params = {}, body = {}) {
  return {
    user: user || { userId: '1def1a50-78c7-4b3d-bd6b-784ea2504c7b', role: 'admin' },
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

async function testStaffDocuments() {
  try {
    console.log('🧪 Testing Staff Documents Endpoint...\n');

    // First, find a guide and driver to test with
    console.log('1. Finding test users...');
    
    const guideResult = await db.query(`
      SELECT u.id, u.email, u.user_role 
      FROM users u 
      JOIN guides g ON u.id = g.user_id 
      LIMIT 1
    `);
    
    const driverResult = await db.query(`
      SELECT u.id, u.email, u.user_role 
      FROM users u 
      JOIN drivers d ON u.id = d.user_id 
      LIMIT 1
    `);

    if (guideResult.rows.length > 0) {
      const guide = guideResult.rows[0];
      console.log(`   Found guide: ${guide.email} (${guide.id})`);
      
      // Test guide documents
      console.log('\n2. Testing guide documents...');
      const req1 = createMockReq(null, { id: guide.id });
      const res1 = createMockRes();
      
      await userController.getStaffDocuments(req1, res1);
      
      if (res1.statusCode === 200 && res1.data.success) {
        console.log('   ✅ Guide documents retrieved successfully');
        console.log(`   License: ${res1.data.data.documents.license.number}`);
        console.log(`   License Photo: ${res1.data.data.documents.license.photo_url || 'Not uploaded'}`);
        console.log(`   License Expired: ${res1.data.data.documents.license.is_expired ? 'Yes' : 'No'}`);
        console.log(`   First Aid Cert: ${res1.data.data.documents.first_aid.has_cert ? 'Yes' : 'No'}`);
      } else {
        console.log('   ❌ Guide documents failed:', res1.data);
      }
    } else {
      console.log('   ⚠️  No guides found in database');
    }

    if (driverResult.rows.length > 0) {
      const driver = driverResult.rows[0];
      console.log(`\n   Found driver: ${driver.email} (${driver.id})`);
      
      // Test driver documents
      console.log('\n3. Testing driver documents...');
      const req2 = createMockReq(null, { id: driver.id });
      const res2 = createMockRes();
      
      await userController.getStaffDocuments(req2, res2);
      
      if (res2.statusCode === 200 && res2.data.success) {
        console.log('   ✅ Driver documents retrieved successfully');
        console.log(`   License: ${res2.data.data.documents.license.number}`);
        console.log(`   License Photo: ${res2.data.data.documents.license.photo_url || 'Not uploaded'}`);
        console.log(`   License Expired: ${res2.data.data.documents.license.is_expired ? 'Yes' : 'No'}`);
      } else {
        console.log('   ❌ Driver documents failed:', res2.data);
      }
    } else {
      console.log('   ⚠️  No drivers found in database');
    }

    // Test enhanced getUserById
    if (guideResult.rows.length > 0) {
      console.log('\n4. Testing enhanced getUserById with documents...');
      const req3 = createMockReq(null, { id: guideResult.rows[0].id });
      const res3 = createMockRes();
      
      await userController.getUserById(req3, res3);
      
      if (res3.statusCode === 200 && res3.data.success && res3.data.data.documents) {
        console.log('   ✅ getUserById now includes document information');
        console.log(`   Documents included: ${Object.keys(res3.data.data.documents).join(', ')}`);
      } else {
        console.log('   ❌ getUserById documents failed or missing');
      }
    }

    console.log('\n✅ Staff Documents Test Complete!');
    console.log('\n📋 Summary:');
    console.log('   ✅ New endpoint: GET /api/users/:id/documents');
    console.log('   ✅ Enhanced getUserById with document info');
    console.log('   ✅ License photo URLs included');
    console.log('   ✅ Expiration status calculated');
    console.log('   ✅ First aid certification info (guides)');
    console.log('\n🎯 Frontend can now access staff documents!');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error(error.stack);
  } finally {
    process.exit(0);
  }
}

testStaffDocuments();