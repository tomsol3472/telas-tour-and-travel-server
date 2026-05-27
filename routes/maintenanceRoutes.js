const express = require('express');
const router = express.Router();
const maintenanceController = require('../controllers/maintenanceController');
const { verifyToken, checkRole } = require('../middleware/authMiddleware');

// System Health Routes
router.get('/health', verifyToken, checkRole(['admin']), maintenanceController.getSystemHealth);

// Backup Routes
router.get('/backups', verifyToken, checkRole(['admin']), maintenanceController.getBackupHistory);
router.post('/backup', verifyToken, checkRole(['admin']), maintenanceController.triggerBackup);

// Cleanup Routes
router.post('/cleanup', verifyToken, checkRole(['admin']), maintenanceController.cleanupLogs);

// Database Routes
router.get('/database/stats', verifyToken, checkRole(['admin']), maintenanceController.getDatabaseStats);
router.post('/database/optimize', verifyToken, checkRole(['admin']), maintenanceController.optimizeDatabase);

// System Alerts Routes
router.get('/alerts', verifyToken, checkRole(['admin']), maintenanceController.getSystemAlerts);
router.post('/alerts', verifyToken, checkRole(['admin']), maintenanceController.createSystemAlert);
router.put('/alerts/:id/resolve', verifyToken, checkRole(['admin']), maintenanceController.resolveSystemAlert);

module.exports = router;