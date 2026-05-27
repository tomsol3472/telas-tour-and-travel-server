/**
 * Emergency Protocol Service
 * Handles SOS triggers, emergency notifications, and safety compliance
 */

const db = require('../config/db');
const socketService = require('./socketService');

/**
 * Trigger SOS emergency alert
 */
exports.triggerSOS = async (bookingId, userId, location, emergencyType, description) => {
    try {
        console.log('🚨 SOS TRIGGERED:', { bookingId, userId, emergencyType });

        // 1. Create emergency record
        const emergencyResult = await db.query(`
            INSERT INTO emergency_incidents (
                booking_id,
                reported_by,
                incident_type,
                severity,
                location,
                description,
                status,
                created_at
            ) VALUES ($1, $2, $3, $4, ST_SetSRID(ST_MakePoint($5, $6), 4326), $7, 'active', NOW())
            RETURNING id
        `, [
            bookingId,
            userId,
            emergencyType,
            'critical',
            location.longitude,
            location.latitude,
            description
        ]);

        const emergencyId = emergencyResult.rows[0].id;

        // 2. Get booking details
        const bookingResult = await db.query(`
            SELECT 
                b.*,
                t.user_id as tourist_user_id,
                up_tourist.first_name as tourist_first_name,
                up_tourist.last_name as tourist_last_name,
                u_tourist.phone as tourist_phone,
                u_tourist.email as tourist_email,
                d.user_id as driver_user_id,
                up_driver.first_name as driver_first_name,
                up_driver.last_name as driver_last_name,
                u_driver.phone as driver_phone,
                g.user_id as guide_user_id,
                up_guide.first_name as guide_first_name,
                up_guide.last_name as guide_last_name,
                u_guide.phone as guide_phone
            FROM bookings b
            LEFT JOIN tourists t ON b.tourist_id = t.id
            LEFT JOIN users u_tourist ON t.user_id = u_tourist.id
            LEFT JOIN user_profiles up_tourist ON u_tourist.id = up_tourist.user_id
            LEFT JOIN drivers d ON b.assigned_driver_id = d.id
            LEFT JOIN users u_driver ON d.user_id = u_driver.id
            LEFT JOIN user_profiles up_driver ON u_driver.id = up_driver.user_id
            LEFT JOIN guides g ON b.assigned_guide_id = g.id
            LEFT JOIN users u_guide ON g.user_id = u_guide.id
            LEFT JOIN user_profiles up_guide ON u_guide.id = up_guide.user_id
            WHERE b.id = $1
        `, [bookingId]);

        if (bookingResult.rows.length === 0) {
            throw new Error('Booking not found');
        }

        const booking = bookingResult.rows[0];

        // 3. Notify all parties via Socket.IO
        const notification = {
            type: 'SOS_ALERT',
            emergencyId: emergencyId,
            bookingId: bookingId,
            emergencyType: emergencyType,
            location: location,
            description: description,
            timestamp: new Date().toISOString()
        };

        // Notify tourist
        if (booking.tourist_user_id) {
            socketService.sendToUser(booking.tourist_user_id, 'emergency_alert', notification);
        }

        // Notify driver
        if (booking.driver_user_id) {
            socketService.sendToUser(booking.driver_user_id, 'emergency_alert', notification);
        }

        // Notify guide
        if (booking.guide_user_id) {
            socketService.sendToUser(booking.guide_user_id, 'emergency_alert', notification);
        }

        // 4. Send SMS/Email notifications (in production, integrate with Twilio/SendGrid)
        const notifications = [];

        if (booking.tourist_phone) {
            notifications.push({
                type: 'SMS',
                to: booking.tourist_phone,
                message: `🚨 EMERGENCY ALERT: ${emergencyType} reported for booking ${booking.booking_code}. Location: ${location.latitude}, ${location.longitude}. Emergency services have been notified.`
            });
        }

        if (booking.driver_phone) {
            notifications.push({
                type: 'SMS',
                to: booking.driver_phone,
                message: `🚨 EMERGENCY: ${emergencyType} for booking ${booking.booking_code}. Immediate assistance required at ${location.latitude}, ${location.longitude}.`
            });
        }

        if (booking.guide_phone) {
            notifications.push({
                type: 'SMS',
                to: booking.guide_phone,
                message: `🚨 EMERGENCY: ${emergencyType} for booking ${booking.booking_code}. Immediate assistance required at ${location.latitude}, ${location.longitude}.`
            });
        }

        // 5. Find nearest available providers
        const nearbyProviders = await this.findNearestProviders(location, 50); // 50km radius

        // 6. Log emergency response
        await db.query(`
            INSERT INTO emergency_responses (
                incident_id,
                response_type,
                responder_type,
                response_data,
                created_at
            ) VALUES ($1, 'NOTIFICATION_SENT', 'SYSTEM', $2, NOW())
        `, [emergencyId, JSON.stringify({ notifications, nearbyProviders })]);

        console.log('✓ SOS notifications sent:', notifications.length);

        return {
            success: true,
            emergencyId: emergencyId,
            notificationsSent: notifications.length,
            nearbyProviders: nearbyProviders.length,
            message: 'Emergency alert triggered successfully'
        };
    } catch (error) {
        console.error('❌ Trigger SOS Error:', error);
        throw error;
    }
};

/**
 * Find nearest available providers
 */
exports.findNearestProviders = async (location, radiusKm = 50) => {
    try {
        const result = await db.query(`
            SELECT 
                u.id,
                u.user_role,
                up.first_name,
                up.last_name,
                u.phone,
                CASE 
                    WHEN u.user_role = 'driver' THEN d.current_location
                    WHEN u.user_role = 'guide' THEN NULL
                    ELSE NULL
                END as location,
                ST_Distance(
                    ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
                    CASE 
                        WHEN u.user_role = 'driver' THEN d.current_location::geography
                        ELSE NULL
                    END
                ) / 1000 as distance_km
            FROM users u
            LEFT JOIN user_profiles up ON u.id = up.user_id
            LEFT JOIN drivers d ON u.id = d.user_id AND u.user_role = 'driver'
            WHERE u.user_role IN ('driver', 'guide', 'admin')
            AND u.status = 'active'
            AND (
                (u.user_role = 'driver' AND d.is_available = true AND d.current_location IS NOT NULL)
                OR u.user_role IN ('guide', 'admin')
            )
            AND ST_DWithin(
                ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
                CASE 
                    WHEN u.user_role = 'driver' THEN d.current_location::geography
                    ELSE ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
                END,
                $3 * 1000
            )
            ORDER BY distance_km ASC
            LIMIT 10
        `, [location.longitude, location.latitude, radiusKm]);

        return result.rows;
    } catch (error) {
        console.error('Find Nearest Providers Error:', error);
        return [];
    }
};

/**
 * Check guide-to-tourist ratio compliance
 */
exports.checkGuideRatioCompliance = async (bookingId) => {
    try {
        const result = await db.query(`
            SELECT 
                b.id,
                b.total_persons,
                b.assigned_guide_id,
                g.max_group_size,
                CASE 
                    WHEN b.total_persons <= 15 THEN 'COMPLIANT'
                    WHEN b.total_persons <= 25 AND b.assigned_guide_id IS NOT NULL THEN 'COMPLIANT'
                    WHEN b.total_persons > 25 THEN 'REQUIRES_ADDITIONAL_GUIDE'
                    ELSE 'NON_COMPLIANT'
                END as compliance_status
            FROM bookings b
            LEFT JOIN guides g ON b.assigned_guide_id = g.id
            WHERE b.id = $1
        `, [bookingId]);

        if (result.rows.length === 0) {
            throw new Error('Booking not found');
        }

        const booking = result.rows[0];

        return {
            bookingId: booking.id,
            totalPersons: booking.total_persons,
            hasGuide: booking.assigned_guide_id !== null,
            maxGroupSize: booking.max_group_size,
            complianceStatus: booking.compliance_status,
            compliant: booking.compliance_status === 'COMPLIANT',
            recommendation: booking.compliance_status === 'REQUIRES_ADDITIONAL_GUIDE' 
                ? 'Assign additional guide for groups over 25'
                : booking.compliance_status === 'NON_COMPLIANT'
                ? 'Assign a guide for groups over 15'
                : 'Group size is compliant'
        };
    } catch (error) {
        console.error('Check Guide Ratio Compliance Error:', error);
        throw error;
    }
};

/**
 * Verify vehicle compliance
 */
exports.verifyVehicleCompliance = async (vehicleId) => {
    try {
        const result = await db.query(`
            SELECT 
                v.id,
                v.plate_number,
                v.registration_expiry,
                v.insurance_expiry,
                v.last_service_date,
                v.next_service_date,
                v.is_active,
                CASE 
                    WHEN v.registration_expiry < CURRENT_DATE THEN 'EXPIRED_REGISTRATION'
                    WHEN v.insurance_expiry < CURRENT_DATE THEN 'EXPIRED_INSURANCE'
                    WHEN v.next_service_date < CURRENT_DATE THEN 'SERVICE_OVERDUE'
                    WHEN v.registration_expiry < CURRENT_DATE + INTERVAL '30 days' THEN 'REGISTRATION_EXPIRING_SOON'
                    WHEN v.insurance_expiry < CURRENT_DATE + INTERVAL '30 days' THEN 'INSURANCE_EXPIRING_SOON'
                    WHEN v.next_service_date < CURRENT_DATE + INTERVAL '7 days' THEN 'SERVICE_DUE_SOON'
                    ELSE 'COMPLIANT'
                END as compliance_status
            FROM vehicles v
            WHERE v.id = $1
        `, [vehicleId]);

        if (result.rows.length === 0) {
            throw new Error('Vehicle not found');
        }

        const vehicle = result.rows[0];

        return {
            vehicleId: vehicle.id,
            plateNumber: vehicle.plate_number,
            registrationExpiry: vehicle.registration_expiry,
            insuranceExpiry: vehicle.insurance_expiry,
            lastServiceDate: vehicle.last_service_date,
            nextServiceDate: vehicle.next_service_date,
            isActive: vehicle.is_active,
            complianceStatus: vehicle.compliance_status,
            compliant: vehicle.compliance_status === 'COMPLIANT',
            alerts: vehicle.compliance_status !== 'COMPLIANT' ? [vehicle.compliance_status] : []
        };
    } catch (error) {
        console.error('Verify Vehicle Compliance Error:', error);
        throw error;
    }
};

/**
 * Get active emergencies
 */
exports.getActiveEmergencies = async () => {
    try {
        const result = await db.query(`
            SELECT 
                e.id,
                e.booking_id,
                b.booking_code,
                e.incident_type,
                e.severity,
                ST_X(e.location::geometry) as longitude,
                ST_Y(e.location::geometry) as latitude,
                e.description,
                e.status,
                e.created_at,
                up.first_name || ' ' || up.last_name as reported_by_name,
                u.phone as reported_by_phone
            FROM emergency_incidents e
            JOIN bookings b ON e.booking_id = b.id
            JOIN users u ON e.reported_by = u.id
            JOIN user_profiles up ON u.id = up.user_id
            WHERE e.status = 'active'
            ORDER BY e.created_at DESC
        `);

        return result.rows;
    } catch (error) {
        console.error('Get Active Emergencies Error:', error);
        throw error;
    }
};

/**
 * Resolve emergency
 */
exports.resolveEmergency = async (emergencyId, resolvedBy, resolution) => {
    try {
        await db.query(`
            UPDATE emergency_incidents
            SET status = 'resolved',
                resolved_by = $2,
                resolved_at = NOW(),
                resolution_notes = $3
            WHERE id = $1
        `, [emergencyId, resolvedBy, resolution]);

        // Log resolution
        await db.query(`
            INSERT INTO emergency_responses (
                incident_id,
                response_type,
                responder_type,
                responder_id,
                response_data,
                created_at
            ) VALUES ($1, 'RESOLVED', 'ADMIN', $2, $3, NOW())
        `, [emergencyId, resolvedBy, JSON.stringify({ resolution })]);

        return {
            success: true,
            message: 'Emergency resolved successfully'
        };
    } catch (error) {
        console.error('Resolve Emergency Error:', error);
        throw error;
    }
};

module.exports = exports;
