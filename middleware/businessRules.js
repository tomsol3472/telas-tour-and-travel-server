/**
 * Business Rules Middleware
 * Enforces Telas Tourism Platform business rules across all operations
 */

const db = require('../config/db');

/**
 * Verification Tier Requirements
 * All staff must complete identity verification before accepting bookings
 */
const requireVerification = (minTier = 'basic') => {
  return async (req, res, next) => {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ success: false, error: 'Authentication required' });
      }

      const result = await db.query(
        `SELECT verification_tier, status FROM users WHERE id = $1`,
        [userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, error: 'User not found' });
      }

      const user = result.rows[0];
      const tierLevels = { basic: 1, verified: 2, premium: 3 };
      const requiredLevel = tierLevels[minTier] || 1;
      const userLevel = tierLevels[user.verification_tier] || 0;

      if (userLevel < requiredLevel) {
        return res.status(403).json({
          success: false,
          error: `Verification tier '${minTier}' or higher required`,
          currentTier: user.verification_tier,
          requiredTier: minTier
        });
      }

      if (user.status !== 'active') {
        return res.status(403).json({
          success: false,
          error: 'Account must be active to perform this action',
          status: user.status
        });
      }

      next();
    } catch (error) {
      console.error('Verification check error:', error);
      res.status(500).json({ success: false, error: 'Verification check failed' });
    }
  };
};

/**
 * Response Time Tracking
 * Monitors service provider response times (4hr business hours, 12hr off-hours)
 */
const trackResponseTime = async (providerId, inquiryType, bookingId = null) => {
  try {
    const now = new Date();
    const hour = now.getHours();
    const isBusinessHours = hour >= 8 && hour < 20; // 8 AM - 8 PM Ethiopia time
    const requiredHours = isBusinessHours ? 4 : 12;

    await db.query(
      `INSERT INTO provider_response_tracking 
       (provider_id, inquiry_type, inquiry_sent_at, was_business_hours, required_response_time_hours, booking_id)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id`,
      [providerId, inquiryType, now, isBusinessHours, requiredHours, bookingId]
    );

    return { success: true, requiredHours };
  } catch (error) {
    console.error('Response tracking error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Record Response Received
 */
const recordResponse = async (providerId, inquiryType) => {
  try {
    await db.query(
      `UPDATE provider_response_tracking 
       SET response_received_at = CURRENT_TIMESTAMP
       WHERE provider_id = $1 
       AND inquiry_type = $2 
       AND response_received_at IS NULL
       ORDER BY inquiry_sent_at DESC
       LIMIT 1`,
      [providerId, inquiryType]
    );

    // Refresh materialized view
    await db.query('REFRESH MATERIALIZED VIEW CONCURRENTLY provider_response_metrics');

    return { success: true };
  } catch (error) {
    console.error('Record response error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Availability Update Validation
 * Enforces 48-hour advance notice requirement
 */
const validateAvailabilityUpdate = async (providerId, availabilityDate) => {
  try {
    const hoursUntilDate = (new Date(availabilityDate) - new Date()) / (1000 * 60 * 60);
    
    if (hoursUntilDate < 48) {
      // Last-minute unavailability - impact reliability score
      await updateReliabilityScore(providerId, -5, 'Last-minute availability change');
      
      return {
        success: false,
        error: 'Availability must be updated at least 48 hours in advance',
        hoursUntilDate: Math.round(hoursUntilDate),
        reliabilityImpact: -5
      };
    }

    return { success: true, hoursUntilDate: Math.round(hoursUntilDate) };
  } catch (error) {
    console.error('Availability validation error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Update Reliability Score
 */
const updateReliabilityScore = async (providerId, scoreChange, reason) => {
  try {
    // Determine if provider is driver or guide
    const userResult = await db.query(
      'SELECT user_role FROM users WHERE id = $1',
      [providerId]
    );

    if (userResult.rows.length === 0) return { success: false, error: 'Provider not found' };

    const role = userResult.rows[0].user_role;
    const table = role === 'driver' ? 'drivers' : 'guides';

    await db.query(
      `UPDATE ${table} 
       SET reliability_score = GREATEST(0, LEAST(100, reliability_score + $1)),
           reliability_updated_at = CURRENT_TIMESTAMP
       WHERE user_id = $2`,
      [scoreChange, providerId]
    );

    // Log the change
    await db.query(
      `INSERT INTO system_audit_logs (user_id, action_type, table_name, new_values)
       VALUES ($1, 'reliability_score_update', $2, $3)`,
      [providerId, table, JSON.stringify({ scoreChange, reason })]
    );

    return { success: true };
  } catch (error) {
    console.error('Reliability score update error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Price Lock Guarantee
 * Locks booking price regardless of subsequent rate changes
 */
const lockBookingPrice = async (bookingId, priceBreakdown, currency = 'ETB') => {
  try {
    const lockedPrice = priceBreakdown.final_amount;
    const lockExpiresAt = new Date();
    lockExpiresAt.setHours(lockExpiresAt.getHours() + 24); // 24-hour lock

    await db.query(
      `INSERT INTO booking_price_locks 
       (booking_id, locked_price, locked_currency, price_breakdown, lock_expires_at, locked_by)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (booking_id) DO UPDATE
       SET locked_price = EXCLUDED.locked_price,
           price_breakdown = EXCLUDED.price_breakdown,
           lock_expires_at = EXCLUDED.lock_expires_at`,
      [bookingId, lockedPrice, currency, JSON.stringify(priceBreakdown), lockExpiresAt, priceBreakdown.userId]
    );

    return { success: true, lockedPrice, lockExpiresAt };
  } catch (error) {
    console.error('Price lock error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Calculate Cancellation Penalty
 * Implements tiered cancellation policy (48hr free for day tours, 7-day for multi-day)
 */
const calculateCancellationPenalty = async (bookingId) => {
  try {
    const bookingResult = await db.query(
      `SELECT b.*, tp.duration_days, b.start_date, b.final_amount
       FROM bookings b
       LEFT JOIN tour_packages tp ON b.package_id = tp.id
       WHERE b.id = $1`,
      [bookingId]
    );

    if (bookingResult.rows.length === 0) {
      return { success: false, error: 'Booking not found' };
    }

    const booking = bookingResult.rows[0];
    const hoursUntilStart = (new Date(booking.start_date) - new Date()) / (1000 * 60 * 60);
    const durationDays = booking.duration_days || 1;

    // Find applicable cancellation policy
    const policyResult = await db.query(
      `SELECT * FROM cancellation_policies
       WHERE (tour_duration_days IS NULL OR tour_duration_days <= $1)
       AND hours_before_start <= $2
       AND is_active = TRUE
       ORDER BY hours_before_start DESC
       LIMIT 1`,
      [durationDays, hoursUntilStart]
    );

    let refundPercentage = 0;
    let penaltyPercentage = 100;

    if (policyResult.rows.length > 0) {
      const policy = policyResult.rows[0];
      refundPercentage = parseFloat(policy.refund_percentage);
      penaltyPercentage = parseFloat(policy.penalty_percentage);
    }

    const refundAmount = (booking.final_amount * refundPercentage) / 100;
    const penaltyAmount = (booking.final_amount * penaltyPercentage) / 100;

    return {
      success: true,
      hoursUntilStart: Math.round(hoursUntilStart),
      refundPercentage,
      penaltyPercentage,
      refundAmount,
      penaltyAmount,
      originalAmount: booking.final_amount
    };
  } catch (error) {
    console.error('Cancellation penalty calculation error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Create Payment Installments
 * For multi-day tours: 30% upon start, 40% at midpoint, 30% upon completion
 */
const createPaymentInstallments = async (bookingId, totalAmount, currency = 'ETB') => {
  try {
    const bookingResult = await db.query(
      `SELECT start_date, end_date FROM bookings WHERE id = $1`,
      [bookingId]
    );

    if (bookingResult.rows.length === 0) {
      return { success: false, error: 'Booking not found' };
    }

    const booking = bookingResult.rows[0];
    const startDate = new Date(booking.start_date);
    const endDate = new Date(booking.end_date);
    const midpointDate = new Date((startDate.getTime() + endDate.getTime()) / 2);

    const installments = [
      {
        installment_number: 1,
        installment_type: 'tour_start',
        percentage: 30,
        amount: totalAmount * 0.30,
        due_date: startDate,
        trigger_condition: 'Tour start confirmed'
      },
      {
        installment_number: 2,
        installment_type: 'midpoint_verification',
        percentage: 40,
        amount: totalAmount * 0.40,
        due_date: midpointDate,
        trigger_condition: 'Midpoint verification completed'
      },
      {
        installment_number: 3,
        installment_type: 'tour_completion',
        percentage: 30,
        amount: totalAmount * 0.30,
        due_date: endDate,
        trigger_condition: 'Tour completed and tourist confirmation received'
      }
    ];

    for (const installment of installments) {
      await db.query(
        `INSERT INTO payment_installments 
         (booking_id, installment_number, installment_type, percentage, amount, currency, due_date, trigger_condition)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT (booking_id, installment_number) DO NOTHING`,
        [
          bookingId,
          installment.installment_number,
          installment.installment_type,
          installment.percentage,
          installment.amount,
          currency,
          installment.due_date,
          installment.trigger_condition
        ]
      );
    }

    return { success: true, installments };
  } catch (error) {
    console.error('Create installments error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Check Performance Thresholds
 * Minimum rating 3.5/5, response time <8hr average, completion rate >85%
 */
const checkPerformanceThresholds = async (providerId) => {
  try {
    const userResult = await db.query(
      'SELECT user_role FROM users WHERE id = $1',
      [providerId]
    );

    if (userResult.rows.length === 0) {
      return { success: false, error: 'Provider not found' };
    }

    const role = userResult.rows[0].user_role;
    const table = role === 'driver' ? 'drivers' : 'guides';

    // Get provider metrics
    const metricsResult = await db.query(
      `SELECT rating, total_trips FROM ${table} WHERE user_id = $1`,
      [providerId]
    );

    if (metricsResult.rows.length === 0) {
      return { success: false, error: 'Provider metrics not found' };
    }

    const metrics = metricsResult.rows[0];
    const issues = [];

    // Check rating threshold (3.5/5)
    if (metrics.rating < 3.5 && metrics.total_trips >= 10) {
      issues.push({
        type: 'low_rating',
        threshold: 3.5,
        current: metrics.rating,
        message: 'Rating below minimum threshold of 3.5/5'
      });
    }

    // Check response time
    const responseResult = await db.query(
      `SELECT avg_response_time_minutes FROM provider_response_metrics WHERE provider_id = $1`,
      [providerId]
    );

    if (responseResult.rows.length > 0) {
      const avgResponseMinutes = responseResult.rows[0].avg_response_time_minutes;
      if (avgResponseMinutes > 480) { // 8 hours
        issues.push({
          type: 'slow_response',
          threshold: 480,
          current: avgResponseMinutes,
          message: 'Average response time exceeds 8 hours'
        });
      }
    }

    // Check completion rate
    const completionResult = await db.query(
      `SELECT 
         COUNT(*) FILTER (WHERE status = 'completed') as completed,
         COUNT(*) as total
       FROM bookings
       WHERE (assigned_driver_id = $1 OR assigned_guide_id = $1)
       AND status NOT IN ('cancelled')`,
      [providerId]
    );

    if (completionResult.rows.length > 0) {
      const { completed, total } = completionResult.rows[0];
      const completionRate = total > 0 ? (completed / total) * 100 : 100;
      
      if (completionRate < 85 && total >= 10) {
        issues.push({
          type: 'low_completion_rate',
          threshold: 85,
          current: completionRate,
          message: 'Completion rate below 85%'
        });
      }
    }

    // If issues found, create performance review
    if (issues.length > 0) {
      await db.query(
        `INSERT INTO provider_performance_reviews 
         (provider_id, review_type, trigger_reason, current_rating, review_status)
         VALUES ($1, 'threshold_violation', $2, $3, 'pending')`,
        [providerId, JSON.stringify(issues), metrics.rating]
      );

      return {
        success: true,
        requiresReview: true,
        issues
      };
    }

    return { success: true, requiresReview: false };
  } catch (error) {
    console.error('Performance threshold check error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Verify Review Authenticity
 * Only tourists who completed booked services can leave reviews
 */
const verifyReviewEligibility = async (reviewerId, revieweeId, bookingId) => {
  try {
    const result = await db.query(
      `SELECT b.id, b.status, b.tourist_id, b.assigned_driver_id, b.assigned_guide_id
       FROM bookings b
       INNER JOIN tourists t ON b.tourist_id = t.id
       WHERE b.id = $1 
       AND t.user_id = $2
       AND b.status = 'completed'
       AND (b.assigned_driver_id = (SELECT user_id FROM drivers WHERE user_id = $3)
            OR b.assigned_guide_id = (SELECT user_id FROM guides WHERE user_id = $3))`,
      [bookingId, reviewerId, revieweeId]
    );

    if (result.rows.length === 0) {
      return {
        success: false,
        error: 'Review not allowed. Only tourists who completed booked services can leave reviews.',
        eligible: false
      };
    }

    return { success: true, eligible: true };
  } catch (error) {
    console.error('Review eligibility check error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Domestic Tourist Discount
 * Ethiopian nationals receive automatic 15% discount on platform commissions
 */
const applyDomesticDiscount = (amount, nationality) => {
  if (nationality && nationality.toLowerCase() === 'ethiopia') {
    const discount = amount * 0.15;
    return {
      originalAmount: amount,
      discountPercentage: 15,
      discountAmount: discount,
      finalAmount: amount - discount,
      isDomestic: true
    };
  }
  return {
    originalAmount: amount,
    discountPercentage: 0,
    discountAmount: 0,
    finalAmount: amount,
    isDomestic: false
  };
};

module.exports = {
  requireVerification,
  trackResponseTime,
  recordResponse,
  validateAvailabilityUpdate,
  updateReliabilityScore,
  lockBookingPrice,
  calculateCancellationPenalty,
  createPaymentInstallments,
  checkPerformanceThresholds,
  verifyReviewEligibility,
  applyDomesticDiscount
};
