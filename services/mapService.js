const axios = require('axios');

exports.getRouteDetails = async (origin, destination) => {
    // If no locations provided, return defaults
    if (!origin || !destination) {
        return { distanceKm: 0, durationHrs: 0 };
    }

    try {
        const apiKey = process.env.GOOGLE_MAPS_API_KEY;
        
        // Call Google Maps API
        const url = `https://maps.googleapis.com/maps/api/distancematrix/json?origins=${encodeURIComponent(origin)}&destinations=${encodeURIComponent(destination)}&key=${apiKey}`;
        
        const response = await axios.get(url);
        const data = response.data;

        // Check if Google gave a valid route
        if (data.status === 'OK' && data.rows[0].elements[0].status === 'OK') {
            const element = data.rows[0].elements[0];
            return {
                distanceKm: element.distance.value / 1000, // Convert meters to KM
                durationHrs: element.duration.value / 3600 // Convert seconds to Hours
            };
        } else {
            throw new Error("Route not found");
        }

    } catch (error) {
        console.log("⚠️Google Maps API Failed (or Key invalid). Using Fallback Math.");
        // Fallback: This allows you to test without paying Google yet.
        return {
            distanceKm: 150, // Fake distance
            durationHrs: 3   // Fake time
        };
    }
};