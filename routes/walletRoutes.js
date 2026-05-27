const express = require('express');
const router = express.Router();
const walletController = require('../controllers/walletController');
const { protect, isAdmin } = require('../middleware/auth');

// GET /api/wallet - Get user's wallet
router.get('/', protect, walletController.getWallet);

// POST /api/wallet/withdraw - Request a withdrawal
router.post('/withdraw', protect, walletController.processWithdrawal);

// POST /api/wallet/deposit - Request a deposit
router.post('/deposit', protect, walletController.processDeposit);

// GET /api/wallet/admin/withdrawals - Admin get all withdrawals
router.get('/admin/withdrawals', protect, isAdmin, walletController.getAllWithdrawals);

// PUT /api/wallet/admin/withdrawals/:id/approve - Admin approve/transfer withdrawal
router.put('/admin/withdrawals/:id/approve', protect, isAdmin, walletController.approveWithdrawal);

// PUT /api/wallet/admin/withdrawals/:id/reject - Admin reject withdrawal
router.put('/admin/withdrawals/:id/reject', protect, isAdmin, walletController.rejectWithdrawal);

// PUT /api/wallet/admin/staff/:id/rate - Admin update staff daily rate
router.put('/admin/staff/:id/rate', protect, isAdmin, walletController.updateStaffRate);

module.exports = router;
