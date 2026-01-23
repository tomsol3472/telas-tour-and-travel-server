const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const http = require('http');
const swaggerUI = require('swagger-ui-express');
const swaggerSpec = require('./config/swagger');
const socketService = require('./services/socketService');

// Load Config
dotenv.config();

// Connect DB
const db = require('./config/db');

// Init App
const app = express();
const server = http.createServer(app);

// Init Socket.io
socketService.init(server);

// Middleware
app.use(helmet()); // Security Headers
app.use(cors()); // Enable CORS
app.use(express.json()); // Body Parser
app.use(morgan('dev')); // Logger

// Routes
const authRoutes = require('./routes/authRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
// const adminRoutes = require('./routes/adminRoutes'); // (Create similarly)

app.use('/api/auth', authRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/payments', paymentRoutes);

// Docs
app.use('/api-docs', swaggerUI.serve, swaggerUI.setup(swaggerSpec));

// Error Handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: err.message || 'Server Error'
  });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));