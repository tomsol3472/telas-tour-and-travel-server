const db = require('../config/db');

// @desc    Get all support tickets
// @route   GET /api/support/tickets
// @access  Admin or User (own tickets)
exports.getSupportTickets = async (req, res) => {
  try {
    const userId = req.user.userId;
    const userRole = req.user.role;
    const { status, priority, limit = 50, offset = 0 } = req.query;

    let whereConditions = [];
    let params = [];
    let paramIndex = 1;

    // Non-admin users can only see their own tickets
    if (userRole !== 'admin') {
      whereConditions.push(`st.user_id = $${paramIndex}`);
      params.push(userId);
      paramIndex++;
    }

    if (status) {
      whereConditions.push(`st.status = $${paramIndex}`);
      params.push(status);
      paramIndex++;
    }

    if (priority) {
      whereConditions.push(`st.priority = $${paramIndex}`);
      params.push(priority);
      paramIndex++;
    }

    const whereClause = whereConditions.length > 0 ? `WHERE ${whereConditions.join(' AND ')}` : '';

    params.push(parseInt(limit), parseInt(offset));

    const result = await db.query(`
      SELECT 
        st.id, st.user_id, st.subject, st.description, st.status, 
        st.priority, st.category, st.created_at, st.updated_at, st.resolved_at,
        u.email as user_email,
        COUNT(tm.id) as message_count
      FROM support_tickets st
      LEFT JOIN users u ON st.user_id = u.id
      LEFT JOIN ticket_messages tm ON st.id = tm.ticket_id
      ${whereClause}
      GROUP BY st.id, u.email
      ORDER BY st.created_at DESC
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `, params);

    // Get ticket statistics for admin
    let statistics = null;
    if (userRole === 'admin') {
      const statsResult = await db.query(`
        SELECT 
          status,
          COUNT(*) as count
        FROM support_tickets
        GROUP BY status
      `);
      statistics = statsResult.rows;
    }

    res.status(200).json({
      success: true,
      data: {
        tickets: result.rows,
        statistics,
        pagination: {
          limit: parseInt(limit),
          offset: parseInt(offset)
        }
      }
    });
  } catch (error) {
    console.error('Error fetching support tickets:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch support tickets',
      details: error.message
    });
  }
};

// @desc    Get single support ticket with messages
// @route   GET /api/support/tickets/:id
// @access  Admin or Ticket Owner
exports.getSupportTicket = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;
    const userRole = req.user.role;

    // Get ticket details
    const ticketResult = await db.query(`
      SELECT 
        st.id, st.user_id, st.subject, st.description, st.status, 
        st.priority, st.category, st.created_at, st.updated_at, st.resolved_at,
        u.email as user_email, u.user_role
      FROM support_tickets st
      LEFT JOIN users u ON st.user_id = u.id
      WHERE st.id = $1
    `, [id]);

    if (ticketResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Support ticket not found'
      });
    }

    const ticket = ticketResult.rows[0];

    // Check access permissions
    if (userRole !== 'admin' && ticket.user_id !== userId) {
      return res.status(403).json({
        success: false,
        error: 'You can only access your own tickets'
      });
    }

    // Get ticket messages
    const messagesResult = await db.query(`
      SELECT 
        tm.id, tm.message, tm.is_staff_reply, tm.created_at,
        u.email as sender_email
      FROM ticket_messages tm
      LEFT JOIN users u ON tm.sender_id = u.id
      WHERE tm.ticket_id = $1
      ORDER BY tm.created_at ASC
    `, [id]);

    res.status(200).json({
      success: true,
      data: {
        ticket,
        messages: messagesResult.rows
      }
    });
  } catch (error) {
    console.error('Error fetching support ticket:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch support ticket',
      details: error.message
    });
  }
};

// @desc    Create new support ticket
// @route   POST /api/support/tickets
// @access  Private
exports.createSupportTicket = async (req, res) => {
  try {
    const { subject, description, priority = 'medium', category } = req.body;
    const userId = req.user.userId;

    if (!subject || !description) {
      return res.status(400).json({
        success: false,
        error: 'Subject and description are required'
      });
    }

    const result = await db.query(`
      INSERT INTO support_tickets (user_id, subject, description, priority, category)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `, [userId, subject, description, priority, category]);

    // Create initial message
    await db.query(`
      INSERT INTO ticket_messages (ticket_id, sender_id, message, is_staff_reply)
      VALUES ($1, $2, $3, false)
    `, [result.rows[0].id, userId, description]);

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: 'Support ticket created successfully'
    });
  } catch (error) {
    console.error('Error creating support ticket:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create support ticket',
      details: error.message
    });
  }
};

// @desc    Add message to support ticket
// @route   POST /api/support/tickets/:id/messages
// @access  Admin or Ticket Owner
exports.addTicketMessage = async (req, res) => {
  try {
    const { id } = req.params;
    const { message } = req.body;
    const userId = req.user.userId;
    const userRole = req.user.role;

    if (!message) {
      return res.status(400).json({
        success: false,
        error: 'Message is required'
      });
    }

    // Check if ticket exists and user has access
    const ticketResult = await db.query(`
      SELECT user_id FROM support_tickets WHERE id = $1
    `, [id]);

    if (ticketResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Support ticket not found'
      });
    }

    const ticket = ticketResult.rows[0];

    // Check access permissions
    if (userRole !== 'admin' && ticket.user_id !== userId) {
      return res.status(403).json({
        success: false,
        error: 'You can only reply to your own tickets'
      });
    }

    // Add message
    const messageResult = await db.query(`
      INSERT INTO ticket_messages (ticket_id, sender_id, message, is_staff_reply)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `, [id, userId, message, userRole === 'admin']);

    // Update ticket status if it was resolved and user replied
    if (userRole !== 'admin') {
      await db.query(`
        UPDATE support_tickets
        SET status = 'open', updated_at = CURRENT_TIMESTAMP
        WHERE id = $1 AND status = 'resolved'
      `, [id]);
    }

    res.status(201).json({
      success: true,
      data: messageResult.rows[0],
      message: 'Message added successfully'
    });
  } catch (error) {
    console.error('Error adding ticket message:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to add message',
      details: error.message
    });
  }
};

// @desc    Update support ticket status
// @route   PUT /api/support/tickets/:id/status
// @access  Admin
exports.updateTicketStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const adminId = req.user.userId;

    if (!status) {
      return res.status(400).json({
        success: false,
        error: 'Status is required'
      });
    }

    const validStatuses = ['open', 'in_progress', 'resolved', 'closed'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid status. Must be one of: ' + validStatuses.join(', ')
      });
    }

    const resolvedAt = status === 'resolved' ? 'CURRENT_TIMESTAMP' : 'NULL';

    const result = await db.query(`
      UPDATE support_tickets
      SET status = $1, updated_at = CURRENT_TIMESTAMP, resolved_at = ${resolvedAt}
      WHERE id = $2
      RETURNING *
    `, [status, id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Support ticket not found'
      });
    }

    // Log the status change
    await db.query(`
      INSERT INTO audit_logs (user_id, action, table_name, record_id, new_values)
      VALUES ($1, 'UPDATE', 'support_tickets', $2, $3)
    `, [adminId, id, JSON.stringify({ status })]);

    res.status(200).json({
      success: true,
      data: result.rows[0],
      message: 'Ticket status updated successfully'
    });
  } catch (error) {
    console.error('Error updating ticket status:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update ticket status',
      details: error.message
    });
  }
};

// @desc    Delete support ticket
// @route   DELETE /api/support/tickets/:id
// @access  Admin
exports.deleteSupportTicket = async (req, res) => {
  try {
    const { id } = req.params;
    const adminId = req.user.userId;

    // Delete messages first (foreign key constraint)
    await db.query('DELETE FROM ticket_messages WHERE ticket_id = $1', [id]);

    // Delete ticket
    const result = await db.query('DELETE FROM support_tickets WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Support ticket not found'
      });
    }

    // Log the deletion
    await db.query(`
      INSERT INTO audit_logs (user_id, action, table_name, record_id, old_values)
      VALUES ($1, 'DELETE', 'support_tickets', $2, $3)
    `, [adminId, id, JSON.stringify(result.rows[0])]);

    res.status(200).json({
      success: true,
      message: 'Support ticket deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting support ticket:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete support ticket',
      details: error.message
    });
  }
};

module.exports = exports;