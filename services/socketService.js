const socketIo = require('socket.io');

let io;

exports.init = (server) => {
  io = socketIo(server, {
    cors: { origin: "*" }
  });

  io.on('connection', (socket) => {
    console.log('Client connected:', socket.id);

    // User joins their personal notification room
    socket.on('joinUser', (userId) => {
      socket.join(`user_${userId}`);
      console.log(`User ${userId} joined notification room`);
    });

    // User joins conversation room for group chat
    socket.on('joinConversation', (conversationId) => {
      socket.join(`conversation_${conversationId}`);
      console.log(`Client joined conversation room: conversation_${conversationId}`);
    });

    // User leaves conversation room
    socket.on('leaveConversation', (conversationId) => {
      socket.leave(`conversation_${conversationId}`);
      console.log(`Client left conversation room: conversation_${conversationId}`);
    });

    // Driver sends location
    socket.on('updateLocation', async (data) => {
      const { bookingId, lat, lng } = data;
      
      // Save to DB (Trip Tracking Table)
      // await db.query(...)
      
      // Emit to Tourist assigned to this booking
      io.to(`booking_${bookingId}`).emit('driverLocation', { lat, lng });
    });

    // Tourist joins booking room
    socket.on('joinTrip', (bookingId) => {
      socket.join(`booking_${bookingId}`);
      console.log(`Client joined booking room: booking_${bookingId}`);
    });

    // Staff joins booking room for group chat
    socket.on('joinBooking', (bookingId) => {
      socket.join(`booking_${bookingId}`);
      console.log(`Client joined booking room: booking_${bookingId}`);
    });

    // Handle assignment confirmation via WebSocket
    socket.on('confirmAssignment', async (data) => {
      const { bookingId, staffType, confirmed, userId } = data;
      
      // Broadcast confirmation to booking room
      io.to(`booking_${bookingId}`).emit('assignmentResponse', {
        booking_id: bookingId,
        staff_type: staffType,
        confirmed: confirmed,
        timestamp: new Date().toISOString()
      });
    });

    // Handle typing indicator
    socket.on('typing', (data) => {
      const { conversationId, userId, userName } = data;
      socket.to(`conversation_${conversationId}`).emit('userTyping', {
        userId,
        userName
      });
    });

    // Handle stop typing
    socket.on('stopTyping', (data) => {
      const { conversationId, userId } = data;
      socket.to(`conversation_${conversationId}`).emit('userStoppedTyping', {
        userId
      });
    });

    socket.on('disconnect', () => console.log('Client disconnected'));
  });
};

exports.getIo = () => {
  if (!io) throw new Error("Socket not initialized");
  return io;
};

exports.sendToUser = (userId, event, data) => {
  if (!io) throw new Error("Socket not initialized");
  io.to(`user_${userId}`).emit(event, data);
};

exports.sendToConversation = (conversationId, event, data) => {
  if (!io) throw new Error("Socket not initialized");
  io.to(`conversation_${conversationId}`).emit(event, data);
};

exports.sendToBooking = (bookingId, event, data) => {
  if (!io) throw new Error("Socket not initialized");
  io.to(`booking_${bookingId}`).emit(event, data);
};