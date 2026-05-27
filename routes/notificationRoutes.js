const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { protect } = require('../middleware/auth');

// GET /api/notifications - Get all notifications for user
router.get('/', protect, notificationController.getUserNotifications);

// GET /api/notifications/unread-count - Get unread count
router.get('/unread-count', protect, notificationController.getUnreadCount);

// PATCH /api/notifications/:id/read - Mark notification as read
router.patch('/:id/read', protect, notificationController.markAsRead);

// PATCH /api/notifications/read-all - Mark all as read
router.patch('/read-all', protect, notificationController.markAllAsRead);

// DELETE /api/notifications/:id - Delete notification
router.delete('/:id', protect, notificationController.deleteNotification);

module.exports = router;
