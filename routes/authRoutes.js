const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { protect, isAdmin } = require('../middleware/auth');
const multer = require('multer');
const path = require('path');

// Configure multer for file uploads
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/');
    },
    filename: function (req, file, cb) {
        cb(null, Date.now() + '-' + Math.round(Math.random() * 1E9) + path.extname(file.originalname));
    }
});
const upload = multer({ storage: storage });

// Public Routes
router.post('/register', upload.fields([
    { name: 'vehicle_image', maxCount: 1 },
    { name: 'license_photo', maxCount: 1 },
    { name: 'libre_document', maxCount: 1 },
    { name: 'language_certification', maxCount: 1 },
    { name: 'guide_license_photo', maxCount: 1 },
    { name: 'profile_picture', maxCount: 1 }
]), authController.register);

router.post('/verify-otp', authController.verifyOtp); 
router.post('/resend-otp', authController.resendOtp);
router.post('/login', authController.login);
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);

// Protected Routes (Require valid JWT)
router.get('/profile', protect, authController.getProfile);
router.put('/profile', protect, upload.single('profile_picture'), authController.updateProfile);
router.put('/change-password', protect, authController.changePassword);

// Admin Routes
router.get('/users', protect, isAdmin, authController.getAllUsers);

module.exports = router;