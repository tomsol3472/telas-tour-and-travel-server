-- =====================================================
-- TELAS TOUR AND TRAVEL AGENCY PLATFORM
-- COMPLETE DATABASE SCHEMA v2.1 (FIXED)
-- =====================================================

-- Enable UUID extension for distributed ID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- =====================================================
-- ENUM TYPES
-- =====================================================

-- User Management Enums
CREATE TYPE user_role_enum AS ENUM ('tourist', 'driver', 'guide', 'admin', 'agency_staff', 'scout', 'transporter', 'cook', 'porter', 'security');
CREATE TYPE user_status_enum AS ENUM ('active', 'inactive', 'suspended', 'pending', 'under_review');
CREATE TYPE verification_status_enum AS ENUM ('pending', 'verified', 'rejected', 'expired');
CREATE TYPE gender_enum AS ENUM ('male', 'female', 'other');

-- Booking & Tour Enums (UPDATED: added 'rejected')
CREATE TYPE booking_status_enum AS ENUM ('draft', 'pending', 'confirmed', 'assigned', 'ongoing', 'completed', 'cancelled', 'refunded', 'rejected');
CREATE TYPE payment_status_enum AS ENUM ('pending', 'paid', 'failed', 'refunded', 'partially_paid');
CREATE TYPE tour_type_enum AS ENUM ('historical', 'photography', 'research', 'family', 'adventure', 'cultural', 'religious', 'wildlife', 'honeymoon', 'business');
CREATE TYPE difficulty_level_enum AS ENUM ('easy', 'moderate', 'difficult', 'challenging');
CREATE TYPE season_type_enum AS ENUM ('dry', 'rainy', 'both');
CREATE TYPE payment_calc_method_enum AS ENUM ('per_km', 'per_hour', 'per_person', 'per_day', 'fixed', 'percentage');

-- Vehicle & Transport Enums
CREATE TYPE vehicle_type_enum AS ENUM ('sedan', 'suv', '4x4', 'minibus', 'coaster', 'bus', 'boat', 'other');

-- Communication Enums
CREATE TYPE message_type_enum AS ENUM ('text', 'image', 'file', 'location', 'system');
CREATE TYPE notification_priority_enum AS ENUM ('low', 'normal', 'high', 'urgent');

-- =====================================================
-- 1. CORE USER MANAGEMENT
-- =====================================================

-- Main Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_role user_role_enum NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20) UNIQUE NOT NULL,
    phone_country_code VARCHAR(5) DEFAULT '+251',
    password_hash VARCHAR(255) NOT NULL,
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_phone_verified BOOLEAN DEFAULT FALSE,
    verification_token VARCHAR(100),
    verification_expires TIMESTAMP WITH TIME ZONE,
    otp_code VARCHAR(6),
    otp_expires TIMESTAMP WITH TIME ZONE,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE,
    status user_status_enum DEFAULT 'pending',
    profile_picture_url TEXT,
    preferred_language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50) DEFAULT 'Africa/Addis_Ababa',
    CONSTRAINT valid_phone CHECK (phone ~ '^[0-9]{9,10}$'),
    CONSTRAINT valid_email CHECK (email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

CREATE INDEX idx_users_role ON users(user_role);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_created ON users(created_at);

-- Generate OTP Trigger
CREATE OR REPLACE FUNCTION generate_otp_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.otp_code IS NULL THEN
        -- Generate a 6 digit random number
        NEW.otp_code := lpad(floor(random() * 900000 + 100000)::text, 6, '0');
        NEW.otp_expires := CURRENT_TIMESTAMP + INTERVAL '10 minutes';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_otp_on_insert
BEFORE INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION generate_otp_code();

-- User Profiles
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    date_of_birth DATE,
    gender gender_enum,
    nationality VARCHAR(100),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100) DEFAULT 'Ethiopia',
    postal_code VARCHAR(20),
    emergency_contact_name VARCHAR(200),
    emergency_contact_phone VARCHAR(20),
    emergency_contact_relationship VARCHAR(100),
    dietary_restrictions TEXT[],
    allergies TEXT[],
    medical_conditions TEXT[],
    passport_number VARCHAR(50),
    passport_expiry DATE,
    visa_number VARCHAR(50),
    visa_expiry DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_profiles_user ON user_profiles(user_id);
CREATE INDEX idx_profiles_passport ON user_profiles(passport_number);

-- Departments for Staff Grouping
CREATE TABLE staff_departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_code VARCHAR(50) UNIQUE NOT NULL,
    department_name VARCHAR(100) NOT NULL,
    description TEXT,
    payment_calculation_method payment_calc_method_enum NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Driver Specific Information
CREATE TABLE drivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    department_id UUID REFERENCES staff_departments(id),
    license_number VARCHAR(50) UNIQUE NOT NULL,
    license_issue_date DATE NOT NULL,
    license_expiry_date DATE NOT NULL,
    license_photo_url TEXT,
    years_experience INTEGER DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 0.0,
    total_trips INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    current_location GEOMETRY(POINT, 4326),
    service_areas TEXT[],
    languages_spoken TEXT[] DEFAULT ARRAY['Amharic', 'English'],
    max_daily_hours INTEGER DEFAULT 10,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CHECK (rating >= 0 AND rating <= 5)
);

CREATE INDEX idx_drivers_available ON drivers(is_available);
CREATE INDEX idx_drivers_rating ON drivers(rating);
CREATE INDEX idx_drivers_dept ON drivers(department_id);
CREATE INDEX idx_drivers_location ON drivers USING GIST(current_location);

-- Guide Specific Information
CREATE TABLE guides (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    department_id UUID REFERENCES staff_departments(id),
    guide_license_number VARCHAR(50) UNIQUE NOT NULL,
    license_issue_date DATE NOT NULL,
    license_expiry_date DATE NOT NULL,
    license_photo_url TEXT,
    specialization TEXT[],
    languages_spoken TEXT[] NOT NULL,
    languages_certified TEXT[],
    years_experience INTEGER DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 0.0,
    total_tours INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    hourly_rate DECIMAL(10,2),
    daily_rate DECIMAL(10,2),
    max_group_size INTEGER DEFAULT 15,
    has_first_aid_cert BOOLEAN DEFAULT FALSE,
    first_aid_expiry DATE,
    education_background TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CHECK (rating >= 0 AND rating <= 5)
);

CREATE INDEX idx_guides_dept ON guides(department_id);
CREATE INDEX idx_guides_available ON guides(is_available);

-- Tourist Specific Information
CREATE TABLE tourists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    travel_frequency INTEGER DEFAULT 0,
    preferred_tour_types tour_type_enum[],
    preferred_accommodation TEXT[],
    preferred_transport TEXT[],
    dietary_preferences TEXT[],
    disability_access_needs BOOLEAN DEFAULT FALSE,
    disability_details TEXT,
    frequent_flyer_numbers JSONB,
    loyalty_points INTEGER DEFAULT 0,
    total_bookings INTEGER DEFAULT 0,
    average_rating_given DECIMAL(3,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Verification Documents
CREATE TABLE verification_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL,
    document_number VARCHAR(100),
    front_image_url TEXT NOT NULL,
    back_image_url TEXT,
    issue_date DATE,
    expiry_date DATE,
    issuing_authority VARCHAR(200),
    verification_status verification_status_enum DEFAULT 'pending',
    verified_by UUID REFERENCES users(id),
    verified_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_document_user ON verification_documents(user_id);
CREATE INDEX idx_document_status ON verification_documents(verification_status);

-- =====================================================
-- 2. VEHICLE MANAGEMENT
-- =====================================================

-- Vehicle Categories
CREATE TABLE vehicle_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    passenger_capacity INTEGER NOT NULL,
    luggage_capacity INTEGER,
    vehicle_type vehicle_type_enum NOT NULL,
    icon_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Vehicles
CREATE TABLE vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    category_id UUID REFERENCES vehicle_categories(id),
    plate_number VARCHAR(20) UNIQUE NOT NULL,
    make VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INTEGER,
    color VARCHAR(50),
    registration_number VARCHAR(50),
    registration_expiry DATE,
    insurance_number VARCHAR(100),
    insurance_expiry DATE,
    insurance_photo_url TEXT,
    fuel_type VARCHAR(50),
    transmission VARCHAR(50),
    features TEXT[],
    photos_urls TEXT[],
    is_active BOOLEAN DEFAULT TRUE,
    current_mileage INTEGER,
    last_service_date DATE,
    next_service_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_vehicles_driver ON vehicles(driver_id);
CREATE INDEX idx_vehicles_active ON vehicles(is_active);
CREATE INDEX idx_vehicles_plate ON vehicles(plate_number);

-- =====================================================
-- 3. DESTINATION & TOUR MANAGEMENT
-- =====================================================

-- Destinations
CREATE TABLE destinations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    region VARCHAR(100) NOT NULL,
    city VARCHAR(100),
    location GEOMETRY(POINT, 4326),
    altitude INTEGER,
    is_unesco_site BOOLEAN DEFAULT FALSE,
    description TEXT,
    best_season season_type_enum DEFAULT 'both',
    difficulty difficulty_level_enum DEFAULT 'moderate',
    avg_visit_duration_hours INTEGER,
    entry_fee_local DECIMAL(10,2),
    entry_fee_foreign DECIMAL(10,2),
    photos_urls TEXT[],
    video_url TEXT,
    virtual_tour_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_destinations_region ON destinations(region);
CREATE INDEX idx_destinations_unesco ON destinations(is_unesco_site);
CREATE INDEX idx_destinations_location ON destinations USING GIST(location);

-- Tour Packages
CREATE TABLE tour_packages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    package_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    tour_type tour_type_enum NOT NULL,
    difficulty difficulty_level_enum DEFAULT 'moderate',
    duration_days INTEGER NOT NULL,
    duration_nights INTEGER NOT NULL,
    min_group_size INTEGER DEFAULT 1,
    max_group_size INTEGER DEFAULT 20,
    season_recommendation season_type_enum DEFAULT 'both',
    tags TEXT[],
    inclusions TEXT[] NOT NULL,
    exclusions TEXT[],
    requirements TEXT[],
    important_notes TEXT,
    cancellation_policy TEXT,
    photos_urls TEXT[],
    is_customizable BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tour_packages_type ON tour_packages(tour_type);
CREATE INDEX idx_tour_packages_active ON tour_packages(is_active);
CREATE INDEX idx_tour_packages_code ON tour_packages(package_code);

-- Package Pricing with Dynamic Pricing
CREATE TABLE package_pricing (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    package_id UUID NOT NULL REFERENCES tour_packages(id) ON DELETE CASCADE,
    season VARCHAR(50) NOT NULL,
    start_month INTEGER CHECK (start_month >= 1 AND start_month <= 12),
    end_month INTEGER CHECK (end_month >= 1 AND end_month <= 12),
    price_per_person_local DECIMAL(10,2) NOT NULL,
    price_per_person_diaspora DECIMAL(10,2) NOT NULL,
    price_per_person_international DECIMAL(10,2) NOT NULL,
    child_discount_percentage DECIMAL(5,2) DEFAULT 0,
    infant_discount_percentage DECIMAL(5,2) DEFAULT 0,
    group_discount_percentage DECIMAL(5,2) DEFAULT 0,
    early_bird_discount_percentage DECIMAL(5,2) DEFAULT 0,
    last_minute_discount_percentage DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Package Itinerary
CREATE TABLE package_itineraries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    package_id UUID NOT NULL REFERENCES tour_packages(id) ON DELETE CASCADE,
    day_number INTEGER NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    accommodation_type VARCHAR(100),
    meal_plan VARCHAR(100),
    included_activities TEXT[],
    optional_activities TEXT[],
    distance_km DECIMAL(6,2),
    travel_time_hours DECIMAL(4,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(package_id, day_number)
);

-- Package Destinations
CREATE TABLE package_destinations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    package_id UUID NOT NULL REFERENCES tour_packages(id) ON DELETE CASCADE,
    destination_id UUID NOT NULL REFERENCES destinations(id),
    visit_order INTEGER NOT NULL,
    stay_duration_hours DECIMAL(5,2),
    description TEXT,
    activities TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(package_id, destination_id, visit_order)
);

-- =====================================================
-- 4. PRICE MANAGEMENT SYSTEM
-- =====================================================

-- Base Price Pool
CREATE TABLE base_price_pools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID NOT NULL REFERENCES staff_departments(id) ON DELETE CASCADE,
    price_per_unit DECIMAL(10,2) NOT NULL,
    unit_type VARCHAR(50) NOT NULL,
    currency VARCHAR(3) DEFAULT 'ETB',
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    min_units INTEGER DEFAULT 1,
    max_units INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_dates CHECK (expiry_date IS NULL OR expiry_date > effective_date)
);

CREATE INDEX idx_base_price_department ON base_price_pools(department_id);
CREATE INDEX idx_base_price_active ON base_price_pools(is_active);

-- Staff Base Prices
CREATE TABLE staff_base_prices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    staff_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    department_id UUID NOT NULL REFERENCES staff_departments(id),
    base_price_per_unit DECIMAL(10,2) NOT NULL,
    unit_type VARCHAR(50) NOT NULL,
    currency VARCHAR(3) DEFAULT 'ETB',
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(staff_id, department_id, effective_date)
);

-- Price Adjustment Rules
CREATE TABLE price_adjustment_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_name VARCHAR(100) NOT NULL,
    rule_type VARCHAR(50) NOT NULL,
    department_id UUID REFERENCES staff_departments(id),
    applies_to_staff_type user_role_enum,
    adjustment_type VARCHAR(50) NOT NULL,
    adjustment_value DECIMAL(10,2) NOT NULL,
    min_adjustment DECIMAL(10,2),
    max_adjustment DECIMAL(10,2),
    condition_expression TEXT,
    effective_from_date DATE,
    effective_to_date DATE,
    effective_from_time TIME,
    effective_to_time TIME,
    days_of_week INTEGER[],
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 5. BOOKING MANAGEMENT
-- =====================================================

-- Main Bookings Table
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_code VARCHAR(50) UNIQUE NOT NULL,
    tourist_id UUID NOT NULL REFERENCES tourists(id) ON DELETE CASCADE,
    package_id UUID REFERENCES tour_packages(id),
    is_custom_tour BOOLEAN DEFAULT FALSE,
    custom_tour_name VARCHAR(200),
    custom_tour_description TEXT,
    status booking_status_enum DEFAULT 'pending',
    booking_date DATE NOT NULL DEFAULT CURRENT_DATE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    number_of_adults INTEGER NOT NULL DEFAULT 1,
    number_of_children INTEGER DEFAULT 0,
    number_of_infants INTEGER DEFAULT 0,
    total_persons INTEGER GENERATED ALWAYS AS (number_of_adults + number_of_children + number_of_infants) STORED,
    special_requests TEXT,
    dietary_requirements TEXT[],
    accommodation_preference VARCHAR(50),
    transport_preference VARCHAR(100),
    guide_preference VARCHAR(100),
    estimated_distance_km DECIMAL(8,2),
    estimated_duration_hours DECIMAL(6,2),
    base_price DECIMAL(12,2),
    taxes DECIMAL(10,2),
    service_fee DECIMAL(10,2),
    total_amount DECIMAL(12,2),
    discount_amount DECIMAL(10,2) DEFAULT 0,
    discount_code VARCHAR(50),
    final_amount DECIMAL(12,2),
    currency VARCHAR(3) DEFAULT 'ETB',
    payment_status payment_status_enum DEFAULT 'pending',
    assigned_driver_id UUID REFERENCES drivers(id),
    assigned_guide_id UUID REFERENCES guides(id),
    assigned_vehicle_id UUID REFERENCES vehicles(id),
    calculated_distance_km DECIMAL(8,2),
    calculated_duration_hours DECIMAL(6,2),
    total_staff_cost DECIMAL(12,2) DEFAULT 0,
    agency_profit DECIMAL(12,2) GENERATED ALWAYS AS (final_amount - total_staff_cost - taxes - service_fee) STORED,
    base_price_breakdown JSONB,
    staff_payments_breakdown JSONB,
    rejected_reason TEXT,
    cancelled_by UUID REFERENCES users(id),
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancellation_charges DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CHECK (start_date >= booking_date),
    CHECK (end_date >= start_date)
);

CREATE INDEX idx_bookings_tourist ON bookings(tourist_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_dates ON bookings(start_date, end_date);
CREATE INDEX idx_bookings_payment ON bookings(payment_status);
CREATE INDEX idx_bookings_assigned_driver ON bookings(assigned_driver_id);
CREATE INDEX idx_bookings_assigned_guide ON bookings(assigned_guide_id);
CREATE INDEX idx_bookings_code ON bookings(booking_code);

-- Booking Staff Assignments
CREATE TABLE booking_staff_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    staff_id UUID NOT NULL REFERENCES users(id),
    staff_role user_role_enum NOT NULL,
    department_id UUID REFERENCES staff_departments(id),
    assignment_type VARCHAR(50) NOT NULL,
    price_calculation_method VARCHAR(50) NOT NULL,
    units_assigned DECIMAL(10,2) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) GENERATED ALWAYS AS (units_assigned * unit_price) STORED,
    bonus_amount DECIMAL(10,2) DEFAULT 0,
    deduction_amount DECIMAL(10,2) DEFAULT 0,
    final_payment_amount DECIMAL(10,2) GENERATED ALWAYS AS (units_assigned * unit_price + bonus_amount - deduction_amount) STORED,
    payment_status payment_status_enum DEFAULT 'pending',
    paid_at TIMESTAMP WITH TIME ZONE,
    payment_method VARCHAR(50),
    transaction_id VARCHAR(100),
    assignment_notes TEXT,
    assigned_by UUID REFERENCES users(id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    accepted_by_staff BOOLEAN DEFAULT FALSE,
    accepted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(booking_id, staff_id, assignment_type)
);

CREATE INDEX idx_booking_staff_booking ON booking_staff_assignments(booking_id);
CREATE INDEX idx_booking_staff_staff ON booking_staff_assignments(staff_id);
CREATE INDEX idx_booking_staff_status ON booking_staff_assignments(payment_status);

-- Booking Travelers Details
CREATE TABLE booking_travelers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    traveler_type VARCHAR(20) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    gender gender_enum,
    nationality VARCHAR(100),
    passport_number VARCHAR(50),
    passport_expiry DATE,
    visa_number VARCHAR(50),
    visa_expiry DATE,
    dietary_restrictions TEXT[],
    medical_conditions TEXT[],
    emergency_contact VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Custom Tour Details
CREATE TABLE custom_tour_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    start_destination_id UUID REFERENCES destinations(id),
    end_destination_id UUID REFERENCES destinations(id),
    travel_purpose TEXT,
    specific_requirements TEXT,
    budget_range DECIMAL(12,2),
    preferred_activities TEXT[],
    accommodation_standard VARCHAR(50),
    transport_preference VARCHAR(100),
    guide_required BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Custom Tour Stops
CREATE TABLE custom_tour_stops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    custom_tour_id UUID NOT NULL REFERENCES custom_tour_details(id) ON DELETE CASCADE,
    destination_id UUID NOT NULL REFERENCES destinations(id),
    visit_order INTEGER NOT NULL,
    visit_duration_hours DECIMAL(5,2),
    special_instructions TEXT,
    activities TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(custom_tour_id, visit_order)
);

-- =====================================================
-- 6. PAYMENT PROCESSING
-- =====================================================

-- Payments Table
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_code VARCHAR(50) UNIQUE NOT NULL,
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    tourist_id UUID NOT NULL REFERENCES tourists(id),
    amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'ETB',
    payment_method VARCHAR(50) NOT NULL,
    payment_gateway VARCHAR(50),
    gateway_transaction_id VARCHAR(200),
    gateway_response JSONB,
    payment_status payment_status_enum NOT NULL DEFAULT 'pending',
    paid_at TIMESTAMP WITH TIME ZONE,
    receipt_url TEXT,
    refund_amount DECIMAL(10,2) DEFAULT 0,
    refund_reason TEXT,
    refunded_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_booking ON payments(booking_id);
CREATE INDEX idx_payments_status ON payments(payment_status);
CREATE INDEX idx_payments_gateway_id ON payments(gateway_transaction_id);

-- Staff Payment Transactions
CREATE TABLE staff_payment_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    staff_id UUID NOT NULL REFERENCES users(id),
    booking_id UUID REFERENCES bookings(id),
    assignment_id UUID REFERENCES booking_staff_assignments(id),
    payment_period_start DATE,
    payment_period_end DATE,
    base_amount DECIMAL(10,2) NOT NULL,
    units_worked DECIMAL(10,2),
    unit_price DECIMAL(10,2) NOT NULL,
    adjustments JSONB,
    total_amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'ETB',
    payment_method VARCHAR(50) NOT NULL,
    bank_account_number VARCHAR(50),
    bank_name VARCHAR(100),
    mobile_money_number VARCHAR(20),
    recipient_name VARCHAR(200),
    payment_status payment_status_enum DEFAULT 'pending',
    paid_at TIMESTAMP WITH TIME ZONE,
    transaction_reference VARCHAR(100),
    failure_reason TEXT,
    calculated_by UUID REFERENCES users(id),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_staff_payments_staff ON staff_payment_transactions(staff_id);
CREATE INDEX idx_staff_payments_booking ON staff_payment_transactions(booking_id);
CREATE INDEX idx_staff_payments_status ON staff_payment_transactions(payment_status);

-- =====================================================
-- 7. TRIP EXECUTION & TRACKING
-- =====================================================

-- Trip Assignments
CREATE TABLE trip_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE UNIQUE,
    driver_id UUID NOT NULL REFERENCES drivers(id),
    guide_id UUID REFERENCES guides(id),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id),
    assignment_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    assigned_by UUID REFERENCES users(id),
    assignment_notes TEXT,
    is_accepted BOOLEAN DEFAULT FALSE,
    accepted_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Trip Tracking (Real-time)
CREATE TABLE trip_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    location GEOMETRY(POINT, 4326) NOT NULL,
    altitude DECIMAL(8,2),
    speed DECIMAL(6,2),
    heading DECIMAL(5,2),
    accuracy DECIMAL(5,2),
    battery_level INTEGER,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_trip_tracking_booking ON trip_tracking(booking_id);
CREATE INDEX idx_trip_tracking_time ON trip_tracking(recorded_at);
CREATE INDEX idx_trip_tracking_location ON trip_tracking USING GIST(location);

-- Trip Expenses
CREATE TABLE trip_expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    expense_type VARCHAR(100) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'ETB',
    description TEXT,
    receipt_url TEXT,
    incurred_by UUID REFERENCES users(id),
    incurred_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Trip Payment Calculation
CREATE TABLE trip_payment_calculation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE UNIQUE,
    total_distance_km DECIMAL(8,2) NOT NULL DEFAULT 0,
    distance_rate_used DECIMAL(10,2),
    distance_based_amount DECIMAL(10,2),
    total_hours_worked DECIMAL(6,2) NOT NULL DEFAULT 0,
    hourly_rate_used DECIMAL(10,2),
    time_based_amount DECIMAL(10,2),
    total_persons_served INTEGER NOT NULL DEFAULT 0,
    per_person_rate_used DECIMAL(10,2),
    person_based_amount DECIMAL(10,2),
    fixed_amount DECIMAL(10,2) DEFAULT 0,
    adjustment_amount DECIMAL(10,2) DEFAULT 0,
    final_calculated_amount DECIMAL(12,2) GENERATED ALWAYS AS (
        COALESCE(distance_based_amount, 0) + 
        COALESCE(time_based_amount, 0) + 
        COALESCE(person_based_amount, 0) + 
        COALESCE(fixed_amount, 0) + 
        COALESCE(adjustment_amount, 0)
    ) STORED,
    calculation_notes TEXT,
    calculated_by UUID REFERENCES users(id),
    calculated_at TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 8. REVIEW & RATING SYSTEM
-- =====================================================

-- Reviews Table
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES tourists(id),
    reviewee_id UUID NOT NULL REFERENCES users(id),
    reviewee_role user_role_enum NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(200),
    comment TEXT,
    photos TEXT[],
    response TEXT,
    responded_by UUID REFERENCES users(id),
    responded_at TIMESTAMP WITH TIME ZONE,
    is_verified_booking BOOLEAN DEFAULT TRUE,
    helpful_count INTEGER DEFAULT 0,
    report_count INTEGER DEFAULT 0,
    is_published BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(booking_id, reviewer_id, reviewee_id)
);

CREATE INDEX idx_reviews_reviewee ON reviews(reviewee_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);
CREATE INDEX idx_reviews_booking ON reviews(booking_id);

-- Multi-category Reviews
CREATE TABLE review_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    weight DECIMAL(3,2) DEFAULT 1.0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE review_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES review_categories(id),
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(review_id, category_id)
);

-- =====================================================
-- 9. COMMUNICATION MODULE
-- =====================================================

-- Chat Conversations
CREATE TABLE chat_conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_uuid UUID DEFAULT gen_random_uuid(),
    is_group_chat BOOLEAN DEFAULT FALSE,
    group_name VARCHAR(200),
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Chat Participants
CREATE TABLE chat_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMP WITH TIME ZONE,
    last_read_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(conversation_id, user_id)
);

-- Chat Messages
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id),
    message_type message_type_enum DEFAULT 'text',
    message_text TEXT,
    media_url TEXT,
    location GEOMETRY(POINT, 4326),
    file_name VARCHAR(255),
    file_size INTEGER,
    is_read BOOLEAN DEFAULT FALSE,
    read_by_recipient BOOLEAN DEFAULT FALSE,
    deleted_for_sender BOOLEAN DEFAULT FALSE,
    deleted_for_all BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chat_messages_conversation ON chat_messages(conversation_id);
CREATE INDEX idx_chat_messages_sender ON chat_messages(sender_id);

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(100) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    action_url TEXT,
    priority notification_priority_enum DEFAULT 'normal',
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at);

-- =====================================================
-- 10. SUPPORT TICKETS
-- =====================================================

CREATE TABLE support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_code VARCHAR(50) UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES bookings(id),
    subject VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100) NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium',
    status VARCHAR(50) DEFAULT 'open',
    assigned_to UUID REFERENCES users(id),
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tickets_user ON support_tickets(user_id);
CREATE INDEX idx_tickets_status ON support_tickets(status);

-- Ticket Messages
CREATE TABLE ticket_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id),
    message TEXT NOT NULL,
    attachments_urls TEXT[],
    is_internal_note BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 11. ADMIN & SYSTEM MANAGEMENT
-- =====================================================

-- System Configuration
CREATE TABLE system_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT,
    config_type VARCHAR(50) DEFAULT 'string',
    category VARCHAR(100),
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- API Integrations
CREATE TABLE api_integrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_name VARCHAR(100) NOT NULL,
    api_key_encrypted TEXT,
    api_secret_encrypted TEXT,
    base_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    sandbox_mode BOOLEAN DEFAULT FALSE,
    last_success_at TIMESTAMP WITH TIME ZONE,
    failure_count INTEGER DEFAULT 0,
    rate_limit_per_minute INTEGER,
    config JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Audit Logs
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100),
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    location VARCHAR(200),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_created ON audit_logs(created_at);

-- =====================================================
-- 12. ANALYTICS & REPORTING VIEWS
-- =====================================================

-- Booking Summary View
CREATE VIEW booking_summary AS
SELECT 
    b.id,
    b.booking_code,
    b.booking_date,
    b.start_date,
    b.end_date,
    CONCAT(up.first_name, ' ', up.last_name) as tourist_name,
    b.status,
    b.total_persons,
    b.final_amount,
    b.payment_status,
    b.total_staff_cost,
    b.agency_profit
FROM bookings b
JOIN tourists t ON b.tourist_id = t.id
JOIN users u ON t.user_id = u.id
JOIN user_profiles up ON u.id = up.user_id;

-- Revenue Summary View
CREATE VIEW revenue_summary AS
SELECT 
    DATE_TRUNC('month', b.booking_date) as month,
    COUNT(*) as total_bookings,
    SUM(b.final_amount) as total_revenue,
    SUM(CASE WHEN b.payment_status = 'paid' THEN b.final_amount ELSE 0 END) as paid_revenue,
    AVG(b.final_amount) as avg_booking_value,
    COUNT(DISTINCT b.tourist_id) as unique_tourists,
    SUM(b.total_staff_cost) as total_staff_cost,
    SUM(b.agency_profit) as total_profit
FROM bookings b
WHERE b.status NOT IN ('cancelled', 'rejected')
GROUP BY DATE_TRUNC('month', b.booking_date);

-- Staff Performance View
CREATE VIEW staff_performance AS
SELECT 
    u.id as user_id,
    CONCAT(up.first_name, ' ', up.last_name) as staff_name,
    u.user_role,
    sd.department_name,
    COUNT(DISTINCT bsa.booking_id) as total_assignments,
    AVG(r.rating) as avg_rating,
    SUM(bsa.final_payment_amount) as total_earnings,
    COUNT(DISTINCT r.id) as total_reviews
FROM users u
JOIN user_profiles up ON u.id = up.user_id
LEFT JOIN booking_staff_assignments bsa ON u.id = bsa.staff_id
LEFT JOIN reviews r ON u.id = r.reviewee_id
LEFT JOIN staff_departments sd ON bsa.department_id = sd.id
WHERE u.user_role IN ('driver', 'guide', 'scout', 'transporter', 'cook', 'porter', 'security')
GROUP BY u.id, up.first_name, up.last_name, u.user_role, sd.department_name;

-- =====================================================
-- 13. FUNCTIONS & TRIGGERS
-- =====================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tour_packages_updated_at BEFORE UPDATE ON tour_packages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_drivers_updated_at BEFORE UPDATE ON drivers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_guides_updated_at BEFORE UPDATE ON guides FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON vehicles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Generate Booking Code
CREATE OR REPLACE FUNCTION generate_booking_code()
RETURNS TRIGGER AS $$
DECLARE
    year_part VARCHAR(2);
    month_part VARCHAR(2);
    sequence_num INTEGER;
BEGIN
    year_part := TO_CHAR(NEW.created_at, 'YY');
    month_part := TO_CHAR(NEW.created_at, 'MM');
    
    SELECT COUNT(*) + 1 INTO sequence_num 
    FROM bookings 
    WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', NEW.created_at);
    
    NEW.booking_code := 'TEL-' || year_part || month_part || '-' || LPAD(sequence_num::TEXT, 6, '0');
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER generate_booking_code_trigger 
    BEFORE INSERT ON bookings 
    FOR EACH ROW 
    EXECUTE FUNCTION generate_booking_code();

-- Calculate Staff Payment Function
CREATE OR REPLACE FUNCTION calculate_staff_payment(
    p_staff_id UUID,
    p_department_id UUID,
    p_units DECIMAL,
    p_booking_date DATE,
    p_time_of_day TIME DEFAULT NULL
) RETURNS DECIMAL AS $$
DECLARE
    v_base_price DECIMAL(10,2);
    v_adjustment_factor DECIMAL(5,2) := 1.0;
    v_final_price DECIMAL(10,2);
BEGIN
    -- Get base price
    SELECT COALESCE(
        (SELECT base_price_per_unit 
         FROM staff_base_prices 
         WHERE staff_id = p_staff_id 
           AND department_id = p_department_id
           AND effective_date <= p_booking_date
           AND (expiry_date IS NULL OR expiry_date >= p_booking_date)
           AND is_active = TRUE
         ORDER BY effective_date DESC LIMIT 1),
        (SELECT price_per_unit 
         FROM base_price_pools 
         WHERE department_id = p_department_id
           AND effective_date <= p_booking_date
           AND (expiry_date IS NULL OR expiry_date >= p_booking_date)
           AND is_active = TRUE
         ORDER BY effective_date DESC LIMIT 1)
    ) INTO v_base_price;
    
    -- Apply adjustments
    SELECT COALESCE(
        (SELECT adjustment_value 
         FROM price_adjustment_rules 
         WHERE department_id = p_department_id
           AND effective_from_date <= p_booking_date
           AND (effective_to_date IS NULL OR effective_to_date >= p_booking_date)
           AND (p_time_of_day IS NULL OR 
                (effective_from_time IS NULL OR effective_from_time <= p_time_of_day) AND
                (effective_to_time IS NULL OR effective_to_time >= p_time_of_day))
           AND is_active = TRUE
         ORDER BY adjustment_value DESC LIMIT 1),
        1.0
    ) INTO v_adjustment_factor;
    
    v_final_price := v_base_price * p_units * v_adjustment_factor;
    RETURN v_final_price;
END;
$$ LANGUAGE plpgsql;

-- Update Staff Rating Function
CREATE OR REPLACE FUNCTION update_staff_rating()
RETURNS TRIGGER AS $$
DECLARE
    avg_rating DECIMAL;
BEGIN
    SELECT AVG(rating) INTO avg_rating
    FROM reviews 
    WHERE reviewee_id = NEW.reviewee_id;
    
    -- Update appropriate staff table based on role
    IF NEW.reviewee_role = 'driver' THEN
        UPDATE drivers 
        SET rating = COALESCE(avg_rating, 0)
        WHERE user_id = NEW.reviewee_id;
    ELSIF NEW.reviewee_role = 'guide' THEN
        UPDATE guides 
        SET rating = COALESCE(avg_rating, 0)
        WHERE user_id = NEW.reviewee_id;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_staff_rating_trigger 
    AFTER INSERT ON reviews 
    FOR EACH ROW 
    EXECUTE FUNCTION update_staff_rating();