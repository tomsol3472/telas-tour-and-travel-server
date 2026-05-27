--
-- PostgreSQL database dump
--

\restrict Xy6O2TQmlQff0VbfRcjhfqnPc2B8LaGbxl9aRvq9O6HWlKagaLuIUur7XCvHimx

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: booking_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.booking_status_enum AS ENUM (
    'draft',
    'pending',
    'confirmed',
    'assigned',
    'ongoing',
    'completed',
    'cancelled',
    'refunded',
    'rejected'
);


ALTER TYPE public.booking_status_enum OWNER TO postgres;

--
-- Name: difficulty_level_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.difficulty_level_enum AS ENUM (
    'easy',
    'moderate',
    'difficult',
    'challenging'
);


ALTER TYPE public.difficulty_level_enum OWNER TO postgres;

--
-- Name: emergency_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.emergency_status_enum AS ENUM (
    'active',
    'resolved',
    'false_alarm'
);


ALTER TYPE public.emergency_status_enum OWNER TO postgres;

--
-- Name: gender_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.gender_enum AS ENUM (
    'male',
    'female',
    'other'
);


ALTER TYPE public.gender_enum OWNER TO postgres;

--
-- Name: log_level_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.log_level_enum AS ENUM (
    'INFO',
    'WARNING',
    'ERROR',
    'SUCCESS',
    'DEBUG'
);


ALTER TYPE public.log_level_enum OWNER TO postgres;

--
-- Name: message_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.message_type_enum AS ENUM (
    'text',
    'image',
    'file',
    'location',
    'system'
);


ALTER TYPE public.message_type_enum OWNER TO postgres;

--
-- Name: notification_priority_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.notification_priority_enum AS ENUM (
    'low',
    'normal',
    'high',
    'urgent'
);


ALTER TYPE public.notification_priority_enum OWNER TO postgres;

--
-- Name: payment_calc_method_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.payment_calc_method_enum AS ENUM (
    'per_km',
    'per_hour',
    'per_person',
    'per_day',
    'fixed',
    'percentage'
);


ALTER TYPE public.payment_calc_method_enum OWNER TO postgres;

--
-- Name: payment_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.payment_status_enum AS ENUM (
    'pending',
    'paid',
    'failed',
    'refunded',
    'partially_paid'
);


ALTER TYPE public.payment_status_enum OWNER TO postgres;

--
-- Name: refund_tier_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.refund_tier_enum AS ENUM (
    'none',
    'pending_escrow',
    'refunded_75',
    'refunded_50',
    'no_refund',
    'force_majeure_refund'
);


ALTER TYPE public.refund_tier_enum OWNER TO postgres;

--
-- Name: season_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.season_type_enum AS ENUM (
    'dry',
    'rainy',
    'both'
);


ALTER TYPE public.season_type_enum OWNER TO postgres;

--
-- Name: tour_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.tour_type_enum AS ENUM (
    'historical',
    'photography',
    'research',
    'family',
    'adventure',
    'cultural',
    'religious',
    'wildlife',
    'honeymoon',
    'business'
);


ALTER TYPE public.tour_type_enum OWNER TO postgres;

--
-- Name: user_role_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role_enum AS ENUM (
    'tourist',
    'driver',
    'guide',
    'admin',
    'agency_staff',
    'scout',
    'transporter',
    'cook',
    'porter',
    'security'
);


ALTER TYPE public.user_role_enum OWNER TO postgres;

--
-- Name: user_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_status_enum AS ENUM (
    'active',
    'inactive',
    'suspended',
    'pending',
    'under_review'
);


ALTER TYPE public.user_status_enum OWNER TO postgres;

--
-- Name: vehicle_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.vehicle_type_enum AS ENUM (
    'sedan',
    'suv',
    '4x4',
    'minibus',
    'coaster',
    'bus',
    'boat',
    'other'
);


ALTER TYPE public.vehicle_type_enum OWNER TO postgres;

--
-- Name: verification_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.verification_status_enum AS ENUM (
    'pending',
    'verified',
    'rejected',
    'expired'
);


ALTER TYPE public.verification_status_enum OWNER TO postgres;

--
-- Name: verification_tier_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.verification_tier_enum AS ENUM (
    'basic',
    'verified',
    'premium'
);


ALTER TYPE public.verification_tier_enum OWNER TO postgres;

--
-- Name: auto_create_tour_chat(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.auto_create_tour_chat() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.status = 'confirmed' AND OLD.status != 'confirmed' THEN
        INSERT INTO chat_conversations (booking_id, is_group_chat, group_name)
        VALUES (NEW.id, TRUE, 'Tour Chat - ' || NEW.booking_code);
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.auto_create_tour_chat() OWNER TO postgres;

--
-- Name: auto_generate_otp_for_new_users(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.auto_generate_otp_for_new_users() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Automatically generate 6-digit OTP and set it to 45 seconds for all new inserts
    NEW.otp_code := LPAD(TRUNC(random() * 1000000)::INT::TEXT, 6, '0');
    NEW.otp_expires := CURRENT_TIMESTAMP + INTERVAL '45 seconds';
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.auto_generate_otp_for_new_users() OWNER TO postgres;

--
-- Name: calculate_provider_assignment_score(numeric, integer, numeric, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_provider_assignment_score(p_provider_rating numeric, p_response_time_mins integer, p_distance_km numeric, p_specialization_match boolean) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.calculate_provider_assignment_score(p_provider_rating numeric, p_response_time_mins integer, p_distance_km numeric, p_specialization_match boolean) OWNER TO postgres;

--
-- Name: calculate_staff_payment(uuid, uuid, numeric, date, time without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_staff_payment(p_staff_id uuid, p_department_id uuid, p_units numeric, p_booking_date date, p_time_of_day time without time zone DEFAULT NULL::time without time zone) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.calculate_staff_payment(p_staff_id uuid, p_department_id uuid, p_units numeric, p_booking_date date, p_time_of_day time without time zone) OWNER TO postgres;

--
-- Name: check_performance_review(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_performance_review() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.check_performance_review() OWNER TO postgres;

--
-- Name: delete_old_tour_messages(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_old_tour_messages() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Delete messages where the associated booking's end_date is older than 1 month
    -- Assuming a chat_messages table exists linking to bookings
    DELETE FROM chat_messages cm
    USING bookings b
    WHERE cm.booking_id = b.id
      AND b.status = 'completed'
      AND b.end_date < CURRENT_DATE - INTERVAL '1 month';
      
    -- Note: If you are storing media on a cloud service (AWS S3, Cloudinary),
    -- you would need a Node.js cron job instead to trigger the API deletion 
    -- of the actual files before deleting the database row.
    
    RAISE NOTICE 'Old chat messages deleted successfully.';
END;
$$;


ALTER FUNCTION public.delete_old_tour_messages() OWNER TO postgres;

--
-- Name: generate_booking_code(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_booking_code() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.generate_booking_code() OWNER TO postgres;

--
-- Name: generate_payment_code(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_payment_code() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.payment_code IS NULL THEN
        NEW.payment_code := 'PAY-' || EXTRACT(EPOCH FROM NOW())::BIGINT || '-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8);
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.generate_payment_code() OWNER TO postgres;

--
-- Name: regenerate_user_otp(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.regenerate_user_otp(p_user_email character varying) RETURNS TABLE(new_otp character varying, expires_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- This updates the existing user with a fresh OTP and returns it
    RETURN QUERY
    UPDATE users
    SET 
        otp_code = LPAD(TRUNC(random() * 1000000)::INT::TEXT, 6, '0'),
        otp_expires = CURRENT_TIMESTAMP + INTERVAL '45 seconds',
        updated_at = CURRENT_TIMESTAMP
    WHERE email = p_user_email
    RETURNING otp_code, otp_expires;
END;
$$;


ALTER FUNCTION public.regenerate_user_otp(p_user_email character varying) OWNER TO postgres;

--
-- Name: update_staff_rating(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_staff_rating() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.update_staff_rating() OWNER TO postgres;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bookings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bookings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    booking_code character varying(50) NOT NULL,
    tourist_id uuid NOT NULL,
    package_id uuid,
    is_custom_tour boolean DEFAULT false,
    custom_tour_name character varying(200),
    custom_tour_description text,
    status public.booking_status_enum DEFAULT 'pending'::public.booking_status_enum,
    booking_date date DEFAULT CURRENT_DATE NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    number_of_adults integer DEFAULT 1 NOT NULL,
    number_of_children integer DEFAULT 0,
    number_of_infants integer DEFAULT 0,
    total_persons integer GENERATED ALWAYS AS (((number_of_adults + number_of_children) + number_of_infants)) STORED,
    special_requests text,
    dietary_requirements text[],
    accommodation_preference character varying(50),
    transport_preference character varying(100),
    guide_preference character varying(100),
    estimated_distance_km numeric(8,2),
    estimated_duration_hours numeric(6,2),
    base_price numeric(12,2),
    taxes numeric(10,2),
    service_fee numeric(10,2),
    total_amount numeric(12,2),
    discount_amount numeric(10,2) DEFAULT 0,
    discount_code character varying(50),
    final_amount numeric(12,2),
    currency character varying(3) DEFAULT 'ETB'::character varying,
    payment_status public.payment_status_enum DEFAULT 'pending'::public.payment_status_enum,
    assigned_driver_id uuid,
    assigned_guide_id uuid,
    assigned_vehicle_id uuid,
    calculated_distance_km numeric(8,2),
    calculated_duration_hours numeric(6,2),
    total_staff_cost numeric(12,2) DEFAULT 0,
    agency_profit numeric(12,2) GENERATED ALWAYS AS ((((final_amount - total_staff_cost) - taxes) - service_fee)) STORED,
    base_price_breakdown jsonb,
    staff_payments_breakdown jsonb,
    rejected_reason text,
    cancelled_by uuid,
    cancelled_at timestamp with time zone,
    cancellation_charges numeric(10,2) DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    locked_exchange_rate numeric(10,4),
    locked_base_price numeric(12,2),
    refund_tier public.refund_tier_enum DEFAULT 'none'::public.refund_tier_enum,
    dispute_reason text,
    is_in_escrow boolean DEFAULT false,
    guide_name character varying(200),
    driver_name character varying(200),
    funds_allocated boolean DEFAULT false,
    CONSTRAINT bookings_end_after_start CHECK ((end_date >= start_date))
);


ALTER TABLE public.bookings OWNER TO postgres;

--
-- Name: COLUMN bookings.guide_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.bookings.guide_name IS 'Cached guide name for quick display - updated when assigned_guide_id changes';


--
-- Name: COLUMN bookings.driver_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.bookings.driver_name IS 'Cached driver name for quick display - updated when assigned_driver_id changes';


--
-- Name: tourists; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tourists (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    travel_frequency integer DEFAULT 0,
    preferred_tour_types public.tour_type_enum[],
    preferred_accommodation text[],
    preferred_transport text[],
    dietary_preferences text[],
    disability_access_needs boolean DEFAULT false,
    disability_details text,
    frequent_flyer_numbers jsonb,
    loyalty_points integer DEFAULT 0,
    total_bookings integer DEFAULT 0,
    average_rating_given numeric(3,2),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.tourists OWNER TO postgres;

--
-- Name: trip_tracking; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trip_tracking (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    booking_id uuid NOT NULL,
    location public.geometry(Point,4326) NOT NULL,
    altitude numeric(8,2),
    speed numeric(6,2),
    heading numeric(5,2),
    accuracy numeric(5,2),
    battery_level integer,
    recorded_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.trip_tracking OWNER TO postgres;

--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_profiles (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    middle_name character varying(100),
    date_of_birth date,
    gender public.gender_enum,
    nationality character varying(100),
    address text,
    city character varying(100),
    state character varying(100),
    country character varying(100) DEFAULT 'Ethiopia'::character varying,
    postal_code character varying(20),
    emergency_contact_name character varying(200),
    emergency_contact_phone character varying(20),
    emergency_contact_relationship character varying(100),
    dietary_restrictions text[],
    allergies text[],
    medical_conditions text[],
    passport_number character varying(50),
    passport_expiry date,
    visa_number character varying(50),
    visa_expiry date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    verification_tier public.verification_tier_enum DEFAULT 'basic'::public.verification_tier_enum,
    is_diaspora_verified boolean DEFAULT false
);


ALTER TABLE public.user_profiles OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_role public.user_role_enum NOT NULL,
    email character varying(255),
    phone character varying(20) NOT NULL,
    phone_country_code character varying(5) DEFAULT '+251'::character varying,
    password_hash character varying(255) NOT NULL,
    is_email_verified boolean DEFAULT false,
    is_phone_verified boolean DEFAULT false,
    verification_token character varying(100),
    verification_expires timestamp with time zone,
    otp_code character varying(6),
    otp_expires timestamp with time zone,
    two_factor_enabled boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_login timestamp with time zone,
    status public.user_status_enum DEFAULT 'pending'::public.user_status_enum,
    profile_picture_url text,
    preferred_language character varying(10) DEFAULT 'en'::character varying,
    timezone character varying(50) DEFAULT 'Africa/Addis_Ababa'::character varying,
    CONSTRAINT valid_email CHECK (((email IS NULL) OR ((email)::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text))),
    CONSTRAINT valid_phone CHECK (((phone)::text ~ '^[0-9]{9,10}$'::text))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: active_tours_location_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.active_tours_location_view AS
 SELECT DISTINCT ON (t.booking_id) t.booking_id,
    b.booking_code,
    b.status,
    b.start_date,
    concat(up.first_name, ' ', up.last_name) AS tourist_name,
    public.st_y((t.location)::public.geometry) AS latitude,
    public.st_x((t.location)::public.geometry) AS longitude,
    t.speed,
    t.recorded_at AS last_updated
   FROM ((((public.trip_tracking t
     JOIN public.bookings b ON ((t.booking_id = b.id)))
     JOIN public.tourists tor ON ((b.tourist_id = tor.id)))
     JOIN public.users u ON ((tor.user_id = u.id)))
     JOIN public.user_profiles up ON ((u.id = up.user_id)))
  WHERE (b.status = ANY (ARRAY['confirmed'::public.booking_status_enum, 'assigned'::public.booking_status_enum, 'ongoing'::public.booking_status_enum]))
  ORDER BY t.booking_id, t.recorded_at DESC;


ALTER VIEW public.active_tours_location_view OWNER TO postgres;

--
-- Name: reviews; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reviews (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    booking_id uuid NOT NULL,
    reviewer_id uuid NOT NULL,
    reviewee_id uuid NOT NULL,
    reviewee_role public.user_role_enum NOT NULL,
    rating integer NOT NULL,
    title character varying(200),
    comment text,
    photos text[],
    response text,
    responded_by uuid,
    responded_at timestamp with time zone,
    is_verified_booking boolean DEFAULT true,
    helpful_count integer DEFAULT 0,
    report_count integer DEFAULT 0,
    is_published boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reviews_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.reviews OWNER TO postgres;

--
-- Name: advanced_kpi_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.advanced_kpi_summary AS
 SELECT COALESCE(round(avg(rating), 1), (0)::numeric) AS customer_satisfaction,
    COALESCE(round(((( SELECT (count(repeat_tourists.tourist_id))::numeric AS count
           FROM ( SELECT bookings.tourist_id
                   FROM public.bookings
                  GROUP BY bookings.tourist_id
                 HAVING (count(*) > 1)) repeat_tourists) / (NULLIF(( SELECT count(DISTINCT bookings.tourist_id) AS count
           FROM public.bookings), 0))::numeric) * (100)::numeric), 1), (0)::numeric) AS repeat_customer_percentage
   FROM public.reviews;


ALTER VIEW public.advanced_kpi_summary OWNER TO postgres;

--
-- Name: api_integrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.api_integrations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    service_name character varying(100) NOT NULL,
    api_key_encrypted text,
    api_secret_encrypted text,
    base_url text,
    is_active boolean DEFAULT true,
    sandbox_mode boolean DEFAULT false,
    last_success_at timestamp with time zone,
    failure_count integer DEFAULT 0,
    rate_limit_per_minute integer,
    config jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.api_integrations OWNER TO postgres;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    action character varying(100) NOT NULL,
    entity_type character varying(100),
    entity_id uuid,
    old_values jsonb,
    new_values jsonb,
    ip_address inet,
    user_agent text,
    location character varying(200),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- Name: backup_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.backup_history (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    backup_type character varying(20) NOT NULL,
    status character varying(20) DEFAULT 'completed'::character varying,
    file_name character varying(255),
    file_size_bytes bigint,
    initiated_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.backup_history OWNER TO postgres;

--
-- Name: base_price_pools; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.base_price_pools (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    department_id uuid NOT NULL,
    price_per_unit numeric(10,2) NOT NULL,
    unit_type character varying(50) NOT NULL,
    currency character varying(3) DEFAULT 'ETB'::character varying,
    effective_date date DEFAULT CURRENT_DATE NOT NULL,
    expiry_date date,
    min_units integer DEFAULT 1,
    max_units integer,
    is_active boolean DEFAULT true,
    created_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_dates CHECK (((expiry_date IS NULL) OR (expiry_date > effective_date)))
);


ALTER TABLE public.base_price_pools OWNER TO postgres;

--
-- Name: booking_staff_assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.booking_staff_assignments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    booking_id uuid NOT NULL,
    staff_id uuid NOT NULL,
    staff_role public.user_role_enum NOT NULL,
    department_id uuid,
    assignment_type character varying(50) NOT NULL,
    price_calculation_method character varying(50) NOT NULL,
    units_assigned numeric(10,2) NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    total_price numeric(10,2) GENERATED ALWAYS AS ((units_assigned * unit_price)) STORED,
    bonus_amount numeric(10,2) DEFAULT 0,
    deduction_amount numeric(10,2) DEFAULT 0,
    final_payment_amount numeric(10,2) GENERATED ALWAYS AS ((((units_assigned * unit_price) + bonus_amount) - deduction_amount)) STORED,
    payment_status public.payment_status_enum DEFAULT 'pending'::public.payment_status_enum,
    paid_at timestamp with time zone,
    payment_method character varying(50),
    transaction_id character varying(100),
    assignment_notes text,
    assigned_by uuid,
    assigned_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    accepted_by_staff boolean DEFAULT false,
    accepted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    installment_start_paid boolean DEFAULT false,
    installment_midpoint_paid boolean DEFAULT false,
    installment_completion_paid boolean DEFAULT false
);


ALTER TABLE public.booking_staff_assignments OWNER TO postgres;

--
-- Name: drivers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.drivers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    department_id uuid,
    license_number character varying(50) NOT NULL,
    license_issue_date date NOT NULL,
    license_expiry_date date NOT NULL,
    license_photo_url text,
    years_experience integer DEFAULT 0,
    rating numeric(3,2) DEFAULT 0.0,
    total_trips integer DEFAULT 0,
    is_available boolean DEFAULT true,
    current_location public.geometry(Point,4326),
    service_areas text[],
    languages_spoken text[] DEFAULT ARRAY['Amharic'::text, 'English'::text],
    max_daily_hours integer DEFAULT 10,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    average_response_time_minutes integer DEFAULT 0,
    booking_completion_rate numeric(5,2) DEFAULT 100.00,
    consecutive_low_ratings integer DEFAULT 0,
    performance_review_status boolean DEFAULT false,
    CONSTRAINT drivers_rating_check CHECK (((rating >= (0)::numeric) AND (rating <= (5)::numeric)))
);


ALTER TABLE public.drivers OWNER TO postgres;

--
-- Name: guides; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.guides (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    department_id uuid,
    guide_license_number character varying(50) NOT NULL,
    license_issue_date date NOT NULL,
    license_expiry_date date NOT NULL,
    license_photo_url text,
    specialization text[],
    languages_spoken text[] NOT NULL,
    languages_certified text[],
    years_experience integer DEFAULT 0,
    rating numeric(3,2) DEFAULT 0.0,
    total_tours integer DEFAULT 0,
    is_available boolean DEFAULT true,
    hourly_rate numeric(10,2),
    daily_rate numeric(10,2),
    max_group_size integer DEFAULT 15,
    has_first_aid_cert boolean DEFAULT false,
    first_aid_expiry date,
    education_background text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    average_response_time_minutes integer DEFAULT 0,
    booking_completion_rate numeric(5,2) DEFAULT 100.00,
    consecutive_low_ratings integer DEFAULT 0,
    performance_review_status boolean DEFAULT false,
    CONSTRAINT guides_rating_check CHECK (((rating >= (0)::numeric) AND (rating <= (5)::numeric)))
);


ALTER TABLE public.guides OWNER TO postgres;

--
-- Name: tour_packages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tour_packages (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    package_code character varying(50) NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    tour_type public.tour_type_enum NOT NULL,
    difficulty public.difficulty_level_enum DEFAULT 'moderate'::public.difficulty_level_enum,
    duration_days integer NOT NULL,
    duration_nights integer NOT NULL,
    min_group_size integer DEFAULT 1,
    max_group_size integer DEFAULT 20,
    season_recommendation public.season_type_enum DEFAULT 'both'::public.season_type_enum,
    tags text[],
    inclusions text[] NOT NULL,
    exclusions text[],
    requirements text[],
    important_notes text,
    cancellation_policy text,
    photos_urls text[],
    is_customizable boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    base_price numeric(10,2) DEFAULT 0.00
);


ALTER TABLE public.tour_packages OWNER TO postgres;

--
-- Name: booking_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.booking_summary AS
 SELECT b.id,
    b.booking_code,
    b.booking_date,
    b.created_at,
    b.tourist_id,
    to_char((b.start_date)::timestamp with time zone, 'Mon DD, YYYY'::text) AS date,
    b.start_date,
    b.end_date,
    concat(up.first_name, ' ', up.last_name) AS customer,
    concat(up.first_name, ' ', up.last_name) AS tourist_name,
    COALESCE(tp.name, b.custom_tour_name, 'Custom Tour'::character varying) AS tour,
    b.status,
    b.total_persons AS participants,
    b.total_persons,
    b.final_amount AS amount,
    b.final_amount,
    initcap((b.payment_status)::text) AS paymentstatus,
    b.payment_status,
    b.total_staff_cost,
    b.agency_profit,
    b.package_id,
    b.custom_tour_name,
    COALESCE(concat(dp.first_name, ' ', dp.last_name), 'Unassigned'::text) AS driver,
    b.assigned_driver_id,
    COALESCE(concat(gp.first_name, ' ', gp.last_name), 'Unassigned'::text) AS guide,
    b.assigned_guide_id,
    ( SELECT r.rating
           FROM public.reviews r
          WHERE (r.booking_id = b.id)
         LIMIT 1) AS rating,
    ( SELECT r.comment
           FROM public.reviews r
          WHERE (r.booking_id = b.id)
         LIMIT 1) AS feedback
   FROM ((((((((public.bookings b
     JOIN public.tourists t ON ((b.tourist_id = t.id)))
     JOIN public.users u ON ((t.user_id = u.id)))
     JOIN public.user_profiles up ON ((u.id = up.user_id)))
     LEFT JOIN public.tour_packages tp ON ((b.package_id = tp.id)))
     LEFT JOIN public.drivers d ON ((b.assigned_driver_id = d.id)))
     LEFT JOIN public.user_profiles dp ON ((d.user_id = dp.user_id)))
     LEFT JOIN public.guides g ON ((b.assigned_guide_id = g.id)))
     LEFT JOIN public.user_profiles gp ON ((g.user_id = gp.user_id)));


ALTER VIEW public.booking_summary OWNER TO postgres;

--
-- Name: booking_travelers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.booking_travelers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    booking_id uuid NOT NULL,
    traveler_type character varying(20) NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    date_of_birth date,
    gender public.gender_enum,
    nationality character varying(100),
    passport_number character varying(50),
    passport_expiry date,
    visa_number character varying(50),
    visa_expiry date,
    dietary_restrictions text[],
    medical_conditions text[],
    emergency_contact character varying(20),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.booking_travelers OWNER TO postgres;

--
-- Name: chat_conversations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_conversations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    conversation_uuid uuid DEFAULT gen_random_uuid(),
    is_group_chat boolean DEFAULT false,
    group_name character varying(200),
    created_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    booking_id uuid
);


ALTER TABLE public.chat_conversations OWNER TO postgres;

--
-- Name: chat_messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_messages (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    conversation_id uuid NOT NULL,
    sender_id uuid NOT NULL,
    message_type public.message_type_enum DEFAULT 'text'::public.message_type_enum,
    message_text text,
    media_url text,
    location public.geometry(Point,4326),
    file_name character varying(255),
    file_size integer,
    is_read boolean DEFAULT false,
    read_by_recipient boolean DEFAULT false,
    deleted_for_sender boolean DEFAULT false,
    deleted_for_all boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.chat_messages OWNER TO postgres;

--
-- Name: chat_participants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_participants (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    conversation_id uuid NOT NULL,
    user_id uuid NOT NULL,
    joined_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    left_at timestamp with time zone,
    last_read_at timestamp with time zone
);


ALTER TABLE public.chat_participants OWNER TO postgres;

--
-- Name: web_traffic_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.web_traffic_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    session_id character varying(100) NOT NULL,
    user_id uuid,
    event_type character varying(50) NOT NULL,
    path_visited text,
    ip_address inet,
    device_type character varying(50),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.web_traffic_logs OWNER TO postgres;

--
-- Name: conversion_funnel_analytics; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.conversion_funnel_analytics AS
 SELECT count(DISTINCT session_id) FILTER (WHERE ((event_type)::text = 'visit'::text)) AS website_visitors,
    count(DISTINCT session_id) FILTER (WHERE ((event_type)::text = 'browse_tours'::text)) AS browse_tours,
    count(DISTINCT session_id) FILTER (WHERE ((event_type)::text = 'view_tour_details'::text)) AS view_details,
    count(DISTINCT session_id) FILTER (WHERE ((event_type)::text = 'start_booking'::text)) AS start_booking,
    count(DISTINCT session_id) FILTER (WHERE ((event_type)::text = 'complete_booking'::text)) AS complete_booking
   FROM public.web_traffic_logs;


ALTER VIEW public.conversion_funnel_analytics OWNER TO postgres;

--
-- Name: custom_tour_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.custom_tour_details (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    booking_id uuid NOT NULL,
    start_destination_id uuid,
    end_destination_id uuid,
    travel_purpose text,
    specific_requirements text,
    budget_range numeric(12,2),
    preferred_activities text[],
    accommodation_standard character varying(50),
    transport_preference character varying(100),
    guide_required boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.custom_tour_details OWNER TO postgres;

--
-- Name: custom_tour_stops; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.custom_tour_stops (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    custom_tour_id uuid NOT NULL,
    destination_id uuid NOT NULL,
    visit_order integer NOT NULL,
    visit_duration_hours numeric(5,2),
    special_instructions text,
    activities text[],
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.custom_tour_stops OWNER TO postgres;

--
-- Name: payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    payment_code character varying(50) DEFAULT ((('PAY-'::text || (EXTRACT(epoch FROM now()))::bigint) || '-'::text) || SUBSTRING(md5((random())::text) FROM 1 FOR 8)),
    booking_id uuid NOT NULL,
    tourist_id uuid,
    amount numeric(12,2) NOT NULL,
    currency character varying(3) DEFAULT 'ETB'::character varying,
    payment_method character varying(50) NOT NULL,
    payment_gateway character varying(50),
    gateway_transaction_id character varying(200),
    gateway_response jsonb,
    payment_status public.payment_status_enum DEFAULT 'pending'::public.payment_status_enum NOT NULL,
    paid_at timestamp with time zone,
    receipt_url text,
    refund_amount numeric(10,2) DEFAULT 0,
    refund_reason text,
    refunded_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    tx_ref character varying(100),
    verified_at timestamp with time zone,
    chapa_response jsonb,
    method character varying(50) DEFAULT 'chapa'::character varying,
    status character varying(50) DEFAULT 'pending'::character varying
);


ALTER TABLE public.payments OWNER TO postgres;

--
-- Name: TABLE payments; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.payments IS 'Payment transactions including Chapa integration';


--
-- Name: COLUMN payments.tx_ref; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.payments.tx_ref IS 'Chapa transaction reference for tracking';


--
-- Name: COLUMN payments.verified_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.payments.verified_at IS 'Timestamp when payment was verified with Chapa';


--
-- Name: COLUMN payments.chapa_response; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.payments.chapa_response IS 'Full JSON response from Chapa API';


--
-- Name: dashboard_overview_trends; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.dashboard_overview_trends AS
 WITH current_month AS (
         SELECT ( SELECT count(*) AS count
                   FROM public.users) AS total_users,
            ( SELECT count(*) AS count
                   FROM public.tour_packages
                  WHERE (tour_packages.is_active = true)) AS active_packages,
            ( SELECT count(*) AS count
                   FROM public.bookings
                  WHERE (date_trunc('month'::text, bookings.created_at) = date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))) AS recent_bookings,
            ( SELECT COALESCE(sum(payments.amount), (0)::numeric) AS "coalesce"
                   FROM public.payments
                  WHERE ((payments.payment_status = 'paid'::public.payment_status_enum) AND (date_trunc('month'::text, payments.paid_at) = date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone)))) AS monthly_revenue
        ), last_month AS (
         SELECT ( SELECT count(*) AS count
                   FROM public.users
                  WHERE (users.created_at < date_trunc('month'::text, (CURRENT_DATE)::timestamp with time zone))) AS old_users,
            ( SELECT count(*) AS count
                   FROM public.bookings
                  WHERE (date_trunc('month'::text, bookings.created_at) = date_trunc('month'::text, (CURRENT_DATE - '1 mon'::interval)))) AS old_bookings,
            ( SELECT COALESCE(sum(payments.amount), (0)::numeric) AS "coalesce"
                   FROM public.payments
                  WHERE ((payments.payment_status = 'paid'::public.payment_status_enum) AND (date_trunc('month'::text, payments.paid_at) = date_trunc('month'::text, (CURRENT_DATE - '1 mon'::interval))))) AS old_revenue
        )
 SELECT c.total_users,
    round(((((c.total_users - l.old_users))::numeric / (GREATEST(l.old_users, (1)::bigint))::numeric) * (100)::numeric), 1) AS users_trend_percent,
    c.active_packages,
    c.recent_bookings,
    (c.recent_bookings - l.old_bookings) AS bookings_trend_count,
    c.monthly_revenue,
    (c.monthly_revenue - l.old_revenue) AS revenue_trend_amount
   FROM (current_month c
     CROSS JOIN last_month l);


ALTER VIEW public.dashboard_overview_trends OWNER TO postgres;

--
-- Name: demographic_age_groups; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.demographic_age_groups AS
 WITH age_data AS (
         SELECT
                CASE
                    WHEN ((EXTRACT(year FROM age((CURRENT_DATE)::timestamp with time zone, (up.date_of_birth)::timestamp with time zone)) >= (18)::numeric) AND (EXTRACT(year FROM age((CURRENT_DATE)::timestamp with time zone, (up.date_of_birth)::timestamp with time zone)) <= (25)::numeric)) THEN '18-25'::text
                    WHEN ((EXTRACT(year FROM age((CURRENT_DATE)::timestamp with time zone, (up.date_of_birth)::timestamp with time zone)) >= (26)::numeric) AND (EXTRACT(year FROM age((CURRENT_DATE)::timestamp with time zone, (up.date_of_birth)::timestamp with time zone)) <= (35)::numeric)) THEN '26-35'::text
                    WHEN ((EXTRACT(year FROM age((CURRENT_DATE)::timestamp with time zone, (up.date_of_birth)::timestamp with time zone)) >= (36)::numeric) AND (EXTRACT(year FROM age((CURRENT_DATE)::timestamp with time zone, (up.date_of_birth)::timestamp with time zone)) <= (45)::numeric)) THEN '36-45'::text
                    WHEN ((EXTRACT(year FROM age((CURRENT_DATE)::timestamp with time zone, (up.date_of_birth)::timestamp with time zone)) >= (46)::numeric) AND (EXTRACT(year FROM age((CURRENT_DATE)::timestamp with time zone, (up.date_of_birth)::timestamp with time zone)) <= (55)::numeric)) THEN '46-55'::text
                    ELSE '55+'::text
                END AS age_group,
            b.id AS booking_id
           FROM ((public.user_profiles up
             JOIN public.tourists t ON ((up.user_id = t.user_id)))
             JOIN public.bookings b ON ((t.id = b.tourist_id)))
          WHERE (up.date_of_birth IS NOT NULL)
        )
 SELECT age_group,
    count(booking_id) AS bookings,
    round((((count(booking_id))::numeric / (NULLIF(( SELECT count(*) AS count
           FROM age_data age_data_1), 0))::numeric) * (100)::numeric), 1) AS percentage
   FROM age_data
  GROUP BY age_group
  ORDER BY age_group;


ALTER VIEW public.demographic_age_groups OWNER TO postgres;

--
-- Name: demographic_nationalities; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.demographic_nationalities AS
 SELECT COALESCE(up.nationality, 'Unknown'::character varying) AS country,
    count(DISTINCT b.id) AS bookings,
    round((((count(DISTINCT b.id))::numeric / (NULLIF(( SELECT count(*) AS count
           FROM public.bookings), 0))::numeric) * (100)::numeric), 1) AS percentage
   FROM ((public.user_profiles up
     JOIN public.tourists t ON ((up.user_id = t.user_id)))
     JOIN public.bookings b ON ((t.id = b.tourist_id)))
  GROUP BY up.nationality
  ORDER BY (count(DISTINCT b.id)) DESC;


ALTER VIEW public.demographic_nationalities OWNER TO postgres;

--
-- Name: emergency_alerts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.emergency_alerts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    booking_id uuid,
    triggered_by uuid,
    location public.geometry(Point,4326),
    alert_time timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    status public.emergency_status_enum DEFAULT 'active'::public.emergency_status_enum,
    resolved_by uuid,
    resolution_notes text
);


ALTER TABLE public.emergency_alerts OWNER TO postgres;

--
-- Name: famous_destinations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.famous_destinations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    address text,
    description text,
    main_image_url text,
    latitude numeric(10,8),
    longitude numeric(11,8),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.famous_destinations OWNER TO postgres;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    notification_type character varying(100) NOT NULL,
    title character varying(200) NOT NULL,
    message text NOT NULL,
    data jsonb,
    is_read boolean DEFAULT false,
    read_at timestamp with time zone,
    action_url text,
    priority public.notification_priority_enum DEFAULT 'normal'::public.notification_priority_enum,
    expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: operations_staff; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.operations_staff AS
 SELECT u.id,
    u.user_role,
    concat(up.first_name, ' ', up.last_name) AS name,
        CASE
            WHEN (d.is_available = true) THEN 'Available'::text
            ELSE 'Unavailable'::text
        END AS status,
    ARRAY['Driver'::text] AS specialization
   FROM ((public.users u
     JOIN public.user_profiles up ON ((u.id = up.user_id)))
     JOIN public.drivers d ON ((u.id = d.user_id)))
  WHERE (u.user_role = 'driver'::public.user_role_enum)
UNION ALL
 SELECT u.id,
    u.user_role,
    concat(up.first_name, ' ', up.last_name) AS name,
        CASE
            WHEN (g.is_available = true) THEN 'Available'::text
            ELSE 'Unavailable'::text
        END AS status,
    g.specialization
   FROM ((public.users u
     JOIN public.user_profiles up ON ((u.id = up.user_id)))
     JOIN public.guides g ON ((u.id = g.user_id)))
  WHERE (u.user_role = 'guide'::public.user_role_enum);


ALTER VIEW public.operations_staff OWNER TO postgres;

--
-- Name: package_destinations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.package_destinations (
    package_id uuid NOT NULL,
    destination_id uuid NOT NULL
);


ALTER TABLE public.package_destinations OWNER TO postgres;

--
-- Name: package_itineraries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.package_itineraries (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    package_id uuid NOT NULL,
    day_number integer NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    accommodation_type character varying(100),
    meal_plan character varying(100),
    included_activities text[],
    optional_activities text[],
    distance_km numeric(6,2),
    travel_time_hours numeric(4,2),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.package_itineraries OWNER TO postgres;

--
-- Name: package_management_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.package_management_view AS
 SELECT id,
    package_code,
    name,
    description,
    tour_type,
    difficulty,
    duration_days,
    duration_nights,
    min_group_size,
    max_group_size,
    season_recommendation,
    base_price,
    photos_urls,
    inclusions,
    exclusions,
    tags,
    requirements,
    is_active,
    is_customizable,
    COALESCE(( SELECT json_agg(json_build_object('day_number', pi.day_number, 'title', pi.title, 'description', pi.description, 'accommodation_type', pi.accommodation_type, 'meal_plan', pi.meal_plan) ORDER BY pi.day_number) AS json_agg
           FROM public.package_itineraries pi
          WHERE (pi.package_id = tp.id)), '[]'::json) AS itinerary
   FROM public.tour_packages tp;


ALTER VIEW public.package_management_view OWNER TO postgres;

--
-- Name: package_pricing; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.package_pricing (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    package_id uuid NOT NULL,
    season character varying(50) NOT NULL,
    start_month integer,
    end_month integer,
    price_per_person_local numeric(10,2) NOT NULL,
    price_per_person_diaspora numeric(10,2) NOT NULL,
    price_per_person_international numeric(10,2) NOT NULL,
    child_discount_percentage numeric(5,2) DEFAULT 0,
    infant_discount_percentage numeric(5,2) DEFAULT 0,
    group_discount_percentage numeric(5,2) DEFAULT 0,
    early_bird_discount_percentage numeric(5,2) DEFAULT 0,
    last_minute_discount_percentage numeric(5,2) DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT package_pricing_end_month_check CHECK (((end_month >= 1) AND (end_month <= 12))),
    CONSTRAINT package_pricing_start_month_check CHECK (((start_month >= 1) AND (start_month <= 12)))
);


ALTER TABLE public.package_pricing OWNER TO postgres;

--
-- Name: price_adjustment_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.price_adjustment_rules (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    rule_name character varying(100) NOT NULL,
    rule_type character varying(50) NOT NULL,
    department_id uuid,
    applies_to_staff_type public.user_role_enum,
    adjustment_type character varying(50) NOT NULL,
    adjustment_value numeric(10,2) NOT NULL,
    min_adjustment numeric(10,2),
    max_adjustment numeric(10,2),
    condition_expression text,
    effective_from_date date,
    effective_to_date date,
    effective_from_time time without time zone,
    effective_to_time time without time zone,
    days_of_week integer[],
    is_active boolean DEFAULT true,
    created_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    is_holiday_rule boolean DEFAULT false,
    CONSTRAINT check_holiday_cap CHECK (((is_holiday_rule = false) OR ((is_holiday_rule = true) AND (adjustment_value <= 1.25))))
);


ALTER TABLE public.price_adjustment_rules OWNER TO postgres;

--
-- Name: revenue_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.revenue_summary AS
 SELECT date_trunc('month'::text, (booking_date)::timestamp with time zone) AS month,
    count(*) AS total_bookings,
    sum(final_amount) AS total_revenue,
    sum(
        CASE
            WHEN (payment_status = 'paid'::public.payment_status_enum) THEN final_amount
            ELSE (0)::numeric
        END) AS paid_revenue,
    avg(final_amount) AS avg_booking_value,
    count(DISTINCT tourist_id) AS unique_tourists,
    sum(total_staff_cost) AS total_staff_cost,
    sum(agency_profit) AS total_profit
   FROM public.bookings b
  WHERE (status <> ALL (ARRAY['cancelled'::public.booking_status_enum, 'rejected'::public.booking_status_enum]))
  GROUP BY (date_trunc('month'::text, (booking_date)::timestamp with time zone));


ALTER VIEW public.revenue_summary OWNER TO postgres;

--
-- Name: review_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.review_categories (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    category_name character varying(100) NOT NULL,
    description text,
    weight numeric(3,2) DEFAULT 1.0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.review_categories OWNER TO postgres;

--
-- Name: review_ratings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.review_ratings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    review_id uuid NOT NULL,
    category_id uuid NOT NULL,
    rating integer NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT review_ratings_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.review_ratings OWNER TO postgres;

--
-- Name: seasonal_trends_analytics; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.seasonal_trends_analytics AS
 SELECT to_char((booking_date)::timestamp with time zone, 'Mon'::text) AS month_name,
    EXTRACT(month FROM booking_date) AS month_num,
    count(id) AS bookings,
    sum(final_amount) AS revenue,
        CASE
            WHEN (EXTRACT(month FROM booking_date) = ANY (ARRAY[(6)::numeric, (7)::numeric, (8)::numeric, (9)::numeric, (12)::numeric])) THEN 'Peak'::text
            WHEN (EXTRACT(month FROM booking_date) = ANY (ARRAY[(1)::numeric, (2)::numeric])) THEN 'Off-Peak'::text
            ELSE 'Regular'::text
        END AS season
   FROM public.bookings
  WHERE (status <> ALL (ARRAY['cancelled'::public.booking_status_enum, 'rejected'::public.booking_status_enum]))
  GROUP BY (to_char((booking_date)::timestamp with time zone, 'Mon'::text)), (EXTRACT(month FROM booking_date))
  ORDER BY (EXTRACT(month FROM booking_date));


ALTER VIEW public.seasonal_trends_analytics OWNER TO postgres;

--
-- Name: staff_base_prices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff_base_prices (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    staff_id uuid NOT NULL,
    department_id uuid NOT NULL,
    base_price_per_unit numeric(10,2) NOT NULL,
    unit_type character varying(50) NOT NULL,
    currency character varying(3) DEFAULT 'ETB'::character varying,
    effective_date date DEFAULT CURRENT_DATE NOT NULL,
    expiry_date date,
    notes text,
    is_active boolean DEFAULT true,
    created_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.staff_base_prices OWNER TO postgres;

--
-- Name: staff_departments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff_departments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    department_code character varying(50) NOT NULL,
    department_name character varying(100) NOT NULL,
    description text,
    payment_calculation_method public.payment_calc_method_enum NOT NULL,
    is_active boolean DEFAULT true,
    created_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.staff_departments OWNER TO postgres;

--
-- Name: staff_payment_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff_payment_transactions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    staff_id uuid NOT NULL,
    booking_id uuid,
    assignment_id uuid,
    payment_period_start date,
    payment_period_end date,
    base_amount numeric(10,2) NOT NULL,
    units_worked numeric(10,2),
    unit_price numeric(10,2) NOT NULL,
    adjustments jsonb,
    total_amount numeric(10,2) NOT NULL,
    currency character varying(3) DEFAULT 'ETB'::character varying,
    payment_method character varying(50) NOT NULL,
    bank_account_number character varying(50),
    bank_name character varying(100),
    mobile_money_number character varying(20),
    recipient_name character varying(200),
    payment_status public.payment_status_enum DEFAULT 'pending'::public.payment_status_enum,
    paid_at timestamp with time zone,
    transaction_reference character varying(100),
    failure_reason text,
    calculated_by uuid,
    approved_by uuid,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.staff_payment_transactions OWNER TO postgres;

--
-- Name: staff_performance; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.staff_performance AS
 SELECT u.id AS user_id,
    concat(up.first_name, ' ', up.last_name) AS staff_name,
    u.user_role,
    sd.department_name,
    count(DISTINCT bsa.booking_id) AS total_assignments,
    avg(r.rating) AS avg_rating,
    sum(bsa.final_payment_amount) AS total_earnings,
    count(DISTINCT r.id) AS total_reviews
   FROM ((((public.users u
     JOIN public.user_profiles up ON ((u.id = up.user_id)))
     LEFT JOIN public.booking_staff_assignments bsa ON ((u.id = bsa.staff_id)))
     LEFT JOIN public.reviews r ON ((u.id = r.reviewee_id)))
     LEFT JOIN public.staff_departments sd ON ((bsa.department_id = sd.id)))
  WHERE (u.user_role = ANY (ARRAY['driver'::public.user_role_enum, 'guide'::public.user_role_enum, 'scout'::public.user_role_enum, 'transporter'::public.user_role_enum, 'cook'::public.user_role_enum, 'porter'::public.user_role_enum, 'security'::public.user_role_enum]))
  GROUP BY u.id, up.first_name, up.last_name, u.user_role, sd.department_name;


ALTER VIEW public.staff_performance OWNER TO postgres;

--
-- Name: staff_wallets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff_wallets (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    balance numeric(12,2) DEFAULT 0.00,
    total_earned numeric(12,2) DEFAULT 0.00,
    total_withdrawn numeric(12,2) DEFAULT 0.00,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.staff_wallets OWNER TO postgres;

--
-- Name: staff_withdrawals; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff_withdrawals (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    amount numeric(12,2) NOT NULL,
    bank_name character varying(100) NOT NULL,
    account_number character varying(100) NOT NULL,
    account_name character varying(100) NOT NULL,
    status character varying(50) DEFAULT 'pending'::character varying,
    admin_notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    processed_at timestamp with time zone,
    processed_by uuid
);


ALTER TABLE public.staff_withdrawals OWNER TO postgres;

--
-- Name: support_tickets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.support_tickets (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    ticket_code character varying(50) NOT NULL,
    user_id uuid NOT NULL,
    booking_id uuid,
    subject character varying(200) NOT NULL,
    description text NOT NULL,
    category character varying(100) NOT NULL,
    priority character varying(20) DEFAULT 'medium'::character varying,
    status character varying(50) DEFAULT 'open'::character varying,
    assigned_to uuid,
    resolved_by uuid,
    resolved_at timestamp with time zone,
    resolution_notes text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.support_tickets OWNER TO postgres;

--
-- Name: system_app_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.system_app_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    level public.log_level_enum DEFAULT 'INFO'::public.log_level_enum,
    category character varying(100) DEFAULT 'SYSTEM'::character varying,
    message text NOT NULL,
    user_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.system_app_logs OWNER TO postgres;

--
-- Name: system_configurations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.system_configurations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    config_key character varying(100) NOT NULL,
    config_value text,
    config_type character varying(50) DEFAULT 'string'::character varying,
    category character varying(100),
    description text,
    is_public boolean DEFAULT false,
    created_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.system_configurations OWNER TO postgres;

--
-- Name: system_performance_metrics; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.system_performance_metrics AS
 SELECT ( SELECT count(*) AS count
           FROM public.bookings) AS total_bookings,
    ( SELECT count(*) AS count
           FROM public.bookings
          WHERE (bookings.status = 'pending'::public.booking_status_enum)) AS pending_bookings,
    ( SELECT count(*) AS count
           FROM public.bookings
          WHERE (bookings.created_at >= (CURRENT_DATE - '7 days'::interval))) AS recent_bookings,
    ( SELECT count(*) AS count
           FROM public.users
          WHERE (users.status = 'active'::public.user_status_enum)) AS active_users,
    ( SELECT count(*) AS count
           FROM pg_stat_activity
          WHERE ((pg_stat_activity.datname = current_database()) AND (pg_stat_activity.state = 'active'::text))) AS active_connections,
    pg_size_pretty(pg_database_size(current_database())) AS db_size_formatted,
    ( SELECT EXTRACT(epoch FROM (CURRENT_TIMESTAMP - pg_postmaster_start_time())) AS "extract") AS uptime_seconds;


ALTER VIEW public.system_performance_metrics OWNER TO postgres;

--
-- Name: ticket_messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ticket_messages (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    ticket_id uuid NOT NULL,
    sender_id uuid NOT NULL,
    message text NOT NULL,
    attachments_urls text[],
    is_internal_note boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ticket_messages OWNER TO postgres;

--
-- Name: tour_chat_messages_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.tour_chat_messages_view AS
 SELECT cm.id AS message_id,
    cc.booking_id,
    cm.message_text AS text,
        CASE
            WHEN (u.user_role = ANY (ARRAY['admin'::public.user_role_enum, 'agency_staff'::public.user_role_enum])) THEN 'admin'::text
            ELSE concat(up.first_name, ' (', u.user_role, ')')
        END AS sender,
    cm.created_at
   FROM (((public.chat_messages cm
     JOIN public.chat_conversations cc ON ((cm.conversation_id = cc.id)))
     JOIN public.users u ON ((cm.sender_id = u.id)))
     LEFT JOIN public.user_profiles up ON ((u.id = up.user_id)))
  ORDER BY cm.created_at;


ALTER VIEW public.tour_chat_messages_view OWNER TO postgres;

--
-- Name: trip_assignments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trip_assignments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    booking_id uuid NOT NULL,
    driver_id uuid NOT NULL,
    guide_id uuid,
    vehicle_id uuid NOT NULL,
    assignment_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    assigned_by uuid,
    assignment_notes text,
    is_accepted boolean DEFAULT false,
    accepted_at timestamp with time zone,
    rejection_reason text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.trip_assignments OWNER TO postgres;

--
-- Name: trip_expenses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trip_expenses (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    booking_id uuid NOT NULL,
    expense_type character varying(100) NOT NULL,
    amount numeric(10,2) NOT NULL,
    currency character varying(3) DEFAULT 'ETB'::character varying,
    description text,
    receipt_url text,
    incurred_by uuid,
    incurred_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    approved_by uuid,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.trip_expenses OWNER TO postgres;

--
-- Name: trip_payment_calculation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trip_payment_calculation (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    booking_id uuid NOT NULL,
    total_distance_km numeric(8,2) DEFAULT 0 NOT NULL,
    distance_rate_used numeric(10,2),
    distance_based_amount numeric(10,2),
    total_hours_worked numeric(6,2) DEFAULT 0 NOT NULL,
    hourly_rate_used numeric(10,2),
    time_based_amount numeric(10,2),
    total_persons_served integer DEFAULT 0 NOT NULL,
    per_person_rate_used numeric(10,2),
    person_based_amount numeric(10,2),
    fixed_amount numeric(10,2) DEFAULT 0,
    adjustment_amount numeric(10,2) DEFAULT 0,
    final_calculated_amount numeric(12,2) GENERATED ALWAYS AS (((((COALESCE(distance_based_amount, (0)::numeric) + COALESCE(time_based_amount, (0)::numeric)) + COALESCE(person_based_amount, (0)::numeric)) + COALESCE(fixed_amount, (0)::numeric)) + COALESCE(adjustment_amount, (0)::numeric))) STORED,
    calculation_notes text,
    calculated_by uuid,
    calculated_at timestamp with time zone,
    approved_by uuid,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.trip_payment_calculation OWNER TO postgres;

--
-- Name: unified_recent_activities; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.unified_recent_activities AS
 SELECT b.id,
    'booking'::text AS type,
    ('New booking for '::text || (COALESCE(tp.name, b.custom_tour_name, 'Custom Tour'::character varying))::text) AS title,
    concat(up.first_name, ' ', up.last_name) AS user_name,
    b.final_amount AS amount,
    b.booking_code AS reference,
    NULL::text AS status,
    NULL::character varying AS method,
    b.created_at
   FROM (((public.bookings b
     JOIN public.tourists t ON ((b.tourist_id = t.id)))
     JOIN public.user_profiles up ON ((t.user_id = up.user_id)))
     LEFT JOIN public.tour_packages tp ON ((b.package_id = tp.id)))
UNION ALL
 SELECT p.id,
    'payment'::text AS type,
    'Payment received'::text AS title,
    ('Booking #'::text || (b.booking_code)::text) AS user_name,
    p.amount,
    b.booking_code AS reference,
    (p.payment_status)::text AS status,
    p.payment_method AS method,
    p.paid_at AS created_at
   FROM (public.payments p
     JOIN public.bookings b ON ((p.booking_id = b.id)))
  WHERE (p.payment_status = 'paid'::public.payment_status_enum)
UNION ALL
 SELECT a.id,
    'driver'::text AS type,
    'Driver status update'::text AS title,
    concat(up.first_name, ' ', up.last_name) AS user_name,
    NULL::numeric AS amount,
    NULL::character varying AS reference,
        CASE
            WHEN (((a.new_values ->> 'is_available'::text))::boolean = true) THEN 'Available'::text
            ELSE 'Unavailable'::text
        END AS status,
    NULL::character varying AS method,
    a.created_at
   FROM ((public.audit_logs a
     JOIN public.users u ON ((a.user_id = u.id)))
     JOIN public.user_profiles up ON ((u.id = up.user_id)))
  WHERE (((a.entity_type)::text = 'driver'::text) AND ((a.action)::text = 'UPDATE'::text))
  ORDER BY 9 DESC;


ALTER VIEW public.unified_recent_activities OWNER TO postgres;

--
-- Name: upcoming_tours_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.upcoming_tours_view AS
 SELECT b.id,
    b.booking_code,
    COALESCE(tp.name, b.custom_tour_name, 'Custom Tour'::character varying) AS custom_tour_name,
    tp.name AS package_name,
    b.start_date,
    b.status,
    COALESCE(tp.difficulty, 'moderate'::public.difficulty_level_enum) AS difficulty,
    COALESCE((tp.duration_days * 8), 8) AS estimated_duration_hours,
    1 AS total_persons,
    b.final_amount,
    'ETB'::text AS currency
   FROM (public.bookings b
     LEFT JOIN public.tour_packages tp ON ((b.package_id = tp.id)))
  WHERE ((b.start_date >= CURRENT_DATE) AND (b.status <> ALL (ARRAY['cancelled'::public.booking_status_enum, 'completed'::public.booking_status_enum, 'refunded'::public.booking_status_enum])))
  ORDER BY b.start_date;


ALTER VIEW public.upcoming_tours_view OWNER TO postgres;

--
-- Name: vehicle_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vehicle_categories (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    passenger_capacity integer NOT NULL,
    luggage_capacity integer,
    vehicle_type public.vehicle_type_enum NOT NULL,
    icon_url text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.vehicle_categories OWNER TO postgres;

--
-- Name: vehicles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vehicles (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    driver_id uuid NOT NULL,
    category_id uuid,
    plate_number character varying(20) NOT NULL,
    make character varying(100) NOT NULL,
    model character varying(100) NOT NULL,
    year integer,
    color character varying(50),
    registration_number character varying(50),
    registration_expiry date,
    insurance_number character varying(100),
    insurance_expiry date,
    insurance_photo_url text,
    fuel_type character varying(50),
    transmission character varying(50),
    features text[],
    photos_urls text[],
    is_active boolean DEFAULT true,
    current_mileage integer,
    last_service_date date,
    next_service_date date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    safety_inspection_expiry_date date
);


ALTER TABLE public.vehicles OWNER TO postgres;

--
-- Name: verification_documents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.verification_documents (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    document_type character varying(50) NOT NULL,
    document_number character varying(100),
    front_image_url text NOT NULL,
    back_image_url text,
    issue_date date,
    expiry_date date,
    issuing_authority character varying(200),
    verification_status public.verification_status_enum DEFAULT 'pending'::public.verification_status_enum,
    verified_by uuid,
    verified_at timestamp with time zone,
    rejection_reason text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.verification_documents OWNER TO postgres;

--
-- Name: api_integrations api_integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_integrations
    ADD CONSTRAINT api_integrations_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: backup_history backup_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backup_history
    ADD CONSTRAINT backup_history_pkey PRIMARY KEY (id);


--
-- Name: base_price_pools base_price_pools_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.base_price_pools
    ADD CONSTRAINT base_price_pools_pkey PRIMARY KEY (id);


--
-- Name: booking_staff_assignments booking_staff_assignments_booking_id_staff_id_assignment_ty_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking_staff_assignments
    ADD CONSTRAINT booking_staff_assignments_booking_id_staff_id_assignment_ty_key UNIQUE (booking_id, staff_id, assignment_type);


--
-- Name: booking_staff_assignments booking_staff_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking_staff_assignments
    ADD CONSTRAINT booking_staff_assignments_pkey PRIMARY KEY (id);


--
-- Name: booking_travelers booking_travelers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking_travelers
    ADD CONSTRAINT booking_travelers_pkey PRIMARY KEY (id);


--
-- Name: bookings bookings_booking_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_booking_code_key UNIQUE (booking_code);


--
-- Name: bookings bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (id);


--
-- Name: chat_conversations chat_conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_conversations
    ADD CONSTRAINT chat_conversations_pkey PRIMARY KEY (id);


--
-- Name: chat_messages chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_pkey PRIMARY KEY (id);


--
-- Name: chat_participants chat_participants_conversation_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_participants
    ADD CONSTRAINT chat_participants_conversation_id_user_id_key UNIQUE (conversation_id, user_id);


--
-- Name: chat_participants chat_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_participants
    ADD CONSTRAINT chat_participants_pkey PRIMARY KEY (id);


--
-- Name: custom_tour_details custom_tour_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custom_tour_details
    ADD CONSTRAINT custom_tour_details_pkey PRIMARY KEY (id);


--
-- Name: custom_tour_stops custom_tour_stops_custom_tour_id_visit_order_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custom_tour_stops
    ADD CONSTRAINT custom_tour_stops_custom_tour_id_visit_order_key UNIQUE (custom_tour_id, visit_order);


--
-- Name: custom_tour_stops custom_tour_stops_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custom_tour_stops
    ADD CONSTRAINT custom_tour_stops_pkey PRIMARY KEY (id);


--
-- Name: drivers drivers_license_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_license_number_key UNIQUE (license_number);


--
-- Name: drivers drivers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_pkey PRIMARY KEY (id);


--
-- Name: drivers drivers_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_user_id_key UNIQUE (user_id);


--
-- Name: emergency_alerts emergency_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.emergency_alerts
    ADD CONSTRAINT emergency_alerts_pkey PRIMARY KEY (id);


--
-- Name: famous_destinations famous_destinations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.famous_destinations
    ADD CONSTRAINT famous_destinations_pkey PRIMARY KEY (id);


--
-- Name: guides guides_guide_license_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guides
    ADD CONSTRAINT guides_guide_license_number_key UNIQUE (guide_license_number);


--
-- Name: guides guides_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guides
    ADD CONSTRAINT guides_pkey PRIMARY KEY (id);


--
-- Name: guides guides_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guides
    ADD CONSTRAINT guides_user_id_key UNIQUE (user_id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: package_destinations package_destinations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.package_destinations
    ADD CONSTRAINT package_destinations_pkey PRIMARY KEY (package_id, destination_id);


--
-- Name: package_itineraries package_itineraries_package_id_day_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.package_itineraries
    ADD CONSTRAINT package_itineraries_package_id_day_number_key UNIQUE (package_id, day_number);


--
-- Name: package_itineraries package_itineraries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.package_itineraries
    ADD CONSTRAINT package_itineraries_pkey PRIMARY KEY (id);


--
-- Name: package_pricing package_pricing_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.package_pricing
    ADD CONSTRAINT package_pricing_pkey PRIMARY KEY (id);


--
-- Name: payments payments_payment_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_payment_code_key UNIQUE (payment_code);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: price_adjustment_rules price_adjustment_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.price_adjustment_rules
    ADD CONSTRAINT price_adjustment_rules_pkey PRIMARY KEY (id);


--
-- Name: review_categories review_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.review_categories
    ADD CONSTRAINT review_categories_pkey PRIMARY KEY (id);


--
-- Name: review_ratings review_ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.review_ratings
    ADD CONSTRAINT review_ratings_pkey PRIMARY KEY (id);


--
-- Name: review_ratings review_ratings_review_id_category_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.review_ratings
    ADD CONSTRAINT review_ratings_review_id_category_id_key UNIQUE (review_id, category_id);


--
-- Name: reviews reviews_booking_id_reviewer_id_reviewee_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_booking_id_reviewer_id_reviewee_id_key UNIQUE (booking_id, reviewer_id, reviewee_id);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: staff_base_prices staff_base_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_base_prices
    ADD CONSTRAINT staff_base_prices_pkey PRIMARY KEY (id);


--
-- Name: staff_base_prices staff_base_prices_staff_id_department_id_effective_date_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_base_prices
    ADD CONSTRAINT staff_base_prices_staff_id_department_id_effective_date_key UNIQUE (staff_id, department_id, effective_date);


--
-- Name: staff_departments staff_departments_department_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_departments
    ADD CONSTRAINT staff_departments_department_code_key UNIQUE (department_code);


--
-- Name: staff_departments staff_departments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_departments
    ADD CONSTRAINT staff_departments_pkey PRIMARY KEY (id);


--
-- Name: staff_payment_transactions staff_payment_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_payment_transactions
    ADD CONSTRAINT staff_payment_transactions_pkey PRIMARY KEY (id);


--
-- Name: staff_wallets staff_wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_wallets
    ADD CONSTRAINT staff_wallets_pkey PRIMARY KEY (id);


--
-- Name: staff_wallets staff_wallets_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_wallets
    ADD CONSTRAINT staff_wallets_user_id_key UNIQUE (user_id);


--
-- Name: staff_withdrawals staff_withdrawals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_withdrawals
    ADD CONSTRAINT staff_withdrawals_pkey PRIMARY KEY (id);


--
-- Name: support_tickets support_tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_pkey PRIMARY KEY (id);


--
-- Name: support_tickets support_tickets_ticket_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_ticket_code_key UNIQUE (ticket_code);


--
-- Name: system_app_logs system_app_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_app_logs
    ADD CONSTRAINT system_app_logs_pkey PRIMARY KEY (id);


--
-- Name: system_configurations system_configurations_config_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_configurations
    ADD CONSTRAINT system_configurations_config_key_key UNIQUE (config_key);


--
-- Name: system_configurations system_configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_configurations
    ADD CONSTRAINT system_configurations_pkey PRIMARY KEY (id);


--
-- Name: ticket_messages ticket_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket_messages
    ADD CONSTRAINT ticket_messages_pkey PRIMARY KEY (id);


--
-- Name: tour_packages tour_packages_package_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_packages
    ADD CONSTRAINT tour_packages_package_code_key UNIQUE (package_code);


--
-- Name: tour_packages tour_packages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_packages
    ADD CONSTRAINT tour_packages_pkey PRIMARY KEY (id);


--
-- Name: tourists tourists_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tourists
    ADD CONSTRAINT tourists_pkey PRIMARY KEY (id);


--
-- Name: tourists tourists_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tourists
    ADD CONSTRAINT tourists_user_id_key UNIQUE (user_id);


--
-- Name: trip_assignments trip_assignments_booking_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_assignments
    ADD CONSTRAINT trip_assignments_booking_id_key UNIQUE (booking_id);


--
-- Name: trip_assignments trip_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_assignments
    ADD CONSTRAINT trip_assignments_pkey PRIMARY KEY (id);


--
-- Name: trip_expenses trip_expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_expenses
    ADD CONSTRAINT trip_expenses_pkey PRIMARY KEY (id);


--
-- Name: trip_payment_calculation trip_payment_calculation_booking_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_payment_calculation
    ADD CONSTRAINT trip_payment_calculation_booking_id_key UNIQUE (booking_id);


--
-- Name: trip_payment_calculation trip_payment_calculation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_payment_calculation
    ADD CONSTRAINT trip_payment_calculation_pkey PRIMARY KEY (id);


--
-- Name: trip_tracking trip_tracking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_tracking
    ADD CONSTRAINT trip_tracking_pkey PRIMARY KEY (id);


--
-- Name: user_profiles user_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (id);


--
-- Name: user_profiles user_profiles_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_user_id_key UNIQUE (user_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vehicle_categories vehicle_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle_categories
    ADD CONSTRAINT vehicle_categories_pkey PRIMARY KEY (id);


--
-- Name: vehicles vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_pkey PRIMARY KEY (id);


--
-- Name: vehicles vehicles_plate_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_plate_number_key UNIQUE (plate_number);


--
-- Name: verification_documents verification_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.verification_documents
    ADD CONSTRAINT verification_documents_pkey PRIMARY KEY (id);


--
-- Name: web_traffic_logs web_traffic_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.web_traffic_logs
    ADD CONSTRAINT web_traffic_logs_pkey PRIMARY KEY (id);


--
-- Name: idx_audit_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_created ON public.audit_logs USING btree (created_at);


--
-- Name: idx_audit_entity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_entity ON public.audit_logs USING btree (entity_type, entity_id);


--
-- Name: idx_audit_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_user ON public.audit_logs USING btree (user_id);


--
-- Name: idx_base_price_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_base_price_active ON public.base_price_pools USING btree (is_active);


--
-- Name: idx_base_price_department; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_base_price_department ON public.base_price_pools USING btree (department_id);


--
-- Name: idx_booking_staff_booking; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_booking_staff_booking ON public.booking_staff_assignments USING btree (booking_id);


--
-- Name: idx_booking_staff_staff; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_booking_staff_staff ON public.booking_staff_assignments USING btree (staff_id);


--
-- Name: idx_booking_staff_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_booking_staff_status ON public.booking_staff_assignments USING btree (payment_status);


--
-- Name: idx_bookings_assigned_driver; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_assigned_driver ON public.bookings USING btree (assigned_driver_id);


--
-- Name: idx_bookings_assigned_guide; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_assigned_guide ON public.bookings USING btree (assigned_guide_id);


--
-- Name: idx_bookings_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_code ON public.bookings USING btree (booking_code);


--
-- Name: idx_bookings_dates; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_dates ON public.bookings USING btree (start_date, end_date);


--
-- Name: idx_bookings_driver_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_driver_name ON public.bookings USING btree (driver_name);


--
-- Name: idx_bookings_guide_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_guide_name ON public.bookings USING btree (guide_name);


--
-- Name: idx_bookings_payment; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_payment ON public.bookings USING btree (payment_status);


--
-- Name: idx_bookings_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_status ON public.bookings USING btree (status);


--
-- Name: idx_bookings_tourist; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookings_tourist ON public.bookings USING btree (tourist_id);


--
-- Name: idx_chat_conversations_booking; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_conversations_booking ON public.chat_conversations USING btree (booking_id);


--
-- Name: idx_chat_messages_conversation; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_messages_conversation ON public.chat_messages USING btree (conversation_id);


--
-- Name: idx_chat_messages_sender; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_messages_sender ON public.chat_messages USING btree (sender_id);


--
-- Name: idx_document_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_document_status ON public.verification_documents USING btree (verification_status);


--
-- Name: idx_document_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_document_user ON public.verification_documents USING btree (user_id);


--
-- Name: idx_drivers_available; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_drivers_available ON public.drivers USING btree (is_available);


--
-- Name: idx_drivers_dept; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_drivers_dept ON public.drivers USING btree (department_id);


--
-- Name: idx_drivers_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_drivers_location ON public.drivers USING gist (current_location);


--
-- Name: idx_drivers_rating; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_drivers_rating ON public.drivers USING btree (rating);


--
-- Name: idx_emergency_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_emergency_status ON public.emergency_alerts USING btree (status);


--
-- Name: idx_guides_available; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_guides_available ON public.guides USING btree (is_available);


--
-- Name: idx_guides_dept; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_guides_dept ON public.guides USING btree (department_id);


--
-- Name: idx_notifications_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_created ON public.notifications USING btree (created_at);


--
-- Name: idx_notifications_read; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_read ON public.notifications USING btree (is_read);


--
-- Name: idx_notifications_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_user ON public.notifications USING btree (user_id);


--
-- Name: idx_payments_booking; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payments_booking ON public.payments USING btree (booking_id);


--
-- Name: idx_payments_gateway_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payments_gateway_id ON public.payments USING btree (gateway_transaction_id);


--
-- Name: idx_payments_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payments_status ON public.payments USING btree (payment_status);


--
-- Name: idx_payments_tx_ref; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payments_tx_ref ON public.payments USING btree (tx_ref);


--
-- Name: idx_profiles_passport; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profiles_passport ON public.user_profiles USING btree (passport_number);


--
-- Name: idx_profiles_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_profiles_user ON public.user_profiles USING btree (user_id);


--
-- Name: idx_reviews_booking; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reviews_booking ON public.reviews USING btree (booking_id);


--
-- Name: idx_reviews_rating; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reviews_rating ON public.reviews USING btree (rating);


--
-- Name: idx_reviews_reviewee; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reviews_reviewee ON public.reviews USING btree (reviewee_id);


--
-- Name: idx_staff_payments_booking; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_staff_payments_booking ON public.staff_payment_transactions USING btree (booking_id);


--
-- Name: idx_staff_payments_staff; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_staff_payments_staff ON public.staff_payment_transactions USING btree (staff_id);


--
-- Name: idx_staff_payments_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_staff_payments_status ON public.staff_payment_transactions USING btree (payment_status);


--
-- Name: idx_system_logs_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_system_logs_category ON public.system_app_logs USING btree (category);


--
-- Name: idx_system_logs_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_system_logs_created ON public.system_app_logs USING btree (created_at);


--
-- Name: idx_system_logs_level; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_system_logs_level ON public.system_app_logs USING btree (level);


--
-- Name: idx_tickets_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_status ON public.support_tickets USING btree (status);


--
-- Name: idx_tickets_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tickets_user ON public.support_tickets USING btree (user_id);


--
-- Name: idx_tour_packages_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tour_packages_active ON public.tour_packages USING btree (is_active);


--
-- Name: idx_tour_packages_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tour_packages_code ON public.tour_packages USING btree (package_code);


--
-- Name: idx_tour_packages_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_tour_packages_type ON public.tour_packages USING btree (tour_type);


--
-- Name: idx_trip_tracking_booking; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_trip_tracking_booking ON public.trip_tracking USING btree (booking_id);


--
-- Name: idx_trip_tracking_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_trip_tracking_location ON public.trip_tracking USING gist (location);


--
-- Name: idx_trip_tracking_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_trip_tracking_time ON public.trip_tracking USING btree (recorded_at);


--
-- Name: idx_users_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_created ON public.users USING btree (created_at);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_phone ON public.users USING btree (phone);


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_role ON public.users USING btree (user_role);


--
-- Name: idx_users_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_status ON public.users USING btree (status);


--
-- Name: idx_vehicles_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vehicles_active ON public.vehicles USING btree (is_active);


--
-- Name: idx_vehicles_driver; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vehicles_driver ON public.vehicles USING btree (driver_id);


--
-- Name: idx_vehicles_plate; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vehicles_plate ON public.vehicles USING btree (plate_number);


--
-- Name: idx_web_traffic_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_web_traffic_date ON public.web_traffic_logs USING btree (created_at);


--
-- Name: idx_web_traffic_event; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_web_traffic_event ON public.web_traffic_logs USING btree (event_type);


--
-- Name: bookings generate_booking_code_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER generate_booking_code_trigger BEFORE INSERT ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.generate_booking_code();


--
-- Name: payments trg_generate_payment_code; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_generate_payment_code BEFORE INSERT ON public.payments FOR EACH ROW EXECUTE FUNCTION public.generate_payment_code();


--
-- Name: bookings trigger_auto_create_tour_chat; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_auto_create_tour_chat AFTER UPDATE OF status ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.auto_create_tour_chat();


--
-- Name: reviews trigger_check_performance; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_check_performance AFTER INSERT ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.check_performance_review();


--
-- Name: users trigger_generate_otp_on_register; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_generate_otp_on_register BEFORE INSERT ON public.users FOR EACH ROW EXECUTE FUNCTION public.auto_generate_otp_for_new_users();


--
-- Name: bookings update_bookings_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: drivers update_drivers_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_drivers_updated_at BEFORE UPDATE ON public.drivers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: guides update_guides_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_guides_updated_at BEFORE UPDATE ON public.guides FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: reviews update_staff_rating_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_staff_rating_trigger AFTER INSERT ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.update_staff_rating();


--
-- Name: tour_packages update_tour_packages_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_tour_packages_updated_at BEFORE UPDATE ON public.tour_packages FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: user_profiles update_user_profiles_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: vehicles update_vehicles_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON public.vehicles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: backup_history backup_history_initiated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.backup_history
    ADD CONSTRAINT backup_history_initiated_by_fkey FOREIGN KEY (initiated_by) REFERENCES public.users(id);


--
-- Name: base_price_pools base_price_pools_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.base_price_pools
    ADD CONSTRAINT base_price_pools_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: base_price_pools base_price_pools_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.base_price_pools
    ADD CONSTRAINT base_price_pools_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.staff_departments(id) ON DELETE CASCADE;


--
-- Name: booking_staff_assignments booking_staff_assignments_assigned_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking_staff_assignments
    ADD CONSTRAINT booking_staff_assignments_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(id);


--
-- Name: booking_staff_assignments booking_staff_assignments_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking_staff_assignments
    ADD CONSTRAINT booking_staff_assignments_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
-- Name: booking_staff_assignments booking_staff_assignments_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking_staff_assignments
    ADD CONSTRAINT booking_staff_assignments_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.staff_departments(id);


--
-- Name: booking_staff_assignments booking_staff_assignments_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking_staff_assignments
    ADD CONSTRAINT booking_staff_assignments_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.users(id);


--
-- Name: booking_travelers booking_travelers_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.booking_travelers
    ADD CONSTRAINT booking_travelers_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
-- Name: bookings bookings_assigned_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_assigned_driver_id_fkey FOREIGN KEY (assigned_driver_id) REFERENCES public.drivers(id);


--
-- Name: bookings bookings_assigned_guide_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_assigned_guide_id_fkey FOREIGN KEY (assigned_guide_id) REFERENCES public.guides(id);


--
-- Name: bookings bookings_assigned_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_assigned_vehicle_id_fkey FOREIGN KEY (assigned_vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: bookings bookings_cancelled_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_cancelled_by_fkey FOREIGN KEY (cancelled_by) REFERENCES public.users(id);


--
-- Name: bookings bookings_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.tour_packages(id);


--
-- Name: bookings bookings_tourist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_tourist_id_fkey FOREIGN KEY (tourist_id) REFERENCES public.tourists(id) ON DELETE CASCADE;


--
-- Name: chat_conversations chat_conversations_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_conversations
    ADD CONSTRAINT chat_conversations_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
-- Name: chat_conversations chat_conversations_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_conversations
    ADD CONSTRAINT chat_conversations_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: chat_messages chat_messages_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.chat_conversations(id) ON DELETE CASCADE;


--
-- Name: chat_messages chat_messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id);


--
-- Name: chat_participants chat_participants_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_participants
    ADD CONSTRAINT chat_participants_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.chat_conversations(id) ON DELETE CASCADE;


--
-- Name: chat_participants chat_participants_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_participants
    ADD CONSTRAINT chat_participants_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: custom_tour_details custom_tour_details_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custom_tour_details
    ADD CONSTRAINT custom_tour_details_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
-- Name: custom_tour_stops custom_tour_stops_custom_tour_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custom_tour_stops
    ADD CONSTRAINT custom_tour_stops_custom_tour_id_fkey FOREIGN KEY (custom_tour_id) REFERENCES public.custom_tour_details(id) ON DELETE CASCADE;


--
-- Name: drivers drivers_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.staff_departments(id);


--
-- Name: drivers drivers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: emergency_alerts emergency_alerts_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.emergency_alerts
    ADD CONSTRAINT emergency_alerts_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id);


--
-- Name: emergency_alerts emergency_alerts_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.emergency_alerts
    ADD CONSTRAINT emergency_alerts_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.users(id);


--
-- Name: emergency_alerts emergency_alerts_triggered_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.emergency_alerts
    ADD CONSTRAINT emergency_alerts_triggered_by_fkey FOREIGN KEY (triggered_by) REFERENCES public.users(id);


--
-- Name: guides guides_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guides
    ADD CONSTRAINT guides_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.staff_departments(id);


--
-- Name: guides guides_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guides
    ADD CONSTRAINT guides_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: package_destinations package_destinations_destination_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.package_destinations
    ADD CONSTRAINT package_destinations_destination_id_fkey FOREIGN KEY (destination_id) REFERENCES public.famous_destinations(id) ON DELETE CASCADE;


--
-- Name: package_destinations package_destinations_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.package_destinations
    ADD CONSTRAINT package_destinations_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.tour_packages(id) ON DELETE CASCADE;


--
-- Name: package_itineraries package_itineraries_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.package_itineraries
    ADD CONSTRAINT package_itineraries_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.tour_packages(id) ON DELETE CASCADE;


--
-- Name: package_pricing package_pricing_package_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.package_pricing
    ADD CONSTRAINT package_pricing_package_id_fkey FOREIGN KEY (package_id) REFERENCES public.tour_packages(id) ON DELETE CASCADE;


--
-- Name: payments payments_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
-- Name: payments payments_tourist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_tourist_id_fkey FOREIGN KEY (tourist_id) REFERENCES public.tourists(id);


--
-- Name: price_adjustment_rules price_adjustment_rules_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.price_adjustment_rules
    ADD CONSTRAINT price_adjustment_rules_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: price_adjustment_rules price_adjustment_rules_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.price_adjustment_rules
    ADD CONSTRAINT price_adjustment_rules_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.staff_departments(id);


--
-- Name: review_ratings review_ratings_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.review_ratings
    ADD CONSTRAINT review_ratings_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.review_categories(id);


--
-- Name: review_ratings review_ratings_review_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.review_ratings
    ADD CONSTRAINT review_ratings_review_id_fkey FOREIGN KEY (review_id) REFERENCES public.reviews(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_responded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_responded_by_fkey FOREIGN KEY (responded_by) REFERENCES public.users(id);


--
-- Name: reviews reviews_reviewee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_reviewee_id_fkey FOREIGN KEY (reviewee_id) REFERENCES public.users(id);


--
-- Name: reviews reviews_reviewer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_reviewer_id_fkey FOREIGN KEY (reviewer_id) REFERENCES public.tourists(id);


--
-- Name: staff_base_prices staff_base_prices_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_base_prices
    ADD CONSTRAINT staff_base_prices_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: staff_base_prices staff_base_prices_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_base_prices
    ADD CONSTRAINT staff_base_prices_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.staff_departments(id);


--
-- Name: staff_base_prices staff_base_prices_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_base_prices
    ADD CONSTRAINT staff_base_prices_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: staff_departments staff_departments_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_departments
    ADD CONSTRAINT staff_departments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: staff_payment_transactions staff_payment_transactions_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_payment_transactions
    ADD CONSTRAINT staff_payment_transactions_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(id);


--
-- Name: staff_payment_transactions staff_payment_transactions_assignment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_payment_transactions
    ADD CONSTRAINT staff_payment_transactions_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.booking_staff_assignments(id);


--
-- Name: staff_payment_transactions staff_payment_transactions_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_payment_transactions
    ADD CONSTRAINT staff_payment_transactions_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id);


--
-- Name: staff_payment_transactions staff_payment_transactions_calculated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_payment_transactions
    ADD CONSTRAINT staff_payment_transactions_calculated_by_fkey FOREIGN KEY (calculated_by) REFERENCES public.users(id);


--
-- Name: staff_payment_transactions staff_payment_transactions_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_payment_transactions
    ADD CONSTRAINT staff_payment_transactions_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.users(id);


--
-- Name: staff_wallets staff_wallets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_wallets
    ADD CONSTRAINT staff_wallets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: staff_withdrawals staff_withdrawals_processed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_withdrawals
    ADD CONSTRAINT staff_withdrawals_processed_by_fkey FOREIGN KEY (processed_by) REFERENCES public.users(id);


--
-- Name: staff_withdrawals staff_withdrawals_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_withdrawals
    ADD CONSTRAINT staff_withdrawals_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: support_tickets support_tickets_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id);


--
-- Name: support_tickets support_tickets_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id);


--
-- Name: support_tickets support_tickets_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.users(id);


--
-- Name: support_tickets support_tickets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: system_app_logs system_app_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_app_logs
    ADD CONSTRAINT system_app_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: system_configurations system_configurations_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_configurations
    ADD CONSTRAINT system_configurations_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: ticket_messages ticket_messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket_messages
    ADD CONSTRAINT ticket_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id);


--
-- Name: ticket_messages ticket_messages_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket_messages
    ADD CONSTRAINT ticket_messages_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.support_tickets(id) ON DELETE CASCADE;


--
-- Name: tour_packages tour_packages_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_packages
    ADD CONSTRAINT tour_packages_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: tourists tourists_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tourists
    ADD CONSTRAINT tourists_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: trip_assignments trip_assignments_assigned_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_assignments
    ADD CONSTRAINT trip_assignments_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(id);


--
-- Name: trip_assignments trip_assignments_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_assignments
    ADD CONSTRAINT trip_assignments_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
-- Name: trip_assignments trip_assignments_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_assignments
    ADD CONSTRAINT trip_assignments_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id);


--
-- Name: trip_assignments trip_assignments_guide_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_assignments
    ADD CONSTRAINT trip_assignments_guide_id_fkey FOREIGN KEY (guide_id) REFERENCES public.guides(id);


--
-- Name: trip_assignments trip_assignments_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_assignments
    ADD CONSTRAINT trip_assignments_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id);


--
-- Name: trip_expenses trip_expenses_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_expenses
    ADD CONSTRAINT trip_expenses_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(id);


--
-- Name: trip_expenses trip_expenses_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_expenses
    ADD CONSTRAINT trip_expenses_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
-- Name: trip_expenses trip_expenses_incurred_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_expenses
    ADD CONSTRAINT trip_expenses_incurred_by_fkey FOREIGN KEY (incurred_by) REFERENCES public.users(id);


--
-- Name: trip_payment_calculation trip_payment_calculation_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_payment_calculation
    ADD CONSTRAINT trip_payment_calculation_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(id);


--
-- Name: trip_payment_calculation trip_payment_calculation_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_payment_calculation
    ADD CONSTRAINT trip_payment_calculation_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
-- Name: trip_payment_calculation trip_payment_calculation_calculated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_payment_calculation
    ADD CONSTRAINT trip_payment_calculation_calculated_by_fkey FOREIGN KEY (calculated_by) REFERENCES public.users(id);


--
-- Name: trip_tracking trip_tracking_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trip_tracking
    ADD CONSTRAINT trip_tracking_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
-- Name: user_profiles user_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: vehicles vehicles_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.vehicle_categories(id);


--
-- Name: vehicles vehicles_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id) ON DELETE CASCADE;


--
-- Name: verification_documents verification_documents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.verification_documents
    ADD CONSTRAINT verification_documents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: verification_documents verification_documents_verified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.verification_documents
    ADD CONSTRAINT verification_documents_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES public.users(id);


--
-- Name: web_traffic_logs web_traffic_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.web_traffic_logs
    ADD CONSTRAINT web_traffic_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

\unrestrict Xy6O2TQmlQff0VbfRcjhfqnPc2B8LaGbxl9aRvq9O6HWlKagaLuIUur7XCvHimx

