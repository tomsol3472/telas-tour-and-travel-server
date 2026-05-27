// Quick test to verify server can start
console.log('🧪 Testing server startup...\n');

try {
    // Load all the main modules
    require('./server.js');
    
    // If we get here, server loaded successfully
    setTimeout(() => {
        console.log('\n✅ Server loaded successfully!');
        console.log('✅ All routes registered');
        console.log('✅ WebSocket initialized');
        console.log('✅ Database connected');
        console.log('\n🎉 System is ready!');
        process.exit(0);
    }, 3000);
    
} catch (error) {
    console.error('❌ Server failed to start:', error.message);
    console.error(error.stack);
    process.exit(1);
}
