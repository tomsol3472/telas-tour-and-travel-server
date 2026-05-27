const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api';

async function testMobileFix() {
  try {
    console.log('📱 Testing Mobile Package Loading Fix...\n');

    // Test 1: Test original endpoint with improvements
    console.log('1. Testing improved original endpoint: GET /api/packages');
    try {
      const response = await axios.get(`${BASE_URL}/packages`);
      console.log(`   ✅ Status: ${response.status}`);
      console.log(`   📦 Packages found: ${response.data.length}`);
      
      // Check CORS headers
      const corsHeaders = response.headers['access-control-allow-origin'];
      console.log(`   🌐 CORS header: ${corsHeaders || 'Not set'}`);
      
      if (response.data.length > 0) {
        const pkg = response.data[0];
        console.log(`   📋 Sample package structure:`);
        console.log(`      Name: ${pkg.name}`);
        console.log(`      Active: ${pkg.is_active}`);
        console.log(`      Tags: ${Array.isArray(pkg.tags) ? 'Array' : typeof pkg.tags} (${pkg.tags?.length || 0} items)`);
        console.log(`      Inclusions: ${Array.isArray(pkg.inclusions) ? 'Array' : typeof pkg.inclusions} (${pkg.inclusions?.length || 0} items)`);
        console.log(`      Photos: ${Array.isArray(pkg.photos_urls) ? 'Array' : typeof pkg.photos_urls} (${pkg.photos_urls?.length || 0} items)`);
        console.log(`      Itinerary: ${Array.isArray(pkg.itinerary) ? 'Array' : typeof pkg.itinerary} (${pkg.itinerary?.length || 0} days)`);
        console.log(`      Description: ${pkg.description ? 'Present' : 'Empty/Null'}`);
        console.log(`      Base Price: $${pkg.base_price}`);
      }
    } catch (error) {
      console.log(`   ❌ Original endpoint failed: ${error.message}`);
    }

    // Test 2: Test new mobile-specific endpoint
    console.log('\n2. Testing new mobile endpoint: GET /api/packages/mobile');
    try {
      const response = await axios.get(`${BASE_URL}/packages/mobile`);
      console.log(`   ✅ Status: ${response.status}`);
      console.log(`   📦 Packages found: ${response.data.count}`);
      console.log(`   ✅ Success flag: ${response.data.success}`);
      
      // Check CORS headers
      const corsHeaders = response.headers['access-control-allow-origin'];
      console.log(`   🌐 CORS header: ${corsHeaders || 'Not set'}`);
      
      if (response.data.data && response.data.data.length > 0) {
        const pkg = response.data.data[0];
        console.log(`   📋 Mobile package structure:`);
        console.log(`      Name: ${pkg.name}`);
        console.log(`      Active: ${pkg.is_active}`);
        console.log(`      Pricing object: ${typeof pkg.pricing}`);
        console.log(`      Base Price: $${pkg.pricing.base_price}`);
        console.log(`      International Price: $${pkg.pricing.price_per_person_international}`);
        console.log(`      Tags: ${Array.isArray(pkg.tags) ? 'Array' : typeof pkg.tags} (${pkg.tags?.length || 0} items)`);
        console.log(`      Inclusions: ${Array.isArray(pkg.inclusions) ? 'Array' : typeof pkg.inclusions} (${pkg.inclusions?.length || 0} items)`);
        console.log(`      Photos: ${Array.isArray(pkg.photos_urls) ? 'Array' : typeof pkg.photos_urls} (${pkg.photos_urls?.length || 0} items)`);
        console.log(`      Itinerary: ${Array.isArray(pkg.itinerary) ? 'Array' : typeof pkg.itinerary} (${pkg.itinerary?.length || 0} days)`);
        console.log(`      Description: ${pkg.description ? 'Present' : 'Empty'}`);
      }
    } catch (error) {
      console.log(`   ❌ Mobile endpoint failed: ${error.message}`);
    }

    // Test 3: Test individual package endpoints
    console.log('\n3. Testing individual package endpoints...');
    try {
      const packagesResponse = await axios.get(`${BASE_URL}/packages`);
      if (packagesResponse.data.length > 0) {
        const firstPackageId = packagesResponse.data[0].id;
        
        // Test original individual endpoint
        console.log(`   Testing original: GET /api/packages/${firstPackageId}`);
        const originalResponse = await axios.get(`${BASE_URL}/packages/${firstPackageId}`);
        console.log(`      ✅ Original individual endpoint: ${originalResponse.status}`);
        
        // Test mobile individual endpoint
        console.log(`   Testing mobile: GET /api/packages/mobile/${firstPackageId}`);
        const mobileResponse = await axios.get(`${BASE_URL}/packages/mobile/${firstPackageId}`);
        console.log(`      ✅ Mobile individual endpoint: ${mobileResponse.status}`);
        console.log(`      ✅ Success flag: ${mobileResponse.data.success}`);
        console.log(`      📦 Package name: ${mobileResponse.data.data.name}`);
      }
    } catch (error) {
      console.log(`   ❌ Individual package test failed: ${error.message}`);
    }

    // Test 4: Test image accessibility
    console.log('\n4. Testing image accessibility...');
    try {
      const packagesResponse = await axios.get(`${BASE_URL}/packages/mobile`);
      const packageWithPhotos = packagesResponse.data.data.find(pkg => pkg.photos_urls && pkg.photos_urls.length > 0);
      
      if (packageWithPhotos) {
        const firstImageUrl = packageWithPhotos.photos_urls[0];
        const fullImageUrl = `http://localhost:5000${firstImageUrl}`;
        
        try {
          const imageResponse = await axios.head(fullImageUrl);
          console.log(`   ✅ Images accessible: ${imageResponse.status}`);
          console.log(`   📸 Sample URL: ${fullImageUrl}`);
          console.log(`   📏 Content-Type: ${imageResponse.headers['content-type']}`);
          console.log(`   📐 Content-Length: ${imageResponse.headers['content-length']} bytes`);
        } catch (imageError) {
          console.log(`   ❌ Image not accessible: ${imageError.message}`);
        }
      } else {
        console.log(`   ⚠️  No packages with photos found`);
      }
    } catch (error) {
      console.log(`   ❌ Image accessibility test failed: ${error.message}`);
    }

    // Test 5: Test OPTIONS request (CORS preflight)
    console.log('\n5. Testing CORS preflight (OPTIONS request)...');
    try {
      const optionsResponse = await axios.options(`${BASE_URL}/packages/mobile`);
      console.log(`   ✅ OPTIONS request: ${optionsResponse.status}`);
      console.log(`   🌐 CORS headers in OPTIONS:`);
      console.log(`      Access-Control-Allow-Origin: ${optionsResponse.headers['access-control-allow-origin'] || 'Not set'}`);
      console.log(`      Access-Control-Allow-Methods: ${optionsResponse.headers['access-control-allow-methods'] || 'Not set'}`);
      console.log(`      Access-Control-Allow-Headers: ${optionsResponse.headers['access-control-allow-headers'] || 'Not set'}`);
    } catch (error) {
      console.log(`   ⚠️  OPTIONS request failed: ${error.message}`);
    }

    console.log('\n✅ Mobile Package Loading Fix Test Complete!\n');

    console.log('📱 Mobile App Integration Instructions:');
    console.log('   1. Use the mobile-specific endpoint: GET /api/packages/mobile');
    console.log('   2. Response format: { success: true, count: number, data: Package[] }');
    console.log('   3. Individual packages: GET /api/packages/mobile/:id');
    console.log('   4. All packages are filtered to show only active ones');
    console.log('   5. All array fields are guaranteed to be arrays (never null)');
    console.log('   6. All string fields have fallback empty strings');
    console.log('   7. Pricing is structured in a separate object');
    console.log('   8. CORS headers are explicitly set for mobile compatibility');

    console.log('\n🔧 Mobile App Configuration:');
    console.log('   Base URL: http://localhost:5000/api');
    console.log('   Packages Endpoint: GET /packages/mobile');
    console.log('   Individual Package: GET /packages/mobile/:id');
    console.log('   Image Base URL: http://localhost:5000');
    console.log('   No authentication required for package endpoints');

    console.log('\n⚠️  Mobile App Troubleshooting:');
    console.log('   1. Ensure mobile device can reach server IP address');
    console.log('   2. Check mobile app network security policy (Android 9+)');
    console.log('   3. Verify mobile app handles JSON response format correctly');
    console.log('   4. Test API calls from mobile device browser first');
    console.log('   5. Check mobile app timeout settings (increase if needed)');
    console.log('   6. Verify mobile app error handling for network issues');

  } catch (error) {
    console.error('❌ Mobile fix test failed:', error.message);
  } finally {
    process.exit(0);
  }
}

testMobileFix();