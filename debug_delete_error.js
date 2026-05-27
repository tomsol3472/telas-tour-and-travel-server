/**
 * Debug Delete Error Script
 * This script will help identify the exact error when deleting a user
 */

const db = require('./config/db');

async function testDeleteUser() {
    console.log('🔍 Testing delete user function...');
    
    try {
        // First, let's see what users exist
        console.log('\n1. Checking existing users...');
        const usersResult = await db.query('SELECT id, email, user_role FROM users LIMIT 5');
        console.log('Found users:', usersResult.rows);
        
        if (usersResult.rows.length === 0) {
            console.log('❌ No users found in database');
            return;
        }
        
        // Let's try to delete a test user (we'll create one first)
        console.log('\n2. Creating a test user to delete...');
        const testUserResult = await db.query(`
            INSERT INTO users (email, password_hash, user_role, status, phone) 
            VALUES ($1, $2, $3, $4, $5) 
            RETURNING id, email
        `, ['test-delete@example.com', 'test-hash', 'tourist', 'active', '0900000000']);
        
        const testUserId = testUserResult.rows[0].id;
        console.log('Created test user:', testUserResult.rows[0]);
        
        // Now let's try to delete it step by step
        console.log('\n3. Testing delete process step by step...');
        
        await db.query('BEGIN');
        console.log('✅ Transaction started');
        
        // Test each delete operation individually
        const deleteOperations = [
            { table: 'staff_withdrawals', query: 'DELETE FROM staff_withdrawals WHERE user_id = $1' },
            { table: 'staff_wallets', query: 'DELETE FROM staff_wallets WHERE user_id = $1' },
            { table: 'notifications', query: 'DELETE FROM notifications WHERE user_id = $1' },
            { table: 'chat_participants', query: 'DELETE FROM chat_participants WHERE user_id = $1' },
            { table: 'support_tickets', query: 'DELETE FROM support_tickets WHERE user_id = $1' },
            { table: 'verification_documents', query: 'DELETE FROM verification_documents WHERE user_id = $1' },
            // Skip missing tables
            // { table: 'verification_tier_history', query: 'DELETE FROM verification_tier_history WHERE user_id = $1' },
            // { table: 'user_notification_preferences', query: 'DELETE FROM user_notification_preferences WHERE user_id = $1' },
            // { table: 'user_analytics_events', query: 'DELETE FROM user_analytics_events WHERE user_id = $1' },
            { table: 'user_profiles', query: 'DELETE FROM user_profiles WHERE user_id = $1' },
            { table: 'tourists', query: 'DELETE FROM tourists WHERE user_id = $1' },
            { table: 'guides', query: 'DELETE FROM guides WHERE user_id = $1' },
            { table: 'drivers', query: 'DELETE FROM drivers WHERE user_id = $1' },
            { table: 'users', query: 'DELETE FROM users WHERE id = $1' }
        ];
        
        for (const operation of deleteOperations) {
            try {
                console.log(`   Deleting from ${operation.table}...`);
                const result = await db.query(operation.query, [testUserId]);
                console.log(`   ✅ ${operation.table}: ${result.rowCount} rows deleted`);
            } catch (error) {
                console.log(`   ❌ ${operation.table}: ERROR - ${error.message}`);
                
                // Check if table exists
                try {
                    await db.query(`SELECT 1 FROM ${operation.table} LIMIT 1`);
                    console.log(`      Table ${operation.table} exists`);
                } catch (tableError) {
                    console.log(`      ⚠️  Table ${operation.table} does not exist: ${tableError.message}`);
                }
            }
        }
        
        await db.query('COMMIT');
        console.log('✅ Transaction committed');
        
        console.log('\n4. Verifying user is deleted...');
        const checkResult = await db.query('SELECT id FROM users WHERE id = $1', [testUserId]);
        if (checkResult.rows.length === 0) {
            console.log('✅ User successfully deleted');
        } else {
            console.log('❌ User still exists');
        }
        
    } catch (error) {
        console.error('\n❌ MAIN ERROR:', error.message);
        console.error('Error details:', error);
        
        try {
            await db.query('ROLLBACK');
            console.log('Transaction rolled back');
        } catch (rollbackError) {
            console.error('Rollback error:', rollbackError.message);
        }
    }
}

async function checkDatabaseTables() {
    console.log('\n🔍 Checking which tables exist in the database...');
    
    try {
        const tablesResult = await db.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name IN (
                'users', 'user_profiles', 'tourists', 'guides', 'drivers',
                'staff_wallets', 'staff_withdrawals', 'notifications',
                'chat_participants', 'support_tickets', 'verification_documents',
                'verification_tier_history', 'user_notification_preferences',
                'user_analytics_events'
            )
            ORDER BY table_name
        `);
        
        console.log('Existing tables:');
        tablesResult.rows.forEach(row => {
            console.log(`  ✅ ${row.table_name}`);
        });
        
        const expectedTables = [
            'users', 'user_profiles', 'tourists', 'guides', 'drivers',
            'staff_wallets', 'staff_withdrawals', 'notifications',
            'chat_participants', 'support_tickets', 'verification_documents',
            'verification_tier_history', 'user_notification_preferences',
            'user_analytics_events'
        ];
        
        const existingTableNames = tablesResult.rows.map(row => row.table_name);
        const missingTables = expectedTables.filter(table => !existingTableNames.includes(table));
        
        if (missingTables.length > 0) {
            console.log('\nMissing tables:');
            missingTables.forEach(table => {
                console.log(`  ❌ ${table}`);
            });
        }
        
    } catch (error) {
        console.error('Error checking tables:', error.message);
    }
}

async function main() {
    console.log('🚀 Starting delete user debug session...');
    
    await checkDatabaseTables();
    await testDeleteUser();
    
    console.log('\n✅ Debug session complete');
    process.exit(0);
}

// Handle errors
process.on('unhandledRejection', (error) => {
    console.error('Unhandled rejection:', error);
    process.exit(1);
});

// Run the debug
main().catch(error => {
    console.error('Main error:', error);
    process.exit(1);
});