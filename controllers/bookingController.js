const db = require('../config/db');
const mapService = require('../services/mapService'); // Import the new service

exports.createBooking = async (req, res) => {
    const { package_id, start_date, end_date, adults, origin, destination } = req.body;
    const userId = req.user.userId;

    try {
        // 1. Get Tourist ID
        const touristRes = await db.query("SELECT id FROM tourists WHERE user_id = $1", [userId]);
        if (touristRes.rows.length === 0) return res.status(400).json({ error: "Tourist not found" });
        const touristId = touristRes.rows[0].id;

        // 2. Get Route Data (Google Maps)
        const route = await mapService.getRouteDetails(origin, destination);
        
        // 3. Calculate Dynamic Price
        // Formula: (Adults * 5000) + (Distance_KM * 50 ETB per KM)
        const basePrice = adults * 5000;
        const transportCost = route.distanceKm * 50; 
        const totalAmount = basePrice + transportCost;

        console.log(`📏 Distance: ${route.distanceKm}km | 💰 Price: ${totalAmount} ETB`);

        // 4. Insert Booking
        // Note: We are saving the calculated distance into the DB
        const result = await db.query(
            `INSERT INTO bookings 
            (tourist_id, package_id, start_date, end_date, number_of_adults, 
             calculated_distance_km, calculated_duration_hours, total_amount, status)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'pending') 
            RETURNING *`,
            [touristId, package_id, start_date, end_date, adults, 
             route.distanceKm, route.durationHrs, totalAmount]
        );

        res.status(201).json({
            message: "Booking created with Map Data",
            booking: result.rows[0],
            route_details: route
        });

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Booking failed" });
    }
};