const db = require('../config/db');

// @desc    Get current user profile
// @route   GET /api/users/profile
// @access  Private
exports.getProfile = async (req, res) => {
    try {
        const userId = req.user.userId;
        const role = req.user.role;

        // Base user info
        let query = `SELECT u.id, u.email, u.phone, u.user_role, u.status, 
                            u.profile_picture_url, u.preferred_language,
                            p.first_name, p.last_name, p.middle_name, p.date_of_birth,
                            p.gender, p.nationality, p.address, p.city, p.country
                     FROM users u
                     LEFT JOIN user_profiles p ON u.id = p.user_id
                     WHERE u.id = $1`;
        
        const userRes = await db.query(query, [userId]);
        let userData = userRes.rows[0];

        // Fetch role specific data
        if (role === 'tourist') {
            const touristRes = await db.query("SELECT * FROM tourists WHERE user_id = $1", [userId]);
            userData.roleData = touristRes.rows[0];
        } else if (role === 'driver') {
            const driverRes = await db.query("SELECT * FROM drivers WHERE user_id = $1", [userId]);
            userData.roleData = driverRes.rows[0];
        } else if (role === 'guide') {
            const guideRes = await db.query("SELECT * FROM guides WHERE user_id = $1", [userId]);
            userData.roleData = guideRes.rows[0];
        }

        res.json({ success: true, data: userData });

    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Server Error" });
    }
};

// @desc    Update user profile
// @route   PUT /api/users/profile
// @access  Private
exports.updateProfile = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { first_name, last_name, middle_name, date_of_birth, gender, nationality, address, city, country, role_data } = req.body;

        // Update generic profile
        await db.query(`
            INSERT INTO user_profiles (user_id, first_name, last_name, middle_name, date_of_birth, gender, nationality, address, city, country)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            ON CONFLICT (user_id) 
            DO UPDATE SET 
                first_name = COALESCE($2, user_profiles.first_name),
                last_name = COALESCE($3, user_profiles.last_name),
                middle_name = COALESCE($4, user_profiles.middle_name),
                date_of_birth = COALESCE($5, user_profiles.date_of_birth),
                gender = COALESCE($6, user_profiles.gender),
                nationality = COALESCE($7, user_profiles.nationality),
                address = COALESCE($8, user_profiles.address),
                city = COALESCE($9, user_profiles.city),
                country = COALESCE($10, user_profiles.country),
                updated_at = CURRENT_TIMESTAMP`,
            [userId, first_name, last_name, middle_name, date_of_birth, gender, nationality, address, city, country]
        );

        // Update Role Specifics (Simplified for demo)
        if (req.user.role === 'driver' && role_data) {
             const { license_number, vehicle_info } = role_data; 
             await db.query(
                 `UPDATE drivers SET license_number = $1, vehicle_info = $2 WHERE user_id = $3`,
                 [license_number, vehicle_info, userId]
             );
        }

        res.json({ success: true, message: "Profile updated" });

    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Server Error" });
    }
};

// @desc    Admin: Approve Driver/Guide
// @route   PUT /api/users/approve/:id
// @access  Admin
exports.approveUser = async (req, res) => {
    try {
        const { id } = req.params; 
        
        // 1. Check user role
        const userRes = await db.query("SELECT user_role FROM users WHERE id = $1", [id]);
        if (userRes.rows.length === 0) return res.status(404).json({error: "User not found"});
        
        const role = userRes.rows[0].user_role;

        if (role === 'driver') {
            await db.query("UPDATE drivers SET is_available = true WHERE user_id = $1", [id]);
            await db.query("UPDATE users SET status = 'active' WHERE id = $1", [id]);
        } else if (role === 'guide') {
            await db.query("UPDATE guides SET is_available = true WHERE user_id = $1", [id]);
            await db.query("UPDATE users SET status = 'active' WHERE id = $1", [id]);
        } else {
            return res.status(400).json({ error: "User is not a driver or guide" });
        }

        res.json({ success: true, message: `User ${id} approved/verified` });

    } catch (error) {
         console.error(error);
        res.status(500).json({ error: "Server Error" });
    }
};

// @desc    Admin: Update Any User (Status, Details)
// @route   PUT /api/users/:id
// @access  Admin
exports.updateUser = async (req, res) => {
    const client = await db.pool.connect();
    try {
        const { id } = req.params;
        const { first_name, last_name, phone, role, status } = req.body;

        await client.query('BEGIN');

        // Update core user data (status, role, phone)
        await client.query(
            `UPDATE users 
             SET status = COALESCE($1, status),
                 user_role = COALESCE($2, user_role),
                 phone = COALESCE($3, phone),
                 updated_at = CURRENT_TIMESTAMP
             WHERE id = $4`,
            [status, role, phone, id]
        );

        // Update profile data (first name, last name)
        await client.query(
            `UPDATE user_profiles 
             SET first_name = COALESCE($1, first_name),
                 last_name = COALESCE($2, last_name),
                 updated_at = CURRENT_TIMESTAMP
             WHERE user_id = $3`,
            [first_name, last_name, id]
        );

        await client.query('COMMIT');
        res.status(200).json({ success: true, message: 'User updated successfully' });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error updating user:', error);
        res.status(500).json({ success: false, error: 'Server error updating user' });
    } finally {
        client.release();
    }
};

// @desc    Admin: Delete User Completely
// @route   DELETE /api/users/:id
// @access  Admin
exports.deleteUser = async (req, res) => {
    const client = await db.pool.connect();
    try {
        const { id } = req.params;
        
        console.log('Attempting to delete user:', id);
        
        await client.query('BEGIN');
        
        // 1. Delete wallet-related data
        await client.query('DELETE FROM staff_withdrawals WHERE user_id = $1', [id]);
        await client.query('DELETE FROM staff_wallets WHERE user_id = $1', [id]);
        
        // 2. Delete notification and communication data
        await client.query('DELETE FROM notifications WHERE user_id = $1', [id]);
        await client.query('DELETE FROM chat_messages WHERE sender_id = $1', [id]);
        await client.query('DELETE FROM chat_participants WHERE user_id = $1', [id]);
        await client.query('DELETE FROM chat_conversations WHERE created_by = $1', [id]);
        
        // 3. Delete support and verification data
        await client.query('DELETE FROM ticket_messages WHERE sender_id = $1', [id]);
        await client.query('UPDATE support_tickets SET assigned_to = NULL WHERE assigned_to = $1', [id]);
        await client.query('UPDATE support_tickets SET resolved_by = NULL WHERE resolved_by = $1', [id]);
        await client.query('DELETE FROM support_tickets WHERE user_id = $1', [id]);
        await client.query('DELETE FROM verification_documents WHERE user_id = $1', [id]);
        
        // 3.5 Delete reviews
        await client.query('DELETE FROM reviews WHERE reviewee_id = $1', [id]);
        await client.query('UPDATE reviews SET responded_by = NULL WHERE responded_by = $1', [id]);
        
        // 4. Unassign from bookings to prevent foreign key constraint errors
        await client.query(`UPDATE bookings SET assigned_driver_id = NULL WHERE assigned_driver_id IN (SELECT id FROM drivers WHERE user_id = $1)`, [id]);
        await client.query(`UPDATE bookings SET assigned_guide_id = NULL WHERE assigned_guide_id IN (SELECT id FROM guides WHERE user_id = $1)`, [id]);
        
        // Attempt to remove from booking_staff_assignments if it exists
        await client.query(`DELETE FROM booking_staff_assignments WHERE staff_id = $1`, [id]).catch(() => {});

        // 5. Delete role-specific data
        await client.query('DELETE FROM user_profiles WHERE user_id = $1', [id]);
        await client.query('DELETE FROM tourists WHERE user_id = $1', [id]);
        await client.query('DELETE FROM guides WHERE user_id = $1', [id]);
        await client.query('DELETE FROM drivers WHERE user_id = $1', [id]);
        
        // 6. Finally, delete the actual user
        const result = await client.query('DELETE FROM users WHERE id = $1 RETURNING id, email', [id]);
        
        await client.query('COMMIT');

        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, error: 'User not found' });
        }

        console.log('User deleted successfully:', result.rows[0].email);
        res.status(200).json({ success: true, message: 'User deleted successfully' });
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error deleting user:', error);
        
        let errorMessage = 'Server error deleting user';
        if (error.message) errorMessage += ': ' + error.message;
        
        res.status(500).json({ success: false, error: errorMessage });
    } finally {
        client.release();
    }
};

// @desc    Admin: Get All Users
// @route   GET /api/users
// @access  Admin
exports.getAllUsers = async (req, res) => {
  try {
    const query = `
      SELECT u.id, u.email, u.phone, u.user_role as role, u.status, u.created_at,
             u.profile_picture_url, u.preferred_language,
             p.first_name, p.last_name, p.middle_name, p.nationality, p.city, p.country,
             p.is_diaspora_verified, p.verification_tier,
             t.travel_frequency, t.total_bookings,
             d.license_number as driver_license, d.license_photo_url as driver_license_photo, d.years_experience as driver_experience, d.is_available as driver_available,
             g.guide_license_number as guide_license, g.license_photo_url as guide_license_photo, g.daily_rate as guide_rate, g.is_available as guide_available,
             (SELECT json_agg(json_build_object('type', document_type, 'front_url', front_image_url, 'back_url', back_image_url)) FROM verification_documents vd WHERE vd.user_id = u.id) as verification_documents,
             (SELECT json_agg(json_build_object('photos_urls', v.photos_urls, 'insurance_photo_url', v.insurance_photo_url)) FROM vehicles v WHERE v.driver_id = d.id) as vehicles_data
      FROM users u
      LEFT JOIN user_profiles p ON u.id = p.user_id
      LEFT JOIN tourists t ON u.id = t.user_id
      LEFT JOIN drivers d ON u.id = d.user_id
      LEFT JOIN guides g ON u.id = g.user_id
      ORDER BY u.created_at DESC
    `;
    const result = await db.query(query);
    res.status(200).json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Error fetching users (detailed):', error.message, error.stack);
    res.status(500).json({ error: 'Server error fetching users', details: error.message });
  }
};

// @desc    Admin: Get User By ID
// @route   GET /api/users/:id
// @access  Admin
exports.getUserById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const query = `
      SELECT u.id, u.email, u.phone, u.user_role as role, u.status, u.created_at,
             u.profile_picture_url, u.preferred_language,
             p.first_name, p.last_name, p.middle_name, p.nationality, p.city, p.country,
             p.is_diaspora_verified, p.verification_tier,
             t.travel_frequency, t.total_bookings,
             d.license_number as driver_license, d.license_photo_url as driver_license_photo,
             d.license_issue_date as driver_license_issue, d.license_expiry_date as driver_license_expiry,
             d.years_experience as driver_experience, d.is_available as driver_available, d.rating as driver_rating,
             g.guide_license_number as guide_license, g.license_photo_url as guide_license_photo,
             g.license_issue_date as guide_license_issue, g.license_expiry_date as guide_license_expiry,
             g.daily_rate as guide_rate, g.is_available as guide_available, g.rating as guide_rating,
             g.has_first_aid_cert, g.first_aid_expiry, g.specialization, g.languages_spoken as guide_languages
      FROM users u
      LEFT JOIN user_profiles p ON u.id = p.user_id
      LEFT JOIN tourists t ON u.id = t.user_id
      LEFT JOIN drivers d ON u.id = d.user_id
      LEFT JOIN guides g ON u.id = g.user_id
      WHERE u.id = $1
    `;
    
    const result = await db.query(query, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    
    const userData = result.rows[0];
    
    // Add document status for staff
    if (userData.role === 'guide' && userData.guide_license) {
      userData.documents = {
        license: {
          number: userData.guide_license,
          photo_url: userData.guide_license_photo,
          issue_date: userData.guide_license_issue,
          expiry_date: userData.guide_license_expiry,
          is_expired: userData.guide_license_expiry ? 
            new Date(userData.guide_license_expiry) < new Date() : false
        },
        first_aid: {
          has_cert: userData.has_first_aid_cert,
          expiry_date: userData.first_aid_expiry,
          is_expired: userData.first_aid_expiry ? 
            new Date(userData.first_aid_expiry) < new Date() : null
        }
      };
    } else if (userData.role === 'driver' && userData.driver_license) {
      userData.documents = {
        license: {
          number: userData.driver_license,
          photo_url: userData.driver_license_photo,
          issue_date: userData.driver_license_issue,
          expiry_date: userData.driver_license_expiry,
          is_expired: userData.driver_license_expiry ? 
            new Date(userData.driver_license_expiry) < new Date() : false
        }
      };
    }
    
    res.status(200).json({ success: true, data: userData });
  } catch (error) {
    console.error('Error fetching user by ID:', error);
    res.status(500).json({ success: false, error: 'Server error fetching user' });
  }
};

// @desc    Get Current Authenticated User
// @route   GET /api/users/me
// @access  Private
exports.getCurrentUser = async (req, res) => {
  try {
    const userId = req.user.userId;
    
    const query = `
      SELECT u.id, u.email, u.phone, u.user_role as role, u.status, u.created_at,
             u.profile_picture_url, u.preferred_language,
             p.first_name, p.last_name, p.middle_name, p.nationality, p.city, p.country,
             p.is_diaspora_verified, p.verification_tier,
             t.travel_frequency, t.total_bookings,
             d.license_number as driver_license, d.years_experience as driver_experience, d.is_available as driver_available,
             g.guide_license_number as guide_license, g.daily_rate as guide_rate, g.is_available as guide_available
      FROM users u
      LEFT JOIN user_profiles p ON u.id = p.user_id
      LEFT JOIN tourists t ON u.id = t.user_id
      LEFT JOIN drivers d ON u.id = d.user_id
      LEFT JOIN guides g ON u.id = g.user_id
      WHERE u.id = $1
    `;
    
    const result = await db.query(query, [userId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    
    res.status(200).json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Error fetching current user:', error);
    res.status(500).json({ success: false, error: 'Server error fetching user' });
  }
};

// @desc    Get Staff Documents (Guide/Driver)
// @route   GET /api/users/:id/documents
// @access  Admin or Self
exports.getStaffDocuments = async (req, res) => {
  try {
    const { id } = req.params;
    const requesterId = req.user.userId;
    const requesterRole = req.user.role;
    
    // Check if user is admin or requesting their own documents
    if (requesterRole !== 'admin' && requesterId !== id) {
      return res.status(403).json({ 
        success: false, 
        error: 'You can only view your own documents or must be an admin' 
      });
    }
    
    // Get user role first
    const userResult = await db.query('SELECT user_role FROM users WHERE id = $1', [id]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    
    const userRole = userResult.rows[0].user_role;
    let documents = {};
    
    if (userRole === 'guide') {
      const guideResult = await db.query(`
        SELECT 
          g.guide_license_number,
          g.license_issue_date,
          g.license_expiry_date,
          g.license_photo_url,
          g.specialization,
          g.languages_spoken,
          g.languages_certified,
          g.years_experience,
          g.rating,
          g.total_tours,
          g.is_available,
          g.hourly_rate,
          g.daily_rate,
          g.max_group_size,
          g.has_first_aid_cert,
          g.first_aid_expiry,
          g.education_background,
          g.average_response_time_minutes,
          g.booking_completion_rate,
          g.performance_review_status,
          u.email,
          p.first_name,
          p.last_name
        FROM guides g
        JOIN users u ON g.user_id = u.id
        LEFT JOIN user_profiles p ON u.id = p.user_id
        WHERE g.user_id = $1
      `, [id]);
      
      if (guideResult.rows.length > 0) {
        documents = {
          type: 'guide',
          ...guideResult.rows[0],
          documents: {
            license: {
              number: guideResult.rows[0].guide_license_number,
              issue_date: guideResult.rows[0].license_issue_date,
              expiry_date: guideResult.rows[0].license_expiry_date,
              photo_url: guideResult.rows[0].license_photo_url,
              is_expired: new Date(guideResult.rows[0].license_expiry_date) < new Date()
            },
            first_aid: {
              has_cert: guideResult.rows[0].has_first_aid_cert,
              expiry_date: guideResult.rows[0].first_aid_expiry,
              is_expired: guideResult.rows[0].first_aid_expiry ? 
                new Date(guideResult.rows[0].first_aid_expiry) < new Date() : null
            }
          }
        };
      }
      
    } else if (userRole === 'driver') {
      const driverResult = await db.query(`
        SELECT 
          d.license_number,
          d.license_issue_date,
          d.license_expiry_date,
          d.license_photo_url,
          d.years_experience,
          d.rating,
          d.total_trips,
          d.is_available,
          d.current_location,
          d.service_areas,
          d.languages_spoken,
          d.max_daily_hours,
          d.average_response_time_minutes,
          d.booking_completion_rate,
          d.performance_review_status,
          u.email,
          p.first_name,
          p.last_name
        FROM drivers d
        JOIN users u ON d.user_id = u.id
        LEFT JOIN user_profiles p ON u.id = p.user_id
        WHERE d.user_id = $1
      `, [id]);
      
      if (driverResult.rows.length > 0) {
        documents = {
          type: 'driver',
          ...driverResult.rows[0],
          documents: {
            license: {
              number: driverResult.rows[0].license_number,
              issue_date: driverResult.rows[0].license_issue_date,
              expiry_date: driverResult.rows[0].license_expiry_date,
              photo_url: driverResult.rows[0].license_photo_url,
              is_expired: new Date(driverResult.rows[0].license_expiry_date) < new Date()
            }
          }
        };
      }
      
    } else {
      return res.status(400).json({ 
        success: false, 
        error: 'User is not a guide or driver' 
      });
    }
    
    if (Object.keys(documents).length === 0) {
      return res.status(404).json({ 
        success: false, 
        error: `${userRole} profile not found` 
      });
    }
    
    res.status(200).json({ success: true, data: documents });
    
  } catch (error) {
    console.error('Error fetching staff documents:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Server error fetching staff documents',
      details: error.message 
    });
  }
};