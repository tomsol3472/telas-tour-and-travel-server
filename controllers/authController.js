const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const db = require('../config/db');

// Configure Gmail Sender
const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 587,
    secure: false, // true for 465, false for other ports
    auth: {
        user: 'tomsol3472@gmail.com',
        pass: 'gutavwetbwtlnkbl' 
    },
    connectionTimeout: 10000, // 10 seconds timeout
    greetingTimeout: 10000,
    socketTimeout: 10000
});

// POST /api/auth/register
exports.register = async (req, res) => {
    try {
        const { 
            email, phone, password, role, first_name, last_name,
            date_of_birth, gender, nationality, address, city, country,
            emergency_contact_name, emergency_contact_phone, passport_number,
            license_number, vehicle_plate, vehicle_make, vehicle_model,
            guide_license_number, years_experience, languages_spoken
        } = req.body;
        
        const userRole = role || 'tourist';
        const phoneCountryCode = '+251';

        if (!email || !password || !first_name) {
            return res.status(400).json({ success: false, error: "Missing required fields" });
        }

        const userExists = await db.query("SELECT * FROM users WHERE email = $1 OR phone = $2", [email, phone]);
        if (userExists.rows.length > 0) {
            return res.status(400).json({ success: false, error: "User with this email or phone already exists" });
        }

        // Handle uploaded files
        const files = req.files || {};
        const profile_picture_url = files['profile_picture'] ? `/uploads/${files['profile_picture'][0].filename}` : null;
        const vehicle_image_url = files['vehicle_image'] ? `/uploads/${files['vehicle_image'][0].filename}` : null;
        const license_photo_url = files['license_photo'] ? `/uploads/${files['license_photo'][0].filename}` : null;
        const libre_document_url = files['libre_document'] ? `/uploads/${files['libre_document'][0].filename}` : null;
        const language_certification_url = files['language_certification'] ? `/uploads/${files['language_certification'][0].filename}` : null;
        const guide_license_photo_url = files['guide_license_photo'] ? `/uploads/${files['guide_license_photo'][0].filename}` : null;

        const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 10;
        const salt = await bcrypt.genSalt(saltRounds);
        const hashedPassword = await bcrypt.hash(password, salt);

        const generatedOtp = Math.floor(100000 + Math.random() * 900000).toString();

        await db.query('BEGIN');
        
        const userRes = await db.query(
            `INSERT INTO users (user_role, email, phone, phone_country_code, password_hash, status, profile_picture_url, otp_code, otp_expires) 
             VALUES ($1, $2, $3, $4, $5, 'pending', $6, $7, CURRENT_TIMESTAMP + INTERVAL '10 minutes') RETURNING id`,
            [userRole, email, phone || null, phoneCountryCode, hashedPassword, profile_picture_url, generatedOtp]
        );
        const userId = userRes.rows[0].id;
        const otpCode = generatedOtp;

        await db.query(
            `INSERT INTO user_profiles (
                user_id, first_name, last_name, date_of_birth, gender, nationality, 
                address, city, country, emergency_contact_name, emergency_contact_phone, passport_number
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
            [
                userId, first_name, last_name || null, date_of_birth || null, gender || null,
                nationality || null, address || null, city || null, country || 'Ethiopia',
                emergency_contact_name || null, emergency_contact_phone || null, passport_number || null
            ]
        );

        if (userRole === 'tourist') {
            await db.query(`INSERT INTO tourists (user_id) VALUES ($1)`, [userId]);
        } else if (userRole === 'driver') {
            const driverRes = await db.query(
                `INSERT INTO drivers (user_id, license_number, license_issue_date, license_expiry_date, license_photo_url, years_experience) 
                 VALUES ($1, $2, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 year', $3, $4) RETURNING id`, 
                [userId, license_number || `TMP-${Date.now()}`, license_photo_url, parseInt(years_experience) || 0]
            );
            if (vehicle_plate) {
                await db.query(
                    `INSERT INTO vehicles (driver_id, plate_number, make, model, photos_urls) VALUES ($1, $2, $3, $4, $5)`,
                    [driverRes.rows[0].id, vehicle_plate, vehicle_make || 'Unknown', vehicle_model || 'Unknown', vehicle_image_url ? [vehicle_image_url] : []]
                );
            }
            if (libre_document_url) {
                await db.query(
                    `INSERT INTO verification_documents (user_id, document_type, front_image_url) VALUES ($1, 'libre_document', $2)`,
                    [userId, libre_document_url]
                );
            }
        } else if (userRole === 'guide') {
            await db.query(
                `INSERT INTO guides (user_id, guide_license_number, license_issue_date, license_expiry_date, languages_spoken, license_photo_url, years_experience) 
                 VALUES ($1, $2, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 year', $3, $4, $5)`, 
                [userId, guide_license_number || `TMP-${Date.now()}`, `{${languages_spoken || 'English'}}`, guide_license_photo_url, parseInt(years_experience) || 0]
            );
            if (language_certification_url) {
                await db.query(
                    `INSERT INTO verification_documents (user_id, document_type, front_image_url) VALUES ($1, 'language_certification', $2)`,
                    [userId, language_certification_url]
                );
            }
        }

        await db.query('COMMIT');

        // SEND EMAIL
        if (otpCode) {
            try {
                await transporter.sendMail({
                    from: 'Telas Tour & Travel <tomsol3472@gmail.com>',
                    to: email,
                    subject: 'Your Telas Tour OTP Code',
                    text: `Welcome to Telas Tour! Your 6-digit OTP code is: ${otpCode}. It expires in 45 seconds.`
                });
            } catch (mailError) {
                console.error("Email failed to send:", mailError);
            }
        }

        res.status(201).json({ success: true, message: "User registered successfully. OTP sent via email." });
    } catch (error) {
        await db.query('ROLLBACK');
        console.error('Registration Error:', error);
        res.status(500).json({ success: false, error: "Server error during registration", details: error.message });
    }
};

// POST /api/auth/verify-otp
exports.verifyOtp = async (req, res) => {
    try {
        const { email, otp } = req.body;

        const result = await db.query(
            `SELECT id, user_role FROM users WHERE email = $1 AND otp_code = $2 AND otp_expires > CURRENT_TIMESTAMP`,
            [email, otp]
        );

        if (result.rows.length === 0) {
            return res.status(400).json({ success: false, message: 'Invalid or expired OTP.' });
        }

        const role = result.rows[0].user_role;
        let newStatus = 'active';
        if (role === 'driver' || role === 'guide') {
            newStatus = 'under_review';
        }

        await db.query(
            `UPDATE users SET is_email_verified = TRUE, status = $1, otp_code = NULL WHERE email = $2`,
            [newStatus, email]
        );

        res.status(200).json({ success: true, message: newStatus === 'active' ? 'OTP verified successfully!' : 'OTP verified. Waiting for admin approval.' });
    } catch (error) {
        console.error('OTP Verification Error:', error);
        res.status(500).json({ success: false, message: 'Server error verifying OTP.' });
    }
};

// POST /api/auth/resend-otp
exports.resendOtp = async (req, res) => {
    try {
        const { email } = req.body;

        const new_otp = Math.floor(100000 + Math.random() * 900000).toString();
        const result = await db.query(
            `UPDATE users SET otp_code = $1, otp_expires = CURRENT_TIMESTAMP + INTERVAL '10 minutes' WHERE email = $2 RETURNING id`,
            [new_otp, email]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'User not found.' });
        }

        // Send Email
        await transporter.sendMail({
            from: 'Telas Tour & Travel <tomsol3472@gmail.com>',
            to: email,
            subject: 'Your NEW Telas Tour OTP Code',
            text: `Your new 6-digit OTP code is: ${new_otp}. It expires in 45 seconds.`
        });

        res.status(200).json({ success: true, message: 'New OTP sent successfully.' });
    } catch (error) {
        console.error('Resend OTP Error:', error);
        res.status(500).json({ success: false, message: 'Server error resending OTP.' });
    }
};

// POST /api/auth/login
exports.login = async (req, res) => {
    try {
        const identifier = req.body.email || req.body.phone;
        const password = req.body.password;

        if (!identifier || !password) {
            return res.status(400).json({ success: false, error: "Please provide both email/phone and password" });
        }

        const result = await db.query(
            `SELECT u.*, p.first_name, p.last_name 
             FROM users u 
             LEFT JOIN user_profiles p ON u.id = p.user_id 
             WHERE u.email = $1 OR u.phone = $1`, 
            [identifier]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({ success: false, error: "Invalid credentials" });
        }

        const user = result.rows[0];
        
        if (user.status === 'pending') {
            return res.status(401).json({ success: false, error: "Email not verified. Please verify your OTP." });
        }

        if (user.status === 'under_review') {
            return res.status(401).json({ success: false, error: "Your account is pending admin approval." });
        }

        if (user.status === 'waiting_approval') {
            return res.status(401).json({ success: false, error: "Your account is pending admin approval." });
        }

        const isMatch = await bcrypt.compare(String(password), user.password_hash);
        if (!isMatch) {
            return res.status(401).json({ success: false, error: "Invalid credentials" });
        }

        const token = jwt.sign(
            { userId: user.id, role: user.user_role },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRE || '30d' }
        );

        await db.query("UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = $1", [user.id]);

        delete user.password_hash;
        delete user.verification_token;
        delete user.otp_code;

        res.status(200).json({ success: true, token, user });
    } catch (error) {
        console.error('Login Error:', error);
        res.status(500).json({ success: false, error: "Server error during login", details: error.message });
    }
};

// GET /api/auth/profile
exports.getProfile = async (req, res) => {
    try {
        const result = await db.query(
            `SELECT u.email, u.phone, u.phone_country_code, u.user_role, u.status, u.profile_picture_url, 
                    p.first_name, p.last_name, p.middle_name, p.gender, p.nationality, p.address, p.city, p.country,
                    p.date_of_birth, p.passport_number, p.emergency_contact_name, p.emergency_contact_phone
             FROM users u 
             JOIN user_profiles p ON u.id = p.user_id 
             WHERE u.id = $1`,
            [req.user.userId] 
        );

        if (result.rows.length === 0) return res.status(404).json({ success: false, error: "Profile not found" });
        res.status(200).json({ success: true, data: result.rows[0] });
    } catch (error) {
        console.error('Get Profile Error:', error);
        res.status(500).json({ success: false, error: "Server Error" });
    }
};

// PUT /api/auth/profile
exports.updateProfile = async (req, res) => {
    try {
        const { firstName, lastName, middleName, address, city, country, gender, nationality, phone } = req.body;
        
        let profile_picture_url = req.body.profile_picture_url || null;
        if (req.file) {
            profile_picture_url = `/uploads/${req.file.filename}`;
        }
        
        await db.query('BEGIN');

        await db.query(
            `UPDATE user_profiles 
             SET first_name = COALESCE($1, first_name), 
                 last_name = COALESCE($2, last_name), 
                 middle_name = COALESCE($3, middle_name),
                 address = COALESCE($4, address), 
                 city = COALESCE($5, city), 
                 country = COALESCE($6, country),
                 gender = COALESCE($7, gender), 
                 nationality = COALESCE($8, nationality), 
                 updated_at = CURRENT_TIMESTAMP 
             WHERE user_id = $9`,
            [firstName, lastName, middleName, address, city, country, gender, nationality, req.user.userId]
        );

        await db.query(
            `UPDATE users
             SET phone = COALESCE($1, phone),
                 profile_picture_url = COALESCE($2, profile_picture_url),
                 updated_at = CURRENT_TIMESTAMP
             WHERE id = $3`,
            [phone, profile_picture_url, req.user.userId]
        );

        await db.query('COMMIT');

        res.status(200).json({ success: true, message: "Profile updated successfully" });
    } catch (error) {
        await db.query('ROLLBACK');
        console.error('Update Profile Error:', error);
        res.status(500).json({ success: false, error: "Server Error" });
    }
};

// PUT /api/auth/change-password
exports.changePassword = async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;

        if (!currentPassword || !newPassword) {
            return res.status(400).json({ success: false, error: "Please provide both current and new password" });
        }

        const userRes = await db.query("SELECT password_hash FROM users WHERE id = $1", [req.user.userId]);
        const user = userRes.rows[0];

        const isMatch = await bcrypt.compare(currentPassword, user.password_hash);
        if (!isMatch) return res.status(401).json({ success: false, error: "Incorrect current password" });

        const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 10;
        const salt = await bcrypt.genSalt(saltRounds);
        const hashedPassword = await bcrypt.hash(newPassword, salt);

        await db.query(
            "UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2", 
            [hashedPassword, req.user.userId]
        );

        res.status(200).json({ success: true, message: "Password updated successfully" });
    } catch (error) {
        console.error('Change Password Error:', error);
        res.status(500).json({ success: false, error: "Server error while changing password" });
    }
};

// GET /api/auth/users
exports.getAllUsers = async (req, res) => {
    try {
        const result = await db.query(
            `SELECT u.id, u.email, u.phone, u.user_role, u.status, u.created_at, 
                    p.first_name, p.last_name, p.city, p.country
             FROM users u 
             LEFT JOIN user_profiles p ON u.id = p.user_id 
             ORDER BY u.created_at DESC`
        );
        res.status(200).json({ success: true, data: result.rows });
    } catch (error) {
        console.error('Get All Users Error:', error);
        res.status(500).json({ success: false, error: "Server Error fetching users" });
    }
};

// OTP tracking to prevent brute force
const otpAttempts = new Map();
const MAX_OTP_ATTEMPTS = 5;

// POST /api/auth/forgot-password
exports.forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;
        
        // Reset attempts when a new OTP is requested
        otpAttempts.delete(email);
        
        const new_otp = Math.floor(100000 + Math.random() * 900000).toString();
        const result = await db.query(
            `UPDATE users SET otp_code = $1, otp_expires = CURRENT_TIMESTAMP + INTERVAL '10 minutes' WHERE email = $2 RETURNING id`,
            [new_otp, email]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'User with this email not found.' });
        }

        await transporter.sendMail({
            from: 'Telas Tour & Travel <tomsol3472@gmail.com>',
            to: email,
            subject: 'Password Reset OTP',
            text: `You requested a password reset. Your OTP code is: ${new_otp}. It expires in 10 minutes.`
        });

        res.status(200).json({ success: true, message: 'Password reset OTP sent to email.' });
    } catch (error) {
        console.error('Forgot Password Error:', error);
        res.status(500).json({ success: false, error: "Server error generating password reset OTP" });
    }
};

// POST /api/auth/reset-password
exports.resetPassword = async (req, res) => {
    try {
        const { email, otp, newPassword } = req.body;

        if (!email || !otp || !newPassword) {
            return res.status(400).json({ success: false, message: "Missing required fields" });
        }

        const attemptData = otpAttempts.get(email) || { count: 0 };
        if (attemptData.count >= MAX_OTP_ATTEMPTS) {
            return res.status(403).json({ success: false, message: "Too many failed attempts. Please request a new OTP." });
        }

        const result = await db.query(
            `SELECT id FROM users WHERE email = $1 AND otp_code = $2 AND otp_expires > CURRENT_TIMESTAMP`,
            [email, otp]
        );

        if (result.rows.length === 0) {
            attemptData.count += 1;
            otpAttempts.set(email, attemptData);
            return res.status(400).json({ success: false, message: `Invalid or expired OTP. ${MAX_OTP_ATTEMPTS - attemptData.count} attempts remaining.` });
        }

        // Success, clear attempts
        otpAttempts.delete(email);

        const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 10;
        const salt = await bcrypt.genSalt(saltRounds);
        const hashedPassword = await bcrypt.hash(newPassword, salt);

        await db.query(
            `UPDATE users SET password_hash = $1, otp_code = NULL WHERE email = $2`,
            [hashedPassword, email]
        );

        res.status(200).json({ success: true, message: 'Password reset successfully. You can now login.' });
    } catch (error) {
        console.error('Reset Password Error:', error);
        res.status(500).json({ success: false, error: "Server error resetting password" });
    }
};