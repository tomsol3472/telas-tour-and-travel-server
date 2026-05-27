const express = require('express');
const router = express.Router();
const settingsController = require('../controllers/settingsController');
const { verifyToken, checkRole } = require('../middleware/authMiddleware');

// System Configuration Routes
router.put('/system/maintenance', verifyToken, checkRole(['admin']), settingsController.toggleMaintenanceMode);
router.post('/system/maintenance/schedule', verifyToken, checkRole(['admin']), settingsController.scheduleMaintenance);

// System Logs Routes
router.get('/system/logs', verifyToken, checkRole(['admin']), settingsController.getSystemLogs);
router.post('/system/logs', verifyToken, checkRole(['admin']), settingsController.createSystemLog);
router.delete('/system/logs', verifyToken, checkRole(['admin']), settingsController.clearSystemLogs);

router.get('/system', verifyToken, checkRole(['admin']), settingsController.getSystemConfigurations);
router.post('/system', verifyToken, checkRole(['admin']), settingsController.createSystemConfiguration);
router.put('/system/:id', verifyToken, checkRole(['admin']), settingsController.updateSystemConfiguration);
router.delete('/system/:id', verifyToken, checkRole(['admin']), settingsController.deleteSystemConfiguration);

// Performance Metrics Routes
router.get('/performance', verifyToken, checkRole(['admin']), settingsController.getPerformanceMetrics);

// Traffic Logs Routes
router.get('/traffic', verifyToken, checkRole(['admin']), settingsController.getWebTrafficLogs);

// Audit Logs Routes
router.get('/audit', verifyToken, checkRole(['admin']), settingsController.getAuditLogs);

module.exports = router;