-- =====================================================
-- TELAS TOURISM PLATFORM: BUSINESS RULES MIGRATION
-- =====================================================

-- 1. VERIFICATION TIERS & DIASPORA IDENTIFICATION
CREATE TYPE verification_tier_enum AS ENUM ('basic', 'verified', 'premium');

ALTER TABLE user_profiles
ADD COLUMN verification_tier verification_tier_enum DEFAULT 'basic',
ADD COLUMN is_diaspora_verified BOOLEAN DEFAULT FALSE;

-- 2. PERFORMANCE & QUALITY ASSURANCE (Drivers & Guides)
ALTER TABLE drivers
ADD COLUMN average_response_time_minutes INTEGER DEFAULT 0,
ADD COLUMN booking_completion_rate DECIMAL(5,2) DEFAULT 100.00,
ADD COLUMN consecutive_low_ratings INTEGER DEFAULT 0,
ADD COLUMN performance_review_status BOOLEAN DEFAULT FALSE;

ALTER TABLE guides
ADD COLUMN average_response_time_minutes INTEGER DEFAULT 0,
ADD COLUMN booking_completion_rate DECIMAL(5,2) DEFAULT 100.00,
ADD COLUMN consecutive_low_ratings INTEGER DEFAULT 0,
ADD COLUMN performance_review_status BOOLEAN DEFAULT FALSE;

-- 3. PAYMENT INSTALLMENTS, ESCROW & REFUNDS
CREATE TYPE refund_tier_enum AS ENUM ('none', 'pending_escrow', 'refunded_75', 'refunded_50', 'no_refund', 'force_majeure_refund');

ALTER TABLE bookings
ADD COLUMN locked_exchange_rate DECIMAL(10,4),
ADD COLUMN locked_base_price DECIMAL(12,2),
ADD COLUMN refund_tier refund_tier_enum DEFAULT 'none',
ADD COLUMN dispute_reason TEXT,
ADD COLUMN is_in_escrow BOOLEAN DEFAULT FALSE;

-- Track the 30% / 40% / 30% installment structure for service providers
ALTER TABLE booking_staff_assignments
ADD COLUMN installment_start_paid BOOLEAN DEFAULT FALSE, -- 30%
ADD COLUMN installment_midpoint_paid BOOLEAN DEFAULT FALSE, -- 40%
ADD COLUMN installment_completion_paid BOOLEAN DEFAULT FALSE; -- 30%

-- 4. SAFETY & COMPLIANCE
-- Vehicles older than 8 years need extra safety inspection tracking
ALTER TABLE vehicles
ADD COLUMN safety_inspection_expiry_date DATE;

-- Emergency SOS Table
CREATE TYPE emergency_status_enum AS ENUM ('active', 'resolved', 'false_alarm');

CREATE TABLE emergency_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES bookings(id),
    triggered_by UUID REFERENCES users(id),
    location GEOMETRY(POINT, 4326),
    alert_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status emergency_status_enum DEFAULT 'active',
    resolved_by UUID REFERENCES users(id),
    resolution_notes TEXT
);

CREATE INDEX idx_emergency_status ON emergency_alerts(status);

-- 5. SPECIAL MARKET RULES: Holiday Pricing Caps
ALTER TABLE price_adjustment_rules
ADD COLUMN is_holiday_rule BOOLEAN DEFAULT FALSE,
ADD CONSTRAINT check_holiday_cap CHECK (
    (is_holiday_rule = FALSE) OR 
    (is_holiday_rule = TRUE AND adjustment_value <= 1.25) -- Caps increase at 25%
);

-- 6. ASSIGNMENT PRIORITY ALGORITHM (Function)
-- Calculates an assignment score based on Proximity (40%), Rating (30%), Response History (20%), Specialization (10%)
CREATE OR REPLACE FUNCTION calculate_provider_assignment_score(
    p_provider_rating DECIMAL,
    p_response_time_mins INTEGER,
    p_distance_km DECIMAL,
    p_specialization_match BOOLEAN
) RETURNS DECIMAL AS $$
DECLARE
    score DECIMAL := 0;
    rating_score DECIMAL;
    response_score DECIMAL;
    proximity_score DECIMAL;
    spec_score DECIMAL;
BEGIN
    -- 1. Rating (30% weight) - Assuming rating is out of 5
    rating_score := (COALESCE(p_provider_rating, 0) / 5.0) * 30;
    
    -- 2. Response Time (20% weight) - Ideal is < 4 hours (240 mins)
    IF p_response_time_mins <= 240 THEN
        response_score := 20;
    ELSIF p_response_time_mins <= 720 THEN -- within 12 hours
        response_score := 10;
    ELSE
        response_score := 0;
    END IF;
    
    -- 3. Proximity (40% weight) - Inverse relation to distance (closer is better)
    -- Assuming max reasonable distance is 50km for scoring purposes
    IF p_distance_km <= 5 THEN
        proximity_score := 40;
    ELSIF p_distance_km <= 20 THEN
        proximity_score := 25;
    ELSIF p_distance_km <= 50 THEN
        proximity_score := 10;
    ELSE
        proximity_score := 0;
    END IF;
    
    -- 4. Specialization Match (10% weight)
    IF p_specialization_match THEN
        spec_score := 10;
    ELSE
        spec_score := 0;
    END IF;
    
    score := rating_score + response_score + proximity_score + spec_score;
    RETURN score;
END;
$$ LANGUAGE plpgsql;

-- 7. QUALITY ASSURANCE TRIGGER
-- Automatically flag providers with < 3.5 rating for performance review
CREATE OR REPLACE FUNCTION check_performance_review()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.reviewee_role IN ('driver', 'guide') THEN
        -- If their average rating drops below 3.5
        IF (SELECT AVG(rating) FROM reviews WHERE reviewee_id = NEW.reviewee_id) < 3.5 THEN
            -- Update consecutive low ratings logic could go here, for simplicity we check average
            IF NEW.reviewee_role = 'driver' THEN
                UPDATE drivers SET performance_review_status = TRUE WHERE user_id = NEW.reviewee_id;
            ELSIF NEW.reviewee_role = 'guide' THEN
                UPDATE guides SET performance_review_status = TRUE WHERE user_id = NEW.reviewee_id;
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_performance 
AFTER INSERT ON reviews 
FOR EACH ROW EXECUTE FUNCTION check_performance_review();
