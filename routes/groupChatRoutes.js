const express = require('express');
const router = express.Router();
const groupChatController = require('../controllers/groupChatController');
const { protect } = require('../middleware/auth');

// GET /api/chat - Get all group chats for user
router.get('/', protect, groupChatController.getUserGroupChats);

// GET /api/chat/booking/:bookingId - Get or create group chat for booking
router.get('/booking/:bookingId', protect, groupChatController.getBookingGroupChat);

// POST /api/chat/:conversationId/message - Send message to group chat
router.post('/:conversationId/message', protect, groupChatController.sendMessage);

// GET /api/chat/:conversationId/messages - Get messages for a specific conversation
router.get('/:conversationId/messages', protect, groupChatController.getConversationMessages);

// PATCH /api/chat/:conversationId/read - Mark messages as read
router.patch('/:conversationId/read', protect, groupChatController.markMessagesAsRead);

module.exports = router;
