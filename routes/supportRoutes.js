const express = require('express');
const router = express.Router();
const supportController = require('../controllers/supportController');
const { verifyToken, checkRole } = require('../middleware/authMiddleware');

// Support Ticket Routes
router.get('/tickets', verifyToken, supportController.getSupportTickets);
router.get('/tickets/:id', verifyToken, supportController.getSupportTicket);
router.post('/tickets', verifyToken, supportController.createSupportTicket);
router.post('/tickets/:id/messages', verifyToken, supportController.addTicketMessage);
router.put('/tickets/:id/status', verifyToken, checkRole(['admin']), supportController.updateTicketStatus);
router.delete('/tickets/:id', verifyToken, checkRole(['admin']), supportController.deleteSupportTicket);

module.exports = router;