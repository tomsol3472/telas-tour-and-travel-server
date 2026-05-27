/**
 * Nearby Places Routes
 * API endpoints for fetching nearby places using OpenStreetMap
 */

const express = require('express');
const router = express.Router();
const nearbyPlacesService = require('../services/nearbyPlacesService');

/**
 * GET /api/nearby/places
 * Get nearby places based on user location
 * 
 * Query params:
 * - latitude: User's latitude (required)
 * - longitude: User's longitude (required)
 * - radius: Search radius in meters (optional, default: 5000)
 * - type: Place type - 'hotel', 'attraction', 'restaurant', or 'all' (optional, default: 'all')
 */
router.get('/places', async (req, res) => {
    try {
        const { latitude, longitude, radius, type } = req.query;

        // Validate required parameters
        if (!latitude || !longitude) {
            return res.status(400).json({
                success: false,
                error: 'Latitude and longitude are required'
            });
        }

        const lat = parseFloat(latitude);
        const lon = parseFloat(longitude);
        const searchRadius = radius ? parseInt(radius) : 5000;
        const placeType = type || 'all';

        // Validate coordinates
        if (isNaN(lat) || isNaN(lon) || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
            return res.status(400).json({
                success: false,
                error: 'Invalid coordinates'
            });
        }

        // Fetch nearby places
        const result = await nearbyPlacesService.getNearbyPlaces(lat, lon, searchRadius, placeType);

        res.json(result);

    } catch (error) {
        console.error('Nearby Places API Error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch nearby places',
            message: error.message
        });
    }
});

/**
 * GET /api/nearby/place/:id
 * Get details for a specific place
 */
router.get('/place/:id', async (req, res) => {
    try {
        const { id } = req.params;

        if (!id) {
            return res.status(400).json({
                success: false,
                error: 'Place ID is required'
            });
        }

        const result = await nearbyPlacesService.getPlaceDetails(id);

        if (!result.success) {
            return res.status(404).json(result);
        }

        res.json(result);

    } catch (error) {
        console.error('Get Place Details Error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch place details',
            message: error.message
        });
    }
});

/**
 * GET /api/nearby/test
 * Test endpoint to verify service is working
 */
router.get('/test', (req, res) => {
    res.json({
        success: true,
        message: 'Nearby places service is working!',
        endpoints: {
            places: 'GET /api/nearby/places?latitude=9.03&longitude=38.74&radius=5000&type=all',
            placeDetails: 'GET /api/nearby/place/:id'
        },
        supportedTypes: ['hotel', 'attraction', 'restaurant', 'all'],
        defaultRadius: '5000 meters (5km)',
        dataSource: 'OpenStreetMap (No API key required)'
    });
});

module.exports = router;
