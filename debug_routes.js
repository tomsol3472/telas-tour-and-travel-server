const express = require('express');
const bookingRoutes = require('./routes/bookingRoutes');

const app = express();

// Add the booking routes
app.use('/api/bookings', bookingRoutes);

// Debug: List all registered routes
function listRoutes(app) {
  const routes = [];
  
  app._router.stack.forEach(function(middleware) {
    if (middleware.route) {
      // Routes registered directly on the app
      routes.push({
        method: Object.keys(middleware.route.methods)[0].toUpperCase(),
        path: middleware.route.path
      });
    } else if (middleware.name === 'router') {
      // Router middleware
      middleware.handle.stack.forEach(function(handler) {
        if (handler.route) {
          const basePath = middleware.regexp.source
            .replace('\\/?', '')
            .replace('(?=\\/|$)', '')
            .replace(/\\\//g, '/')
            .replace(/\$.*/, '');
          
          routes.push({
            method: Object.keys(handler.route.methods)[0].toUpperCase(),
            path: basePath + handler.route.path
          });
        }
      });
    }
  });
  
  return routes;
}

console.log('🔍 Registered booking routes:');
const routes = listRoutes(app);
routes.forEach(route => {
  console.log(`${route.method} ${route.path}`);
});

console.log('\n🧪 Testing route matching:');
console.log('Route pattern for GET /:id should match:');
console.log('- /api/bookings/12ac405e-385d-4df4-8bed-f3bbe1cd8880');
console.log('- /api/bookings/TEL-2605-000015');

// Test the route pattern
const testPaths = [
  '/api/bookings/12ac405e-385d-4df4-8bed-f3bbe1cd8880',
  '/api/bookings/TEL-2605-000015',
  '/api/bookings/admin/all'
];

testPaths.forEach(path => {
  const req = { method: 'GET', url: path };
  const match = app._router.handle(req, {}, () => {});
  console.log(`${path}: ${match ? '✅ Match' : '❌ No match'}`);
});