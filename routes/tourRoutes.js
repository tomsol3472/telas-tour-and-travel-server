const express = require('express');
const router = express.Router();
const tourController = require('../controllers/tourController');
const { verifyToken, checkRole } = require('../middleware/authMiddleware');

router.get('/', verifyToken, checkRole(['admin', 'tourist', 'guide', 'driver', 'tour_operator']), tourController.getAllTours);
router.get('/:id', verifyToken, tourController.getTourById);
router.post('/', verifyToken, checkRole(['admin', 'tour_operator', 'tourist']), tourController.createTour);
router.put('/:id', verifyToken, checkRole(['admin', 'tour_operator']), tourController.updateTour);

// State transition routes
router.post('/:id/request-start', verifyToken, checkRole(['guide', 'driver']), tourController.requestStart);
router.post('/:id/approve-start', verifyToken, checkRole(['tourist']), tourController.approveStart);
router.post('/:id/request-end', verifyToken, checkRole(['guide', 'driver']), tourController.requestEnd);
router.post('/:id/approve-end', verifyToken, checkRole(['tourist']), tourController.approveEnd);
router.post('/:id/rate', verifyToken, checkRole(['tourist']), tourController.rateTour);

module.exports = router;
