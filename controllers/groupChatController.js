const db = require('../config/db');
const socketService = require('../services/socketService');

/**
 * Get or create group chat for a booking
 */
exports.getBookingGroupChat = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const userId = req.user.userId;

        // Get booking details
        const bookingResult = await db.query(`
            SELECT 
                b.id,
                b.booking_code,
                b.tourist_id,
                t.user_id as tourist_user_id,
                tu.email as tourist_name,
                b.assigned_guide_id,
                g.user_id as guide_user_id,
                gu.email as guide_name,
                b.assigned_driver_id,
                d.user_id as driver_user_id,
                du.email as driver_name
            FROM bookings b
            LEFT JOIN tourists t ON b.tourist_id = t.id
            LEFT JOIN users tu ON t.user_id = tu.id
            LEFT JOIN guides g ON b.assigned_guide_id = g.id
            LEFT JOIN users gu ON g.user_id = gu.id
            LEFT JOIN drivers d ON b.assigned_driver_id = d.id
            LEFT JOIN users du ON d.user_id = du.id
            WHERE b.id::text = $1 OR b.booking_code = $1
        `, [bookingId]);

        if (bookingResult.rows.length === 0) {
            return res.status(404).json({ error: 'Booking not found' });
        }

        const booking = bookingResult.rows[0];

        // Check if user is part of this booking
        const isParticipant = 
            userId === booking.tourist_user_id ||
            userId === booking.guide_user_id ||
            userId === booking.driver_user_id;

        // Check if user is admin
        const userRole = await db.query(`
            SELECT user_role FROM users WHERE id = $1
        `, [userId]);

        const isAdmin = userRole.rows[0]?.user_role === 'admin' || 
                       userRole.rows[0]?.user_role === 'agency_staff';

        if (!isParticipant && !isAdmin) {
            return res.status(403).json({ error: 'You are not authorized to access this chat' });
        }

        // Check if group chat exists
        let conversationResult = await db.query(`
            SELECT id, group_name, created_at
            FROM chat_conversations
            WHERE group_name = $1 AND is_group_chat = true
        `, [`Booking ${booking.booking_code} Chat`]);

        let conversationId;

        if (conversationResult.rows.length === 0) {
            // Create group chat
            const newConversation = await db.query(`
                INSERT INTO chat_conversations (
                    is_group_chat,
                    group_name,
                    created_by
                ) VALUES (true, $1, $2)
                RETURNING id, group_name, created_at
            `, [`Booking ${booking.booking_code} Chat`, userId]);

            conversationId = newConversation.rows[0].id;
            conversationResult = newConversation;

            // Add participants
            const participants = [
                booking.tourist_user_id,
                booking.guide_user_id,
                booking.driver_user_id
            ].filter(id => id !== null);

            // Add admin users
            const adminUsers = await db.query(`
                SELECT id FROM users WHERE user_role IN ('admin', 'agency_staff')
            `);
            adminUsers.rows.forEach(admin => participants.push(admin.id));

            // Remove duplicates
            const uniqueParticipants = [...new Set(participants)];

            for (const participantId of uniqueParticipants) {
                await db.query(`
                    INSERT INTO chat_participants (conversation_id, user_id)
                    VALUES ($1, $2)
                    ON CONFLICT (conversation_id, user_id) DO NOTHING
                `, [conversationId, participantId]);
            }

            // Send system message
            await db.query(`
                INSERT INTO chat_messages (
                    conversation_id,
                    sender_id,
                    message_type,
                    message_text
                ) VALUES ($1, $2, 'system', $3)
            `, [
                conversationId,
                userId,
                `Group chat created for booking ${booking.booking_code}. All participants can now communicate.`
            ]);

        } else {
            conversationId = conversationResult.rows[0].id;

            // Ensure current user is a participant
            await db.query(`
                INSERT INTO chat_participants (conversation_id, user_id)
                VALUES ($1, $2)
                ON CONFLICT (conversation_id, user_id) DO NOTHING
            `, [conversationId, userId]);
        }

        // Get participants
        const participantsResult = await db.query(`
            SELECT 
                cp.user_id,
                u.email as name,
                u.user_role as role,
                cp.joined_at
            FROM chat_participants cp
            JOIN users u ON cp.user_id = u.id
            WHERE cp.conversation_id = $1
            ORDER BY cp.joined_at ASC
        `, [conversationId]);

        // Get recent messages
        const messagesResult = await db.query(`
            SELECT 
                cm.id,
                cm.sender_id,
                u.email as sender_name,
                u.user_role as sender_role,
                cm.message_type,
                cm.message_text,
                cm.created_at,
                cm.is_read
            FROM chat_messages cm
            JOIN users u ON cm.sender_id = u.id
            WHERE cm.conversation_id = $1
            ORDER BY cm.created_at DESC
            LIMIT 50
        `, [conversationId]);

        res.status(200).json({
            success: true,
            conversation: {
                id: conversationId,
                name: conversationResult.rows[0].group_name,
                booking_code: booking.booking_code,
                created_at: conversationResult.rows[0].created_at
            },
            participants: participantsResult.rows,
            messages: messagesResult.rows.reverse(), // Oldest first
            booking_details: {
                tourist: booking.tourist_name,
                guide: booking.guide_name,
                driver: booking.driver_name
            }
        });

    } catch (err) {
        console.error('Error getting group chat:', err);
        res.status(500).json({ error: 'Failed to get group chat', details: err.message });
    }
};

/**
 * Send message to group chat
 */
exports.sendMessage = async (req, res) => {
    try {
        const { conversationId } = req.params;
        const { message } = req.body;
        const userId = req.user.userId;

        // Verify user is participant
        const participantCheck = await db.query(`
            SELECT 1 FROM chat_participants
            WHERE conversation_id = $1 AND user_id = $2
        `, [conversationId, userId]);

        if (participantCheck.rows.length === 0) {
            return res.status(403).json({ error: 'You are not a participant in this chat' });
        }

        // Insert message
        const result = await db.query(`
            INSERT INTO chat_messages (
                conversation_id,
                sender_id,
                message_type,
                message_text
            ) VALUES ($1, $2, 'text', $3)
            RETURNING id, created_at
        `, [conversationId, userId, message]);

        const messageId = result.rows[0].id;

        // Get sender info
        const senderInfo = await db.query(`
            SELECT email as name, user_role as role
            FROM users
            WHERE id = $1
        `, [userId]);

        const messageData = {
            id: messageId,
            sender_id: userId,
            sender_name: senderInfo.rows[0].name,
            sender_role: senderInfo.rows[0].role,
            message_type: 'text',
            message_text: message,
            created_at: result.rows[0].created_at,
            is_read: false
        };

        // Broadcast to all participants via WebSocket (if available)
        try {
            const io = socketService.getIo();
            io.to(`conversation_${conversationId}`).emit('new_message', messageData);
        } catch (socketError) {
            console.log('WebSocket not available for message broadcast:', socketError.message);
        }

        // Send notifications to other participants
        const participants = await db.query(`
            SELECT user_id FROM chat_participants
            WHERE conversation_id = $1 AND user_id != $2
        `, [conversationId, userId]);

        const notificationController = require('./notificationController');
        for (const participant of participants.rows) {
            await notificationController.sendNotification(participant.user_id, {
                type: 'new_message',
                title: 'New Message',
                message: `${senderInfo.rows[0].name}: ${message.substring(0, 50)}${message.length > 50 ? '...' : ''}`,
                data: {
                    conversation_id: conversationId,
                    message_id: messageId
                },
                priority: 'normal',
                action_url: `/chat/${conversationId}`
            });
        }

        res.status(201).json({
            success: true,
            message: messageData
        });

    } catch (err) {
        console.error('Error sending message:', err);
        res.status(500).json({ error: 'Failed to send message', details: err.message });
    }
};

/**
 * Mark messages as read
 */
exports.markMessagesAsRead = async (req, res) => {
    try {
        const { conversationId } = req.params;
        const userId = req.user.userId;

        await db.query(`
            UPDATE chat_messages
            SET is_read = true
            WHERE conversation_id = $1 
              AND sender_id != $2
              AND is_read = false
        `, [conversationId, userId]);

        res.status(200).json({
            success: true,
            message: 'Messages marked as read'
        });

    } catch (err) {
        console.error('Error marking messages as read:', err);
        res.status(500).json({ error: 'Failed to mark messages as read', details: err.message });
    }
};

/**
 * Get all group chats for user
 */
exports.getUserGroupChats = async (req, res) => {
    try {
        const userId = req.user.userId;

        const result = await db.query(`
            SELECT 
                cc.id,
                cc.group_name,
                cc.created_at,
                (
                    SELECT COUNT(*)
                    FROM chat_messages cm
                    WHERE cm.conversation_id = cc.id
                      AND cm.sender_id != $1
                      AND cm.is_read = false
                ) as unread_count,
                (
                    SELECT cm.message_text
                    FROM chat_messages cm
                    WHERE cm.conversation_id = cc.id
                    ORDER BY cm.created_at DESC
                    LIMIT 1
                ) as last_message,
                (
                    SELECT cm.created_at
                    FROM chat_messages cm
                    WHERE cm.conversation_id = cc.id
                    ORDER BY cm.created_at DESC
                    LIMIT 1
                ) as last_message_at
            FROM chat_conversations cc
            JOIN chat_participants cp ON cc.id = cp.conversation_id
            WHERE cp.user_id = $1 AND cc.is_group_chat = true
            ORDER BY last_message_at DESC NULLS LAST
        `, [userId]);

        res.status(200).json({
            success: true,
            chats: result.rows
        });

    } catch (err) {
        console.error('Error getting user group chats:', err);
        res.status(500).json({ error: 'Failed to get group chats', details: err.message });
    }
};

/**
 * Get messages for a specific conversation
 */
exports.getConversationMessages = async (req, res) => {
    try {
        const { conversationId } = req.params;
        const userId = req.user.userId;

        // Verify user is participant
        const participantCheck = await db.query(`
            SELECT 1 FROM chat_participants
            WHERE conversation_id = $1 AND user_id = $2
        `, [conversationId, userId]);

        if (participantCheck.rows.length === 0) {
            return res.status(403).json({ error: 'You are not a participant in this chat' });
        }

        const messagesResult = await db.query(`
            SELECT 
                cm.id,
                cm.sender_id,
                u.email as sender_name,
                u.user_role as sender_role,
                cm.message_type,
                cm.message_text,
                cm.created_at,
                cm.is_read
            FROM chat_messages cm
            JOIN users u ON cm.sender_id = u.id
            WHERE cm.conversation_id = $1
            ORDER BY cm.created_at DESC
            LIMIT 50
        `, [conversationId]);

        res.status(200).json({
            success: true,
            messages: messagesResult.rows.reverse()
        });
    } catch (err) {
        console.error('Error getting messages:', err);
        res.status(500).json({ error: 'Failed to get messages', details: err.message });
    }
};

module.exports = exports;
