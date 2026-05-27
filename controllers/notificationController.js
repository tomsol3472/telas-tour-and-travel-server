const db = require('../config/db');
const socketService = require('../services/socketService');

/**
 * Get all notifications for a user
 */
exports.getUserNotifications = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { limit = 50, offset = 0, unread_only = false } = req.query;

        let whereClause = 'WHERE user_id = $1';
        const params = [userId];

        if (unread_only === 'true') {
            whereClause += ' AND is_read = false';
        }

        const result = await db.query(`
            SELECT 
                id,
                notification_type,
                title,
                message,
                data,
                priority,
                is_read,
                read_at,
                action_url,
                expires_at,
                created_at
            FROM notifications
            ${whereClause}
            ORDER BY created_at DESC
            LIMIT $${params.length + 1} OFFSET $${params.length + 2}
        `, [...params, parseInt(limit), parseInt(offset)]);

        // Get unread count
        const countResult = await db.query(`
            SELECT COUNT(*) as unread_count
            FROM notifications
            WHERE user_id = $1 AND is_read = false
        `, [userId]);

        res.status(200).json({
            success: true,
            notifications: result.rows,
            unread_count: parseInt(countResult.rows[0].unread_count),
            total: result.rows.length
        });

    } catch (err) {
        console.error('Error fetching notifications:', err);
        res.status(500).json({ error: 'Failed to fetch notifications', details: err.message });
    }
};

/**
 * Mark notification as read
 */
exports.markAsRead = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { id } = req.params;

        const result = await db.query(`
            UPDATE notifications
            SET is_read = true, read_at = NOW()
            WHERE id = $1 AND user_id = $2
            RETURNING *
        `, [id, userId]);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Notification not found' });
        }

        // Emit update via WebSocket (if available)
        try {
            const io = socketService.getIo();
            io.to(`user_${userId}`).emit('notification_read', {
                notification_id: id
            });
        } catch (socketError) {
            console.log('WebSocket not available for notification read:', socketError.message);
        }

        res.status(200).json({
            success: true,
            notification: result.rows[0]
        });

    } catch (err) {
        console.error('Error marking notification as read:', err);
        res.status(500).json({ error: 'Failed to mark notification as read', details: err.message });
    }
};

/**
 * Mark all notifications as read
 */
exports.markAllAsRead = async (req, res) => {
    try {
        const userId = req.user.userId;

        const result = await db.query(`
            UPDATE notifications
            SET is_read = true, read_at = NOW()
            WHERE user_id = $1 AND is_read = false
            RETURNING id
        `, [userId]);

        // Emit update via WebSocket (if available)
        try {
            const io = socketService.getIo();
            io.to(`user_${userId}`).emit('all_notifications_read', {
                count: result.rows.length
            });
        } catch (socketError) {
            console.log('WebSocket not available for mark all read:', socketError.message);
        }

        res.status(200).json({
            success: true,
            marked_count: result.rows.length
        });

    } catch (err) {
        console.error('Error marking all notifications as read:', err);
        res.status(500).json({ error: 'Failed to mark all as read', details: err.message });
    }
};

/**
 * Delete a notification
 */
exports.deleteNotification = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { id } = req.params;

        const result = await db.query(`
            DELETE FROM notifications
            WHERE id = $1 AND user_id = $2
            RETURNING id
        `, [id, userId]);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Notification not found' });
        }

        res.status(200).json({
            success: true,
            message: 'Notification deleted'
        });

    } catch (err) {
        console.error('Error deleting notification:', err);
        res.status(500).json({ error: 'Failed to delete notification', details: err.message });
    }
};

/**
 * Get unread count
 */
exports.getUnreadCount = async (req, res) => {
    try {
        const userId = req.user.userId;

        const result = await db.query(`
            SELECT COUNT(*) as unread_count
            FROM notifications
            WHERE user_id = $1 AND is_read = false
        `, [userId]);

        res.status(200).json({
            success: true,
            unread_count: parseInt(result.rows[0].unread_count)
        });

    } catch (err) {
        console.error('Error getting unread count:', err);
        res.status(500).json({ error: 'Failed to get unread count', details: err.message });
    }
};

/**
 * Send notification to user (internal use)
 */
exports.sendNotification = async (userId, notificationData) => {
    try {
        const {
            type,
            title,
            message,
            data = {},
            priority = 'normal',
            action_url = null,
            expires_at = null
        } = notificationData;

        // Create notification in database
        const result = await db.query(`
            INSERT INTO notifications (
                user_id,
                notification_type,
                title,
                message,
                data,
                priority,
                action_url,
                expires_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING *
        `, [userId, type, title, message, JSON.stringify(data), priority, action_url, expires_at]);

        const notification = result.rows[0];

        // Send real-time notification via WebSocket (if available)
        try {
            const io = socketService.getIo();
            io.to(`user_${userId}`).emit('new_notification', {
                id: notification.id,
                type: notification.notification_type,
                title: notification.title,
                message: notification.message,
                data: notification.data,
                priority: notification.priority,
                action_url: notification.action_url,
                created_at: notification.created_at
            });
        } catch (socketError) {
            // WebSocket not available (e.g., during testing) - continue without it
            console.log('WebSocket not available for notification:', socketError.message);
        }

        return notification;

    } catch (error) {
        console.error('Error sending notification:', error);
        throw error;
    }
};

module.exports = exports;
