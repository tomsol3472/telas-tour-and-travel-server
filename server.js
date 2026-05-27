const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const http = require('http');
const path = require('path');
const fs = require('fs');

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}

const swaggerUI = require('swagger-ui-express');
const swaggerSpec = require('./config/swagger');
const socketService = require('./services/socketService');

// Load env
dotenv.config();

// DB connect
const db = require('./config/db');

const app = express();
const server = http.createServer(app);

// Init Socket.io
socketService.init(server);

// Security / logging
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  })
);

app.use(
  cors({
    origin: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
    credentials: true,
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

app.use(express.json());
app.use(morgan('dev'));

// DATABASE LOGGER MIDDLEWARE
app.use((req, res, next) => {
  const start = process.hrtime();
  
  res.on('finish', () => {
    if (req.originalUrl.includes('/api/settings/system/logs')) return;

    const diff = process.hrtime(start);
    const time = (diff[0] * 1e3 + diff[1] * 1e-6).toFixed(3);
    const logMessage = `${req.method} ${req.originalUrl} ${res.statusCode} ${time} ms`;

    let level = 'INFO';
    if (res.statusCode >= 200 && res.statusCode < 400) level = 'SUCCESS';
    else if (res.statusCode >= 400 && res.statusCode < 500) level = 'WARNING';
    else if (res.statusCode >= 500) level = 'ERROR';

    const query = `
      INSERT INTO system_app_logs (level, category, message) 
      VALUES ($1, 'HTTP_REQUEST', $2)
    `;
    
    if (db && typeof db.query === 'function') {
      db.query(query, [level, logMessage]).catch(err => {
        console.error('Failed to write log to DB:', err);
      });
    }
  });

  next();
});

// Static uploads
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
const authRoutes = require('./routes/authRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const packageRoutes = require('./routes/packageRoutes');
const tourRoutes = require('./routes/tourRoutes');
const userRoutes = require('./routes/userRoutes');
const bookingSummaryRoutes = require('./routes/bookingSummary');
const locationRoutes = require('./routes/locationroutes');
const financeRoutes = require('./routes/financeRoutes');
const businessRulesRoutes = require('./routes/businessRulesRoutes');
const nearbyRoutes = require('./routes/nearbyRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const groupChatRoutes = require('./routes/groupChatRoutes');
const walletRoutes = require('./routes/walletRoutes');
const settingsRoutes = require('./routes/settingsRoutes');
const maintenanceRoutes = require('./routes/maintenanceRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');
const supportRoutes = require('./routes/supportRoutes');

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/packages', packageRoutes);
app.use('/api/tours', tourRoutes);
app.use('/api/finance', financeRoutes);
app.use('/api/business-rules', businessRulesRoutes);
app.use('/api/nearby', nearbyRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/chat', groupChatRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/maintenance', maintenanceRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/support', supportRoutes);
app.use('/api', bookingSummaryRoutes); 
app.use('/api', locationRoutes);       

app.use('/api-docs', swaggerUI.serve, swaggerUI.setup(swaggerSpec));

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  if (db && typeof db.query === 'function') {
    db.query(`INSERT INTO system_app_logs (level, category, message) VALUES ('ERROR', 'SERVER_ERROR', $1)`, [err.message]).catch(e => {
        console.error('Failed to write SERVER_ERROR log to DB:', e);
    });
  }
  res.status(500).json({ success: false, error: err.message || 'Server Error' });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, '0.0.0.0', () => console.log(`🚀 Server running on port ${PORT} across local network`));