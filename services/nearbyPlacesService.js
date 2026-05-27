/**
 * Nearby Places Service
 * Fetches nearby places using OpenStreetMap Overpass API
 * No Google Maps API key required!
 */

const axios = require('axios');

/**
 * Fetch nearby places from OpenStreetMap
 * @param {number} latitude - User's latitude
 * @param {number} longitude - User's longitude
 * @param {number} radius - Search radius in meters (default: 5000m = 5km)
 * @param {string} type - Place type: 'hotel', 'attraction', 'restaurant', or 'all'
 */
exports.getNearbyPlaces = async (latitude, longitude, radius = 5000, type = 'all') => {
    try {
        console.log(`🔍 Searching nearby places: ${type} within ${radius}m of (${latitude}, ${longitude})`);

        const places = [];

        // Build Overpass QL query based on type
        let query = '';

        if (type === 'hotel' || type === 'all') {
            query += `
                node["tourism"="hotel"](around:${radius},${latitude},${longitude});
                node["tourism"="guest_house"](around:${radius},${latitude},${longitude});
                node["tourism"="hostel"](around:${radius},${latitude},${longitude});
            `;
        }

        if (type === 'attraction' || type === 'all') {
            query += `
                node["tourism"="attraction"](around:${radius},${latitude},${longitude});
                node["tourism"="museum"](around:${radius},${latitude},${longitude});
                node["historic"](around:${radius},${latitude},${longitude});
                node["amenity"="place_of_worship"](around:${radius},${latitude},${longitude});
            `;
        }

        if (type === 'restaurant' || type === 'all') {
            query += `
                node["amenity"="restaurant"](around:${radius},${latitude},${longitude});
                node["amenity"="cafe"](around:${radius},${latitude},${longitude});
                node["amenity"="bar"](around:${radius},${latitude},${longitude});
            `;
        }

        const overpassQuery = `
            [out:json][timeout:25];
            (
                ${query}
            );
            out body;
            >;
            out skel qt;
        `;

        // Query Overpass API
        const response = await axios.post(
            'https://overpass-api.de/api/interpreter',
            overpassQuery,
            {
                headers: { 'Content-Type': 'text/plain' },
                timeout: 30000
            }
        );

        if (response.data && response.data.elements) {
            for (const element of response.data.elements) {
                if (element.type === 'node' && element.tags && element.tags.name) {
                    const placeType = determineType(element.tags);
                    const distance = calculateDistance(
                        latitude,
                        longitude,
                        element.lat,
                        element.lon
                    );

                    places.push({
                        id: element.id.toString(),
                        name: element.tags.name,
                        type: placeType,
                        latitude: element.lat,
                        longitude: element.lon,
                        distance: formatDistance(distance),
                        distanceMeters: distance,
                        rating: generateRating(element.tags),
                        address: element.tags['addr:street'] || element.tags['addr:city'] || '',
                        phone: element.tags.phone || element.tags['contact:phone'] || '',
                        website: element.tags.website || element.tags['contact:website'] || '',
                        description: element.tags.description || '',
                        tags: element.tags
                    });
                }
            }
        }

        // Sort by distance
        places.sort((a, b) => a.distanceMeters - b.distanceMeters);

        // Limit to 50 places
        const limitedPlaces = places.slice(0, 50);

        console.log(`✓ Found ${limitedPlaces.length} nearby places`);

        return {
            success: true,
            count: limitedPlaces.length,
            places: limitedPlaces,
            userLocation: { latitude, longitude },
            radius: radius
        };

    } catch (error) {
        console.error('❌ Nearby Places Error:', error.message);

        // Return fallback data if API fails
        return {
            success: false,
            error: error.message,
            count: 0,
            places: getFallbackPlaces(latitude, longitude),
            userLocation: { latitude, longitude },
            radius: radius
        };
    }
};

/**
 * Determine place type from OSM tags
 */
function determineType(tags) {
    if (tags.tourism === 'hotel' || tags.tourism === 'guest_house' || tags.tourism === 'hostel') {
        return 'hotel';
    }
    if (tags.amenity === 'restaurant' || tags.amenity === 'cafe' || tags.amenity === 'bar') {
        return 'restaurant';
    }
    if (tags.tourism === 'attraction' || tags.tourism === 'museum' || tags.historic || tags.amenity === 'place_of_worship') {
        return 'attraction';
    }
    return 'other';
}

/**
 * Calculate distance between two coordinates (Haversine formula)
 * Returns distance in meters
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371e3; // Earth's radius in meters
    const φ1 = lat1 * Math.PI / 180;
    const φ2 = lat2 * Math.PI / 180;
    const Δφ = (lat2 - lat1) * Math.PI / 180;
    const Δλ = (lon2 - lon1) * Math.PI / 180;

    const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
              Math.cos(φ1) * Math.cos(φ2) *
              Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c; // Distance in meters
}

/**
 * Format distance for display
 */
function formatDistance(meters) {
    if (meters < 1000) {
        return `${Math.round(meters)}m`;
    }
    return `${(meters / 1000).toFixed(1)}km`;
}

/**
 * Generate rating based on tags (simple heuristic)
 */
function generateRating(tags) {
    let rating = 3.5; // Base rating

    // Increase rating if has website
    if (tags.website || tags['contact:website']) rating += 0.3;

    // Increase rating if has phone
    if (tags.phone || tags['contact:phone']) rating += 0.2;

    // Increase rating for certain types
    if (tags.tourism === 'museum') rating += 0.5;
    if (tags.historic) rating += 0.4;
    if (tags.tourism === 'attraction') rating += 0.3;

    // Cap at 5.0
    return Math.min(rating, 5.0);
}

/**
 * Fallback places for Addis Ababa (if API fails)
 */
function getFallbackPlaces(latitude, longitude) {
    // Default to Addis Ababa landmarks
    const addisPlaces = [
        {
            id: 'fallback-1',
            name: 'National Museum of Ethiopia',
            type: 'attraction',
            latitude: 9.0384,
            longitude: 38.7618,
            distance: calculateDistance(latitude, longitude, 9.0384, 38.7618),
            rating: 4.6,
            address: 'King George VI St, Addis Ababa',
            description: 'Home to Lucy, the 3.2 million year old skeleton'
        },
        {
            id: 'fallback-2',
            name: 'Holy Trinity Cathedral',
            type: 'attraction',
            latitude: 9.0305,
            longitude: 38.7662,
            distance: calculateDistance(latitude, longitude, 9.0305, 38.7662),
            rating: 4.7,
            address: 'Arat Kilo, Addis Ababa',
            description: 'Beautiful Ethiopian Orthodox cathedral'
        },
        {
            id: 'fallback-3',
            name: 'Sheraton Addis',
            type: 'hotel',
            latitude: 9.0182,
            longitude: 38.7633,
            distance: calculateDistance(latitude, longitude, 9.0182, 38.7633),
            rating: 4.8,
            address: 'Taitu Street, Addis Ababa'
        },
        {
            id: 'fallback-4',
            name: 'Yod Abyssinia Traditional Restaurant',
            type: 'restaurant',
            latitude: 8.9892,
            longitude: 38.7885,
            distance: calculateDistance(latitude, longitude, 8.9892, 38.7885),
            rating: 4.5,
            address: 'Bole Road, Addis Ababa',
            description: 'Traditional Ethiopian food with cultural show'
        },
        {
            id: 'fallback-5',
            name: 'Ethnological Museum',
            type: 'attraction',
            latitude: 9.0365,
            longitude: 38.7639,
            distance: calculateDistance(latitude, longitude, 9.0365, 38.7639),
            rating: 4.4,
            address: 'Addis Ababa University, Sidist Kilo'
        }
    ];

    // Format distances
    return addisPlaces.map(place => ({
        ...place,
        distanceMeters: place.distance,
        distance: formatDistance(place.distance)
    })).sort((a, b) => a.distanceMeters - b.distanceMeters);
}

/**
 * Get place details by ID
 */
exports.getPlaceDetails = async (placeId) => {
    try {
        const query = `
            [out:json];
            node(${placeId});
            out body;
        `;

        const response = await axios.post(
            'https://overpass-api.de/api/interpreter',
            query,
            {
                headers: { 'Content-Type': 'text/plain' },
                timeout: 10000
            }
        );

        if (response.data && response.data.elements && response.data.elements.length > 0) {
            const element = response.data.elements[0];
            return {
                success: true,
                place: {
                    id: element.id.toString(),
                    name: element.tags.name,
                    type: determineType(element.tags),
                    latitude: element.lat,
                    longitude: element.lon,
                    tags: element.tags
                }
            };
        }

        return {
            success: false,
            error: 'Place not found'
        };

    } catch (error) {
        console.error('Get Place Details Error:', error);
        return {
            success: false,
            error: error.message
        };
    }
};

module.exports = exports;
