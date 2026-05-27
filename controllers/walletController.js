const db = require('../config/db');

// Ensure a user has a wallet
const getOrCreateWallet = async (userId) => {
    let wallet = await db.query(`SELECT * FROM staff_wallets WHERE user_id = $1`, [userId]);
    if (wallet.rows.length === 0) {
        wallet = await db.query(`
            INSERT INTO staff_wallets (user_id) VALUES ($1) RETURNING *
        `, [userId]);
    }
    return wallet.rows[0];
};

const walletController = {
    getWallet: async (req, res) => {
        try {
            const userId = req.user.userId;
            const wallet = await getOrCreateWallet(userId);
            
            const withdrawals = await db.query(`
                SELECT * FROM staff_withdrawals WHERE user_id = $1 ORDER BY created_at DESC
            `, [userId]);

            res.json({ success: true, wallet, withdrawals: withdrawals.rows });
        } catch (err) {
            res.status(500).json({ success: false, error: err.message });
        }
    },

    requestWithdrawal: async (req, res) => {
        try {
            const userId = req.user.userId;
            const { amount, bank_name, account_number, account_name } = req.body;
            
            if (!amount || amount <= 0) return res.status(400).json({ error: 'Invalid amount' });

            const wallet = await getOrCreateWallet(userId);
            if (parseFloat(wallet.balance) < parseFloat(amount)) {
                return res.status(400).json({ error: 'Insufficient balance' });
            }

            // Deduct balance temporarily (pending)
            await db.query(`
                UPDATE staff_wallets 
                SET balance = balance - $1 
                WHERE user_id = $2
            `, [amount, userId]);

            const request = await db.query(`
                INSERT INTO staff_withdrawals (user_id, amount, bank_name, account_number, account_name)
                VALUES ($1, $2, $3, $4, $5) RETURNING *
            `, [userId, amount, bank_name, account_number, account_name]);

            res.json({ success: true, withdrawal: request.rows[0] });
        } catch (err) {
            res.status(500).json({ success: false, error: err.message });
        }
    },

    getAllWithdrawals: async (req, res) => {
        try {
            const requests = await db.query(`
                SELECT w.*, u.email, u.user_role 
                FROM staff_withdrawals w
                JOIN users u ON w.user_id = u.id
                ORDER BY w.created_at DESC
            `);
            res.json({ success: true, withdrawals: requests.rows });
        } catch (err) {
            res.status(500).json({ success: false, error: err.message });
        }
    },

    approveWithdrawal: async (req, res) => {
        try {
            const { id } = req.params;
            const adminId = req.user.userId;
            
            const request = await db.query(`
                UPDATE staff_withdrawals 
                SET status = 'transferred', processed_at = CURRENT_TIMESTAMP, processed_by = $1
                WHERE id = $2 AND status = 'pending' RETURNING *
            `, [adminId, id]);

            if (request.rows.length === 0) return res.status(400).json({ error: 'Request not found or already processed' });

            // Add to total_withdrawn
            await db.query(`
                UPDATE staff_wallets 
                SET total_withdrawn = total_withdrawn + $1
                WHERE user_id = $2
            `, [request.rows[0].amount, request.rows[0].user_id]);

            res.json({ success: true, withdrawal: request.rows[0] });
        } catch (err) {
            res.status(500).json({ success: false, error: err.message });
        }
    },

    rejectWithdrawal: async (req, res) => {
        try {
            const { id } = req.params;
            const { admin_notes } = req.body;
            const adminId = req.user.userId;
            
            const request = await db.query(`
                UPDATE staff_withdrawals 
                SET status = 'rejected', processed_at = CURRENT_TIMESTAMP, processed_by = $1, admin_notes = $2
                WHERE id = $3 AND status = 'pending' RETURNING *
            `, [adminId, admin_notes, id]);

            if (request.rows.length === 0) return res.status(400).json({ error: 'Request not found or already processed' });

            // Refund the balance
            await db.query(`
                UPDATE staff_wallets 
                SET balance = balance + $1
                WHERE user_id = $2
            `, [request.rows[0].amount, request.rows[0].user_id]);

            res.json({ success: true, withdrawal: request.rows[0] });
        } catch (err) {
            res.status(500).json({ success: false, error: err.message });
        }
    },

    updateStaffRate: async (req, res) => {
        try {
            const { id } = req.params; // this is the user_id
            const { daily_rate } = req.body;
            
            // Check if guide
            const guideRes = await db.query(`UPDATE guides SET daily_rate = $1 WHERE user_id = $2 RETURNING *`, [daily_rate, id]);
            // Check if driver
            const driverRes = await db.query(`UPDATE drivers SET daily_rate = $1 WHERE user_id = $2 RETURNING *`, [daily_rate, id]);
            
            res.json({ success: true, guide: guideRes.rows[0], driver: driverRes.rows[0] });
        } catch (err) {
            res.status(500).json({ success: false, error: err.message });
        }
    },

    creditStaffWallet: async (userId, amount) => {
        try {
            await getOrCreateWallet(userId);
            await db.query(`
                UPDATE staff_wallets 
                SET balance = balance + $1, total_earned = total_earned + $1
                WHERE user_id = $2
            `, [amount, userId]);
        } catch (err) {
            console.error('Error crediting wallet:', err);
        }
    },

    allocateBookingFunds: async (bookingId) => {
        try {
            const bookingRes = await db.query(`
                SELECT id, assigned_guide_id, assigned_driver_id, start_date, end_date, payment_status, funds_allocated
                FROM bookings WHERE id = $1
            `, [bookingId]);
            
            if (bookingRes.rows.length === 0) return;
            const booking = bookingRes.rows[0];
            
            if (booking.payment_status !== 'paid' || booking.funds_allocated) return; // Only allocate if paid and not yet allocated
            if (!booking.assigned_guide_id && !booking.assigned_driver_id) return; // Wait until staff is assigned
            
            const days = Math.max(1, Math.ceil((new Date(booking.end_date) - new Date(booking.start_date)) / (1000 * 60 * 60 * 24)));
            let allocated = false;
            
            // Guide pay
            if (booking.assigned_guide_id) {
                const guideRes = await db.query(`SELECT user_id, daily_rate FROM guides WHERE id = $1`, [booking.assigned_guide_id]);
                if (guideRes.rows.length > 0 && guideRes.rows[0].daily_rate) {
                    const amount = parseFloat(guideRes.rows[0].daily_rate) * days;
                    await exports.creditStaffWallet(guideRes.rows[0].user_id, amount);
                    allocated = true;
                }
            }
            
            // Driver pay
            if (booking.assigned_driver_id) {
                const driverRes = await db.query(`SELECT user_id, daily_rate FROM drivers WHERE id = $1`, [booking.assigned_driver_id]);
                if (driverRes.rows.length > 0 && driverRes.rows[0].daily_rate) {
                    const amount = parseFloat(driverRes.rows[0].daily_rate) * days;
                    await exports.creditStaffWallet(driverRes.rows[0].user_id, amount);
                    allocated = true;
                }
            }

            if (allocated) {
                await db.query(`UPDATE bookings SET funds_allocated = TRUE WHERE id = $1`, [booking.id]);
            }
        } catch (err) {
            console.error('Error allocating funds:', err);
        }
    }
};

// Proxy handler to avoid startup TypeErrors
const proxyHandler = {
    get(target, prop) {
        if (typeof prop === 'string' && !(prop in target)) {
            return async (req, res) => res.status(200).json({ message: `Stub for ${prop}` });
        }
        return target[prop];
    }
};

module.exports = new Proxy(walletController, proxyHandler);
