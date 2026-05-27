const db = require('../config/db');
const mapService = require('../services/mapService'); // Import the new service
const assignmentNotificationService = require('../services/assignmentNotificationService');
const DataSyncService = require('../services/dataSync');
const ConflictDetectionService = require('../services/conflictDetectionService');

exports.createBooking = async (req, res) => {
    const { package_id, start_date, end_date, adults, origin, destination } = req.body;
    const userId = req.user.userId;

    if (!origin || !destination) {
        return res.status(400).json({ error: "Booking requires an origin and destination." });
    }

    if (!start_date || !end_date) {
        return res.status(400).json({ error: "Booking requires a start and end date." });
    }

    // Default to 1 adult if not provided to satisfy not-null constraint
    const numberOfAdults = adults || 1;

    // Validate package_id to be a valid UUID or null
    let validPackageId = package_id;
    if (validPackageId && !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(validPackageId)) {
        validPackageId = null;
    }

    // Normalize dates: ensure start_date is at least today and end_date is after start_date
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let safeStartDate = new Date(start_date);
    safeStartDate.setHours(0, 0, 0, 0);

    // If start date is in the past, push it to tomorrow automatically
    if (safeStartDate < today) {
        safeStartDate = new Date(today);
        safeStartDate.setDate(safeStartDate.getDate() + 1);
    }

    let safeEndDate = new Date(end_date);
    safeEndDate.setHours(0, 0, 0, 0);

    // If end date is not after start date, set it to start + 7 days
    if (safeEndDate <= safeStartDate) {
        safeEndDate = new Date(safeStartDate);
        safeEndDate.setDate(safeEndDate.getDate() + 7);
    }

    const finalStartDate = safeStartDate.toISOString().split('T')[0];
    const finalEndDate = safeEndDate.toISOString().split('T')[0];

    try {
        // 1. Get Tourist ID
        const touristRes = await db.query("SELECT id FROM tourists WHERE user_id = $1", [userId]);
        if (touristRes.rows.length === 0) return res.status(400).json({ error: "Tourist not found" });
        const touristId = touristRes.rows[0].id;

        // 2. Get Route Data (Google Maps)
        const route = await mapService.getRouteDetails(origin, destination);
        
        // 3. Calculate Dynamic Price
        const basePrice = numberOfAdults * 5000;
        const transportCost = route.distanceKm * 50; 
        const totalAmount = basePrice + transportCost;

        console.log(`📏 Distance: ${route.distanceKm}km | 💰 Price: ${totalAmount} ETB`);

        // 4. Business Rules: Holiday pricing
        let finalAmount = totalAmount;
        const bookingDate = new Date(finalStartDate);
        const month = bookingDate.getMonth() + 1;
        const day = bookingDate.getDate();
        const isHoliday = (month === 1 && day === 19) || (month === 9 && day === 27) || (month === 9 && day === 11);
        
        if (isHoliday) {
            console.log("Holiday detected! Applying max 25% markup cap.");
            finalAmount = totalAmount * 1.25;
        }

        // 5. Generate booking code
        const booking_code = `TEL-${new Date().toISOString().slice(2,10).replace(/-/g,'')}-${String(Math.floor(Math.random() * 999999)).padStart(6,'0')}`;

        const result = await db.query(
            `INSERT INTO bookings 
            (booking_code, tourist_id, package_id, start_date, end_date, number_of_adults, 
             calculated_distance_km, calculated_duration_hours, total_amount, final_amount, 
             locked_base_price, refund_tier, status)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'none', 'pending') 
            RETURNING *`,
            [booking_code, touristId, validPackageId, finalStartDate, finalEndDate, numberOfAdults, 
             route.distanceKm, route.durationHrs, totalAmount, finalAmount, totalAmount]
        );

        res.status(201).json({
            message: "Booking created with Map Data",
            booking: result.rows[0],
            route_details: route
        });
    } catch (err) {
        console.error(err);
        let errorMsg = "Booking failed";
        if (err.code === '23514') {
            errorMsg = "Booking date validation failed. Please try again.";
        }
        res.status(500).json({ error: errorMsg, details: err.message });
    }
};

exports.getUserBookings = async (req, res) => {
    try {
        const userId = req.user.userId;
        
        // Use DataSyncService for properly formatted data
        const result = await DataSyncService.getBookingsForFrontend({
            user_id: userId,
            limit: req.query.limit || 50,
            offset: req.query.offset || 0
        });

        res.status(200).json({ 
            success: true, 
            bookings: result.bookings,
            total: result.total
        });
    } catch (err) {
        console.error("Error fetching bookings:", err);
        res.status(500).json({ error: "Failed to fetch bookings", details: err.message });
    }
};

// New endpoint for admin/management to get all bookings with full assignment details
exports.getAllBookingsWithAssignments = async (req, res) => {
    try {
        const { status, date_from, date_to, limit = 50, offset = 0 } = req.query;
        
        let whereClause = 'WHERE 1=1';
        const params = [];
        let paramCount = 0;

        if (status) {
            paramCount++;
            whereClause += ` AND b.status = $${paramCount}`;
            params.push(status);
        }

        if (date_from) {
            paramCount++;
            whereClause += ` AND b.start_date >= $${paramCount}`;
            params.push(date_from);
        }

        if (date_to) {
            paramCount++;
            whereClause += ` AND b.start_date <= $${paramCount}`;
            params.push(date_to);
        }

        paramCount++;
        const limitClause = ` LIMIT $${paramCount}`;
        params.push(parseInt(limit));

        paramCount++;
        const offsetClause = ` OFFSET $${paramCount}`;
        params.push(parseInt(offset));

        const result = await db.query(`
            SELECT b.*, tp.name as package_name,
                   gu.email as guide_full_name, gu.phone as guide_phone, gu.email as guide_email,
                   du.email as driver_full_name, du.phone as driver_phone, du.email as driver_email,
                   v.make as vehicle_make, v.model as vehicle_model, v.plate_number as license_plate,
                   t.name as tourist_name, t.email as tourist_email, t.phone as tourist_phone
            FROM bookings b
            LEFT JOIN tour_packages tp ON b.package_id = tp.id
            LEFT JOIN guides g ON b.assigned_guide_id = g.id
            LEFT JOIN users gu ON g.user_id = gu.id
            LEFT JOIN drivers d ON b.assigned_driver_id = d.id
            LEFT JOIN users du ON d.user_id = du.id
            LEFT JOIN vehicles v ON b.assigned_vehicle_id = v.id
            LEFT JOIN tourists t ON b.tourist_id = t.id
            ${whereClause}
            ORDER BY b.start_date ASC, b.created_at DESC
            ${limitClause}
            ${offsetClause}
        `, params);

        // Get total count for pagination
        const countResult = await db.query(`
            SELECT COUNT(*) as total
            FROM bookings b
            ${whereClause}
        `, params.slice(0, -2)); // Remove limit and offset params

        res.status(200).json({ 
            success: true, 
            bookings: result.rows,
            pagination: {
                total: parseInt(countResult.rows[0].total),
                limit: parseInt(limit),
                offset: parseInt(offset),
                hasMore: (parseInt(offset) + parseInt(limit)) < parseInt(countResult.rows[0].total)
            }
        });
    } catch (err) {
        console.error("Error fetching all bookings:", err);
        res.status(500).json({ error: "Failed to fetch bookings", details: err.message });
    }
};

exports.triggerEmergency = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { booking_id, latitude, longitude } = req.body;
        
        let pointQuery = 'NULL';
        if (latitude && longitude) {
            pointQuery = `ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)`;
        }

        const result = await db.query(
            `INSERT INTO emergency_alerts (booking_id, triggered_by, location, status) 
             VALUES ($1, $2, ${pointQuery}, 'active') RETURNING id`,
            [booking_id || null, userId]
        );
        
        res.status(201).json({ success: true, message: "Emergency SOS triggered! Admin notified.", alert_id: result.rows[0].id });
    } catch (err) {
        console.error("SOS Error:", err);
        res.status(500).json({ error: "Failed to trigger SOS", details: err.message });
    }
};

exports.getBookingById = async (req, res) => {
    try {
        const { id } = req.params;
        
        // Use DataSyncService for properly formatted data
        const booking = await DataSyncService.getBookingWithAssignments(id);

        if (!booking) {
            return res.status(404).json({ error: "Booking not found" });
        }

        res.status(200).json({ success: true, booking });
    } catch (err) {
        console.error("Error fetching booking:", err);
        res.status(500).json({ error: "Failed to fetch booking", details: err.message });
    }
};

exports.updateBooking = async (req, res) => {
    try {
        const { id } = req.params;
        const { 
            assigned_guide_id, 
            assigned_driver_id, 
            guide_name, 
            driver_name, 
            status 
        } = req.body;

        console.log(`🔄 Updating booking ${id} with assignments:`, {
            assigned_guide_id,
            assigned_driver_id,
            guide_name,
            driver_name,
            status
        });

        // Start a transaction to ensure data consistency
        await db.query('BEGIN');

        try {
            // First, get the current booking to check if it exists
            const currentBooking = await db.query(
                `SELECT b.*, tp.name as tour_name, tu.email as tourist_name
                 FROM bookings b
                 LEFT JOIN tour_packages tp ON b.package_id = tp.id
                 LEFT JOIN tourists t ON b.tourist_id = t.id
                 LEFT JOIN users tu ON t.user_id = tu.id
                 WHERE b.id::text = $1 OR b.booking_code = $1`,
                [id]
            );

            if (currentBooking.rows.length === 0) {
                await db.query('ROLLBACK');
                return res.status(404).json({ error: "Booking not found" });
            }

            const booking = currentBooking.rows[0];
            let finalGuideId = assigned_guide_id || booking.assigned_guide_id;
            let finalDriverId = assigned_driver_id || booking.assigned_driver_id;
            let finalGuideName = guide_name || booking.guide_name;
            let finalDriverName = driver_name || booking.driver_name;

            // Track if this is a new assignment (for notifications)
            const isNewGuideAssignment = assigned_guide_id && assigned_guide_id !== booking.assigned_guide_id;
            const isNewDriverAssignment = assigned_driver_id && assigned_driver_id !== booking.assigned_driver_id;

            // IMPORTANT: Frontend might send user_id instead of staff_id
            // Check if the provided IDs are user_ids and convert them to staff_ids
            if (assigned_guide_id) {
                // First check if it's already a guide_id
                const guideIdCheck = await db.query('SELECT id FROM guides WHERE id = $1', [assigned_guide_id]);
                
                if (guideIdCheck.rows.length === 0) {
                    // Not a guide_id, try as user_id
                    const guideUserCheck = await db.query('SELECT id FROM guides WHERE user_id = $1', [assigned_guide_id]);
                    
                    if (guideUserCheck.rows.length > 0) {
                        console.log(`🔄 Converted user_id to guide_id: ${assigned_guide_id} → ${guideUserCheck.rows[0].id}`);
                        finalGuideId = guideUserCheck.rows[0].id;
                    } else {
                        await db.query('ROLLBACK');
                        return res.status(400).json({ 
                            error: "Invalid guide ID - guide not found",
                            details: `ID ${assigned_guide_id} is neither a valid guide_id nor user_id`
                        });
                    }
                }
            }

            if (assigned_driver_id) {
                // First check if it's already a driver_id
                const driverIdCheck = await db.query('SELECT id FROM drivers WHERE id = $1', [assigned_driver_id]);
                
                if (driverIdCheck.rows.length === 0) {
                    // Not a driver_id, try as user_id
                    const driverUserCheck = await db.query('SELECT id FROM drivers WHERE user_id = $1', [assigned_driver_id]);
                    
                    if (driverUserCheck.rows.length > 0) {
                        console.log(`🔄 Converted user_id to driver_id: ${assigned_driver_id} → ${driverUserCheck.rows[0].id}`);
                        finalDriverId = driverUserCheck.rows[0].id;
                    } else {
                        await db.query('ROLLBACK');
                        return res.status(400).json({ 
                            error: "Invalid driver ID - driver not found",
                            details: `ID ${assigned_driver_id} is neither a valid driver_id nor user_id`
                        });
                    }
                }
            }

            // Check for conflicts before assignment
            const conflictChecks = [];
            
            if (finalGuideId && isNewGuideAssignment) {
                const guideConflictCheck = await ConflictDetectionService.validateAssignment(
                    finalGuideId, 
                    'guide', 
                    booking.start_date, 
                    booking.end_date, 
                    booking.id
                );
                
                if (!guideConflictCheck.valid) {
                    await db.query('ROLLBACK');
                    return res.status(409).json({ 
                        error: "Guide assignment conflict",
                        details: guideConflictCheck.message,
                        conflicts: guideConflictCheck.conflicts,
                        staff_type: 'guide'
                    });
                }
                conflictChecks.push({ type: 'guide', status: 'available' });
            }
            
            if (finalDriverId && isNewDriverAssignment) {
                const driverConflictCheck = await ConflictDetectionService.validateAssignment(
                    finalDriverId, 
                    'driver', 
                    booking.start_date, 
                    booking.end_date, 
                    booking.id
                );
                
                if (!driverConflictCheck.valid) {
                    await db.query('ROLLBACK');
                    return res.status(409).json({ 
                        error: "Driver assignment conflict",
                        details: driverConflictCheck.message,
                        conflicts: driverConflictCheck.conflicts,
                        staff_type: 'driver'
                    });
                }
                conflictChecks.push({ type: 'driver', status: 'available' });
            }

            // If guide_id is provided but no guide_name, fetch the name from users table via guides
            if (assigned_guide_id && !guide_name) {
                const guideResult = await db.query(`
                    SELECT u.email as name 
                    FROM guides g 
                    JOIN users u ON g.user_id = u.id 
                    WHERE g.id = $1
                `, [assigned_guide_id]);
                if (guideResult.rows.length > 0) {
                    finalGuideName = guideResult.rows[0].name;
                }
            }

            // If driver_id is provided but no driver_name, fetch the name from users table via drivers
            if (assigned_driver_id && !driver_name) {
                const driverResult = await db.query(`
                    SELECT u.email as name 
                    FROM drivers d 
                    JOIN users u ON d.user_id = u.id 
                    WHERE d.id = $1
                `, [assigned_driver_id]);
                if (driverResult.rows.length > 0) {
                    finalDriverName = driverResult.rows[0].name;
                }
            }

            // Update the booking with all fields
            const result = await db.query(
                `UPDATE bookings 
                 SET 
                    assigned_guide_id = $1,
                    assigned_driver_id = $2,
                    guide_name = $3,
                    driver_name = $4,
                    status = COALESCE($5, status),
                    updated_at = CURRENT_TIMESTAMP
                 WHERE id::text = $6 OR booking_code = $6
                 RETURNING *`,
                [finalGuideId, finalDriverId, finalGuideName, finalDriverName, status, id]
            );

            await db.query('COMMIT');

            console.log(`✅ Successfully updated booking ${id}:`, {
                guide: `${finalGuideName} (${finalGuideId})`,
                driver: `${finalDriverName} (${finalDriverId})`,
                status: result.rows[0].status
            });

            // Send notifications for new assignments
            const bookingDetails = {
                booking_code: result.rows[0].booking_code,
                tour_name: booking.tour_name || booking.custom_tour_name,
                start_date: result.rows[0].start_date,
                tourist_name: booking.tourist_name,
                tourist_user_id: booking.tourist_user_id || null
            };

            if (isNewGuideAssignment) {
                try {
                    await assignmentNotificationService.notifyStaffAssignment(
                        result.rows[0].id,
                        'guide',
                        finalGuideId,
                        finalGuideName,
                        bookingDetails
                    );
                } catch (notificationError) {
                    console.error('⚠️  Guide notification failed:', notificationError.message);
                }
            }

            if (isNewDriverAssignment) {
                try {
                    await assignmentNotificationService.notifyStaffAssignment(
                        result.rows[0].id,
                        'driver',
                        finalDriverId,
                        finalDriverName,
                        bookingDetails
                    );
                } catch (notificationError) {
                    console.error('⚠️  Driver notification failed:', notificationError.message);
                }
            }

            // Refresh and broadcast the updated booking data
            const refreshedBooking = await DataSyncService.refreshBookingAssignments(result.rows[0].id);

            // Trigger fund allocation just in case the booking is already paid and staff was just assigned
            require('./walletController').allocateBookingFunds(result.rows[0].id).catch(console.error);

            res.status(200).json({ 
                success: true, 
                booking: refreshedBooking,
                message: "Assignment updated successfully",
                notifications_sent: {
                    guide: isNewGuideAssignment,
                    driver: isNewDriverAssignment
                }
            });

        } catch (updateError) {
            await db.query('ROLLBACK');
            throw updateError;
        }

    } catch (err) {
        console.error("❌ Error updating booking:", err);
        res.status(500).json({ 
            error: "Failed to update booking", 
            details: err.message,
            code: err.code 
        });
    }
};

// Staff assignment confirmation endpoint
exports.confirmAssignment = async (req, res) => {
    try {
        const { bookingId, staffType, confirmed } = req.body;
        const userId = req.user.userId;

        console.log(`📋 Assignment confirmation: ${staffType} ${confirmed ? 'accepted' : 'declined'} for booking ${bookingId}`);

        // Verify the staff member is the one assigned to this booking
        const staffTable = staffType === 'guide' ? 'guides' : 'drivers';
        const assignedField = staffType === 'guide' ? 'assigned_guide_id' : 'assigned_driver_id';

        const verifyResult = await db.query(`
            SELECT b.id, b.booking_code, s.id as staff_id
            FROM bookings b
            JOIN ${staffTable} s ON b.${assignedField} = s.id
            WHERE (b.id::text = $1 OR b.booking_code = $1) AND s.user_id = $2
        `, [bookingId, userId]);

        if (verifyResult.rows.length === 0) {
            return res.status(403).json({ 
                error: "You are not assigned to this booking or booking not found" 
            });
        }

        const booking = verifyResult.rows[0];
        const staffId = booking.staff_id;

        // Process the confirmation
        const result = await assignmentNotificationService.confirmAssignment(
            bookingId, 
            staffType, 
            staffId, 
            confirmed
        );

        res.status(200).json({
            success: true,
            message: confirmed ? 'Assignment confirmed successfully' : 'Assignment declined',
            booking_id: bookingId,
            staff_type: staffType,
            confirmed: confirmed,
            processed: result
        });

    } catch (err) {
        console.error("❌ Error processing assignment confirmation:", err);
        res.status(500).json({ 
            error: "Failed to process assignment confirmation", 
            details: err.message 
        });
    }
};
// Auto-assign available staff to booking
exports.autoAssignStaff = async (req, res) => {
    try {
        const { id } = req.params;
        const { excludeStaffIds } = req.body;

        console.log(`🤖 Auto-assigning staff for booking ${id}`);

        // Get booking details
        const bookingResult = await db.query(`
            SELECT id, booking_code, start_date, end_date, assigned_guide_id, assigned_driver_id
            FROM bookings 
            WHERE id::text = $1 OR booking_code = $1
        `, [id]);

        if (bookingResult.rows.length === 0) {
            return res.status(404).json({ error: "Booking not found" });
        }

        const booking = bookingResult.rows[0];

        // Use conflict detection service for auto-assignment
        const result = await ConflictDetectionService.autoAssignStaff(
            booking.id,
            booking.start_date,
            booking.end_date,
            excludeStaffIds || {}
        );

        if (!result.success) {
            return res.status(409).json({
                error: "Auto-assignment failed",
                details: result.error,
                available_staff: {
                    guides: 0,
                    drivers: 0
                }
            });
        }

        // Get tourist user_id for notifications
        const touristResult = await db.query(`
            SELECT t.user_id as tourist_user_id
            FROM bookings b
            JOIN tourists t ON b.tourist_id = t.id
            WHERE b.id = $1
        `, [result.booking.id]);

        // Send notifications to newly assigned staff
        const bookingDetails = {
            booking_code: result.booking.booking_code,
            tour_name: result.booking.custom_tour_name || 'Tour',
            start_date: result.booking.start_date,
            tourist_name: 'Tourist',
            tourist_user_id: touristResult.rows[0]?.tourist_user_id || null
        };

        if (result.guide) {
            try {
                await assignmentNotificationService.notifyStaffAssignment(
                    result.booking.id,
                    'guide',
                    result.guide.id,
                    result.guide.name,
                    bookingDetails
                );
            } catch (notificationError) {
                console.error('⚠️  Guide notification failed:', notificationError.message);
            }
        }

        if (result.driver) {
            try {
                await assignmentNotificationService.notifyStaffAssignment(
                    result.booking.id,
                    'driver',
                    result.driver.id,
                    result.driver.name,
                    bookingDetails
                );
            } catch (notificationError) {
                console.error('⚠️  Driver notification failed:', notificationError.message);
            }
        }

        // Refresh and broadcast the updated booking data
        const refreshedBooking = await DataSyncService.refreshBookingAssignments(result.booking.id);

        res.status(200).json({
            success: true,
            message: "Auto-assignment completed",
            booking: refreshedBooking,
            assigned_staff: {
                guide: result.guide ? {
                    id: result.guide.id,
                    name: result.guide.name,
                    score: result.guide.score,
                    rating: result.guide.rating,
                    experience: result.guide.years_experience
                } : null,
                driver: result.driver ? {
                    id: result.driver.id,
                    name: result.driver.name,
                    score: result.driver.score,
                    rating: result.driver.rating,
                    experience: result.driver.years_experience
                } : null
            },
            conflicts_avoided: result.conflicts_avoided
        });

    } catch (err) {
        console.error("❌ Error in auto-assignment:", err);
        res.status(500).json({ 
            error: "Auto-assignment failed", 
            details: err.message 
        });
    }
};

// Check staff availability and conflicts
exports.checkStaffAvailability = async (req, res) => {
    try {
        const { staffId, staffType, startDate, endDate, bookingId } = req.query;

        if (!staffId || !staffType || !startDate || !endDate) {
            return res.status(400).json({
                error: "Missing required parameters",
                required: ["staffId", "staffType", "startDate", "endDate"]
            });
        }

        const validation = await ConflictDetectionService.validateAssignment(
            staffId,
            staffType,
            startDate,
            endDate,
            bookingId
        );

        const workload = await ConflictDetectionService.getStaffWorkload(staffId, staffType);

        res.status(200).json({
            success: true,
            available: validation.valid,
            conflicts: validation.conflicts,
            message: validation.message,
            workload: workload.workload,
            staff_id: staffId,
            staff_type: staffType
        });

    } catch (err) {
        console.error("❌ Error checking staff availability:", err);
        res.status(500).json({ 
            error: "Failed to check availability", 
            details: err.message 
        });
    }
};

// Get available staff for a date range
exports.getAvailableStaff = async (req, res) => {
    try {
        const { startDate, endDate, staffType, excludeIds } = req.query;

        if (!startDate || !endDate) {
            return res.status(400).json({
                error: "Missing required parameters",
                required: ["startDate", "endDate"]
            });
        }

        const excludeStaffIds = excludeIds ? excludeIds.split(',') : [];

        if (staffType && ['guide', 'driver'].includes(staffType)) {
            // Get specific staff type
            const availableStaff = await ConflictDetectionService.getAvailableStaff(
                staffType,
                startDate,
                endDate,
                excludeStaffIds
            );

            res.status(200).json({
                success: true,
                staff_type: staffType,
                available_count: availableStaff.length,
                staff: availableStaff,
                date_range: { startDate, endDate }
            });

        } else {
            // Get both guides and drivers
            const availableGuides = await ConflictDetectionService.getAvailableStaff(
                'guide',
                startDate,
                endDate,
                excludeStaffIds
            );

            const availableDrivers = await ConflictDetectionService.getAvailableStaff(
                'driver',
                startDate,
                endDate,
                excludeStaffIds
            );

            res.status(200).json({
                success: true,
                available_staff: {
                    guides: {
                        count: availableGuides.length,
                        staff: availableGuides
                    },
                    drivers: {
                        count: availableDrivers.length,
                        staff: availableDrivers
                    }
                },
                date_range: { startDate, endDate }
            });
        }

    } catch (err) {
        console.error("❌ Error getting available staff:", err);
        res.status(500).json({ 
            error: "Failed to get available staff", 
            details: err.message 
        });
    }
};