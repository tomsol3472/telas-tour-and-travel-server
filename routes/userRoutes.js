const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { verifyToken, checkRole } = require('../middleware/authMiddleware');

router.get('/', verifyToken, checkRole(['admin']), userController.getAllUsers);
router.get('/profile', verifyToken, userController.getProfile);
router.put('/profile', verifyToken, userController.updateProfile);
router.get('/:id', verifyToken, checkRole(['admin']), userController.getUserById);
router.get('/:id/documents', verifyToken, userController.getStaffDocuments); // New route for staff documents
router.put('/:id', verifyToken, checkRole(['admin']), userController.updateUser);
router.delete('/:id', verifyToken, checkRole(['admin']), userController.deleteUser);

module.exports = router;