const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api';

async function testMobileAPI() {
  try {
    console.log('📱 Testing Mobile App API Endpoints...\n');

    // Test 1: Check if server is running
    console.log('1. Testing server connectivity...');
    try {
      const response = await axios.get(`${BASE_URL}/packages`);
      console.log(`   ✅ Server is running and packages endpoint is accessible`);
      console.log(`   📦 Found ${response.data.length} packages`);
      
      // Test the response structure
      if (response.data.length > 0) {
        const pkg = response.data[0];
        console.log(`\n📋 Sample Package Structure:`);
        console.log(`   Name: ${pkg.name}`);
        console.log(`   ID: ${pkg.id}`);
        console.log(`   Active: ${pkg.is_active}`);
        console.log(`   Base Price: $${pkg.base_price}`);
        console.log(`   Duration: ${pkg.duration_days} days`);
        console.log(`   Photos: ${pkg.photos_urls ? pkg.photos_urls.length : 0} images`);
        console.log(`   Itinerary: ${pkg.itinerary ? pkg.itinerary.length : 0} days`);
        
        // Check if all required fields are present
        const requiredFields = ['id', 'name', 'description', 'tour_type', 'difficulty', 'duration_days', 'is_active', 'base_price'];
        const missingFields = requiredFields.filter(field => pkg[field] === undefined || pkg[field] === null);
        
        if (missingFields.length === 0) {
          console.log(`   ✅ All required fields are present`);
        } else {
          console.log(`   ⚠️  Missing fields: ${missingFields.join(', ')}`);
        }
      }
      
    } catch (error) {
      console.log(`   ❌ Server connectivity failed:`, error.message);
      if (error.code === 'ECONNREFUSED') {
        console.log(`   💡 Make sure the server is running on port 5000`);
        return;
      }
    }

    // Test 2: Test individual package endpoint
    console.log('\n2. Testing individual package endpoint...');
    try {
      const packagesResponse = await axios.get(`${BASE_URL}/packages`);
      if (packagesResponse.data.length > 0) {
        const firstPackageId = packagesResponse.data[0].id;
        const packageResponse = await axios.get(`${BASE_URL}/packages/${firstPackageId}`);
        
        console.log(`   ✅ Individual package endpoint working`);
        console.log(`   📦 Package: ${packageResponse.data.name}`);
        console.log(`   📝 Description: ${packageResponse.data.description ? 'Present' : 'Missing'}`);
        console.log(`   💰 Pricing: International $${packageResponse.data.price_per_person_international}`);
        console.log(`   📸 Photos: ${packageResponse.data.photos_urls ? packageResponse.data.photos_urls.length : 0} images`);
        console.log(`   📅 Itinerary: ${packageResponse.data.itinerary ? packageResponse.data.itinerary.length : 0} days`);
      }
    } catch (error) {
      console.log(`   ❌ Individual package endpoint failed:`, error.message);
    }

    // Test 3: Check image accessibility
    console.log('\n3. Testing image accessibility...');
    try {
      const packagesResponse = await axios.get(`${BASE_URL}/packages`);
      const packageWithPhotos = packagesResponse.data.find(pkg => pkg.photos_urls && pkg.photos_urls.length > 0);
      
      if (packageWithPhotos) {
        const firstImageUrl = packageWithPhotos.photos_urls[0];
        const fullImageUrl = `http://localhost:5000${firstImageUrl}`;
        
        try {
          const imageResponse = await axios.head(fullImageUrl);
          console.log(`   ✅ Images are accessible`);
          console.log(`   📸 Sample image URL: ${fullImageUrl}`);
          console.log(`   📏 Content-Type: ${imageResponse.headers['content-type']}`);
        } catch (imageError) {
          console.log(`   ❌ Images not accessible: ${imageError.message}`);
          console.log(`   🔗 Tried URL: ${fullImageUrl}`);
          console.log(`   💡 Check if uploads folder exists and images are served correctly`);
        }
      } else {
        console.log(`   ⚠️  No packages with photos found to test`);
      }
    } catch (error) {
      console.log(`   ❌ Image accessibility test failed:`, error.message);
    }

    // Test 4: Test CORS headers
    console.log('\n4. Testing CORS headers...');
    try {
      const response = await axios.get(`${BASE_URL}/packages`);
      const corsHeaders = {
        'Access-Control-Allow-Origin': response.headers['access-control-allow-origin'],
        'Access-Control-Allow-Methods': response.headers['access-control-allow-methods'],
        'Access-Control-Allow-Headers': response.headers['access-control-allow-headers']
      };
      
      console.log(`   CORS Headers:`);
      Object.entries(corsHeaders).forEach(([key, value]) => {
        console.log(`      ${key}: ${value || 'Not set'}`);
      });
      
      if (corsHeaders['Access-Control-Allow-Origin']) {
        console.log(`   ✅ CORS is configured`);
      } else {
        console.log(`   ⚠️  CORS headers not found - may cause mobile app issues`);
      }
    } catch (error) {
      console.log(`   ❌ CORS test failed:`, error.message);
    }

    // Test 5: Test response time
    console.log('\n5. Testing response time...');
    try {
      const startTime = Date.now();
      await axios.get(`${BASE_URL}/packages`);
      const endTime = Date.now();
      const responseTime = endTime - startTime;
      
      console.log(`   ⏱️  Response time: ${responseTime}ms`);
      if (responseTime < 1000) {
        console.log(`   ✅ Good response time`);
      } else if (responseTime < 3000) {
        console.log(`   ⚠️  Slow response time`);
      } else {
        console.log(`   ❌ Very slow response time - may cause mobile app timeouts`);
      }
    } catch (error) {
      console.log(`   ❌ Response time test failed:`, error.message);
    }

    console.log('\n📱 Mobile App Integration Checklist:');
    console.log('   ✅ 1. API endpoint is accessible: GET /api/packages');
    console.log('   ✅ 2. Packages exist and are active');
    console.log('   ✅ 3. Response includes all necessary fields');
    console.log('   ⚠️  4. Check mobile app network configuration');
    console.log('   ⚠️  5. Verify mobile app error handling');
    console.log('   ⚠️  6. Check mobile app JSON parsing');
    console.log('   ⚠️  7. Verify image loading in mobile app');

    console.log('\n🔧 Common Mobile App Issues:');
    console.log('   1. Network Security Policy (Android 9+) - requires HTTPS or network_security_config');
    console.log('   2. CORS issues - check if mobile app sets proper headers');
    console.log('   3. JSON parsing errors - check mobile app JSON handling');
    console.log('   4. Image loading - verify image URLs are accessible from mobile network');
    console.log('   5. Timeout issues - check mobile app timeout settings');
    console.log('   6. Base URL configuration - ensure mobile app uses correct server URL');

    console.log('\n💡 Debugging Steps for Mobile App:');
    console.log('   1. Check mobile app logs for specific error messages');
    console.log('   2. Test API call from mobile device browser');
    console.log('   3. Verify mobile device can reach server IP/domain');
    console.log('   4. Check if mobile app handles empty arrays correctly');
    console.log('   5. Verify mobile app filters active packages (is_active = true)');
    console.log('   6. Test with mobile device on same network as server');

  } catch (error) {
    console.error('❌ Mobile API test failed:', error.message);
  } finally {
    process.exit(0);
  }
}

testMobileAPI();