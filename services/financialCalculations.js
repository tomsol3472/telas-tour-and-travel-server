/**
 * Financial Calculations Service
 * Handles all financial calculations, profit margins, and reconciliation
 */

const db = require('../config/db');

/**
 * Calculate agency profit for a booking
 */
exports.calculateAgencyProfit = async (bookingId) => {
    try {
        const result = await db.query(`
            SELECT 
                b.id,
                b.total_amount,
                b.total_staff_cost,
                b.taxes,
                b.service_fee,
                b.agency_profit,
                b.final_amount
            FROM bookings b
            WHERE b.id = $1
        `, [bookingId]);

        if (result.rows.length === 0) {
            throw new Error('Booking not found');
        }

        const booking = result.rows[0];
        
        // Calculate profit: final_amount - staff_costs - taxes - service_fee
        const profit = parseFloat(booking.final_amount || booking.total_amount) - 
                      parseFloat(booking.total_staff_cost || 0) - 
                      parseFloat(booking.taxes || 0) - 
                      parseFloat(booking.service_fee || 0);

        return {
            bookingId: booking.id,
            revenue: parseFloat(booking.final_amount || booking.total_amount),
            staffCosts: parseFloat(booking.total_staff_cost || 0),
            taxes: parseFloat(booking.taxes || 0),
            serviceFee: parseFloat(booking.service_fee || 0),
            profit: profit,
            profitMargin: (profit / parseFloat(booking.final_amount || booking.total_amount)) * 100
        };
    } catch (error) {
        console.error('Calculate Agency Profit Error:', error);
        throw error;
    }
};

/**
 * Calculate package profit margin
 */
exports.calculatePackageProfitMargin = async (packageId) => {
    try {
        const bookingsResult = await db.query(`
            SELECT 
                COUNT(*) as total_bookings,
                SUM(final_amount) as total_revenue,
                SUM(total_staff_cost) as total_costs,
                SUM(taxes) as total_taxes,
                SUM(service_fee) as total_fees
            FROM bookings
            WHERE package_id = $1 AND status IN ('confirmed', 'completed')
        `, [packageId]);

        const data = bookingsResult.rows[0];
        
        const revenue = parseFloat(data.total_revenue || 0);
        const costs = parseFloat(data.total_costs || 0);
        const taxes = parseFloat(data.total_taxes || 0);
        const fees = parseFloat(data.total_fees || 0);
        const profit = revenue - costs - taxes - fees;
        const margin = revenue > 0 ? (profit / revenue) * 100 : 0;

        return {
            packageId,
            totalBookings: parseInt(data.total_bookings || 0),
            totalRevenue: revenue,
            totalCosts: costs,
            totalTaxes: taxes,
            totalFees: fees,
            totalProfit: profit,
            profitMargin: margin,
            alert: margin < 15 ? 'LOW_MARGIN' : margin > 40 ? 'HIGH_MARGIN' : 'NORMAL'
        };
    } catch (error) {
        console.error('Calculate Package Profit Margin Error:', error);
        throw error;
    }
};

/**
 * Apply dynamic pricing adjustments
 */
exports.applyDynamicPricing = async (packageId, basePrice, bookingDate, groupSize) => {
    try {
        // Get pricing rules
        const rulesResult = await db.query(`
            SELECT * FROM price_adjustment_rules
            WHERE (package_id = $1 OR package_id IS NULL)
            AND is_active = true
            AND (effective_from_date IS NULL OR effective_from_date <= $2)
            AND (effective_to_date IS NULL OR effective_to_date >= $2)
            ORDER BY priority DESC
        `, [packageId, bookingDate]);

        let adjustedPrice = parseFloat(basePrice);
        const appliedRules = [];

        for (const rule of rulesResult.rows) {
            let adjustment = 0;

            switch (rule.rule_type) {
                case 'SEASONAL':
                    // Apply seasonal pricing
                    if (rule.adjustment_type === 'PERCENTAGE') {
                        adjustment = adjustedPrice * (parseFloat(rule.adjustment_value) / 100);
                    } else {
                        adjustment = parseFloat(rule.adjustment_value);
                    }
                    break;

                case 'GROUP_SIZE':
                    // Apply group discount
                    if (groupSize >= rule.min_group_size) {
                        adjustment = adjustedPrice * (parseFloat(rule.adjustment_value) / 100);
                    }
                    break;

                case 'EARLY_BIRD':
                    // Apply early bird discount
                    const daysUntilBooking = Math.floor((new Date(bookingDate) - new Date()) / (1000 * 60 * 60 * 24));
                    if (daysUntilBooking >= rule.min_days_advance) {
                        adjustment = adjustedPrice * (parseFloat(rule.adjustment_value) / 100);
                    }
                    break;

                case 'LAST_MINUTE':
                    // Apply last minute discount
                    const daysUntilTrip = Math.floor((new Date(bookingDate) - new Date()) / (1000 * 60 * 60 * 24));
                    if (daysUntilTrip <= rule.max_days_advance) {
                        adjustment = adjustedPrice * (parseFloat(rule.adjustment_value) / 100);
                    }
                    break;
            }

            if (adjustment !== 0) {
                adjustedPrice += adjustment;
                appliedRules.push({
                    ruleName: rule.rule_name,
                    ruleType: rule.rule_type,
                    adjustment: adjustment
                });
            }
        }

        return {
            basePrice: parseFloat(basePrice),
            adjustedPrice: adjustedPrice,
            totalAdjustment: adjustedPrice - parseFloat(basePrice),
            appliedRules: appliedRules
        };
    } catch (error) {
        console.error('Apply Dynamic Pricing Error:', error);
        throw error;
    }
};

/**
 * Convert currency
 */
exports.convertCurrency = async (amount, fromCurrency, toCurrency) => {
    try {
        // Exchange rates (in production, fetch from API)
        const rates = {
            ETB: 1,
            USD: 0.018,  // 1 ETB = 0.018 USD
            EUR: 0.017   // 1 ETB = 0.017 EUR
        };

        if (!rates[fromCurrency] || !rates[toCurrency]) {
            throw new Error('Unsupported currency');
        }

        // Convert to ETB first, then to target currency
        const amountInETB = parseFloat(amount) / rates[fromCurrency];
        const convertedAmount = amountInETB * rates[toCurrency];

        return {
            originalAmount: parseFloat(amount),
            originalCurrency: fromCurrency,
            convertedAmount: convertedAmount,
            targetCurrency: toCurrency,
            exchangeRate: rates[toCurrency] / rates[fromCurrency]
        };
    } catch (error) {
        console.error('Convert Currency Error:', error);
        throw error;
    }
};

/**
 * Perform daily reconciliation
 */
exports.performDailyReconciliation = async (date) => {
    try {
        const targetDate = date || new Date().toISOString().split('T')[0];

        // Get all payments for the day
        const paymentsResult = await db.query(`
            SELECT 
                COUNT(*) as total_transactions,
                SUM(amount) as total_amount,
                payment_method,
                status
            FROM payments
            WHERE DATE(created_at) = $1
            GROUP BY payment_method, status
        `, [targetDate]);

        // Get all bookings for the day
        const bookingsResult = await db.query(`
            SELECT 
                COUNT(*) as total_bookings,
                SUM(final_amount) as total_revenue,
                SUM(total_staff_cost) as total_costs,
                status
            FROM bookings
            WHERE DATE(created_at) = $1
            GROUP BY status
        `, [targetDate]);

        return {
            date: targetDate,
            payments: paymentsResult.rows,
            bookings: bookingsResult.rows,
            reconciledAt: new Date().toISOString()
        };
    } catch (error) {
        console.error('Daily Reconciliation Error:', error);
        throw error;
    }
};

/**
 * Get financial dashboard data
 */
exports.getFinancialDashboard = async (startDate, endDate) => {
    try {
        const start = startDate || new Date(new Date().setDate(new Date().getDate() - 30)).toISOString().split('T')[0];
        const end = endDate || new Date().toISOString().split('T')[0];

        // Total revenue
        const revenueResult = await db.query(`
            SELECT 
                SUM(final_amount) as total_revenue,
                COUNT(*) as total_bookings
            FROM bookings
            WHERE DATE(created_at) BETWEEN $1 AND $2
            AND status IN ('confirmed', 'completed')
        `, [start, end]);

        // Total costs
        const costsResult = await db.query(`
            SELECT 
                SUM(total_staff_cost) as total_staff_costs,
                SUM(taxes) as total_taxes,
                SUM(service_fee) as total_fees
            FROM bookings
            WHERE DATE(created_at) BETWEEN $1 AND $2
            AND status IN ('confirmed', 'completed')
        `, [start, end]);

        // Payment breakdown
        const paymentsResult = await db.query(`
            SELECT 
                payment_method,
                COUNT(*) as count,
                SUM(amount) as total
            FROM payments
            WHERE DATE(created_at) BETWEEN $1 AND $2
            AND status = 'success'
            GROUP BY payment_method
        `, [start, end]);

        const revenue = parseFloat(revenueResult.rows[0].total_revenue || 0);
        const staffCosts = parseFloat(costsResult.rows[0].total_staff_costs || 0);
        const taxes = parseFloat(costsResult.rows[0].total_taxes || 0);
        const fees = parseFloat(costsResult.rows[0].total_fees || 0);
        const profit = revenue - staffCosts - taxes - fees;

        return {
            period: { start, end },
            revenue: revenue,
            costs: {
                staff: staffCosts,
                taxes: taxes,
                fees: fees,
                total: staffCosts + taxes + fees
            },
            profit: profit,
            profitMargin: revenue > 0 ? (profit / revenue) * 100 : 0,
            bookings: parseInt(revenueResult.rows[0].total_bookings || 0),
            paymentMethods: paymentsResult.rows
        };
    } catch (error) {
        console.error('Get Financial Dashboard Error:', error);
        throw error;
    }
};

/**
 * Generate monthly P&L statement
 */
exports.generateMonthlyPL = async (year, month) => {
    try {
        const startDate = `${year}-${String(month).padStart(2, '0')}-01`;
        const endDate = new Date(year, month, 0).toISOString().split('T')[0];

        const dashboard = await this.getFinancialDashboard(startDate, endDate);

        // Get additional breakdown
        const packageBreakdown = await db.query(`
            SELECT 
                p.name as package_name,
                COUNT(b.id) as bookings,
                SUM(b.final_amount) as revenue,
                SUM(b.total_staff_cost) as costs
            FROM bookings b
            JOIN tour_packages p ON b.package_id = p.id
            WHERE DATE(b.created_at) BETWEEN $1 AND $2
            AND b.status IN ('confirmed', 'completed')
            GROUP BY p.id, p.name
            ORDER BY revenue DESC
        `, [startDate, endDate]);

        return {
            period: {
                year: year,
                month: month,
                startDate: startDate,
                endDate: endDate
            },
            summary: dashboard,
            packageBreakdown: packageBreakdown.rows,
            generatedAt: new Date().toISOString()
        };
    } catch (error) {
        console.error('Generate Monthly P&L Error:', error);
        throw error;
    }
};

module.exports = exports;
