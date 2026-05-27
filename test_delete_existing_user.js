/**
 * Test Delete Existing User
 * This script tests deleting an actual user from the database
 */

const db = require('./config/db');

async function testDeleteExistingUser() {
    console.log('🔍 Testing delete with existing user...');
    
    try {
        // Get a tourist user (safest to delete)
        console.log('\n1. Finding a tourist user to delete...');
        const touristResult = await db.query(`
            SELECT u.id, u.email, u.user_role 
            FROM users u 
            WHERE u.user_role = 'tourist' 
            AND u.email LIKE '%test%' 
            LIMIT 1
        `);
        
        if (touristResult.rows.length === 0) {
            console.log('No test tourist users found. Creating one...');
            
            // Create a test tourist user
            const createResult = await db.query(`
                INSERT INTO users (email, password_hash, user_role, status, phone) 
                VALUES ($1, $2, $3, $4, $5) 
                RETURNING id, email
            `, ['test-tourist-delete@example.com', 'test-hash', 'tourist', 'active', '0911111111']);
            
            console.log('Created test user:', createResult.rows[0]);
            
            // Also create a profile for this user
            await db.query(`
                INSERT INTO user_profiles (user_id, first_name, last_name) 
                VALUES ($1, $2, $3)
            `, [createResult.rows[0].id, 'Test', 'Tourist']);
            
            // And tourist record
            await db.query(`
                INSERT INTO tourists (user_id, travel_frequency) 
                VALUES ($1, $2)
            `, [createResult.rows[0].id, 0]);
            
            console.log('Created profile and tourist record');
            
            var userToDelete = createResult.rows[0];
        } else {
            var userToDelete = touristResult.rows[0];
            console.log('Found existing user to delete:', userToDelete);
        }
        
        // Now test the delete function (same as in controller)
        console.log('\n2. Testing delete function...');
        const userId = userToDelete.id;
        
        await db.query('BEGIN');
        console.log('✅ Transaction started');
        
        // Delete in the same order as the controller
        console.log('Deleting related data...');
        
        const deleteResults = [];
        
        // 1. Delete wallet-related data
        let result = await db.query('DELETE FROM staff_withdrawals WHERE user_id = $1', [userId]);
        deleteResults.push({ table: 'staff_withdrawals', count: result.rowCount });
        
        result = await db.query('DELETE FROM staff_wallets WHERE user_id = $1', [userId]);
        deleteResults.push({ table: 'staff_wallets', count: result.rowCount });
        
        // 2. Delete notification and communication data
        result = await db.query('DELETE FROM notifications WHERE user_id = $1', [userId]);
        deleteResults.push({ table: 'notifications', count: result.rowCount });
        
        result = await db.query('DELETE FROM chat_participants WHERE user_id = $1', [userId]);
        deleteResults.push({ table: 'chat_participants', count: result.rowCount });
        
        // 3. Delete support and verification data
        result = await db.query('DELETE FROM support_tickets WHERE user_id = $1', [userId]);
        deleteResults.push({ table: 'support_tickets', count: result.rowCount });
        
        result = await db.query('DELETE FROM verification_documents WHERE user_id = $1', [userId]);
        deleteResults.push({ table: 'verification_documents', count: result.rowCount });
        
        // 4. Delete role-specific data
        result = await db.query('DELETE FROM user_profiles WHERE user_id = $1', [userId]);
        deleteResults.push({ table: 'user_profiles', count: result.rowCount });
        
        result = await db.query('DELETE FROM tourists WHERE user_id = $1', [userId]);
        deleteResults.push({ table: 'tourists', count: result.rowCount });
        
        result = await db.query('DELETE FROM guides WHERE user_id = $1', [userId]);
        deleteResults.push({ table: 'guides', count: result.rowCount });
        
        result = await db.query('DELETE FROM drivers WHERE user_id = $1', [userId]);
        deleteResults.push({ table: 'drivers', count: result.rowCount });
        
        // 5. Finally, delete the actual user
        result = await db.query('DELETE FROM users WHERE id = $1 RETURNING id, email', [userId]);
        deleteResults.push({ table: 'users', count: result.rowCount });
        
        await db.query('COMMIT');
        console.log('✅ Transaction committed');
        
        // Show results
        console.log('\n3. Delete results:');
        deleteResults.forEach(res => {
            const status = res.count > 0 ? '✅' : '⚪';
            console.log(`   ${status} ${res.table}: ${res.count} rows deleted`);
        });
        
        if (result.rows.length > 0) {
            console.log('\n✅ SUCCESS: User deleted successfully!');
            console.log('Deleted user:', result.rows[0].email);
        } else {
            console.log('\n❌ FAILED: User not found or not deleted');
        }
        
        // Verify user is gone
        console.log('\n4. Verifying deletion...');
        const checkResult = await db.query('SELECT id FROM users WHERE id = $1', [userId]);
        if (checkResult.rows.length === 0) {
            console.log('✅ Verification passed: User completely removed from database');
        } else {
            console.log('❌ Verification failed: User still exists in database');
        }
        
    } catch (error) {
        console.error('\n❌ ERROR:', error.message);
        console.error('Error details:', error);
        
        try {
            await db.query('ROLLBACK');
            console.log('Transaction rolled back');
        } catch (rollbackError) {
            console.error('Rollback error:', rollbackError.message);
        }
    }
}

async function main() {
    console.log('🚀 Testing delete function with existing user...');
    
    await testDeleteExistingUser();
    
    console.log('\n✅ Test complete');
    process.exit(0);
}

// Handle errors
process.on('unhandledRejection', (error) => {
    console.error('Unhandled rejection:', error);
    process.exit(1);
});

// Run the test
main().catch(error => {
    console.error('Main error:', error);
    process.exit(1);
});