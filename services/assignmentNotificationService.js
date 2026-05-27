const db = require('../config/db');
const socketService = require('./socketService');

class AssignmentNotificationService {
  constructor() {
    this.pendingAssignments = new Map(); // Store pending assignments with timeouts
    this.RESPONSE_TIMEOUT = 60 * 60 * 1000; // 1 hour in milliseconds
  }

  /**
   * Send assignment notification to staff and start timeout
   */
  async notifyStaffAssignment(bookingId, staffType, staffId, staffName, bookingDetails) {
    try {
      console.log(`📢 Sending ${staffType} assignment notification for booking ${bookingId}`);

      // Get staff user_id
      const staffUserResult = await db.query(`
        SELECT user_id FROM ${staffType}s WHERE id = $1
      `, [staffId]);

      if (staffUserResult.rows.length === 0) {
        console.log(`⚠️  ${staffType} not found`);
        return;
      }

      const staffUserId = staffUserResult.rows[0].user_id;

      // Create notification in database for staff
      const notification = await db.query(`
        INSERT INTO notifications (
          user_id, 
          notification_type, 
          title, 
          message, 
          data, 
          priority, 
          expires_at,
          action_url
        ) VALUES (
          $1,
          'assignment_request',
          'New Tour Assignment',
          $2,
          $3,
          'high',
          NOW() + INTERVAL '1 hour',
          $4
        ) RETURNING id
      `, [
        staffUserId,
        `You have been assigned to ${bookingDetails.tour_name || 'a tour'} starting ${bookingDetails.start_date}. Please confirm within 1 hour.`,
        JSON.stringify({
          booking_id: bookingId,
          booking_code: bookingDetails.booking_code,
          staff_type: staffType,
          staff_id: staffId,
          tour_name: bookingDetails.tour_name,
          start_date: bookingDetails.start_date,
          tourist_name: bookingDetails.tourist_name
        }),
        `/chat/booking/${bookingId}`
      ]);

      // Send real-time notification via WebSocket to staff (if available)
      try {
        const io = socketService.getIo();
        io.to(`user_${staffUserId}`).emit('assignment_notification', {
          type: 'assignment_request',
          booking_id: bookingId,
          booking_code: bookingDetails.booking_code,
          staff_type: staffType,
          message: `New ${staffType} assignment for ${bookingDetails.tour_name}`,
          action_url: `/chat/booking/${bookingId}`,
          expires_at: new Date(Date.now() + this.RESPONSE_TIMEOUT).toISOString()
        });
      } catch (socketError) {
        console.log('WebSocket not available for assignment notification:', socketError.message);
      }

      // Send notification to tourist
      if (bookingDetails.tourist_user_id) {
        await db.query(`
          INSERT INTO notifications (
            user_id,
            notification_type,
            title,
            message,
            data,
            priority,
            action_url
          ) VALUES ($1, 'staff_assigned', 'Staff Assigned to Your Tour', $2, $3, 'normal', $4)
        `, [
          bookingDetails.tourist_user_id,
          `A ${staffType} has been assigned to your tour: ${staffName}`,
          JSON.stringify({
            booking_id: bookingId,
            booking_code: bookingDetails.booking_code,
            staff_type: staffType,
            staff_name: staffName
          }),
          `/chat/booking/${bookingId}`
        ]);

        try {
          const io = socketService.getIo();
          io.to(`user_${bookingDetails.tourist_user_id}`).emit('staff_assigned_notification', {
            type: 'staff_assigned',
            booking_id: bookingId,
            booking_code: bookingDetails.booking_code,
            staff_type: staffType,
            staff_name: staffName,
            message: `${staffName} has been assigned as your ${staffType}`,
            action_url: `/chat/booking/${bookingId}`
          });
        } catch (socketError) {
          console.log('WebSocket not available for tourist notification:', socketError.message);
        }
      }

      // Send notification to admin users
      const adminUsers = await db.query(`
        SELECT id FROM users WHERE user_role IN ('admin', 'agency_staff')
      `);

      for (const admin of adminUsers.rows) {
        await db.query(`
          INSERT INTO notifications (
            user_id,
            notification_type,
            title,
            message,
            data,
            priority,
            action_url
          ) VALUES ($1, 'assignment_made', 'Staff Assignment Made', $2, $3, 'low', $4)
        `, [
          admin.id,
          `${staffName} assigned as ${staffType} for booking ${bookingDetails.booking_code}`,
          JSON.stringify({
            booking_id: bookingId,
            booking_code: bookingDetails.booking_code,
            staff_type: staffType,
            staff_name: staffName
          }),
          `/chat/booking/${bookingId}`
        ]);

        try {
          const io = socketService.getIo();
          io.to(`user_${admin.id}`).emit('assignment_made_notification', {
            type: 'assignment_made',
            booking_id: bookingId,
            booking_code: bookingDetails.booking_code,
            staff_type: staffType,
            staff_name: staffName,
            action_url: `/chat/booking/${bookingId}`
          });
        } catch (socketError) {
          console.log('WebSocket not available for admin notification:', socketError.message);
        }
      }

      // Send group chat message
      await this.sendGroupChatMessage(bookingId, {
        type: 'system',
        message: `${staffName} has been assigned as ${staffType}. Waiting for confirmation...`,
        data: {
          staff_type: staffType,
          staff_name: staffName,
          status: 'pending_confirmation'
        }
      });

      // Set timeout for automatic reassignment
      const timeoutKey = `${bookingId}_${staffType}`;
      this.pendingAssignments.set(timeoutKey, {
        bookingId,
        staffType,
        staffId,
        staffName,
        bookingDetails,
        notificationId: notification.rows[0].id,
        timeout: setTimeout(() => {
          this.handleAssignmentTimeout(bookingId, staffType, staffId, staffName, bookingDetails);
        }, this.RESPONSE_TIMEOUT)
      });

      console.log(`⏰ Set ${this.RESPONSE_TIMEOUT / 1000 / 60} minute timeout for ${staffType} assignment`);

    } catch (error) {
      console.error('❌ Error sending assignment notification:', error);
      throw error;
    }
  }

  /**
   * Handle staff confirmation of assignment
   */
  async confirmAssignment(bookingId, staffType, staffId, confirmed = true) {
    const timeoutKey = `${bookingId}_${staffType}`;
    const pendingAssignment = this.pendingAssignments.get(timeoutKey);

    if (!pendingAssignment) {
      console.log(`⚠️  No pending assignment found for ${timeoutKey}`);
      return false;
    }

    try {
      // Clear the timeout
      clearTimeout(pendingAssignment.timeout);
      this.pendingAssignments.delete(timeoutKey);

      if (confirmed) {
        // Update booking status to confirmed
        await db.query(`
          UPDATE bookings 
          SET status = 'confirmed'
          WHERE id = $1 OR booking_code = $1
        `, [bookingId]);

        // Mark notification as read
        await db.query(`
          UPDATE notifications 
          SET is_read = true, read_at = NOW()
          WHERE id = $1
        `, [pendingAssignment.notificationId]);

        // Send confirmation to group chat
        await this.sendGroupChatMessage(bookingId, {
          type: 'system',
          message: `✅ ${pendingAssignment.staffName} confirmed ${staffType} assignment`,
          data: {
            staff_type: staffType,
            staff_name: pendingAssignment.staffName,
            status: 'confirmed'
          }
        });

        // Notify via WebSocket (if available)
        try {
          const io = socketService.getIo();
          io.to(`booking_${bookingId}`).emit('assignment_confirmed', {
            booking_id: bookingId,
            staff_type: staffType,
            staff_name: pendingAssignment.staffName,
            confirmed: true
          });
        } catch (socketError) {
          console.log('WebSocket not available for assignment confirmation:', socketError.message);
        }

        console.log(`✅ ${staffType} assignment confirmed for booking ${bookingId}`);
        return true;

      } else {
        // Staff declined - trigger automatic reassignment
        console.log(`❌ ${staffType} assignment declined for booking ${bookingId}`);
        await this.handleAssignmentDeclined(bookingId, staffType, pendingAssignment);
        return false;
      }

    } catch (error) {
      console.error('❌ Error confirming assignment:', error);
      throw error;
    }
  }

  /**
   * Handle assignment timeout - automatically assign to next best staff
   */
  async handleAssignmentTimeout(bookingId, staffType, staffId, staffName, bookingDetails) {
    console.log(`⏰ Assignment timeout for ${staffType} ${staffName} on booking ${bookingId}`);

    try {
      // Mark original notification as expired
      await db.query(`
        UPDATE notifications 
        SET message = message || ' (EXPIRED - No response)',
          priority = 'low'
        WHERE user_id = (SELECT user_id FROM ${staffType}s WHERE id = $1)
          AND notification_type = 'assignment_request'
          AND data->>'booking_id' = $2
          AND is_read = false
      `, [staffId, bookingId]);

      // Send timeout message to group chat
      await this.sendGroupChatMessage(bookingId, {
        type: 'system',
        message: `⏰ ${staffName} did not respond to ${staffType} assignment within 1 hour. Finding alternative...`,
        data: {
          staff_type: staffType,
          staff_name: staffName,
          status: 'timeout'
        }
      });

      // Find next best available staff
      await this.autoReassign(bookingId, staffType, [staffId], bookingDetails);

    } catch (error) {
      console.error('❌ Error handling assignment timeout:', error);
    }
  }

  /**
   * Handle assignment declined by staff
   */
  async handleAssignmentDeclined(bookingId, staffType, pendingAssignment) {
    try {
      // Send decline message to group chat
      await this.sendGroupChatMessage(bookingId, {
        type: 'system',
        message: `❌ ${pendingAssignment.staffName} declined ${staffType} assignment. Finding alternative...`,
        data: {
          staff_type: staffType,
          staff_name: pendingAssignment.staffName,
          status: 'declined'
        }
      });

      // Find next best available staff
      await this.autoReassign(bookingId, staffType, [pendingAssignment.staffId], pendingAssignment.bookingDetails);

    } catch (error) {
      console.error('❌ Error handling assignment decline:', error);
    }
  }

  /**
   * Automatically reassign to next best available staff
   */
  async autoReassign(bookingId, staffType, excludeStaffIds = [], bookingDetails) {
    try {
      console.log(`🔄 Auto-reassigning ${staffType} for booking ${bookingId}`);

      // Get next best available staff (excluding those who already declined/timed out)
      const excludeClause = excludeStaffIds.length > 0 
        ? `AND s.id NOT IN (${excludeStaffIds.map((_, i) => `$${i + 2}`).join(', ')})`
        : '';

      const staffQuery = `
        SELECT s.id, u.email as name, s.rating, s.years_experience, s.is_available
        FROM ${staffType}s s
        JOIN users u ON s.user_id = u.id
        WHERE s.is_available = true 
          AND u.status = 'active'
          ${excludeClause}
        ORDER BY s.rating DESC, s.years_experience DESC
        LIMIT 1
      `;

      const staffResult = await db.query(staffQuery, [bookingId, ...excludeStaffIds]);

      if (staffResult.rows.length === 0) {
        // No more staff available - escalate to admin
        await this.escalateToAdmin(bookingId, staffType, bookingDetails);
        return;
      }

      const nextStaff = staffResult.rows[0];

      // Update booking with new assignment
      const updateField = staffType === 'guide' ? 'assigned_guide_id' : 'assigned_driver_id';
      const nameField = staffType === 'guide' ? 'guide_name' : 'driver_name';

      await db.query(`
        UPDATE bookings 
        SET ${updateField} = $1, ${nameField} = $2
        WHERE id = $3 OR booking_code = $3
      `, [nextStaff.id, nextStaff.name, bookingId]);

      // Send new assignment notification
      await this.notifyStaffAssignment(bookingId, staffType, nextStaff.id, nextStaff.name, bookingDetails);

      console.log(`✅ Auto-reassigned ${staffType} to ${nextStaff.name} for booking ${bookingId}`);

    } catch (error) {
      console.error('❌ Error in auto-reassignment:', error);
      await this.escalateToAdmin(bookingId, staffType, bookingDetails);
    }
  }

  /**
   * Escalate to admin when no staff available
   */
  async escalateToAdmin(bookingId, staffType, bookingDetails) {
    try {
      console.log(`🚨 Escalating ${staffType} assignment to admin for booking ${bookingId}`);

      // Get all admin users
      const admins = await db.query(`
        SELECT id FROM users 
        WHERE user_role IN ('admin', 'agency_staff') 
          AND status = 'active'
      `);

      // Send notification to all admins
      for (const admin of admins.rows) {
        await db.query(`
          INSERT INTO notifications (
            user_id, 
            notification_type, 
            title, 
            message, 
            data, 
            priority,
            action_url
          ) VALUES ($1, 'assignment_escalation', 'Urgent: Manual Assignment Required', $2, $3, 'urgent', $4)
        `, [
          admin.id,
          `No available ${staffType} found for booking ${bookingDetails.booking_code}. Manual assignment required.`,
          JSON.stringify({
            booking_id: bookingId,
            booking_code: bookingDetails.booking_code,
            staff_type: staffType,
            escalation_reason: 'no_available_staff'
          }),
          `/booking/upcoming/${bookingId}`
        ]);
      }

      // Send escalation message to group chat
      await this.sendGroupChatMessage(bookingId, {
        type: 'system',
        message: `🚨 Unable to find available ${staffType}. Admin intervention required.`,
        data: {
          staff_type: staffType,
          status: 'escalated_to_admin'
        }
      });

      // Notify via WebSocket (if available)
      try {
        const io = socketService.getIo();
        io.emit('assignment_escalation', {
          booking_id: bookingId,
          booking_code: bookingDetails.booking_code,
          staff_type: staffType,
          message: `Manual ${staffType} assignment required`
        });
      } catch (socketError) {
        console.log('WebSocket not available for escalation notification:', socketError.message);
      }

    } catch (error) {
      console.error('❌ Error escalating to admin:', error);
    }
  }

  /**
   * Send message to booking group chat
   */
  async sendGroupChatMessage(bookingId, messageData) {
    try {
      // Check if group chat exists for this booking
      let conversationResult = await db.query(`
        SELECT id FROM chat_conversations 
        WHERE group_name = $1 AND is_group_chat = true
      `, [`Booking ${bookingId} Chat`]);

      let conversationId;

      if (conversationResult.rows.length === 0) {
        // Create group chat for this booking
        const newConversation = await db.query(`
          INSERT INTO chat_conversations (
            is_group_chat, 
            group_name, 
            created_by
          ) VALUES (true, $1, (SELECT id FROM users WHERE user_role = 'admin' LIMIT 1))
          RETURNING id
        `, [`Booking ${bookingId} Chat`]);

        conversationId = newConversation.rows[0].id;

        // Add relevant participants (tourist, assigned staff, admins)
        const participants = await db.query(`
          SELECT DISTINCT u.id as user_id
          FROM bookings b
          LEFT JOIN tourists t ON b.tourist_id = t.id
          LEFT JOIN guides g ON b.assigned_guide_id = g.id
          LEFT JOIN drivers d ON b.assigned_driver_id = d.id
          LEFT JOIN users u ON u.id IN (t.user_id, g.user_id, d.user_id)
          WHERE b.id = $1 OR b.booking_code = $1
          UNION
          SELECT id as user_id FROM users WHERE user_role IN ('admin', 'agency_staff')
        `, [bookingId]);

        for (const participant of participants.rows) {
          if (participant.user_id) {
            await db.query(`
              INSERT INTO chat_participants (conversation_id, user_id)
              VALUES ($1, $2)
              ON CONFLICT (conversation_id, user_id) DO NOTHING
            `, [conversationId, participant.user_id]);
          }
        }
      } else {
        conversationId = conversationResult.rows[0].id;
      }

      // Send the message
      const systemUserId = await db.query(`
        SELECT id FROM users WHERE user_role = 'admin' LIMIT 1
      `);

      await db.query(`
        INSERT INTO chat_messages (
          conversation_id,
          sender_id,
          message_type,
          message_text
        ) VALUES ($1, $2, 'system', $3)
      `, [
        conversationId,
        systemUserId.rows[0]?.id,
        messageData.message
      ]);

      // Emit to WebSocket (if available)
      try {
        const io = socketService.getIo();
        io.to(`booking_${bookingId}`).emit('group_chat_message', {
          conversation_id: conversationId,
          type: 'system',
          message: messageData.message,
          data: messageData.data,
          timestamp: new Date().toISOString()
        });
      } catch (socketError) {
        console.log('WebSocket not available for group chat message:', socketError.message);
      }

    } catch (error) {
      console.error('❌ Error sending group chat message:', error);
    }
  }

  /**
   * Clean up expired assignments
   */
  cleanup() {
    const now = Date.now();
    for (const [key, assignment] of this.pendingAssignments.entries()) {
      if (assignment.createdAt && (now - assignment.createdAt) > this.RESPONSE_TIMEOUT) {
        clearTimeout(assignment.timeout);
        this.pendingAssignments.delete(key);
      }
    }
  }
}

// Create singleton instance
const assignmentNotificationService = new AssignmentNotificationService();

// Clean up expired assignments every 5 minutes
setInterval(() => {
  assignmentNotificationService.cleanup();
}, 5 * 60 * 1000);

module.exports = assignmentNotificationService;