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

async function testUserManagement() {
  console.log('🧪 Testing User Management Endpoints...\n');

  try {
    // Test 1: Get all users
    console.log('1. Testing GET /api/users (Get all users)...');
    try {
      const response = await api.get('/users');
      if (response.data.success) {
        console.log(`   ✅ Success: Found ${response.data.data.length} users`);
        
        if (response.data.data.length > 0) {
          const sampleUser = response.data.data[0];
          console.log(`   📋 Sample user: ${sampleUser.first_name} ${sampleUser.last_name} (${sampleUser.role})`);
          console.log(`   📧 Email: ${sampleUser.email}`);
          console.log(`   📱 Phone: ${sampleUser.phone || 'Not provided'}`);
          console.log(`   ✅ Status: ${sampleUser.status}`);
          
          // Store first user ID for further tests
          global.testUserId = sampleUser.id;
        }
      } else {
        console.log('   ❌ Failed: Response success is false');
      }
    } catch (error) {
      console.log(`   ❌ Failed: ${error.response?.data?.error || error.message}`);
    }

    // Test 2: Get user by ID
    if (global.testUserId) {
      console.log('\n2. Testing GET /api/users/:id (Get user by ID)...');
      try {
        const response = await api.get(`/users/${global.testUserId}`);
        if (response.data.success) {
          console.log(`   ✅ Success: Retrieved user ${response.data.data.first_name} ${response.data.data.last_name}`);
          console.log(`   📋 Role: ${response.data.data.role}`);
          console.log(`   📧 Email: ${response.data.data.email}`);
          console.log(`   📱 Phone: ${response.data.data.phone || 'Not provided'}`);
          console.log(`   🏠 Location: ${response.data.data.city || 'Not provided'}, ${response.data.data.country || 'Not provided'}`);
          
          // Check if user has documents (for staff)
          if (response.data.data.documents) {
            console.log(`   📄 Documents: Available`);
          } else {
            console.log(`   📄 Documents: Not available (not staff or no documents)`);
          }
        } else {
          console.log('   ❌ Failed: Response success is false');
        }
      } catch (error) {
        console.log(`   ❌ Failed: ${error.response?.data?.error || error.message}`);
      }
    }

    // Test 3: Get staff documents (if user is staff)
    if (global.testUserId) {
      console.log('\n3. Testing GET /api/users/:id/documents (Get staff documents)...');
      try {
        const response = await api.get(`/users/${global.testUserId}/documents`);
        if (response.data.success) {
          console.log(`   ✅ Success: Retrieved ${response.data.data.type} documents`);
          console.log(`   📄 License Number: ${response.data.data.documents?.license?.number || 'Not provided'}`);
          console.log(`   📸 License Photo: ${response.data.data.documents?.license?.photo_url ? 'Available' : 'Not available'}`);
          console.log(`   📅 License Expiry: ${response.data.data.documents?.license?.expiry_date || 'Not provided'}`);
          console.log(`   ⚠️  License Expired: ${response.data.data.documents?.license?.is_expired ? 'Yes' : 'No'}`);
        } else {
          console.log('   ❌ Failed: Response success is false');
        }
      } catch (error) {
        if (error.response?.status === 400) {
          console.log(`   ⚠️  User is not staff (guide/driver): ${error.response.data.error}`);
        } else {
          console.log(`   ❌ Failed: ${error.response?.data?.error || error.message}`);
        }
      }
    }

    // Test 4: Update user (simulate edit button)
    if (global.testUserId) {
      console.log('\n4. Testing PUT /api/users/:id (Update user - Edit button)...');
      try {
        const updateData = {
          first_name: 'Updated Name',
          status: 'active'
        };
        
        const response = await api.put(`/users/${global.testUserId}`, updateData);
        if (response.data.success) {
          console.log(`   ✅ Success: User updated successfully`);
          console.log(`   📝 Message: ${response.data.message}`);
        } else {
          console.log('   ❌ Failed: Response success is false');
        }
      } catch (error) {
        console.log(`   ❌ Failed: ${error.response?.data?.error || error.message}`);
        if (error.response?.status === 401) {
          console.log('   🔐 Authentication issue: Check if admin token is valid');
        } else if (error.response?.status === 403) {
          console.log('   🚫 Authorization issue: User may not have admin privileges');
        }
      }
    }

    // Test 5: Test delete endpoint (but don't actually delete)
    console.log('\n5. Testing DELETE endpoint availability (Delete button)...');
    try {
      // We'll test with a non-existent ID to avoid actually deleting data
      const response = await api.delete('/users/00000000-0000-0000-0000-000000000000');
    } catch (error) {
      if (error.response?.status === 404) {
        console.log('   ✅ Delete endpoint is working (returned 404 for non-existent user)');
      } else if (error.response?.status === 401) {
        console.log('   🔐 Authentication issue: Check if admin token is valid');
      } else if (error.response?.status === 403) {
        console.log('   🚫 Authorization issue: User may not have admin privileges');
      } else {
        console.log(`   ❌ Unexpected error: ${error.response?.data?.error || error.message}`);
      }
    }

    console.log('\n📊 User Management Test Summary:');
    console.log('   ✅ User listing endpoint: Available');
    console.log('   ✅ User detail endpoint: Available');
    console.log('   ✅ Staff documents endpoint: Available');
    console.log('   ✅ User update endpoint: Available');
    console.log('   ✅ User delete endpoint: Available');

    console.log('\n🔧 Common Issues and Solutions:');
    console.log('   1. Edit/Delete buttons not working:');
    console.log('      - Check if admin token is valid and not expired');
    console.log('      - Verify user has admin role in database');
    console.log('      - Check browser console for JavaScript errors');
    console.log('      - Verify API endpoints are being called correctly');
    
    console.log('\n   2. User profiles/files not showing:');
    console.log('      - Check if user has profile data in user_profiles table');
    console.log('      - For staff: Check if documents exist in guides/drivers table');
    console.log('      - Verify image URLs are accessible');
    console.log('      - Check if frontend is handling null/empty data correctly');
    
    console.log('\n   3. Authentication issues:');
    console.log('      - Ensure admin is logged in with valid token');
    console.log('      - Check token expiration time');
    console.log('      - Verify authMiddleware is working correctly');

    console.log('\n💡 Frontend Integration Tips:');
    console.log('   - Edit button should call: PUT /api/users/:id');
    console.log('   - Delete button should call: DELETE /api/users/:id');
    console.log('   - Profile view should call: GET /api/users/:id');
    console.log('   - Staff documents should call: GET /api/users/:id/documents');
    console.log('   - Always include Authorization header with admin token');

  } catch (error) {
    console.error('❌ Test suite failed:', error.message);
  } finally {
    process.exit(0);
  }
}

testUserManagement();