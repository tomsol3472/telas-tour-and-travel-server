-- =====================================================
-- TELAS TOURISM PLATFORM
-- BUSINESS RULES SCHEMA ENHANCEMENTS
-- =====================================================

-- =====================================================
-- 1. VERIFICATION TIER SYSTEM
-- =====================================================

-- Verification Tiers Enum
CREATE TYPE verification_tier_enum AS ENUM ('basic', 'verified', 'premium');

-- Add verification tier to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS verification_tier verification_tier_enum DEFAULT 'basic',
ADD COLUMN IF NOT EXISTS verification_tier_updated_at TIMESTAMP WITH TIME ZONE;

-- Verification Tier History
CREATE TABLE IF NOT EXISTS verification_tier_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    previous_tier verification_tier_enum,
    new_tier verification_tier_enum NOT NULL,
    tier_change_reason TEXT,
    documentation_completeness_score DECIMAL(5,2),
    years_experience INTEGER,
    average_rating DECIMAL(3,2),
    total_completed_bookings INTEGER,
    changed_by UUID REFERENCES users(id),
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_verification_tier_history_user ON verification_tier_history(user_id);
CREATE INDEX idx_verification_tier_history_date ON verification_tier_history(changed_at);

-- =====================================================
-- 2. CANCELLATION POLICIES
-- =====================================================

-- Cancellation Policy Rules
CREATE TABLE IF NOT EXISTS cancellation_policies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    policy_name VARCHAR(100) NOT NULL,
    tour_type tour_type_enum,
    tour_duration_days INTEGER,
    hours_before_start INTEGER NOT NULL,
    refund_percentage DECIMAL(5,2) NOT NULL CHECK (refund_percentage >= 0 AND refund_percentage <= 100),
    penalty_percentage DECIMAL(5,2) NOT NULL CHECK (penalty_percentage >= 0 AND penalty_percentage <= 100),
    applies_to_domestic BOOLEAN DEFAULT TRUE,
    applies_to_international BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_percentages CHECK (refund_percentage + penalty_percentage <= 100)
);

CREATE INDEX idx_cancellation_policies_type ON cancellation_policies(tour_type);
CREATE INDEX idx_cancellation_policies_active ON cancellation_policies(is_active);

-- Insert default cancellation policies
INSERT INTO cancellation_policies (policy_name, tour_duration_days, hours_before_start, refund_percentage, penalty_percentage) VALUES
('Day Tour - Free Cancellation', 1, 48, 100, 0),
('Day Tour - Late Cancellation', 1, 24, 50, 50),
('Day Tour - Very Late', 1, 0, 0, 100),
('Multi-Day - Early Cancellation', 2, 168, 75, 25),  -- 7 days
('Multi-Day - Medium Notice', 2, 336, 50, 50),       -- 14 days
('Multi-Day - Late Cancellation', 2, 0, 0, 100);

-- =====================================================
-- 3. PRICE LOCK SYSTEM
-- =====================================================

-- Price Lock Records
CREATE TABLE IF NOT EXISTS booking_price_locks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
    locked_price DECIMAL(12,2) NOT NULL,
    locked_currency VARCHAR(3) NOT NULL,
    exchange_rate DECIMAL(10,4),
    price_breakdown JSONB NOT NULL,
    locked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    locked_by UUID REFERENCES users(id),
    lock_expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    subsequent_price_changes JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_price_locks_booking ON booking_price_locks(booking_id);
CREATE INDEX idx_price_locks_active ON booking_price_locks(is_active);
CREATE INDEX idx_price_locks_expiry ON booking_price_locks(lock_expires_at);

-- =====================================================
-- 4. SERVICE PROVIDER RESPONSE TRACKING
-- =====================================================

-- Response Time Tracking
CREATE TABLE IF NOT EXISTS provider_response_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    inquiry_type VARCHAR(50) NOT NULL,
    inquiry_sent_at TIMESTAMP WITH TIME ZONE NOT NULL,
    response_received_at TIMESTAMP WITH TIME ZONE,
    response_time_minutes INTEGER GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (response_received_at - inquiry_sent_at)) / 60
    ) STORED,
    was_business_hours BOOLEAN NOT NULL,
    required_response_time_hours INTEGER NOT NULL,
    was_on_time BOOLEAN GENERATED ALWAYS AS (
        CASE 
            WHEN response_received_at IS NULL THEN FALSE
            WHEN EXTRACT(EPOCH FROM (response_received_at - inquiry_sent_at)) / 3600 <= required_response_time_hours THEN TRUE
            ELSE FALSE
        END
    ) STORED,
    booking_id UUID REFERENCES bookings(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_response_tracking_provider ON provider_response_tracking(provider_id);
CREATE INDEX idx_response_tracking_booking ON provider_response_tracking(booking_id);
CREATE INDEX idx_response_tracking_date ON provider_response_tracking(inquiry_sent_at);

-- Provider Response Metrics (Materialized View)
CREATE MATERIALIZED VIEW IF NOT EXISTS provider_response_metrics AS
SELECT 
    provider_id,
    COUNT(*) as total_inquiries,
    AVG(response_time_minutes) as avg_response_time_minutes,
    COUNT(*) FILTER (WHERE was_on_time = TRUE) as on_time_responses,
    COUNT(*) FILTER (WHERE was_on_time = FALSE) as late_responses,
    ROUND(100.0 * COUNT(*) FILTER (WHERE was_on_time = TRUE) / NULLIF(COUNT(*), 0), 2) as on_time_percentage,
    MAX(inquiry_sent_at) as last_inquiry_date
FROM provider_response_tracking
WHERE response_received_at IS NOT NULL
GROUP BY provider_id;

CREATE UNIQUE INDEX idx_response_metrics_provider ON provider_response_metrics(provider_id);

-- =====================================================
-- 5. AVAILABILITY MANAGEMENT
-- =====================================================

-- Provider Availability Updates
CREATE TABLE IF NOT EXISTS provider_availability_updates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    availability_date DATE NOT NULL,
    is_available BOOLEAN NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    hours_before_date INTEGER GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (availability_date::timestamp - updated_at)) / 3600
    ) STORED,
    meets_48hr_requirement BOOLEAN GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (availability_date::timestamp - updated_at)) / 3600 >= 48
    ) STORED,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_availability_updates_provider ON provider_availability_updates(provider_id);
CREATE INDEX idx_availability_updates_date ON provider_availability_updates(availability_date);

-- Add reliability score to drivers and guides
ALTER TABLE drivers 
ADD COLUMN IF NOT EXISTS reliability_score DECIMAL(5,2) DEFAULT 100.0 CHECK (reliability_score >= 0 AND reliability_score <= 100),
ADD COLUMN IF NOT EXISTS last_minute_cancellations INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS reliability_updated_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE guides 
ADD COLUMN IF NOT EXISTS reliability_score DECIMAL(5,2) DEFAULT 100.0 CHECK (reliability_score >= 0 AND reliability_score <= 100),
ADD COLUMN IF NOT EXISTS last_minute_cancellations INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS reliability_updated_at TIMESTAMP WITH TIME ZONE;

-- =====================================================
-- 6. DISPUTE MANAGEMENT SYSTEM
-- =====================================================

-- Dispute Status Enum
CREATE TYPE dispute_status_enum AS ENUM ('open', 'under_review', 'in_mediation', 'resolved', 'escalated', 'closed');
CREATE TYPE dispute_resolution_enum AS ENUM ('full_refund', 'partial_refund', 'no_refund', 'compensation', 'service_credit');

-- Disputes Table
CREATE TABLE IF NOT EXISTS booking_disputes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dispute_code VARCHAR(50) UNIQUE NOT NULL,
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    raised_by UUID NOT NULL REFERENCES users(id),
    dispute_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    evidence_urls TEXT[],
    status dispute_status_enum DEFAULT 'open',
    priority notification_priority_enum DEFAULT 'normal',
    disputed_amount DECIMAL(12,2),
    escrow_amount DECIMAL(12,2),
    escrow_held_at TIMESTAMP WITH TIME ZONE,
    resolution_type dispute_resolution_enum,
    resolution_amount DECIMAL(12,2),
    resolution_notes TEXT,
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    mediation_started_at TIMESTAMP WITH TIME ZONE,
    mediation_deadline TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_disputes_booking ON booking_disputes(booking_id);
CREATE INDEX idx_disputes_status ON booking_disputes(status);
CREATE INDEX idx_disputes_raised_by ON booking_disputes(raised_by);
CREATE INDEX idx_disputes_created ON booking_disputes(created_at);

-- Dispute Messages
CREATE TABLE IF NOT EXISTS dispute_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dispute_id UUID NOT NULL REFERENCES booking_disputes(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id),
    message TEXT NOT NULL,
    attachments TEXT[],
    is_internal_note BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dispute_messages_dispute ON dispute_messages(dispute_id);
CREATE INDEX idx_dispute_messages_sender ON dispute_messages(sender_id);

-- =====================================================
-- 7. REVIEW AUTHENTICITY VERIFICATION
-- =====================================================

-- Add booking verification to reviews (if reviews table exists)
-- Assuming there's a reviews table, add these columns
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES users(id),
    reviewee_id UUID NOT NULL REFERENCES users(id),
    reviewee_type user_role_enum NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(200),
    comment TEXT,
    photos_urls TEXT[],
    is_verified_booking BOOLEAN DEFAULT TRUE,
    is_moderated BOOLEAN DEFAULT FALSE,
    moderation_status VARCHAR(50) DEFAULT 'pending',
    moderation_notes TEXT,
    moderated_by UUID REFERENCES users(id),
    moderated_at TIMESTAMP WITH TIME ZONE,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_verified_review CHECK (
        is_verified_booking = TRUE OR booking_id IS NOT NULL
    )
);

CREATE INDEX idx_reviews_booking ON reviews(booking_id);
CREATE INDEX idx_reviews_reviewer ON reviews(reviewer_id);
CREATE INDEX idx_reviews_reviewee ON reviews(reviewee_id);
CREATE INDEX idx_reviews_verified ON reviews(is_verified_booking);

-- =====================================================
-- 8. EMERGENCY PROTOCOL SYSTEM
-- =====================================================

-- Emergency SOS Logs
CREATE TABLE IF NOT EXISTS emergency_sos_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sos_code VARCHAR(50) UNIQUE NOT NULL,
    booking_id UUID REFERENCES bookings(id),
    triggered_by UUID NOT NULL REFERENCES users(id),
    trigger_location GEOMETRY(POINT, 4326),
    trigger_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    emergency_type VARCHAR(100),
    description TEXT,
    severity notification_priority_enum DEFAULT 'urgent',
    status VARCHAR(50) DEFAULT 'active',
    local_emergency_notified BOOLEAN DEFAULT FALSE,
    local_emergency_notified_at TIMESTAMP WITH TIME ZONE,
    nearest_providers_notified BOOLEAN DEFAULT FALSE,
    nearest_providers_notified_at TIMESTAMP WITH TIME ZONE,
    platform_safety_notified BOOLEAN DEFAULT FALSE,
    platform_safety_notified_at TIMESTAMP WITH TIME ZONE,
    response_time_minutes INTEGER,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sos_logs_booking ON emergency_sos_logs(booking_id);
CREATE INDEX idx_sos_logs_triggered_by ON emergency_sos_logs(triggered_by);
CREATE INDEX idx_sos_logs_status ON emergency_sos_logs(status);
CREATE INDEX idx_sos_logs_location ON emergency_sos_logs USING GIST(trigger_location);

-- Emergency Contacts
CREATE TABLE IF NOT EXISTS emergency_contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    region VARCHAR(100) NOT NULL,
    city VARCHAR(100),
    contact_type VARCHAR(50) NOT NULL,
    organization_name VARCHAR(200) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    alternate_phone VARCHAR(20),
    email VARCHAR(255),
    address TEXT,
    location GEOMETRY(POINT, 4326),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_emergency_contacts_region ON emergency_contacts(region);
CREATE INDEX idx_emergency_contacts_type ON emergency_contacts(contact_type);
CREATE INDEX idx_emergency_contacts_location ON emergency_contacts USING GIST(location);

-- =====================================================
-- 9. PAYMENT INSTALLMENT TRACKING
-- =====================================================

-- Payment Installments
CREATE TABLE IF NOT EXISTS payment_installments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    installment_number INTEGER NOT NULL,
    installment_type VARCHAR(50) NOT NULL,
    percentage DECIMAL(5,2) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'ETB',
    due_date DATE,
    trigger_condition VARCHAR(100),
    payment_status payment_status_enum DEFAULT 'pending',
    paid_at TIMESTAMP WITH TIME ZONE,
    payment_id UUID REFERENCES payments(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(booking_id, installment_number)
);

CREATE INDEX idx_installments_booking ON payment_installments(booking_id);
CREATE INDEX idx_installments_status ON payment_installments(payment_status);
CREATE INDEX idx_installments_due_date ON payment_installments(due_date);

-- =====================================================
-- 10. DYNAMIC PRICING HISTORY
-- =====================================================

-- Price Change History
CREATE TABLE IF NOT EXISTS package_price_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    package_id UUID NOT NULL REFERENCES tour_packages(id) ON DELETE CASCADE,
    pricing_id UUID REFERENCES package_pricing(id),
    previous_price DECIMAL(10,2),
    new_price DECIMAL(10,2) NOT NULL,
    price_change_percentage DECIMAL(5,2),
    change_reason VARCHAR(200),
    cost_factors JSONB,
    changed_by UUID REFERENCES users(id),
    effective_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_price_history_package ON package_price_history(package_id);
CREATE INDEX idx_price_history_date ON package_price_history(effective_from);

-- =====================================================
-- 11. PROFIT MARGIN ALERTS
-- =====================================================

-- Profit Margin Thresholds
CREATE TABLE IF NOT EXISTS profit_margin_thresholds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    package_id UUID REFERENCES tour_packages(id),
    tour_type tour_type_enum,
    minimum_margin_percentage DECIMAL(5,2) NOT NULL DEFAULT 20.0,
    warning_margin_percentage DECIMAL(5,2) NOT NULL DEFAULT 25.0,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Profit Margin Alerts
CREATE TABLE IF NOT EXISTS profit_margin_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    package_id UUID NOT NULL REFERENCES tour_packages(id),
    current_margin_percentage DECIMAL(5,2) NOT NULL,
    threshold_margin_percentage DECIMAL(5,2) NOT NULL,
    alert_type VARCHAR(50) NOT NULL,
    cost_change_details JSONB,
    is_acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by UUID REFERENCES users(id),
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_margin_alerts_package ON profit_margin_alerts(package_id);
CREATE INDEX idx_margin_alerts_acknowledged ON profit_margin_alerts(is_acknowledged);

-- =====================================================
-- 12. PERFORMANCE REVIEW SYSTEM
-- =====================================================

-- Performance Review Status
CREATE TYPE performance_review_status_enum AS ENUM ('pending', 'in_progress', 'completed', 'failed', 'passed');

-- Performance Reviews
CREATE TABLE IF NOT EXISTS provider_performance_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    review_type VARCHAR(50) NOT NULL,
    trigger_reason TEXT NOT NULL,
    current_rating DECIMAL(3,2),
    current_completion_rate DECIMAL(5,2),
    current_response_time_avg DECIMAL(6,2),
    review_status performance_review_status_enum DEFAULT 'pending',
    review_started_at TIMESTAMP WITH TIME ZONE,
    review_completed_at TIMESTAMP WITH TIME ZONE,
    reviewer_id UUID REFERENCES users(id),
    review_notes TEXT,
    action_required TEXT,
    retraining_required BOOLEAN DEFAULT FALSE,
    retraining_completed_at TIMESTAMP WITH TIME ZONE,
    can_accept_bookings BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_performance_reviews_provider ON provider_performance_reviews(provider_id);
CREATE INDEX idx_performance_reviews_status ON provider_performance_reviews(review_status);

-- =====================================================
-- 13. DATA RETENTION & ARCHIVAL
-- =====================================================

-- Data Retention Policies
CREATE TABLE IF NOT EXISTS data_retention_policies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    data_type VARCHAR(100) NOT NULL UNIQUE,
    retention_period_years INTEGER NOT NULL,
    archive_after_years INTEGER,
    delete_after_years INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insert default retention policies
INSERT INTO data_retention_policies (data_type, retention_period_years, archive_after_years, delete_after_years) VALUES
('booking_records', 7, NULL, NULL),
('chat_messages', 2, NULL, 2),
('user_data_inactive', 3, 3, NULL),
('payment_records', 7, NULL, NULL),
('trip_tracking', 2, 2, NULL);

-- Archived Data Log
CREATE TABLE IF NOT EXISTS archived_data_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    data_type VARCHAR(100) NOT NULL,
    record_count INTEGER NOT NULL,
    archive_location TEXT NOT NULL,
    archived_from_date DATE,
    archived_to_date DATE,
    archived_by UUID REFERENCES users(id),
    archived_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 14. SYSTEM AUDIT LOGS
-- =====================================================

-- Comprehensive Audit Logs
CREATE TABLE IF NOT EXISTS system_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    action_type VARCHAR(100) NOT NULL,
    table_name VARCHAR(100),
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_user ON system_audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON system_audit_logs(action_type);
CREATE INDEX idx_audit_logs_table ON system_audit_logs(table_name);
CREATE INDEX idx_audit_logs_date ON system_audit_logs(created_at);

-- =====================================================
-- 15. NOTIFICATION PREFERENCES
-- =====================================================

-- User Notification Preferences
CREATE TABLE IF NOT EXISTS user_notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    email_notifications BOOLEAN DEFAULT TRUE,
    sms_notifications BOOLEAN DEFAULT TRUE,
    push_notifications BOOLEAN DEFAULT TRUE,
    booking_updates BOOLEAN DEFAULT TRUE,
    payment_updates BOOLEAN DEFAULT TRUE,
    promotional_messages BOOLEAN DEFAULT FALSE,
    price_alerts BOOLEAN DEFAULT TRUE,
    emergency_alerts BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 16. SYSTEM MAINTENANCE WINDOWS
-- =====================================================

-- Maintenance Windows
CREATE TABLE IF NOT EXISTS system_maintenance_windows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    maintenance_type VARCHAR(100) NOT NULL,
    description TEXT,
    scheduled_start TIMESTAMP WITH TIME ZONE NOT NULL,
    scheduled_end TIMESTAMP WITH TIME ZONE NOT NULL,
    actual_start TIMESTAMP WITH TIME ZONE,
    actual_end TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50) DEFAULT 'scheduled',
    notification_sent BOOLEAN DEFAULT FALSE,
    notification_sent_at TIMESTAMP WITH TIME ZONE,
    affected_services TEXT[],
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_maintenance_time CHECK (scheduled_end > scheduled_start)
);

CREATE INDEX idx_maintenance_windows_start ON system_maintenance_windows(scheduled_start);
CREATE INDEX idx_maintenance_windows_status ON system_maintenance_windows(status);

-- =====================================================
-- REFRESH MATERIALIZED VIEWS
-- =====================================================

-- Function to refresh all materialized views
CREATE OR REPLACE FUNCTION refresh_all_materialized_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY provider_response_metrics;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =====================================================

-- Update updated_at timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers to relevant tables
CREATE TRIGGER update_cancellation_policies_updated_at BEFORE UPDATE ON cancellation_policies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_disputes_updated_at BEFORE UPDATE ON booking_disputes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_performance_reviews_updated_at BEFORE UPDATE ON provider_performance_reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE verification_tier_history IS 'Tracks changes in service provider verification tiers (Basic, Verified, Premium)';
COMMENT ON TABLE cancellation_policies IS 'Defines tiered cancellation rules with refund percentages based on notice period';
COMMENT ON TABLE booking_price_locks IS 'Ensures price guarantee - locks booking price regardless of subsequent rate changes';
COMMENT ON TABLE provider_response_tracking IS 'Monitors service provider response times (4hr business hours, 12hr off-hours requirement)';
COMMENT ON TABLE booking_disputes IS 'Manages dispute resolution with escrow system and tiered refund processing';
COMMENT ON TABLE emergency_sos_logs IS 'Tracks emergency SOS signals and response protocol execution';
COMMENT ON TABLE payment_installments IS 'Manages multi-day tour installment payments (30%-40%-30% release schedule)';
COMMENT ON TABLE profit_margin_alerts IS 'Alerts agency when cost changes impact profit margins below threshold';
COMMENT ON TABLE provider_performance_reviews IS 'Tracks performance reviews for providers below quality thresholds';
COMMENT ON TABLE data_retention_policies IS 'Defines data retention rules (7yr bookings, 2yr messages, 3yr inactive users)';

-- =====================================================
-- END OF SCHEMA ENHANCEMENTS
-- =====================================================
