/**
 * Emergency Protocol Utility
 * Handles SOS signals, emergency responses, and safety compliance
 */

const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');

/**
 * Trigger SOS Emergency Protocol
 * Steps: 1) Notify local emergency contacts, 2) Alert nearest providers, 3) Notify platform safety team
 */
const triggerSOS = async (userId, bookingId, location, emergencyType, description) => {
  try {
    const sosCode = `SOS-${Date.now()}-${uuidv4().substring(0, 8)}`;

    // Create SOS log
    const sosResult = await db.query(
      `INSERT INTO emergency_sos_logs 
       (sos_code, booking_id, triggered_by, trigger_location, emergency_type, description, severity, status)
       VALUES ($1, $2, $3, ST_SetSRID(ST_MakePoint($4, $5), 4326), $6, $7, 'urgent', 'active')
       RETURNING id, sos_code`,
      [sosCode, bookingId, userId, location.longitude, location.latitude, emergencyType, description]
    );

    const sosId = sosResult.rows[0].id;
    const sosCodeGenerated = sosResult.rows[0].sos_code;

    // Step 1: Notify local emergency contacts
    const localEmergencyResult = await notifyLocalEmergency(location, sosCodeGenerated, emergencyType);

    if (localEmergencyResult.success) {
      await db.query(
        `UPDATE emergency_sos_logs 
         SET local_emergency_notified = TRUE, local_emergency_notified_at = CURRENT_TIMESTAMP
         WHERE id = $1`,
        [sosId]
      );
    }

    // Step 2: Alert nearest registered service providers
    const nearestProvidersResult = await alertNearestProviders(location, sosCodeGenerated, bookingId);

    if (nearestProvidersResult.success) {
      await db.query(
        `UPDATE emergency_sos_logs 
         SET nearest_providers_notified = TRUE, nearest_providers_notified_at = CURRENT_TIMESTAMP
         WHERE id = $1`,
        [sosId]
      );
    }

    // Step 3: Notify platform safety team
    const safetyTeamResult = await notifyPlatformSafetyTeam(sosCodeGenerated, userId, bookingId, emergencyType, description);

    if (safetyTeamResult.success) {
      await db.query(
        `UPDATE emergency_sos_logs 
         SET platform_safety_notified = TRUE, platform_safety_notified_at = CURRENT_TIMESTAMP
         WHERE id = $1`,
        [sosId]
      );
    }

    return {
      success: true,
      sosCode: sosCodeGenerated,
      sosId,
      notifications: {
        localEmergency: localEmergencyResult,
        nearestProviders: nearestProvidersResult,
        platformSafety: safetyTeamResult
      },
      message: 'Emergency protocol activated successfully'
    };
  } catch (error) {
    console.error('SOS trigger error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Notify Local Emergency Contacts
 */
const notifyLocalEmergency = async (location, sosCode, emergencyType) => {
  try {
    // Find nearest emergency contacts within 50km radius
    const emergencyContactsResult = await db.query(
      `SELECT 
         id, organization_name, phone_number, alternate_phone, email, contact_type,
         ST_Distance(location::geography, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography) / 1000 as distance_km
       FROM emergency_contacts
       WHERE is_active = TRUE
       AND ST_DWithin(
         location::geography,
         ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
         50000
       )
       ORDER BY distance_km
       LIMIT 5`,
      [location.longitude, location.latitude]
    );

    const contacts = emergencyContactsResult.rows;

    if (contacts.length === 0) {
      // Use national emergency numbers as fallback
      contacts.push({
        organization_name: 'Ethiopian Emergency Services',
        phone_number: '911',
        contact_type: 'national_emergency'
      });
    }

    // In production, integrate with SMS/Call API
    const notifications = [];
    for (const contact of contacts) {
      notifications.push({
        organization: contact.organization_name,
        phone: contact.phone_number,
        type: contact.contact_type,
        distance: contact.distance_km ? `${contact.distance_km.toFixed(2)} km` : 'N/A',
        message: `EMERGENCY SOS ${sosCode}: ${emergencyType} at coordinates ${location.latitude}, ${location.longitude}`
      });
    }

    // Log notification attempt
    await db.query(
      `INSERT INTO system_audit_logs (action_type, table_name, new_values)
       VALUES ('emergency_notification', 'emergency_contacts', $1)`,
      [JSON.stringify({ sosCode, contacts: notifications })]
    );

    return {
      success: true,
      contactsNotified: contacts.length,
      notifications
    };
  } catch (error) {
    console.error('Local emergency notification error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Alert Nearest Service Providers
 */
const alertNearestProviders = async (location, sosCode, bookingId) => {
  try {
    // Find nearest available drivers and guides within 30km
    const nearestDriversResult = await db.query(
      `SELECT 
         u.id, u.phone, up.first_name, up.last_name,
         ST_Distance(d.current_location::geography, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography) / 1000 as distance_km
       FROM drivers d
       INNER JOIN users u ON d.user_id = u.id
       INNER JOIN user_profiles up ON u.id = up.user_id
       WHERE d.is_available = TRUE
       AND u.status = 'active'
       AND d.current_location IS NOT NULL
       AND ST_DWithin(
         d.current_location::geography,
         ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
         30000
       )
       ORDER BY distance_km
       LIMIT 5`,
      [location.longitude, location.latitude]
    );

    const nearestGuidesResult = await db.query(
      `SELECT 
         u.id, u.phone, up.first_name, up.last_name
       FROM guides g
       INNER JOIN users u ON g.user_id = u.id
       INNER JOIN user_profiles up ON u.id = up.user_id
       WHERE g.is_available = TRUE
       AND u.status = 'active'
       LIMIT 5`
    );

    const providers = [
      ...nearestDriversResult.rows.map(p => ({ ...p, type: 'driver' })),
      ...nearestGuidesResult.rows.map(p => ({ ...p, type: 'guide' }))
    ];

    // In production, send push notifications and SMS
    const notifications = providers.map(provider => ({
      providerId: provider.id,
      providerName: `${provider.first_name} ${provider.last_name}`,
      providerType: provider.type,
      phone: provider.phone,
      distance: provider.distance_km ? `${provider.distance_km.toFixed(2)} km` : 'N/A',
      message: `EMERGENCY ALERT ${sosCode}: Assistance needed at ${location.latitude}, ${location.longitude}`
    }));

    return {
      success: true,
      providersNotified: providers.length,
      notifications
    };
  } catch (error) {
    console.error('Nearest providers alert error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Notify Platform Safety Team
 */
const notifyPlatformSafetyTeam = async (sosCode, userId, bookingId, emergencyType, description) => {
  try {
    // Get all admin users with safety team role
    const safetyTeamResult = await db.query(
      `SELECT u.id, u.email, u.phone, up.first_name, up.last_name
       FROM users u
       INNER JOIN user_profiles up ON u.id = up.user_id
       WHERE u.user_role = 'admin'
       AND u.status = 'active'`
    );

    const safetyTeam = safetyTeamResult.rows;

    // Get user and booking details
    const detailsResult = await db.query(
      `SELECT 
         u.phone as user_phone,
         up.first_name as user_first_name,
         up.last_name as user_last_name,
         b.booking_code,
         b.start_date,
         tp.name as package_name
       FROM users u
       INNER JOIN user_profiles up ON u.id = up.user_id
       LEFT JOIN tourists t ON u.id = t.user_id
       LEFT JOIN bookings b ON b.id = $2
       LEFT JOIN tour_packages tp ON b.package_id = tp.id
       WHERE u.id = $1`,
      [userId, bookingId]
    );

    const details = detailsResult.rows[0] || {};

    const alertMessage = {
      sosCode,
      emergencyType,
      description,
      user: {
        name: `${details.user_first_name} ${details.user_last_name}`,
        phone: details.user_phone
      },
      booking: {
        code: details.booking_code,
        package: details.package_name,
        startDate: details.start_date
      },
      timestamp: new Date()
    };

    // In production, send email and push notifications
    const notifications = safetyTeam.map(member => ({
      memberId: member.id,
      memberName: `${member.first_name} ${member.last_name}`,
      email: member.email,
      phone: member.phone,
      message: `URGENT: Emergency SOS ${sosCode} - ${emergencyType}`
    }));

    // Log to system
    await db.query(
      `INSERT INTO system_audit_logs (action_type, table_name, new_values)
       VALUES ('safety_team_alert', 'emergency_sos_logs', $1)`,
      [JSON.stringify(alertMessage)]
    );

    return {
      success: true,
      teamMembersNotified: safetyTeam.length,
      notifications
    };
  } catch (error) {
    console.error('Platform safety team notification error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Resolve SOS Emergency
 */
const resolveEmergency = async (sosId, resolutionNotes) => {
  try {
    const result = await db.query(
      `UPDATE emergency_sos_logs
       SET status = 'resolved',
           resolved_at = CURRENT_TIMESTAMP,
           resolution_notes = $2,
           response_time_minutes = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - trigger_time)) / 60
       WHERE id = $1
       RETURNING sos_code, response_time_minutes`,
      [sosId, resolutionNotes]
    );

    if (result.rows.length === 0) {
      return { success: false, error: 'SOS record not found' };
    }

    return {
      success: true,
      sosCode: result.rows[0].sos_code,
      responseTimeMinutes: result.rows[0].response_time_minutes,
      message: 'Emergency resolved successfully'
    };
  } catch (error) {
    console.error('Resolve emergency error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Check Guide-to-Tourist Ratio
 * Certified Guide (max 15), Senior Guide (max 25), Specialized Guide (varies)
 */
const checkGuideTouristRatio = async (guideId, numberOfTourists) => {
  try {
    const guideResult = await db.query(
      `SELECT max_group_size, guide_license_number
       FROM guides
       WHERE user_id = $1`,
      [guideId]
    );

    if (guideResult.rows.length === 0) {
      return { success: false, error: 'Guide not found' };
    }

    const guide = guideResult.rows[0];
    const maxGroupSize = guide.max_group_size || 15;

    if (numberOfTourists > maxGroupSize) {
      return {
        success: false,
        allowed: false,
        numberOfTourists,
        maxGroupSize,
        message: `Group size ${numberOfTourists} exceeds guide's maximum capacity of ${maxGroupSize}`
      };
    }

    return {
      success: true,
      allowed: true,
      numberOfTourists,
      maxGroupSize,
      message: 'Group size within acceptable limits'
    };
  } catch (error) {
    console.error('Guide-tourist ratio check error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Check Vehicle Compliance
 * Verify insurance, registration, and safety certification
 */
const checkVehicleCompliance = async (vehicleId) => {
  try {
    const vehicleResult = await db.query(
      `SELECT 
         v.plate_number,
         v.registration_expiry,
         v.insurance_expiry,
         v.year,
         v.last_service_date,
         v.is_active
       FROM vehicles v
       WHERE v.id = $1`,
      [vehicleId]
    );

    if (vehicleResult.rows.length === 0) {
      return { success: false, error: 'Vehicle not found' };
    }

    const vehicle = vehicleResult.rows[0];
    const today = new Date();
    const issues = [];

    // Check registration expiry
    if (new Date(vehicle.registration_expiry) < today) {
      issues.push({
        type: 'registration_expired',
        message: 'Vehicle registration has expired',
        expiryDate: vehicle.registration_expiry
      });
    }

    // Check insurance expiry
    if (new Date(vehicle.insurance_expiry) < today) {
      issues.push({
        type: 'insurance_expired',
        message: 'Vehicle insurance has expired',
        expiryDate: vehicle.insurance_expiry
      });
    }

    // Check vehicle age (>8 years requires additional inspection)
    const currentYear = today.getFullYear();
    const vehicleAge = currentYear - vehicle.year;
    
    if (vehicleAge > 8) {
      // Check if additional safety inspection is documented
      issues.push({
        type: 'age_inspection_required',
        message: `Vehicle is ${vehicleAge} years old and requires additional safety inspection`,
        vehicleAge
      });
    }

    // Check if vehicle is active
    if (!vehicle.is_active) {
      issues.push({
        type: 'vehicle_inactive',
        message: 'Vehicle is marked as inactive'
      });
    }

    const isCompliant = issues.length === 0;

    return {
      success: true,
      vehicleId,
      plateNumber: vehicle.plate_number,
      isCompliant,
      issues,
      message: isCompliant ? 'Vehicle is compliant' : 'Vehicle has compliance issues'
    };
  } catch (error) {
    console.error('Vehicle compliance check error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Get Active Emergencies
 */
const getActiveEmergencies = async () => {
  try {
    const result = await db.query(
      `SELECT 
         e.id,
         e.sos_code,
         e.emergency_type,
         e.description,
         e.trigger_time,
         e.severity,
         ST_X(e.trigger_location) as longitude,
         ST_Y(e.trigger_location) as latitude,
         u.phone as user_phone,
         up.first_name,
         up.last_name,
         b.booking_code
       FROM emergency_sos_logs e
       INNER JOIN users u ON e.triggered_by = u.id
       INNER JOIN user_profiles up ON u.id = up.user_id
       LEFT JOIN bookings b ON e.booking_id = b.id
       WHERE e.status = 'active'
       ORDER BY e.trigger_time DESC`,
      []
    );

    return {
      success: true,
      activeEmergencies: result.rows,
      count: result.rows.length
    };
  } catch (error) {
    console.error('Get active emergencies error:', error);
    return { success: false, error: error.message };
  }
};

module.exports = {
  triggerSOS,
  resolveEmergency,
  checkGuideTouristRatio,
  checkVehicleCompliance,
  getActiveEmergencies,
  notifyLocalEmergency,
  alertNearestProviders,
  notifyPlatformSafetyTeam
};
