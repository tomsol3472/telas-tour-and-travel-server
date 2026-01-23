const socketIo = require('socket.io');

let io;

exports.init = (server) => {
  io = socketIo(server, {
    cors: { origin: "*" }
  });

  io.on('connection', (socket) => {
    console.log('Client connected:', socket.id);

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
    });

    socket.on('disconnect', () => console.log('Client disconnected'));
  });
};

exports.getIo = () => {
  if (!io) throw new Error("Socket not initialized");
  return io;
};