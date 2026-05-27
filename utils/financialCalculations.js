/**
 * Financial Calculations Utility
 * Handles profit calculation, dynamic pricing, currency conversion, and financial reporting
 */

const db = require('../config/db');

/**
 * Calculate Agency Profit
 * Profit = Total Revenue - Total Expenditure - Taxes - Service Fees
 */
const calculateAgencyProfit = async (bookingId) => {
  try {
    const result = await db.query(
      `SELECT 
         b.final_amount as total_revenue,
         b.total_staff_cost as total_expenditure,
         b.taxes,
         b.service_fee,
         b.currency,
         b.agency_profit
       FROM bookings b
       WHERE b.id = $1`,
      [bookingId]
    );

    if (result.rows.length === 0) {
      return { success: false, error: 'Booking not found' };
    }

    const booking = result.rows[0];
    
    // Calculate profit components
    const totalRevenue = parseFloat(booking.total_revenue) || 0;
    const totalExpenditure = parseFloat(booking.total_expenditure) || 0;
    const taxes = parseFloat(booking.taxes) || 0;
    const serviceFee = parseFloat(booking.service_fee) || 0;
    
    const profit = totalRevenue - totalExpenditure - taxes - serviceFee;
    const profitMargin = totalRevenue > 0 ? (profit / totalRevenue) * 100 : 0;

    return {
      success: true,
      bookingId,
      totalRevenue,
      totalExpenditure,
      taxes,
      serviceFee,
      profit,
      profitMargin: profitMargin.toFixed(2),
      currency: booking.currency
    };
  } catch (error) {
    console.error('Profit calculation error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Calculate Profit Margin for Package
 */
const calculatePackageProfitMargin = async (packageId, numberOfPersons, startDate) => {
  try {
    // Get package pricing
    const pricingResult = await db.query(
      `SELECT 
         pp.price_per_person_local,
         pp.price_per_person_diaspora,
         pp.price_per_person_international,
         tp.duration_days
       FROM package_pricing pp
       INNER JOIN tour_packages tp ON pp.package_id = tp.id
       WHERE pp.package_id = $1
       AND $2::date BETWEEN 
         make_date(EXTRACT(YEAR FROM $2::date)::int, pp.start_month, 1) AND
         make_date(EXTRACT(YEAR FROM $2::date)::int, pp.end_month, 28)
       LIMIT 1`,
      [packageId, startDate]
    );

    if (pricingResult.rows.length === 0) {
      return { success: false, error: 'Package pricing not found' };
    }

    const pricing = pricingResult.rows[0];

    // Get estimated staff costs
    const staffCostResult = await db.query(
      `SELECT 
         SUM(bp.price_per_unit * $2) as estimated_staff_cost
       FROM base_price_pools bp
       INNER JOIN staff_departments sd ON bp.department_id = sd.id
       WHERE bp.is_active = TRUE
       AND (bp.expiry_date IS NULL OR bp.expiry_date > CURRENT_DATE)`,
      [packageId, pricing.duration_days]
    );

    const estimatedStaffCost = staffCostResult.rows[0]?.estimated_staff_cost || 0;

    // Calculate for different tourist types
    const calculations = {
      local: {
        pricePerPerson: pricing.price_per_person_local,
        totalRevenue: pricing.price_per_person_local * numberOfPersons,
        estimatedCost: estimatedStaffCost,
        estimatedProfit: (pricing.price_per_person_local * numberOfPersons) - estimatedStaffCost,
        profitMargin: ((pricing.price_per_person_local * numberOfPersons - estimatedStaffCost) / (pricing.price_per_person_local * numberOfPersons)) * 100
      },
      diaspora: {
        pricePerPerson: pricing.price_per_person_diaspora,
        totalRevenue: pricing.price_per_person_diaspora * numberOfPersons,
        estimatedCost: estimatedStaffCost,
        estimatedProfit: (pricing.price_per_person_diaspora * numberOfPersons) - estimatedStaffCost,
        profitMargin: ((pricing.price_per_person_diaspora * numberOfPersons - estimatedStaffCost) / (pricing.price_per_person_diaspora * numberOfPersons)) * 100
      },
      international: {
        pricePerPerson: pricing.price_per_person_international,
        totalRevenue: pricing.price_per_person_international * numberOfPersons,
        estimatedCost: estimatedStaffCost,
        estimatedProfit: (pricing.price_per_person_international * numberOfPersons) - estimatedStaffCost,
        profitMargin: ((pricing.price_per_person_international * numberOfPersons - estimatedStaffCost) / (pricing.price_per_person_international * numberOfPersons)) * 100
      }
    };

    return {
      success: true,
      packageId,
      numberOfPersons,
      durationDays: pricing.duration_days,
      calculations
    };
  } catch (error) {
    console.error('Package profit margin calculation error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Check Profit Margin Threshold
 * Alert when margin falls below predefined threshold (default 20%)
 */
const checkProfitMarginThreshold = async (packageId, currentMargin) => {
  try {
    const thresholdResult = await db.query(
      `SELECT minimum_margin_percentage, warning_margin_percentage
       FROM profit_margin_thresholds
       WHERE package_id = $1 AND is_active = TRUE
       LIMIT 1`,
      [packageId]
    );

    let minimumMargin = 20; // Default
    let warningMargin = 25;

    if (thresholdResult.rows.length > 0) {
      minimumMargin = parseFloat(thresholdResult.rows[0].minimum_margin_percentage);
      warningMargin = parseFloat(thresholdResult.rows[0].warning_margin_percentage);
    }

    if (currentMargin < minimumMargin) {
      // Create alert
      await db.query(
        `INSERT INTO profit_margin_alerts 
         (package_id, current_margin_percentage, threshold_margin_percentage, alert_type)
         VALUES ($1, $2, $3, 'below_minimum')`,
        [packageId, currentMargin, minimumMargin]
      );

      return {
        success: true,
        alert: true,
        alertType: 'below_minimum',
        currentMargin,
        minimumMargin,
        message: `Profit margin ${currentMargin.toFixed(2)}% is below minimum threshold ${minimumMargin}%`
      };
    } else if (currentMargin < warningMargin) {
      await db.query(
        `INSERT INTO profit_margin_alerts 
         (package_id, current_margin_percentage, threshold_margin_percentage, alert_type)
         VALUES ($1, $2, $3, 'warning')`,
        [packageId, currentMargin, warningMargin]
      );

      return {
        success: true,
        alert: true,
        alertType: 'warning',
        currentMargin,
        warningMargin,
        message: `Profit margin ${currentMargin.toFixed(2)}% is approaching minimum threshold`
      };
    }

    return {
      success: true,
      alert: false,
      currentMargin,
      message: 'Profit margin is healthy'
    };
  } catch (error) {
    console.error('Profit margin threshold check error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Dynamic Pricing Adjustment
 * Adjust package pricing based on fluctuating service costs
 */
const adjustPackagePricing = async (packageId, costChanges, adjustmentReason) => {
  try {
    // Get current pricing
    const currentPricingResult = await db.query(
      `SELECT * FROM package_pricing WHERE package_id = $1 ORDER BY created_at DESC LIMIT 1`,
      [packageId]
    );

    if (currentPricingResult.rows.length === 0) {
      return { success: false, error: 'Package pricing not found' };
    }

    const currentPricing = currentPricingResult.rows[0];

    // Calculate new prices based on cost changes
    const costIncrease = costChanges.reduce((sum, change) => sum + change.amount, 0);
    const adjustmentPercentage = (costIncrease / currentPricing.price_per_person_local) * 100;

    const newPricing = {
      price_per_person_local: parseFloat(currentPricing.price_per_person_local) + costIncrease,
      price_per_person_diaspora: parseFloat(currentPricing.price_per_person_diaspora) + costIncrease,
      price_per_person_international: parseFloat(currentPricing.price_per_person_international) + costIncrease
    };

    // Record price history
    await db.query(
      `INSERT INTO package_price_history 
       (package_id, pricing_id, previous_price, new_price, price_change_percentage, change_reason, cost_factors)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        packageId,
        currentPricing.id,
        currentPricing.price_per_person_local,
        newPricing.price_per_person_local,
        adjustmentPercentage,
        adjustmentReason,
        JSON.stringify(costChanges)
      ]
    );

    // Update pricing
    await db.query(
      `UPDATE package_pricing 
       SET price_per_person_local = $1,
           price_per_person_diaspora = $2,
           price_per_person_international = $3,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $4`,
      [
        newPricing.price_per_person_local,
        newPricing.price_per_person_diaspora,
        newPricing.price_per_person_international,
        currentPricing.id
      ]
    );

    return {
      success: true,
      packageId,
      previousPricing: {
        local: currentPricing.price_per_person_local,
        diaspora: currentPricing.price_per_person_diaspora,
        international: currentPricing.price_per_person_international
      },
      newPricing,
      adjustmentPercentage: adjustmentPercentage.toFixed(2),
      costChanges
    };
  } catch (error) {
    console.error('Dynamic pricing adjustment error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Currency Conversion
 * Convert between USD, EUR, and ETB with real-time rates
 */
const convertCurrency = async (amount, fromCurrency, toCurrency) => {
  try {
    // In production, integrate with real-time currency API
    // For now, using approximate rates
    const exchangeRates = {
      'USD_ETB': 115.50,
      'EUR_ETB': 125.30,
      'ETB_USD': 0.00866,
      'ETB_EUR': 0.00798,
      'USD_EUR': 0.92,
      'EUR_USD': 1.09
    };

    if (fromCurrency === toCurrency) {
      return {
        success: true,
        originalAmount: amount,
        convertedAmount: amount,
        fromCurrency,
        toCurrency,
        exchangeRate: 1
      };
    }

    const rateKey = `${fromCurrency}_${toCurrency}`;
    const exchangeRate = exchangeRates[rateKey];

    if (!exchangeRate) {
      return { success: false, error: `Exchange rate not found for ${rateKey}` };
    }

    const convertedAmount = amount * exchangeRate;

    return {
      success: true,
      originalAmount: amount,
      convertedAmount: parseFloat(convertedAmount.toFixed(2)),
      fromCurrency,
      toCurrency,
      exchangeRate
    };
  } catch (error) {
    console.error('Currency conversion error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Daily Reconciliation
 * Match bookings, payments, and payouts
 */
const performDailyReconciliation = async (date) => {
  try {
    const targetDate = date || new Date().toISOString().split('T')[0];

    // Get all bookings for the date
    const bookingsResult = await db.query(
      `SELECT 
         COUNT(*) as total_bookings,
         SUM(final_amount) as total_revenue,
         SUM(total_staff_cost) as total_staff_costs,
         SUM(agency_profit) as total_profit
       FROM bookings
       WHERE DATE(created_at) = $1`,
      [targetDate]
    );

    // Get all payments for the date
    const paymentsResult = await db.query(
      `SELECT 
         COUNT(*) as total_payments,
         SUM(amount) as total_paid,
         COUNT(*) FILTER (WHERE payment_status = 'paid') as successful_payments,
         COUNT(*) FILTER (WHERE payment_status = 'failed') as failed_payments
       FROM payments
       WHERE DATE(created_at) = $1`,
      [targetDate]
    );

    // Get all staff payments for the date
    const staffPaymentsResult = await db.query(
      `SELECT 
         COUNT(*) as total_staff_payments,
         SUM(total_amount) as total_staff_paid,
         COUNT(*) FILTER (WHERE payment_status = 'paid') as completed_staff_payments,
         COUNT(*) FILTER (WHERE payment_status = 'pending') as pending_staff_payments
       FROM staff_payment_transactions
       WHERE DATE(created_at) = $1`,
      [targetDate]
    );

    const reconciliation = {
      date: targetDate,
      bookings: bookingsResult.rows[0],
      payments: paymentsResult.rows[0],
      staffPayments: staffPaymentsResult.rows[0],
      reconciled: true,
      timestamp: new Date()
    };

    // Check for discrepancies
    const expectedRevenue = parseFloat(reconciliation.bookings.total_revenue) || 0;
    const actualPayments = parseFloat(reconciliation.payments.total_paid) || 0;
    const discrepancy = Math.abs(expectedRevenue - actualPayments);

    if (discrepancy > 0.01) {
      reconciliation.reconciled = false;
      reconciliation.discrepancy = discrepancy;
      reconciliation.message = `Discrepancy found: Expected ${expectedRevenue}, Received ${actualPayments}`;
    }

    return {
      success: true,
      reconciliation
    };
  } catch (error) {
    console.error('Daily reconciliation error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Generate Financial Dashboard Data
 */
const getFinancialDashboard = async (startDate, endDate) => {
  try {
    const result = await db.query(
      `SELECT 
         COUNT(*) as total_bookings,
         SUM(final_amount) as total_revenue,
         SUM(total_staff_cost) as total_expenditure,
         SUM(taxes) as total_taxes,
         SUM(service_fee) as total_service_fees,
         SUM(agency_profit) as total_profit,
         AVG(agency_profit) as avg_profit_per_booking,
         COUNT(*) FILTER (WHERE payment_status = 'paid') as paid_bookings,
         COUNT(*) FILTER (WHERE payment_status = 'pending') as pending_bookings,
         SUM(final_amount) FILTER (WHERE payment_status = 'pending') as outstanding_receivables
       FROM bookings
       WHERE created_at BETWEEN $1 AND $2`,
      [startDate, endDate]
    );

    const dashboard = result.rows[0];

    // Calculate profit margin
    const totalRevenue = parseFloat(dashboard.total_revenue) || 0;
    const totalProfit = parseFloat(dashboard.total_profit) || 0;
    dashboard.profit_margin_percentage = totalRevenue > 0 ? ((totalProfit / totalRevenue) * 100).toFixed(2) : 0;

    // Get outstanding payables
    const payablesResult = await db.query(
      `SELECT SUM(total_amount) as outstanding_payables
       FROM staff_payment_transactions
       WHERE payment_status = 'pending'
       AND created_at BETWEEN $1 AND $2`,
      [startDate, endDate]
    );

    dashboard.outstanding_payables = payablesResult.rows[0].outstanding_payables || 0;

    // Calculate cash flow
    dashboard.cash_flow = totalRevenue - parseFloat(dashboard.outstanding_payables || 0);

    return {
      success: true,
      period: { startDate, endDate },
      dashboard
    };
  } catch (error) {
    console.error('Financial dashboard error:', error);
    return { success: false, error: error.message };
  }
};

/**
 * Generate Monthly P&L Statement
 */
const generateMonthlyPL = async (year, month) => {
  try {
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0);

    const result = await db.query(
      `SELECT 
         SUM(final_amount) as total_revenue,
         SUM(total_staff_cost) as cost_of_services,
         SUM(taxes) as taxes,
         SUM(service_fee) as service_fees,
         SUM(agency_profit) as net_profit
       FROM bookings
       WHERE created_at BETWEEN $1 AND $2
       AND payment_status = 'paid'`,
      [startDate, endDate]
    );

    const pl = result.rows[0];

    // Calculate gross profit
    const totalRevenue = parseFloat(pl.total_revenue) || 0;
    const costOfServices = parseFloat(pl.cost_of_services) || 0;
    const grossProfit = totalRevenue - costOfServices;
    const grossMargin = totalRevenue > 0 ? ((grossProfit / totalRevenue) * 100).toFixed(2) : 0;

    // Calculate operating expenses
    const taxes = parseFloat(pl.taxes) || 0;
    const serviceFees = parseFloat(pl.service_fees) || 0;
    const operatingExpenses = taxes + serviceFees;

    // Net profit
    const netProfit = grossProfit - operatingExpenses;
    const netMargin = totalRevenue > 0 ? ((netProfit / totalRevenue) * 100).toFixed(2) : 0;

    return {
      success: true,
      period: { year, month, startDate, endDate },
      profitAndLoss: {
        revenue: {
          totalRevenue
        },
        costOfServices,
        grossProfit,
        grossMargin,
        operatingExpenses: {
          taxes,
          serviceFees,
          total: operatingExpenses
        },
        netProfit,
        netMargin
      }
    };
  } catch (error) {
    console.error('Monthly P&L generation error:', error);
    return { success: false, error: error.message };
  }
};

module.exports = {
  calculateAgencyProfit,
  calculatePackageProfitMargin,
  checkProfitMarginThreshold,
  adjustPackagePricing,
  convertCurrency,
  performDailyReconciliation,
  getFinancialDashboard,
  generateMonthlyPL
};
