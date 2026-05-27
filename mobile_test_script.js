/**
 * Mobile Package Loading Test Script
 * 
 * This script simulates how a mobile app would interact with the package API.
 * Mobile developers can use this to verify the API is working correctly.
 */

const axios = require('axios');

// Configuration - Update these for your environment
const CONFIG = {
  BASE_URL: 'http://localhost:5000/api',
  IMAGE_BASE_URL: 'http://localhost:5000',
  TIMEOUT: 10000  // 10 seconds
};

// Create axios instance with mobile app configuration
const api = axios.create({
  baseURL: CONFIG.BASE_URL,
  timeout: CONFIG.TIMEOUT,
  headers: {
    'Content-Type': 'application/json',
    'User-Agent': 'TelasToursApp/1.0'
  }
});

// Simulate mobile app package loading
async function simulateMobileApp() {
  console.log('📱 Simulating Mobile App Package Loading...\n');
  console.log(`🌐 Server: ${CONFIG.BASE_URL}`);
  console.log(`🖼️  Images: ${CONFIG.IMAGE_BASE_URL}\n`);

  try {
    // Step 1: Load all packages (like app home screen)
    console.log('1️⃣  Loading packages for home screen...');
    const packagesResponse = await api.get('/packages/mobile');
    
    if (!packagesResponse.data.success) {
      throw new Error('API returned success: false');
    }
    
    const packages = packagesResponse.data.data;
    console.log(`   ✅ Loaded ${packages.length} packages`);
    
    if (packages.length === 0) {
      console.log('   ⚠️  No packages available');
      return;
    }

    // Step 2: Display package list (like mobile app would)
    console.log('\n2️⃣  Package List (as mobile app would display):');
    packages.forEach((pkg, index) => {
      console.log(`\n   📦 Package ${index + 1}: ${pkg.name}`);
      console.log(`      💰 Price: $${pkg.pricing.price_per_person_international}`);
      console.log(`      ⏱️  Duration: ${pkg.duration_days} days`);
      console.log(`      📸 Photos: ${pkg.photos_urls.length} images`);
      console.log(`      📋 Itinerary: ${pkg.itinerary.length} days planned`);
      console.log(`      ✅ Active: ${pkg.is_active}`);
      
      // Check data integrity (what mobile app needs)
      const dataChecks = {
        'Name': pkg.name ? '✅' : '❌',
        'Description': pkg.description !== null ? '✅' : '❌',
        'Tags Array': Array.isArray(pkg.tags) ? '✅' : '❌',
        'Inclusions Array': Array.isArray(pkg.inclusions) ? '✅' : '❌',
        'Photos Array': Array.isArray(pkg.photos_urls) ? '✅' : '❌',
        'Itinerary Array': Array.isArray(pkg.itinerary) ? '✅' : '❌',
        'Pricing Object': typeof pkg.pricing === 'object' ? '✅' : '❌'
      };
      
      console.log(`      🔍 Data Integrity: ${Object.entries(dataChecks).map(([key, status]) => `${key}${status}`).join(' ')}`);
    });

    // Step 3: Load individual package details (when user taps on package)
    console.log('\n3️⃣  Loading package details (user tapped on first package)...');
    const firstPackage = packages[0];
    const detailResponse = await api.get(`/packages/mobile/${firstPackage.id}`);
    
    if (!detailResponse.data.success) {
      throw new Error('Package detail API returned success: false');
    }
    
    const packageDetail = detailResponse.data.data;
    console.log(`   ✅ Loaded details for: ${packageDetail.name}`);
    console.log(`   📝 Description: ${packageDetail.description.substring(0, 100)}...`);
    console.log(`   🏷️  Inclusions: ${packageDetail.inclusions.join(', ')}`);
    console.log(`   🚫 Exclusions: ${packageDetail.exclusions.join(', ')}`);

    // Step 4: Test image loading (critical for mobile apps)
    console.log('\n4️⃣  Testing image accessibility...');
    if (packageDetail.photos_urls.length > 0) {
      const firstImageUrl = `${CONFIG.IMAGE_BASE_URL}${packageDetail.photos_urls[0]}`;
      
      try {
        const imageResponse = await axios.head(firstImageUrl, { timeout: 5000 });
        console.log(`   ✅ Images accessible`);
        console.log(`   📸 Sample URL: ${firstImageUrl}`);
        console.log(`   📏 Content-Type: ${imageResponse.headers['content-type']}`);
        console.log(`   📐 Size: ${Math.round(imageResponse.headers['content-length'] / 1024)}KB`);
      } catch (imageError) {
        console.log(`   ❌ Image not accessible: ${imageError.message}`);
        console.log(`   🔗 URL tested: ${firstImageUrl}`);
      }
    } else {
      console.log(`   ⚠️  No images to test for this package`);
    }

    // Step 5: Test itinerary display (important for tour packages)
    console.log('\n5️⃣  Testing itinerary display...');
    if (packageDetail.itinerary.length > 0) {
      console.log(`   ✅ Itinerary available (${packageDetail.itinerary.length} days)`);
      packageDetail.itinerary.slice(0, 2).forEach(day => {
        console.log(`   📅 Day ${day.day_number}: ${day.title}`);
        console.log(`      ${day.description.substring(0, 80)}...`);
      });
      if (packageDetail.itinerary.length > 2) {
        console.log(`   ... and ${packageDetail.itinerary.length - 2} more days`);
      }
    } else {
      console.log(`   ⚠️  No itinerary available for this package`);
    }

    // Step 6: Performance test (mobile apps need fast responses)
    console.log('\n6️⃣  Performance test...');
    const startTime = Date.now();
    await api.get('/packages/mobile');
    const endTime = Date.now();
    const responseTime = endTime - startTime;
    
    console.log(`   ⏱️  Response time: ${responseTime}ms`);
    if (responseTime < 1000) {
      console.log(`   ✅ Excellent performance for mobile`);
    } else if (responseTime < 3000) {
      console.log(`   ⚠️  Acceptable performance for mobile`);
    } else {
      console.log(`   ❌ Slow performance - may cause mobile app issues`);
    }

    // Final summary
    console.log('\n🎉 Mobile App Simulation Complete!');
    console.log('\n📊 Summary:');
    console.log(`   📦 Packages loaded: ${packages.length}`);
    console.log(`   🌐 API endpoints: Working`);
    console.log(`   📸 Images: ${packageDetail.photos_urls.length > 0 ? 'Available' : 'None'}`);
    console.log(`   📋 Data format: Mobile-friendly`);
    console.log(`   ⚡ Performance: ${responseTime < 1000 ? 'Fast' : responseTime < 3000 ? 'Good' : 'Slow'}`);

    console.log('\n✅ The mobile app should be able to load packages successfully!');

  } catch (error) {
    console.error('\n❌ Mobile App Simulation Failed!');
    
    if (error.response) {
      console.error(`   Status: ${error.response.status}`);
      console.error(`   Error: ${error.response.data.error || error.response.statusText}`);
      console.error(`   Details: ${error.response.data.details || 'No additional details'}`);
    } else if (error.request) {
      console.error(`   Network Error: ${error.message}`);
      console.error(`   Check if server is running on ${CONFIG.BASE_URL}`);
    } else {
      console.error(`   Error: ${error.message}`);
    }

    console.log('\n🔧 Troubleshooting Steps:');
    console.log('   1. Ensure server is running: node server.js');
    console.log('   2. Check server URL is correct');
    console.log('   3. Verify network connectivity');
    console.log('   4. Check server logs for errors');
  }
}

// Run the simulation
simulateMobileApp().then(() => {
  process.exit(0);
}).catch(error => {
  console.error('Simulation crashed:', error);
  process.exit(1);
});