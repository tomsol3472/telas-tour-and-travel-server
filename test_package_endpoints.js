const db = require('./config/db');
const packageController = require('./controllers/packageController');

// Mock request and response objects for testing
function createMockReq(params = {}, body = {}, query = {}) {
  return {
    params,
    body,
    query,
    user: null // No authentication for package endpoints
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

async function testPackageEndpoints() {
  try {
    console.log('🧪 Testing Package Endpoints...\n');

    // Test 1: Check if tour_packages table exists and has data
    console.log('1. Checking tour_packages table...');
    try {
      const tableCheck = await db.query(`
        SELECT COUNT(*) as count FROM tour_packages
      `);
      console.log(`   ✅ tour_packages table exists with ${tableCheck.rows[0].count} packages`);
      
      if (tableCheck.rows[0].count > 0) {
        const samplePackage = await db.query(`
          SELECT id, package_code, name, is_active, created_at 
          FROM tour_packages 
          LIMIT 1
        `);
        console.log(`   📦 Sample package: ${samplePackage.rows[0].name} (Active: ${samplePackage.rows[0].is_active})`);
      }
    } catch (error) {
      console.log('   ❌ tour_packages table issue:', error.message);
    }

    // Test 2: Check package_pricing table
    console.log('\n2. Checking package_pricing table...');
    try {
      const pricingCheck = await db.query(`
        SELECT COUNT(*) as count FROM package_pricing
      `);
      console.log(`   ✅ package_pricing table exists with ${pricingCheck.rows[0].count} pricing records`);
    } catch (error) {
      console.log('   ❌ package_pricing table issue:', error.message);
    }

    // Test 3: Check package_itineraries table
    console.log('\n3. Checking package_itineraries table...');
    try {
      const itineraryCheck = await db.query(`
        SELECT COUNT(*) as count FROM package_itineraries
      `);
      console.log(`   ✅ package_itineraries table exists with ${itineraryCheck.rows[0].count} itinerary records`);
    } catch (error) {
      console.log('   ❌ package_itineraries table issue:', error.message);
    }

    // Test 4: Test getAllPackages controller
    console.log('\n4. Testing getAllPackages controller...');
    const req1 = createMockReq();
    const res1 = createMockRes();
    
    await packageController.getAllPackages(req1, res1);
    
    if (res1.statusCode === 200) {
      const packages = res1.data;
      console.log(`   ✅ getAllPackages: Found ${packages.length} packages`);
      
      if (packages.length > 0) {
        const pkg = packages[0];
        console.log(`   📦 First package: ${pkg.name}`);
        console.log(`   💰 Base price: $${pkg.base_price}`);
        console.log(`   🏃 Active: ${pkg.is_active}`);
        console.log(`   📅 Created: ${new Date(pkg.created_at).toLocaleDateString()}`);
        
        // Check if pricing data is included
        if (pkg.price_per_person_international) {
          console.log(`   💵 International price: $${pkg.price_per_person_international}`);
        } else {
          console.log('   ⚠️  No pricing data found');
        }
        
        // Check if itinerary data is included
        if (pkg.itinerary && pkg.itinerary.length > 0) {
          console.log(`   📋 Itinerary: ${pkg.itinerary.length} days`);
        } else {
          console.log('   ⚠️  No itinerary data found');
        }
      }
    } else {
      console.log('   ❌ getAllPackages failed:', res1.data);
    }

    // Test 5: Test getPackageById if packages exist
    if (res1.statusCode === 200 && res1.data.length > 0) {
      console.log('\n5. Testing getPackageById controller...');
      const firstPackageId = res1.data[0].id;
      
      const req2 = createMockReq({ id: firstPackageId });
      const res2 = createMockRes();
      
      await packageController.getPackageById(req2, res2);
      
      if (res2.statusCode === 200) {
        const pkg = res2.data;
        console.log(`   ✅ getPackageById: Found package "${pkg.name}"`);
        console.log(`   📝 Description length: ${pkg.description ? pkg.description.length : 0} characters`);
        console.log(`   🏷️  Tags: ${pkg.tags ? pkg.tags.length : 0} tags`);
        console.log(`   ✅ Inclusions: ${pkg.inclusions ? pkg.inclusions.length : 0} items`);
        console.log(`   ❌ Exclusions: ${pkg.exclusions ? pkg.exclusions.length : 0} items`);
        console.log(`   📸 Photos: ${pkg.photos_urls ? pkg.photos_urls.length : 0} images`);
      } else {
        console.log('   ❌ getPackageById failed:', res2.data);
      }
    }

    // Test 6: Check for common issues
    console.log('\n6. Checking for common issues...');
    
    // Check for inactive packages
    const inactiveCheck = await db.query(`
      SELECT COUNT(*) as count FROM tour_packages WHERE is_active = false
    `);
    if (inactiveCheck.rows[0].count > 0) {
      console.log(`   ⚠️  Found ${inactiveCheck.rows[0].count} inactive packages (won't show in mobile app)`);
    }
    
    // Check for packages without pricing
    const noPricingCheck = await db.query(`
      SELECT tp.id, tp.name 
      FROM tour_packages tp 
      LEFT JOIN package_pricing pp ON tp.id = pp.package_id 
      WHERE pp.package_id IS NULL AND tp.is_active = true
    `);
    if (noPricingCheck.rows.length > 0) {
      console.log(`   ⚠️  Found ${noPricingCheck.rows.length} active packages without pricing:`);
      noPricingCheck.rows.forEach(pkg => {
        console.log(`      - ${pkg.name} (ID: ${pkg.id})`);
      });
    }
    
    // Check for packages without photos
    const noPhotosCheck = await db.query(`
      SELECT COUNT(*) as count 
      FROM tour_packages 
      WHERE (photos_urls IS NULL OR photos_urls::text = '[]' OR photos_urls::text = '') 
      AND is_active = true
    `);
    if (noPhotosCheck.rows[0].count > 0) {
      console.log(`   ⚠️  Found ${noPhotosCheck.rows[0].count} active packages without photos`);
    }

    console.log('\n✅ Package Endpoints Test Complete!');
    
    // Provide recommendations
    console.log('\n💡 Recommendations for Mobile App:');
    console.log('   1. Ensure mobile app calls GET /api/packages (no auth required)');
    console.log('   2. Check if mobile app filters for is_active = true packages');
    console.log('   3. Verify mobile app handles pricing data correctly');
    console.log('   4. Check if image URLs are accessible from mobile app');
    console.log('   5. Ensure proper error handling for network issues');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.error(error.stack);
  } finally {
    process.exit(0);
  }
}

testPackageEndpoints();