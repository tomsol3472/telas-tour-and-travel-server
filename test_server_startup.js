// Quick test to see if server.js can be loaded without errors
console.log('Testing server startup...');

try {
    // Just try to require the main modules to see if there are syntax errors
    const express = require('express');
    const walletRoutes = require('./routes/walletRoutes');
    const notificationRoutes = require('./routes/notificationRoutes');
    const groupChatRoutes = require('./routes/groupChatRoutes');
    
    console.log('✅ All route modules loaded successfully');
    console.log('✅ walletRoutes:', typeof walletRoutes);
    console.log('✅ notificationRoutes:', typeof notificationRoutes);
    console.log('✅ groupChatRoutes:', typeof groupChatRoutes);
    
    process.exit(0);
} catch (error) {
    console.error('❌ Error loading modules:', error.message);
    console.error(error.stack);
    process.exit(1);
}
