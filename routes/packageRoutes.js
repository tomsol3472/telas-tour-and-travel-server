const express = require('express');
const router = express.Router();
const packageController = require('../controllers/packageController');
const multer = require('multer');
const path = require('path');

// Configure multer for image uploads
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/'); // Ensure the 'uploads' folder exists in your backend root
    },
    filename: function (req, file, cb) {
        cb(null, Date.now() + '-' + Math.round(Math.random() * 1E9) + path.extname(file.originalname));
    }
});
const upload = multer({ storage: storage });

// Routes
router.get('/mobile', packageController.getMobilePackages); // Mobile-specific endpoint (must be before /:id)
router.get('/mobile/:id', packageController.getMobilePackageById); // Mobile-specific endpoint
router.get('/', packageController.getAllPackages);
router.get('/:id', packageController.getPackageById);

// Apply Multer middleware to process 'images' array from frontend FormData
router.post('/', upload.array('images', 10), packageController.createPackage);
router.put('/:id', upload.array('images', 10), packageController.updatePackage);

router.delete('/:id', packageController.deletePackage);
router.patch('/:id', packageController.updatePackageStatus); 

module.exports = router;