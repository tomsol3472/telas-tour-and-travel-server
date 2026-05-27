const db = require('./config/db');

async function checkPackageData() {
  try {
    console.log('🔍 Checking Package Data Structure...\n');

    // Get all packages with full details
    const packages = await db.query(`
      SELECT 
        tp.id,
        tp.package_code,
        tp.name,
        tp.description,
        tp.tour_type,
        tp.difficulty,
        tp.duration_days,
        tp.duration_nights,
        tp.min_group_size,
        tp.max_group_size,
        tp.season_recommendation,
        tp.tags,
        tp.inclusions,
        tp.exclusions,
        tp.requirements,
        tp.important_notes,
        tp.cancellation_policy,
        tp.photos_urls,
        tp.is_customizable,
        tp.is_active,
        tp.created_at,
        pp.season,
        pp.price_per_person_international,
        pp.price_per_person_local,
        pp.price_per_person_diaspora,
        pp.child_discount_percentage,
        pp.infant_discount_percentage,
        pp.group_discount_percentage
      FROM tour_packages tp
      LEFT JOIN package_pricing pp ON tp.id = pp.package_id
      ORDER BY tp.created_at DESC
    `);

    console.log(`Found ${packages.rows.length} packages:\n`);

    packages.rows.forEach((pkg, index) => {
      console.log(`📦 Package ${index + 1}: ${pkg.name}`);
      console.log(`   ID: ${pkg.id}`);
      console.log(`   Code: ${pkg.package_code}`);
      console.log(`   Active: ${pkg.is_active}`);
      console.log(`   Tour Type: ${pkg.tour_type}`);
      console.log(`   Difficulty: ${pkg.difficulty}`);
      console.log(`   Duration: ${pkg.duration_days} days, ${pkg.duration_nights} nights`);
      console.log(`   Group Size: ${pkg.min_group_size}-${pkg.max_group_size} people`);
      console.log(`   Season: ${pkg.season_recommendation}`);
      
      // Check pricing
      if (pkg.price_per_person_international) {
        console.log(`   💰 Pricing:`);
        console.log(`      International: $${pkg.price_per_person_international}`);
        console.log(`      Local: $${pkg.price_per_person_local}`);
        console.log(`      Diaspora: $${pkg.price_per_person_diaspora}`);
      } else {
        console.log(`   ❌ No pricing data!`);
      }
      
      // Check arrays
      console.log(`   📋 Data Arrays:`);
      console.log(`      Tags: ${pkg.tags ? JSON.stringify(pkg.tags) : 'null'}`);
      console.log(`      Inclusions: ${pkg.inclusions ? JSON.stringify(pkg.inclusions) : 'null'}`);
      console.log(`      Exclusions: ${pkg.exclusions ? JSON.stringify(pkg.exclusions) : 'null'}`);
      console.log(`      Requirements: ${pkg.requirements ? JSON.stringify(pkg.requirements) : 'null'}`);
      
      // Check photos
      if (pkg.photos_urls) {
        console.log(`   📸 Photos: ${JSON.stringify(pkg.photos_urls)}`);
      } else {
        console.log(`   📸 Photos: null`);
      }
      
      // Check text fields
      console.log(`   📝 Description: ${pkg.description ? pkg.description.substring(0, 100) + '...' : 'null'}`);
      console.log(`   ⚠️  Important Notes: ${pkg.important_notes ? pkg.important_notes.substring(0, 50) + '...' : 'null'}`);
      console.log(`   🚫 Cancellation Policy: ${pkg.cancellation_policy ? pkg.cancellation_policy.substring(0, 50) + '...' : 'null'}`);
      
      console.log(''); // Empty line between packages
    });

    // Check itineraries for each package
    console.log('📅 Checking Itineraries...\n');
    for (const pkg of packages.rows) {
      const itinerary = await db.query(`
        SELECT day_number, title, description, accommodation_type, meal_plan, distance_km, travel_time_hours
        FROM package_itineraries
        WHERE package_id = $1
        ORDER BY day_number
      `, [pkg.id]);
      
      console.log(`📦 ${pkg.name} - Itinerary (${itinerary.rows.length} days):`);
      itinerary.rows.forEach(day => {
        console.log(`   Day ${day.day_number}: ${day.title}`);
        console.log(`      Description: ${day.description ? day.description.substring(0, 80) + '...' : 'No description'}`);
        console.log(`      Accommodation: ${day.accommodation_type || 'Not specified'}`);
        console.log(`      Meals: ${day.meal_plan || 'Not specified'}`);
        console.log(`      Distance: ${day.distance_km || 0}km, Travel time: ${day.travel_time_hours || 0}h`);
      });
      console.log('');
    }

    // Test the API response format
    console.log('🌐 Testing API Response Format...\n');
    const apiResponse = await db.query(`
      SELECT 
        tp.*, 
        pp.season, pp.price_per_person_international, pp.price_per_person_local, pp.price_per_person_diaspora,
        pp.child_discount_percentage, pp.infant_discount_percentage, pp.group_discount_percentage,
        COALESCE(pp.price_per_person_international, 0) AS base_price,
        (SELECT json_agg(pi.* ORDER BY pi.day_number) FROM package_itineraries pi WHERE pi.package_id = tp.id) as itinerary
      FROM tour_packages tp
      LEFT JOIN package_pricing pp ON tp.id = pp.package_id
      WHERE tp.is_active = true
      ORDER BY tp.created_at DESC
    `);

    console.log('API Response Structure:');
    if (apiResponse.rows.length > 0) {
      const sample = apiResponse.rows[0];
      console.log(`✅ Sample package for mobile app:`);
      console.log(`   Name: ${sample.name}`);
      console.log(`   Base Price: $${sample.base_price}`);
      console.log(`   Active: ${sample.is_active}`);
      console.log(`   Has Itinerary: ${sample.itinerary ? 'Yes (' + sample.itinerary.length + ' days)' : 'No'}`);
      console.log(`   Photos Count: ${sample.photos_urls ? sample.photos_urls.length : 0}`);
      
      // Check if photos are accessible URLs
      if (sample.photos_urls && sample.photos_urls.length > 0) {
        console.log(`   Photo URLs:`);
        sample.photos_urls.forEach((url, index) => {
          console.log(`      ${index + 1}. ${url}`);
        });
      }
    } else {
      console.log('❌ No active packages found!');
    }

    console.log('\n🔧 Mobile App Troubleshooting:');
    console.log('1. Check if mobile app is calling: GET /api/packages');
    console.log('2. Verify network connectivity from mobile device');
    console.log('3. Check if mobile app handles JSON arrays correctly');
    console.log('4. Ensure image URLs are accessible from mobile network');
    console.log('5. Check mobile app error logs for specific error messages');
    console.log('6. Verify mobile app filters for is_active = true packages');

  } catch (error) {
    console.error('❌ Error checking package data:', error.message);
    console.error(error.stack);
  } finally {
    process.exit(0);
  }
}

checkPackageData();