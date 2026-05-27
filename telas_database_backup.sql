--
-- PostgreSQL database dump
--

\restrict FVqpcalBzy9Rg1q9uAjEKCz4GhfnUp1kF1b2qaW4p4sfXf1EIykJNY2QbggcWJQ

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
-- Data for Name: api_integrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.api_integrations (id, service_name, api_key_encrypted, api_secret_encrypted, base_url, is_active, sandbox_mode, last_success_at, failure_count, rate_limit_per_minute, config, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_logs (id, user_id, action, entity_type, entity_id, old_values, new_values, ip_address, user_agent, location, created_at) FROM stdin;
105063c2-a01f-4f02-8948-9c00be8699dd	351b31d4-40b1-4f69-85dd-f5f25031a184	CREATE	system_configurations	59f6c628-b618-4d2c-9000-c50f85a601b6	\N	{"id": "59f6c628-b618-4d2c-9000-c50f85a601b6", "category": "testing", "is_public": false, "config_key": "test_setting_1779801494001", "created_at": "2026-05-26T13:18:14.002Z", "created_by": "351b31d4-40b1-4f69-85dd-f5f25031a184", "updated_at": "2026-05-26T13:18:14.002Z", "config_type": null, "description": "Test configuration for system test", "config_value": "test_value"}	\N	\N	\N	2026-05-26 16:18:15.596035+03
0b363c38-c58d-4723-a81c-c2009c01d78b	351b31d4-40b1-4f69-85dd-f5f25031a184	DELETE	system_configurations	59f6c628-b618-4d2c-9000-c50f85a601b6	{"id": "59f6c628-b618-4d2c-9000-c50f85a601b6", "category": "testing", "is_public": false, "config_key": "test_setting_1779801494001", "created_at": "2026-05-26T13:18:14.002Z", "created_by": "351b31d4-40b1-4f69-85dd-f5f25031a184", "updated_at": "2026-05-26T13:18:14.002Z", "config_type": null, "description": "Test configuration for system test", "config_value": "test_value"}	\N	\N	\N	\N	2026-05-26 16:18:16.873445+03
9e699d73-591d-4902-aa03-d239bb2f5d19	02667157-3f8d-4370-a4cf-9551d7f5c025	BACKUP	backup_history	b8c0b082-bd9f-4b3a-8080-a40c684cffb8	\N	{"status": "completed"}	\N	\N	\N	2026-05-27 05:18:24.71003+03
5f73a775-5336-4475-8172-f4dd269c6911	02667157-3f8d-4370-a4cf-9551d7f5c025	BACKUP	backup_history	49016bbd-13fc-4c15-a6e1-eb0a96850b96	\N	{"status": "completed"}	\N	\N	\N	2026-05-27 05:18:26.298419+03
17160726-889f-49b2-bf02-f6dbc3352d47	02667157-3f8d-4370-a4cf-9551d7f5c025	BACKUP	backup_history	d66718da-3f04-4eba-b9a6-f6ca9b8868c2	\N	{"status": "completed"}	\N	\N	\N	2026-05-27 05:20:59.877335+03
165dff82-d595-4d57-ac06-b62a568d905e	02667157-3f8d-4370-a4cf-9551d7f5c025	BACKUP	backup_history	969eb73f-8f34-4b7d-bacd-d7e7b4705260	\N	{"status": "completed"}	\N	\N	\N	2026-05-27 05:21:04.641953+03
966bfd3c-77e6-447e-aafd-7a8a6316c040	02667157-3f8d-4370-a4cf-9551d7f5c025	CLEAR	system_logs	\N	\N	{"status": "cleared"}	\N	\N	\N	2026-05-27 05:34:50.944877+03
dcc60872-be7f-42e6-992b-0d7445f19926	02667157-3f8d-4370-a4cf-9551d7f5c025	BACKUP	backup_history	f02de73c-283f-47d0-9c84-48932f976d6b	\N	{"status": "completed"}	\N	\N	\N	2026-05-27 05:46:49.304945+03
\.


--
-- Data for Name: backup_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.backup_history (id, backup_type, status, file_name, file_size_bytes, initiated_by, created_at) FROM stdin;
b8c0b082-bd9f-4b3a-8080-a40c684cffb8	full	completed	telas_full_1779848299662.sql	400813	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-27 05:18:19.657721+03
49016bbd-13fc-4c15-a6e1-eb0a96850b96	data	completed	telas_data_1779848305136.sql	401038	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-27 05:18:25.13272+03
d66718da-3f04-4eba-b9a6-f6ca9b8868c2	full	completed	telas_full_1779848458543.sql	402022	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-27 05:20:58.530441+03
969eb73f-8f34-4b7d-bacd-d7e7b4705260	data	completed	telas_data_1779848463359.sql	402159	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-27 05:21:03.353751+03
f02de73c-283f-47d0-9c84-48932f976d6b	full	completed	telas_full_1779850007185.sql	213379	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-27 05:46:47.180694+03
\.


--
-- Data for Name: base_price_pools; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.base_price_pools (id, department_id, price_per_unit, unit_type, currency, effective_date, expiry_date, min_units, max_units, is_active, created_by, created_at, updated_at) FROM stdin;
f8155cb1-167b-4344-a4f7-2df6bf0ee12a	9fdfe79a-4c33-4719-9f99-ceec4484cd18	90.00	per_km	ETB	2026-04-13	\N	1	\N	t	\N	2026-04-13 11:02:49.555734+03	2026-04-13 11:02:49.555734+03
65b4074e-716a-4b9f-a67e-ef3c38cedac8	244638fd-e3d4-4039-ae1f-0f4e3177af3f	3000.00	per_km	ETB	2026-05-20	\N	1	\N	t	\N	2026-05-20 01:12:13.704656+03	2026-05-20 01:12:13.704656+03
d8110564-95fd-4666-b331-3f58ec4965d8	9fdfe79a-4c33-4719-9f99-ceec4484cd18	55667.00	per_km	ETB	2026-05-21	\N	1	\N	t	\N	2026-05-21 18:00:39.453387+03	2026-05-21 18:00:39.453387+03
\.


--
-- Data for Name: booking_staff_assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.booking_staff_assignments (id, booking_id, staff_id, staff_role, department_id, assignment_type, price_calculation_method, units_assigned, unit_price, bonus_amount, deduction_amount, payment_status, paid_at, payment_method, transaction_id, assignment_notes, assigned_by, assigned_at, accepted_by_staff, accepted_at, created_at, updated_at, installment_start_paid, installment_midpoint_paid, installment_completion_paid) FROM stdin;
\.


--
-- Data for Name: booking_travelers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.booking_travelers (id, booking_id, traveler_type, first_name, last_name, date_of_birth, gender, nationality, passport_number, passport_expiry, visa_number, visa_expiry, dietary_restrictions, medical_conditions, emergency_contact, created_at) FROM stdin;
\.


--
-- Data for Name: bookings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bookings (id, booking_code, tourist_id, package_id, is_custom_tour, custom_tour_name, custom_tour_description, status, booking_date, start_date, end_date, number_of_adults, number_of_children, number_of_infants, special_requests, dietary_requirements, accommodation_preference, transport_preference, guide_preference, estimated_distance_km, estimated_duration_hours, base_price, taxes, service_fee, total_amount, discount_amount, discount_code, final_amount, currency, payment_status, assigned_driver_id, assigned_guide_id, assigned_vehicle_id, calculated_distance_km, calculated_duration_hours, total_staff_cost, base_price_breakdown, staff_payments_breakdown, rejected_reason, cancelled_by, cancelled_at, cancellation_charges, created_at, updated_at, locked_exchange_rate, locked_base_price, refund_tier, dispute_reason, is_in_escrow, guide_name, driver_name, funds_allocated) FROM stdin;
bf10e218-dd6d-429a-b77b-0fa8786c2824	TEL-2605-000003	095acb8f-ead1-47af-9b49-f4205e22f019	ece6dfea-fb15-48f0-8f5e-61df8e647117	f	\N	\N	pending	2026-05-18	2026-05-18	2026-05-18	1	0	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12500.00	0.00	\N	12500.00	ETB	pending	\N	\N	\N	150.00	3.00	0.00	\N	\N	\N	\N	\N	0.00	2026-05-18 23:50:40.999202+03	2026-05-18 23:50:40.999202+03	\N	12500.00	none	\N	f	\N	\N	f
eb417132-4b6a-455e-b4a0-d0a5d74d3e22	TEL-2605-000004	095acb8f-ead1-47af-9b49-f4205e22f019	326dc86e-58a3-4e79-802b-1a03a1a6bc2d	f	\N	\N	pending	2026-05-19	2026-05-19	2026-05-22	1	0	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12500.00	0.00	\N	12500.00	ETB	pending	\N	\N	\N	150.00	3.00	0.00	\N	\N	\N	\N	\N	0.00	2026-05-19 00:07:24.021927+03	2026-05-19 00:07:24.021927+03	\N	12500.00	none	\N	f	\N	\N	f
eb9c1fce-1b84-4b35-bd23-96f510b43c3c	TEL-2605-000005	095acb8f-ead1-47af-9b49-f4205e22f019	ece6dfea-fb15-48f0-8f5e-61df8e647117	f	\N	\N	pending	2026-05-19	2026-05-20	2026-05-27	1	0	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12500.00	0.00	\N	12500.00	ETB	pending	\N	\N	\N	150.00	3.00	0.00	\N	\N	\N	\N	\N	0.00	2026-05-19 00:18:12.728444+03	2026-05-19 00:18:12.728444+03	\N	12500.00	none	\N	f	\N	\N	f
e3ddc33f-5037-49b2-abda-57150352d178	TEL-2605-000006	095acb8f-ead1-47af-9b49-f4205e22f019	ece6dfea-fb15-48f0-8f5e-61df8e647117	f	\N	\N	pending	2026-05-19	2026-05-19	2026-05-19	1	0	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12500.00	0.00	\N	12500.00	ETB	pending	\N	\N	\N	150.00	3.00	0.00	\N	\N	\N	\N	\N	0.00	2026-05-19 12:28:51.614041+03	2026-05-19 12:28:51.614041+03	\N	12500.00	none	\N	f	\N	\N	f
cf3bdc4b-fe4a-419e-95df-f996e470a47c	TEL-2605-000007	095acb8f-ead1-47af-9b49-f4205e22f019	ece6dfea-fb15-48f0-8f5e-61df8e647117	f	\N	\N	pending	2026-05-19	2026-05-19	2026-05-19	1	0	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12500.00	0.00	\N	12500.00	ETB	pending	\N	\N	\N	150.00	3.00	0.00	\N	\N	\N	\N	\N	0.00	2026-05-19 12:58:17.735092+03	2026-05-19 12:58:17.735092+03	\N	12500.00	none	\N	f	\N	\N	f
47673b39-1232-4c97-a04b-bd771b7f9a6e	TEL-2605-000008	095acb8f-ead1-47af-9b49-f4205e22f019	ece6dfea-fb15-48f0-8f5e-61df8e647117	f	\N	\N	pending	2026-05-19	2026-05-19	2026-05-19	1	0	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12500.00	0.00	\N	12500.00	ETB	pending	\N	\N	\N	150.00	3.00	0.00	\N	\N	\N	\N	\N	0.00	2026-05-19 13:03:39.938119+03	2026-05-19 13:03:39.938119+03	\N	12500.00	none	\N	f	\N	\N	f
8ff6268a-5782-4773-ad5a-2edc79a5cacf	TEL-2605-000011	095acb8f-ead1-47af-9b49-f4205e22f019	ece6dfea-fb15-48f0-8f5e-61df8e647117	f	\N	\N	pending	2026-05-19	2026-05-19	2026-05-19	1	0	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12500.00	0.00	\N	12500.00	ETB	pending	\N	\N	\N	150.00	3.00	0.00	\N	\N	\N	\N	\N	0.00	2026-05-19 14:41:45.635444+03	2026-05-19 14:41:45.635444+03	\N	12500.00	none	\N	f	\N	\N	f
a020bfc1-8d90-47cf-b44d-069040b63a90	TEL-2605-000009	095acb8f-ead1-47af-9b49-f4205e22f019	ece6dfea-fb15-48f0-8f5e-61df8e647117	f	\N	\N	confirmed	2026-05-19	2026-05-19	2026-05-19	1	0	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12500.00	0.00	\N	12500.00	ETB	pending	2a16833f-49ee-47ec-9c2b-9ec27ab14c49	30640cb1-5427-4f84-9777-f76188dd6fba	\N	150.00	3.00	0.00	\N	\N	\N	\N	\N	0.00	2026-05-19 13:08:56.241251+03	2026-05-23 13:43:47.87845+03	\N	12500.00	none	\N	f	Amanuel Azanaw	abudt12@gmail.com	f
9fd51b0c-2d47-4ab9-8889-cb57163288cd	TEL-2605-000013	095acb8f-ead1-47af-9b49-f4205e22f019	773360e5-2277-4aad-9abd-ba4dcadebed0	f	\N	\N	confirmed	2026-05-20	2026-05-20	2026-05-27	1	0	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12500.00	0.00	\N	12500.00	ETB	pending	2a16833f-49ee-47ec-9c2b-9ec27ab14c49	515be2a1-3ea0-4ce3-8924-2f36425acd3b	\N	150.00	3.00	0.00	\N	\N	\N	\N	\N	0.00	2026-05-20 20:38:47.585678+03	2026-05-23 13:43:47.900678+03	\N	12500.00	none	\N	f	tekymary1221@gmail.com	abudt12@gmail.com	f
28094257-2c0b-4b80-a6ac-9219eb4494f1	TEL-2605-000016	9f37ddc4-4d45-4684-83ed-b3eb54394bc2	773360e5-2277-4aad-9abd-ba4dcadebed0	f	\N	\N	confirmed	2026-05-23	2026-05-23	2026-05-30	1	0	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12500.00	0.00	\N	12500.00	ETB	pending	3792db4b-c57e-4bdd-8a90-75adf290be92	30640cb1-5427-4f84-9777-f76188dd6fba	\N	150.00	3.00	0.00	\N	\N	\N	\N	\N	0.00	2026-05-23 12:29:35.874784+03	2026-05-23 16:11:17.352351+03	\N	12500.00	none	\N	f	Amanuel Azanaw	Teklu  Kidanemariyam	f
b86582fa-0a79-4999-bd11-157fd8d97fd2	TEL-2605-000002	095acb8f-ead1-47af-9b49-f4205e22f019	ece6dfea-fb15-48f0-8f5e-61df8e647117	f	\N	\N	confirmed	2026-05-18	2026-05-18	2026-05-18	1	0	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12500.00	0.00	\N	12500.00	ETB	pending	2a16833f-49ee-47ec-9c2b-9ec27ab14c49	5151f20e-a4a7-464d-8104-921de0ace90b	\N	150.00	3.00	0.00	\N	\N	\N	\N	\N	0.00	2026-05-18 23:04:00.236454+03	2026-05-24 04:59:14.098038+03	\N	12500.00	none	\N	f	Natnael Getnet	Natnael Getnet	f
afc2b963-631d-4b13-9b00-0d309c8599a9	TEL-2605-000017	095acb8f-ead1-47af-9b49-f4205e22f019	773360e5-2277-4aad-9abd-ba4dcadebed0	f	\N	\N	pending	2026-05-25	2026-05-25	2026-06-01	1	0	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12500.00	0.00	\N	12500.00	ETB	pending	\N	\N	\N	150.00	3.00	0.00	\N	\N	\N	\N	\N	0.00	2026-05-25 09:05:09.365045+03	2026-05-25 09:05:09.365045+03	\N	12500.00	none	\N	f	\N	\N	f
10d025be-dd4d-4d34-882f-27f70cd4af76	TEL-2605-000010	095acb8f-ead1-47af-9b49-f4205e22f019	ece6dfea-fb15-48f0-8f5e-61df8e647117	f	\N	\N	confirmed	2026-05-19	2026-05-19	2026-05-19	1	0	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12500.00	0.00	\N	12500.00	ETB	pending	\N	515be2a1-3ea0-4ce3-8924-2f36425acd3b	\N	150.00	3.00	0.00	\N	\N	\N	\N	\N	0.00	2026-05-19 14:28:44.251493+03	2026-05-27 04:33:34.768988+03	\N	12500.00	none	\N	f	tekymary1221@gmail.com	teme24@gmail.com	f
966d47f5-3aef-463e-981c-a773003bf56e	TEL-2605-000014	095acb8f-ead1-47af-9b49-f4205e22f019	773360e5-2277-4aad-9abd-ba4dcadebed0	f	\N	\N	confirmed	2026-05-20	2026-05-20	2026-05-27	1	0	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12500.00	0.00	\N	12500.00	ETB	pending	\N	5151f20e-a4a7-464d-8104-921de0ace90b	\N	150.00	3.00	0.00	\N	\N	\N	\N	\N	0.00	2026-05-20 20:43:13.222499+03	2026-05-27 04:33:34.768988+03	\N	12500.00	none	\N	f	abudt121@gmail.com	teme24@gmail.com	f
447de65c-3790-4f7d-a003-a5a5a20887be	TEL-2605-000001	095acb8f-ead1-47af-9b49-f4205e22f019	ece6dfea-fb15-48f0-8f5e-61df8e647117	f	\N	\N	confirmed	2026-05-18	2026-05-18	2026-05-18	1	0	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12500.00	0.00	\N	12500.00	ETB	pending	3792db4b-c57e-4bdd-8a90-75adf290be92	\N	\N	150.00	3.00	0.00	\N	\N	\N	\N	\N	0.00	2026-05-18 22:55:22.439786+03	2026-05-27 04:38:32.535777+03	\N	12500.00	none	\N	f	temedeg69@gmail.com	teklukide27@gmail.com	f
45882f66-ab79-4559-9cd3-783814d48ebf	TEL-2605-000012	095acb8f-ead1-47af-9b49-f4205e22f019	ece6dfea-fb15-48f0-8f5e-61df8e647117	f	\N	\N	pending	2026-05-19	2026-05-19	2026-05-19	1	0	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12500.00	0.00	\N	12500.00	ETB	pending	\N	\N	\N	150.00	3.00	0.00	\N	\N	\N	\N	\N	0.00	2026-05-19 14:47:37.926408+03	2026-05-27 04:38:32.535777+03	\N	12500.00	none	\N	f	temedeg69@gmail.com	\N	f
12ac405e-385d-4df4-8bed-f3bbe1cd8880	TEL-2605-000015	095acb8f-ead1-47af-9b49-f4205e22f019	773360e5-2277-4aad-9abd-ba4dcadebed0	f	\N	\N	pending	2026-05-20	2026-05-20	2026-05-27	1	0	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	12500.00	0.00	\N	12500.00	ETB	pending	\N	\N	\N	150.00	3.00	0.00	\N	\N	\N	\N	\N	0.00	2026-05-20 20:56:30.63285+03	2026-05-27 04:38:32.535777+03	\N	12500.00	none	\N	f	temedeg69@gmail.com	\N	f
\.


--
-- Data for Name: chat_conversations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_conversations (id, conversation_uuid, is_group_chat, group_name, created_by, created_at, updated_at, booking_id) FROM stdin;
56b2117a-3164-4072-81ea-a5756456f83d	cd855af2-b5ad-4ad7-a102-178d7020bd94	t	Tour Chat - TEL-2605-000015	\N	2026-05-21 12:51:20.632959+03	2026-05-21 12:51:20.632959+03	12ac405e-385d-4df4-8bed-f3bbe1cd8880
58d9d7da-aa16-4dcd-924b-92f73acc860d	e2a903d7-5e5c-42c8-819c-52dbfde97d8c	t	Tour Chat - TEL-2605-000014	\N	2026-05-21 13:21:07.974645+03	2026-05-21 13:21:07.974645+03	966d47f5-3aef-463e-981c-a773003bf56e
1fcd3249-8115-4cfa-81e1-261601a3dfab	4ba43a25-2d1f-404f-bbc6-f76b89d3c4b6	t	Tour Chat - TEL-2605-000013	\N	2026-05-21 13:21:26.672944+03	2026-05-21 13:21:26.672944+03	9fd51b0c-2d47-4ab9-8889-cb57163288cd
59ff4af3-f528-4199-9045-c3c88fbc76cf	71ad8fdf-1024-4b07-bcb0-d9c13ab2cc6a	t	Tour Chat - TEL-2605-000012	\N	2026-05-21 13:21:34.301985+03	2026-05-21 13:21:34.301985+03	45882f66-ab79-4559-9cd3-783814d48ebf
4ba49b0f-b78e-4327-8089-88879eedd74e	85677826-d23f-4fd4-ac0b-6dd73d9755db	t	Tour Chat - TEL-2605-000009	\N	2026-05-21 13:22:13.493891+03	2026-05-21 13:22:13.493891+03	a020bfc1-8d90-47cf-b44d-069040b63a90
0246ef39-3c5a-4816-8c07-3530e2655203	2dc6a358-e187-45ac-abd4-b9e6b5fa9661	t	Tour Chat - TEL-2605-000010	\N	2026-05-21 13:22:27.732849+03	2026-05-21 13:22:27.732849+03	10d025be-dd4d-4d34-882f-27f70cd4af76
5eb262d8-0b56-4398-8ff3-cfe21a784ac6	e9fa3fa8-4c81-470d-ae70-daef75deec63	t	Tour Chat - TEL-2605-000001	\N	2026-05-23 13:37:12.923928+03	2026-05-23 13:37:12.923928+03	447de65c-3790-4f7d-a003-a5a5a20887be
3e46c8a8-9ad6-44c9-a66b-b1b657ac5283	930890bc-ca05-4c74-b499-16b4444a7bdf	t	Tour Chat - TEL-2605-000016	\N	2026-05-23 16:11:17.352351+03	2026-05-23 16:11:17.352351+03	28094257-2c0b-4b80-a6ac-9219eb4494f1
a30cba2e-3355-4889-a8e6-839d31c75b1e	319c6505-e2ad-45ed-8a2b-4fb40a05e7b1	t	Booking TEL-2605-000015 Chat	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-24 04:58:46.255106+03	2026-05-24 04:58:46.255106+03	\N
9acdcb55-14fd-460c-870e-68df44de1cd3	d7b39b05-cd28-4d16-a9fa-49ee8c1dbddd	t	Booking TEL-2605-000005 Chat	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-24 04:58:54.503974+03	2026-05-24 04:58:54.503974+03	\N
6d10d22d-3032-490a-b38d-c39ba3d1072e	d6ded271-a84f-45c0-8568-f40eede4e0f6	t	Booking TEL-2605-000002 Chat	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-24 04:59:09.567167+03	2026-05-24 04:59:09.567167+03	\N
eae6490b-3056-4371-bc30-a251fad13ef5	88f9e9b0-a090-4eb9-aaa2-8506dde2d36a	t	Tour Chat - TEL-2605-000002	\N	2026-05-24 04:59:14.098038+03	2026-05-24 04:59:14.098038+03	b86582fa-0a79-4999-bd11-157fd8d97fd2
80e4fd49-a50e-4db0-9a0a-b06d1288d087	6f965ce7-08be-4cd2-94e5-57e0fb95df1c	t	Booking TEL-2605-000016 Chat	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-24 04:59:22.688257+03	2026-05-24 04:59:22.688257+03	\N
6a526c2e-a00d-4f86-ba38-82e0700da2c3	e7edf943-1341-4e9a-858a-26c455a1ee4a	t	Booking TEL-2605-000014 Chat	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-24 05:15:16.43283+03	2026-05-24 05:15:16.43283+03	\N
be3d060b-8826-4222-8fb0-1e990fd55f83	b834f61f-67d1-441d-bb8b-64f6f0c5fbd5	t	Booking TEL-2605-000017 Chat	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-25 09:07:12.478857+03	2026-05-25 09:07:12.478857+03	\N
f47d9806-42b6-416a-8295-d41474cd0288	e2d9c737-847a-436f-8106-3eb7cebab0c2	t	Booking TEL-2605-000013 Chat	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-26 10:23:08.78368+03	2026-05-26 10:23:08.78368+03	\N
f675c9d3-a787-473f-80e1-32e77cc3cb0d	83bdad47-ef5f-4016-9418-57cce33c1813	t	Booking 966d47f5-3aef-463e-981c-a773003bf56e Chat	\N	2026-05-21 13:21:08.01757+03	2026-05-21 13:21:08.01757+03	\N
ccbbc44c-0657-4324-9843-7d5e7cfa7b5f	abd6f42e-dd80-4888-89c0-ab207b794362	t	Booking 9fd51b0c-2d47-4ab9-8889-cb57163288cd Chat	\N	2026-05-21 13:21:25.031992+03	2026-05-21 13:21:25.031992+03	\N
463d853f-859e-46df-80ea-5d4bc199f51a	800208a4-6b17-4f59-9d84-5605700436e0	t	Booking 45882f66-ab79-4559-9cd3-783814d48ebf Chat	\N	2026-05-21 13:21:32.407346+03	2026-05-21 13:21:32.407346+03	\N
0a75b2bb-7af7-4d7d-a4af-0487e232270e	a4f93a5b-fdfc-4060-a96e-9aa09349d504	t	Booking a020bfc1-8d90-47cf-b44d-069040b63a90 Chat	\N	2026-05-21 13:22:11.508675+03	2026-05-21 13:22:11.508675+03	\N
d7c46ddf-bc4d-4e22-a5ed-7a90270a5bc5	58109b38-4826-46fd-a6e0-fc804e5f4950	t	Booking 10d025be-dd4d-4d34-882f-27f70cd4af76 Chat	\N	2026-05-21 13:22:25.593631+03	2026-05-21 13:22:25.593631+03	\N
bcfe5e68-6ba1-4670-bb40-aa565b92ef5c	c47f9404-2db7-4be6-b800-679dce2e8dc4	t	Booking 447de65c-3790-4f7d-a003-a5a5a20887be Chat	\N	2026-05-23 13:37:13.534851+03	2026-05-23 13:37:13.534851+03	\N
e029970d-55a9-4e73-9d72-86d07a0d94d9	f92bb61b-0d23-49eb-b488-7fdf6639f783	t	Booking 28094257-2c0b-4b80-a6ac-9219eb4494f1 Chat	\N	2026-05-23 16:11:15.43848+03	2026-05-23 16:11:15.43848+03	\N
3061135b-1cba-486e-9024-2ffa449bfc7b	ecb65abe-cc56-45a4-920e-5ec175df3063	t	Booking b86582fa-0a79-4999-bd11-157fd8d97fd2 Chat	\N	2026-05-24 04:59:10.47913+03	2026-05-24 04:59:10.47913+03	\N
\.


--
-- Data for Name: chat_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_messages (id, conversation_id, sender_id, message_type, message_text, media_url, location, file_name, file_size, is_read, read_by_recipient, deleted_for_sender, deleted_for_all, created_at) FROM stdin;
31a6d712-4dbe-483d-beae-6bac7ff3f35a	80e4fd49-a50e-4db0-9a0a-b06d1288d087	02667157-3f8d-4370-a4cf-9551d7f5c025	system	Group chat created for booking TEL-2605-000016. All participants can now communicate.	\N	\N	\N	\N	t	f	f	f	2026-05-24 04:59:22.710814+03
aa1576d5-3649-483d-9ebe-efe818932134	80e4fd49-a50e-4db0-9a0a-b06d1288d087	5cee148d-439c-422b-b3ca-515a7c847d25	text	Hey Guy's my name is teklu kidanemariyam and i am your driver for this tour we🙏	\N	\N	\N	\N	f	f	f	f	2026-05-24 05:14:05.609119+03
6c04fcac-b7a7-4446-898c-3ebbe3ed12d0	6a526c2e-a00d-4f86-ba38-82e0700da2c3	02667157-3f8d-4370-a4cf-9551d7f5c025	system	Group chat created for booking TEL-2605-000014. All participants can now communicate.	\N	\N	\N	\N	t	f	f	f	2026-05-24 05:15:16.509285+03
f8847eb0-511c-47fd-ae49-93b9c17efb0d	6d10d22d-3032-490a-b38d-c39ba3d1072e	02667157-3f8d-4370-a4cf-9551d7f5c025	system	Group chat created for booking TEL-2605-000002. All participants can now communicate.	\N	\N	\N	\N	t	f	f	f	2026-05-24 04:59:09.610568+03
c61dcce4-f05e-4d96-91ae-e370fbaba709	a30cba2e-3355-4889-a8e6-839d31c75b1e	02667157-3f8d-4370-a4cf-9551d7f5c025	system	Group chat created for booking TEL-2605-000015. All participants can now communicate.	\N	\N	\N	\N	t	f	f	f	2026-05-24 04:58:46.478887+03
1b514fed-6d20-4d8b-9163-46be6404fb1e	9acdcb55-14fd-460c-870e-68df44de1cd3	02667157-3f8d-4370-a4cf-9551d7f5c025	system	Group chat created for booking TEL-2605-000005. All participants can now communicate.	\N	\N	\N	\N	t	f	f	f	2026-05-24 04:58:54.526911+03
8b6023d4-d6d4-4017-a687-4407cf7a6727	80e4fd49-a50e-4db0-9a0a-b06d1288d087	02667157-3f8d-4370-a4cf-9551d7f5c025	text	hey this is your tour operator how is going	\N	\N	\N	\N	t	f	f	f	2026-05-25 09:19:44.89213+03
bc33ad3c-7325-4573-8d2a-816456c5b016	80e4fd49-a50e-4db0-9a0a-b06d1288d087	5cee148d-439c-422b-b3ca-515a7c847d25	text	Every thing good 👍	\N	\N	\N	\N	f	f	f	f	2026-05-25 09:20:27.000217+03
13825f0d-4489-42e2-8e03-cc5ae8dc43f2	80e4fd49-a50e-4db0-9a0a-b06d1288d087	5cee148d-439c-422b-b3ca-515a7c847d25	text	Ok happy anniversary	\N	\N	\N	\N	f	f	f	f	2026-05-25 09:20:54.818271+03
0ef6eba0-fff3-48dc-bddd-f6f9781b4077	80e4fd49-a50e-4db0-9a0a-b06d1288d087	02667157-3f8d-4370-a4cf-9551d7f5c025	text	good	\N	\N	\N	\N	t	f	f	f	2026-05-25 09:21:18.855406+03
e6368e33-df34-41b3-904c-d085bce0091c	be3d060b-8826-4222-8fb0-1e990fd55f83	02667157-3f8d-4370-a4cf-9551d7f5c025	system	Group chat created for booking TEL-2605-000017. All participants can now communicate.	\N	\N	\N	\N	t	f	f	f	2026-05-25 09:07:12.730954+03
b044f39f-82a3-4c8f-85b8-a0b9a0761650	6d10d22d-3032-490a-b38d-c39ba3d1072e	02667157-3f8d-4370-a4cf-9551d7f5c025	text	🔔 System: Auto-assignment Confirmed! Guide (Natnael Getnet) and Driver (Natnael Getnet) have been officially added to this group chat.	\N	\N	\N	\N	t	f	f	f	2026-05-24 04:59:14.263239+03
77634652-3484-4122-9992-2003220dd76e	6d10d22d-3032-490a-b38d-c39ba3d1072e	fcabec9c-3367-45f0-b462-271ee937b40c	text	Helo	\N	\N	\N	\N	f	f	f	f	2026-05-25 09:31:14.044193+03
2bc5e343-fe56-4193-93b9-6d385c091aff	6d10d22d-3032-490a-b38d-c39ba3d1072e	02667157-3f8d-4370-a4cf-9551d7f5c025	text	hey there	\N	\N	\N	\N	t	f	f	f	2026-05-25 09:32:08.41614+03
8378b4d9-55f2-427e-961b-f29808e7b8b1	f47d9806-42b6-416a-8295-d41474cd0288	02667157-3f8d-4370-a4cf-9551d7f5c025	system	Group chat created for booking TEL-2605-000013. All participants can now communicate.	\N	\N	\N	\N	t	f	f	f	2026-05-26 10:23:09.872858+03
bbd31863-db48-40a6-a103-174daf17e019	f47d9806-42b6-416a-8295-d41474cd0288	fcabec9c-3367-45f0-b462-271ee937b40c	text	Jejkfk	\N	\N	\N	\N	f	f	f	f	2026-05-26 16:43:19.43203+03
0f6b2bcd-017e-44e9-a875-03069243f226	9acdcb55-14fd-460c-870e-68df44de1cd3	fcabec9c-3367-45f0-b462-271ee937b40c	text	Jehrkjr	\N	\N	\N	\N	f	f	f	f	2026-05-26 16:43:29.637228+03
\.


--
-- Data for Name: chat_participants; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_participants (id, conversation_id, user_id, joined_at, left_at, last_read_at) FROM stdin;
ef6be016-1847-4bff-9fe3-0f90ed03ff1d	a30cba2e-3355-4889-a8e6-839d31c75b1e	fcabec9c-3367-45f0-b462-271ee937b40c	2026-05-24 04:58:46.379033+03	\N	\N
9b46c3a8-2d61-4324-9155-5d570bfd5d72	a30cba2e-3355-4889-a8e6-839d31c75b1e	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-24 04:58:46.472628+03	\N	\N
cc00a763-2a00-4aed-b3b0-e4363c88c345	9acdcb55-14fd-460c-870e-68df44de1cd3	fcabec9c-3367-45f0-b462-271ee937b40c	2026-05-24 04:58:54.514048+03	\N	\N
cc97ae85-695b-4123-a80f-149391f69464	9acdcb55-14fd-460c-870e-68df44de1cd3	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-24 04:58:54.52356+03	\N	\N
51800424-0df0-4bba-8cbb-b783ed3d18ce	6d10d22d-3032-490a-b38d-c39ba3d1072e	fcabec9c-3367-45f0-b462-271ee937b40c	2026-05-24 04:59:09.58022+03	\N	\N
638fb72b-1676-4407-b513-f57088943fb2	6d10d22d-3032-490a-b38d-c39ba3d1072e	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-24 04:59:09.595269+03	\N	\N
9c74e811-581e-485d-b885-92652d9bf368	80e4fd49-a50e-4db0-9a0a-b06d1288d087	37d4e940-020a-41ae-8203-d694a4dd7bdd	2026-05-24 04:59:22.692416+03	\N	\N
1a0bdc66-c627-4938-b502-7a94fccef1a5	80e4fd49-a50e-4db0-9a0a-b06d1288d087	85b671d7-a4e8-4192-b911-306ac6b46b2c	2026-05-24 04:59:22.699052+03	\N	\N
44dd30e0-1e48-454a-bc2b-95905545b5c8	80e4fd49-a50e-4db0-9a0a-b06d1288d087	5cee148d-439c-422b-b3ca-515a7c847d25	2026-05-24 04:59:22.703872+03	\N	\N
7b66192f-c307-4a46-a7b8-27ac14b0d0c6	80e4fd49-a50e-4db0-9a0a-b06d1288d087	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-24 04:59:22.708527+03	\N	\N
ea953c66-8a68-4277-9821-3b26443ce450	6a526c2e-a00d-4f86-ba38-82e0700da2c3	fcabec9c-3367-45f0-b462-271ee937b40c	2026-05-24 05:15:16.49717+03	\N	\N
b5bcd124-8119-4691-b11d-f0f729ff54e5	6a526c2e-a00d-4f86-ba38-82e0700da2c3	351b31d4-40b1-4f69-85dd-f5f25031a184	2026-05-24 05:15:16.499622+03	\N	\N
7e0341b4-73f2-4944-b2f6-71252eb6246a	6a526c2e-a00d-4f86-ba38-82e0700da2c3	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-24 05:15:16.504555+03	\N	\N
58cfc6d3-5645-4933-a5fd-c164fe40f45a	be3d060b-8826-4222-8fb0-1e990fd55f83	fcabec9c-3367-45f0-b462-271ee937b40c	2026-05-25 09:07:12.665081+03	\N	\N
6170d0ca-9d9e-43b6-b7b5-6bb8b4cfd3ea	be3d060b-8826-4222-8fb0-1e990fd55f83	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-25 09:07:12.728787+03	\N	\N
158f6bbb-1da0-4ee9-9c05-8e1ac457269c	f47d9806-42b6-416a-8295-d41474cd0288	fcabec9c-3367-45f0-b462-271ee937b40c	2026-05-26 10:23:09.734528+03	\N	\N
398af46f-290a-490a-aa10-2afbec73ed20	f47d9806-42b6-416a-8295-d41474cd0288	7661899a-97cc-493a-a37d-b783e6335c7f	2026-05-26 10:23:09.738032+03	\N	\N
21a17eb6-f52d-4307-a550-a4abee919d50	f47d9806-42b6-416a-8295-d41474cd0288	8b228fea-ed40-4ee1-b7f9-c17585adc595	2026-05-26 10:23:09.740067+03	\N	\N
e83dc1b0-0330-41cb-a26d-8664001dc2b1	f47d9806-42b6-416a-8295-d41474cd0288	02667157-3f8d-4370-a4cf-9551d7f5c025	2026-05-26 10:23:09.805316+03	\N	\N
\.


--
-- Data for Name: custom_tour_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.custom_tour_details (id, booking_id, start_destination_id, end_destination_id, travel_purpose, specific_requirements, budget_range, preferred_activities, accommodation_standard, transport_preference, guide_required, created_at) FROM stdin;
\.


--
-- Data for Name: custom_tour_stops; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.custom_tour_stops (id, custom_tour_id, destination_id, visit_order, visit_duration_hours, special_instructions, activities, created_at) FROM stdin;
\.


--
-- Data for Name: drivers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.drivers (id, user_id, department_id, license_number, license_issue_date, license_expiry_date, license_photo_url, years_experience, rating, total_trips, is_available, current_location, service_areas, languages_spoken, max_daily_hours, created_at, updated_at, average_response_time_minutes, booking_completion_rate, consecutive_low_ratings, performance_review_status) FROM stdin;
2a16833f-49ee-47ec-9c2b-9ec27ab14c49	8b228fea-ed40-4ee1-b7f9-c17585adc595	\N	DL-53738	2026-05-23	2027-05-23	/uploads/1779523087945-38851047.jpg	5	0.00	0	t	\N	\N	{Amharic,English}	10	2026-05-23 10:58:09.144814+03	2026-05-23 11:52:21.964089+03	0	100.00	0	f
3792db4b-c57e-4bdd-8a90-75adf290be92	5cee148d-439c-422b-b3ca-515a7c847d25	\N	43536	2026-05-17	2027-05-17	/uploads/1778997910145-739862158.jpg	8	0.00	0	t	\N	\N	{Amharic,English}	10	2026-05-17 09:05:10.897877+03	2026-05-23 12:35:57.565611+03	0	100.00	0	f
\.


--
-- Data for Name: emergency_alerts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.emergency_alerts (id, booking_id, triggered_by, location, alert_time, status, resolved_by, resolution_notes) FROM stdin;
\.


--
-- Data for Name: famous_destinations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.famous_destinations (id, name, address, description, main_image_url, latitude, longitude, created_at) FROM stdin;
\.


--
-- Data for Name: guides; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.guides (id, user_id, department_id, guide_license_number, license_issue_date, license_expiry_date, license_photo_url, specialization, languages_spoken, languages_certified, years_experience, rating, total_tours, is_available, hourly_rate, daily_rate, max_group_size, has_first_aid_cert, first_aid_expiry, education_background, created_at, updated_at, average_response_time_minutes, booking_completion_rate, consecutive_low_ratings, performance_review_status) FROM stdin;
515be2a1-3ea0-4ce3-8924-2f36425acd3b	7661899a-97cc-493a-a37d-b783e6335c7f	\N	674648	2026-05-17	2027-05-17	/uploads/1778998746143-126135113.jpg	\N	{Amharic}	\N	6	0.00	0	t	\N	\N	15	f	\N	\N	2026-05-17 09:19:06.524802+03	2026-05-17 09:19:06.524802+03	0	100.00	0	f
30640cb1-5427-4f84-9777-f76188dd6fba	85b671d7-a4e8-4192-b911-306ac6b46b2c	\N	7638748	2026-05-17	2027-05-17	/uploads/1779002219447-641469546.jpg	\N	{English}	\N	6	0.00	0	t	\N	\N	15	f	\N	\N	2026-05-17 10:17:10.479543+03	2026-05-17 11:25:24.65617+03	0	100.00	0	f
5151f20e-a4a7-464d-8104-921de0ace90b	351b31d4-40b1-4f69-85dd-f5f25031a184	\N	GL-2I2	2026-05-23	2027-05-23	/uploads/1779528133794-184732277.jpg	\N	{AMHARIC,ENGLISH}	\N	2	0.00	0	t	\N	\N	15	f	\N	\N	2026-05-23 12:22:14.851954+03	2026-05-23 12:29:42.589287+03	0	100.00	0	f
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, user_id, notification_type, title, message, data, is_read, read_at, action_url, priority, expires_at, created_at) FROM stdin;
fa612599-0c9e-4e36-93ab-58a4b5ff9fc9	5cee148d-439c-422b-b3ca-515a7c847d25	assignment_request	New Tour Assignment	You have been assigned to travel with telas starting Wed May 20 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "3792db4b-c57e-4bdd-8a90-75adf290be92", "tour_name": "travel with telas", "booking_id": "12ac405e-385d-4df4-8bed-f3bbe1cd8880", "staff_type": "driver", "start_date": "2026-05-19T21:00:00.000Z", "booking_code": "TEL-2605-000015", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/12ac405e-385d-4df4-8bed-f3bbe1cd8880	high	2026-05-21 14:08:51.480199+03	2026-05-21 13:08:51.480199+03
b5036c86-3fb0-45f0-bdc0-3b677091eeb8	85b671d7-a4e8-4192-b911-306ac6b46b2c	assignment_request	New Tour Assignment	You have been assigned to travel with telas starting Wed May 20 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "30640cb1-5427-4f84-9777-f76188dd6fba", "tour_name": "travel with telas", "booking_id": "966d47f5-3aef-463e-981c-a773003bf56e", "staff_type": "guide", "start_date": "2026-05-19T21:00:00.000Z", "booking_code": "TEL-2605-000014", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/966d47f5-3aef-463e-981c-a773003bf56e	high	2026-05-21 14:21:08.009588+03	2026-05-21 13:21:08.009588+03
088a7c37-878f-49fc-9000-f86dbb799dc4	5cee148d-439c-422b-b3ca-515a7c847d25	assignment_request	New Tour Assignment	You have been assigned to travel with telas starting Wed May 20 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "3792db4b-c57e-4bdd-8a90-75adf290be92", "tour_name": "travel with telas", "booking_id": "966d47f5-3aef-463e-981c-a773003bf56e", "staff_type": "driver", "start_date": "2026-05-19T21:00:00.000Z", "booking_code": "TEL-2605-000014", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/966d47f5-3aef-463e-981c-a773003bf56e	high	2026-05-21 14:21:08.160303+03	2026-05-21 13:21:08.160303+03
4c1339cf-5677-4771-9c20-86a8f8d8450b	85b671d7-a4e8-4192-b911-306ac6b46b2c	assignment_request	New Tour Assignment	You have been assigned to travel with telas starting Wed May 20 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "30640cb1-5427-4f84-9777-f76188dd6fba", "tour_name": "travel with telas", "booking_id": "9fd51b0c-2d47-4ab9-8889-cb57163288cd", "staff_type": "guide", "start_date": "2026-05-19T21:00:00.000Z", "booking_code": "TEL-2605-000013", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/9fd51b0c-2d47-4ab9-8889-cb57163288cd	high	2026-05-21 14:21:25.01399+03	2026-05-21 13:21:25.01399+03
b0a795e4-a2f2-4813-8904-85898515c8b0	5cee148d-439c-422b-b3ca-515a7c847d25	assignment_request	New Tour Assignment	You have been assigned to travel with telas starting Wed May 20 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "3792db4b-c57e-4bdd-8a90-75adf290be92", "tour_name": "travel with telas", "booking_id": "9fd51b0c-2d47-4ab9-8889-cb57163288cd", "staff_type": "driver", "start_date": "2026-05-19T21:00:00.000Z", "booking_code": "TEL-2605-000013", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/9fd51b0c-2d47-4ab9-8889-cb57163288cd	high	2026-05-21 14:21:25.054814+03	2026-05-21 13:21:25.054814+03
2d3de421-55d6-41ed-ab5b-c83de6ba7451	85b671d7-a4e8-4192-b911-306ac6b46b2c	assignment_request	New Tour Assignment	You have been assigned to travel with telas starting Wed May 20 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "30640cb1-5427-4f84-9777-f76188dd6fba", "tour_name": "travel with telas", "booking_id": "9fd51b0c-2d47-4ab9-8889-cb57163288cd", "staff_type": "guide", "start_date": "2026-05-19T21:00:00.000Z", "booking_code": "TEL-2605-000013", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/9fd51b0c-2d47-4ab9-8889-cb57163288cd	high	2026-05-21 14:21:25.241768+03	2026-05-21 13:21:25.241768+03
6045cf07-0909-4c97-8728-af85a51039fa	5cee148d-439c-422b-b3ca-515a7c847d25	assignment_request	New Tour Assignment	You have been assigned to travel with telas starting Wed May 20 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "3792db4b-c57e-4bdd-8a90-75adf290be92", "tour_name": "travel with telas", "booking_id": "9fd51b0c-2d47-4ab9-8889-cb57163288cd", "staff_type": "driver", "start_date": "2026-05-19T21:00:00.000Z", "booking_code": "TEL-2605-000013", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/9fd51b0c-2d47-4ab9-8889-cb57163288cd	high	2026-05-21 14:21:25.251513+03	2026-05-21 13:21:25.251513+03
2cf58316-d69e-4904-a525-f5fd3030a6c8	85b671d7-a4e8-4192-b911-306ac6b46b2c	assignment_request	New Tour Assignment	You have been assigned to travel with telas starting Wed May 20 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "30640cb1-5427-4f84-9777-f76188dd6fba", "tour_name": "travel with telas", "booking_id": "9fd51b0c-2d47-4ab9-8889-cb57163288cd", "staff_type": "guide", "start_date": "2026-05-19T21:00:00.000Z", "booking_code": "TEL-2605-000013", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/9fd51b0c-2d47-4ab9-8889-cb57163288cd	high	2026-05-21 14:21:26.689949+03	2026-05-21 13:21:26.689949+03
ecc2476e-da81-46ac-83df-a80e98dfa871	5cee148d-439c-422b-b3ca-515a7c847d25	assignment_request	New Tour Assignment	You have been assigned to travel with telas starting Wed May 20 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "3792db4b-c57e-4bdd-8a90-75adf290be92", "tour_name": "travel with telas", "booking_id": "9fd51b0c-2d47-4ab9-8889-cb57163288cd", "staff_type": "driver", "start_date": "2026-05-19T21:00:00.000Z", "booking_code": "TEL-2605-000013", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/9fd51b0c-2d47-4ab9-8889-cb57163288cd	high	2026-05-21 14:21:26.698073+03	2026-05-21 13:21:26.698073+03
b361ce40-61eb-429d-813c-f1b371fe1508	85b671d7-a4e8-4192-b911-306ac6b46b2c	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Tue May 19 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "30640cb1-5427-4f84-9777-f76188dd6fba", "tour_name": "discover Ethiopia ", "booking_id": "45882f66-ab79-4559-9cd3-783814d48ebf", "staff_type": "guide", "start_date": "2026-05-18T21:00:00.000Z", "booking_code": "TEL-2605-000012", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/45882f66-ab79-4559-9cd3-783814d48ebf	high	2026-05-21 14:21:32.391013+03	2026-05-21 13:21:32.391013+03
152e7d03-0b1d-489c-9cce-489a1d18eb11	5cee148d-439c-422b-b3ca-515a7c847d25	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Tue May 19 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "3792db4b-c57e-4bdd-8a90-75adf290be92", "tour_name": "discover Ethiopia ", "booking_id": "45882f66-ab79-4559-9cd3-783814d48ebf", "staff_type": "driver", "start_date": "2026-05-18T21:00:00.000Z", "booking_code": "TEL-2605-000012", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/45882f66-ab79-4559-9cd3-783814d48ebf	high	2026-05-21 14:21:32.430623+03	2026-05-21 13:21:32.430623+03
f3040fa9-6a2b-4634-833c-2d4099d1218f	85b671d7-a4e8-4192-b911-306ac6b46b2c	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Tue May 19 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "30640cb1-5427-4f84-9777-f76188dd6fba", "tour_name": "discover Ethiopia ", "booking_id": "45882f66-ab79-4559-9cd3-783814d48ebf", "staff_type": "guide", "start_date": "2026-05-18T21:00:00.000Z", "booking_code": "TEL-2605-000012", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/45882f66-ab79-4559-9cd3-783814d48ebf	high	2026-05-21 14:21:32.492364+03	2026-05-21 13:21:32.492364+03
518dd128-8f93-4c5e-8c3f-09d0cd4a04c3	5cee148d-439c-422b-b3ca-515a7c847d25	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Tue May 19 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "3792db4b-c57e-4bdd-8a90-75adf290be92", "tour_name": "discover Ethiopia ", "booking_id": "45882f66-ab79-4559-9cd3-783814d48ebf", "staff_type": "driver", "start_date": "2026-05-18T21:00:00.000Z", "booking_code": "TEL-2605-000012", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/45882f66-ab79-4559-9cd3-783814d48ebf	high	2026-05-21 14:21:32.507923+03	2026-05-21 13:21:32.507923+03
dfed637b-2f44-4f42-bde7-8049a71593f1	85b671d7-a4e8-4192-b911-306ac6b46b2c	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Tue May 19 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "30640cb1-5427-4f84-9777-f76188dd6fba", "tour_name": "discover Ethiopia ", "booking_id": "45882f66-ab79-4559-9cd3-783814d48ebf", "staff_type": "guide", "start_date": "2026-05-18T21:00:00.000Z", "booking_code": "TEL-2605-000012", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/45882f66-ab79-4559-9cd3-783814d48ebf	high	2026-05-21 14:21:34.361087+03	2026-05-21 13:21:34.361087+03
2bf8d4a1-8eba-4e49-b7b3-4847f4987328	5cee148d-439c-422b-b3ca-515a7c847d25	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Tue May 19 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "3792db4b-c57e-4bdd-8a90-75adf290be92", "tour_name": "discover Ethiopia ", "booking_id": "45882f66-ab79-4559-9cd3-783814d48ebf", "staff_type": "driver", "start_date": "2026-05-18T21:00:00.000Z", "booking_code": "TEL-2605-000012", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/45882f66-ab79-4559-9cd3-783814d48ebf	high	2026-05-21 14:21:34.374562+03	2026-05-21 13:21:34.374562+03
5bfa10d8-bfc9-41a1-beef-13eb2bc056b7	85b671d7-a4e8-4192-b911-306ac6b46b2c	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Tue May 19 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "30640cb1-5427-4f84-9777-f76188dd6fba", "tour_name": "discover Ethiopia ", "booking_id": "a020bfc1-8d90-47cf-b44d-069040b63a90", "staff_type": "guide", "start_date": "2026-05-18T21:00:00.000Z", "booking_code": "TEL-2605-000009", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/a020bfc1-8d90-47cf-b44d-069040b63a90	high	2026-05-21 14:22:11.501129+03	2026-05-21 13:22:11.501129+03
00037e52-99ec-435a-b514-42b6793313f0	5cee148d-439c-422b-b3ca-515a7c847d25	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Tue May 19 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "3792db4b-c57e-4bdd-8a90-75adf290be92", "tour_name": "discover Ethiopia ", "booking_id": "a020bfc1-8d90-47cf-b44d-069040b63a90", "staff_type": "driver", "start_date": "2026-05-18T21:00:00.000Z", "booking_code": "TEL-2605-000009", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/a020bfc1-8d90-47cf-b44d-069040b63a90	high	2026-05-21 14:22:11.619343+03	2026-05-21 13:22:11.619343+03
68d2fd0e-f060-4934-b6fb-becb08ee6da6	85b671d7-a4e8-4192-b911-306ac6b46b2c	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Tue May 19 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "30640cb1-5427-4f84-9777-f76188dd6fba", "tour_name": "discover Ethiopia ", "booking_id": "a020bfc1-8d90-47cf-b44d-069040b63a90", "staff_type": "guide", "start_date": "2026-05-18T21:00:00.000Z", "booking_code": "TEL-2605-000009", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/a020bfc1-8d90-47cf-b44d-069040b63a90	high	2026-05-21 14:22:11.750071+03	2026-05-21 13:22:11.750071+03
c2cf92e2-bf19-4a75-b06d-7127898f0aa5	5cee148d-439c-422b-b3ca-515a7c847d25	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Tue May 19 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "3792db4b-c57e-4bdd-8a90-75adf290be92", "tour_name": "discover Ethiopia ", "booking_id": "a020bfc1-8d90-47cf-b44d-069040b63a90", "staff_type": "driver", "start_date": "2026-05-18T21:00:00.000Z", "booking_code": "TEL-2605-000009", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/a020bfc1-8d90-47cf-b44d-069040b63a90	high	2026-05-21 14:22:11.765366+03	2026-05-21 13:22:11.765366+03
4c63d0c2-d428-4643-9791-a41349ffba2b	85b671d7-a4e8-4192-b911-306ac6b46b2c	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Tue May 19 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "30640cb1-5427-4f84-9777-f76188dd6fba", "tour_name": "discover Ethiopia ", "booking_id": "a020bfc1-8d90-47cf-b44d-069040b63a90", "staff_type": "guide", "start_date": "2026-05-18T21:00:00.000Z", "booking_code": "TEL-2605-000009", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/a020bfc1-8d90-47cf-b44d-069040b63a90	high	2026-05-21 14:22:13.508183+03	2026-05-21 13:22:13.508183+03
9a462ce7-fcc9-4567-b95d-7abc540ba66d	5cee148d-439c-422b-b3ca-515a7c847d25	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Tue May 19 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "3792db4b-c57e-4bdd-8a90-75adf290be92", "tour_name": "discover Ethiopia ", "booking_id": "a020bfc1-8d90-47cf-b44d-069040b63a90", "staff_type": "driver", "start_date": "2026-05-18T21:00:00.000Z", "booking_code": "TEL-2605-000009", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/a020bfc1-8d90-47cf-b44d-069040b63a90	high	2026-05-21 14:22:13.517018+03	2026-05-21 13:22:13.517018+03
f3cea321-57be-4adb-9ceb-1c5292b2b778	85b671d7-a4e8-4192-b911-306ac6b46b2c	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Tue May 19 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "30640cb1-5427-4f84-9777-f76188dd6fba", "tour_name": "discover Ethiopia ", "booking_id": "10d025be-dd4d-4d34-882f-27f70cd4af76", "staff_type": "guide", "start_date": "2026-05-18T21:00:00.000Z", "booking_code": "TEL-2605-000010", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/10d025be-dd4d-4d34-882f-27f70cd4af76	high	2026-05-21 14:22:25.587609+03	2026-05-21 13:22:25.587609+03
b8bd6107-38a9-49e2-8fab-9443f15f76f7	5cee148d-439c-422b-b3ca-515a7c847d25	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Tue May 19 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "3792db4b-c57e-4bdd-8a90-75adf290be92", "tour_name": "discover Ethiopia ", "booking_id": "10d025be-dd4d-4d34-882f-27f70cd4af76", "staff_type": "driver", "start_date": "2026-05-18T21:00:00.000Z", "booking_code": "TEL-2605-000010", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/10d025be-dd4d-4d34-882f-27f70cd4af76	high	2026-05-21 14:22:25.625826+03	2026-05-21 13:22:25.625826+03
64920fa7-e182-4a42-af8d-0c5c43d9a724	85b671d7-a4e8-4192-b911-306ac6b46b2c	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Tue May 19 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "30640cb1-5427-4f84-9777-f76188dd6fba", "tour_name": "discover Ethiopia ", "booking_id": "10d025be-dd4d-4d34-882f-27f70cd4af76", "staff_type": "guide", "start_date": "2026-05-18T21:00:00.000Z", "booking_code": "TEL-2605-000010", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/10d025be-dd4d-4d34-882f-27f70cd4af76	high	2026-05-21 14:22:25.676326+03	2026-05-21 13:22:25.676326+03
3d0a5cb3-36b7-4264-a34b-7efc78650006	5cee148d-439c-422b-b3ca-515a7c847d25	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Tue May 19 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "3792db4b-c57e-4bdd-8a90-75adf290be92", "tour_name": "discover Ethiopia ", "booking_id": "10d025be-dd4d-4d34-882f-27f70cd4af76", "staff_type": "driver", "start_date": "2026-05-18T21:00:00.000Z", "booking_code": "TEL-2605-000010", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/10d025be-dd4d-4d34-882f-27f70cd4af76	high	2026-05-21 14:22:25.690464+03	2026-05-21 13:22:25.690464+03
6be32356-2aef-4a70-b9d3-5187dcabe6a6	85b671d7-a4e8-4192-b911-306ac6b46b2c	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Tue May 19 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "30640cb1-5427-4f84-9777-f76188dd6fba", "tour_name": "discover Ethiopia ", "booking_id": "10d025be-dd4d-4d34-882f-27f70cd4af76", "staff_type": "guide", "start_date": "2026-05-18T21:00:00.000Z", "booking_code": "TEL-2605-000010", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/10d025be-dd4d-4d34-882f-27f70cd4af76	high	2026-05-21 14:22:27.747775+03	2026-05-21 13:22:27.747775+03
586a3d51-a5ee-4193-8088-dca82190a0dc	5cee148d-439c-422b-b3ca-515a7c847d25	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Tue May 19 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "3792db4b-c57e-4bdd-8a90-75adf290be92", "tour_name": "discover Ethiopia ", "booking_id": "10d025be-dd4d-4d34-882f-27f70cd4af76", "staff_type": "driver", "start_date": "2026-05-18T21:00:00.000Z", "booking_code": "TEL-2605-000010", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/10d025be-dd4d-4d34-882f-27f70cd4af76	high	2026-05-21 14:22:27.757472+03	2026-05-21 13:22:27.757472+03
43e449ca-78e6-4f70-9adc-a0efa7977984	5cee148d-439c-422b-b3ca-515a7c847d25	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Mon May 18 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "3792db4b-c57e-4bdd-8a90-75adf290be92", "tour_name": "discover Ethiopia ", "booking_id": "447de65c-3790-4f7d-a003-a5a5a20887be", "staff_type": "driver", "start_date": "2026-05-17T21:00:00.000Z", "booking_code": "TEL-2605-000001", "tourist_name": "hyme21@gmail.com"}	f	\N	/booking/upcoming/447de65c-3790-4f7d-a003-a5a5a20887be	high	2026-05-23 14:37:13.658124+03	2026-05-23 13:37:13.658124+03
875b541f-21f4-4032-9649-39386156d304	351b31d4-40b1-4f69-85dd-f5f25031a184	test	Test Notification	This is a test notification from the system	{"test": true}	f	\N	/test	normal	\N	2026-05-23 14:28:45.580351+03
a11edd86-d7ec-464c-8bd3-fce9748f5868	85b671d7-a4e8-4192-b911-306ac6b46b2c	assignment_request	New Tour Assignment	You have been assigned to travel with telas starting Sat May 23 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "30640cb1-5427-4f84-9777-f76188dd6fba", "tour_name": "travel with telas", "booking_id": "28094257-2c0b-4b80-a6ac-9219eb4494f1", "staff_type": "guide", "start_date": "2026-05-22T21:00:00.000Z", "booking_code": "TEL-2605-000016", "tourist_name": "tesfahundenekew1@gmail.com"}	f	\N	/chat/booking/28094257-2c0b-4b80-a6ac-9219eb4494f1	high	2026-05-23 17:11:15.06119+03	2026-05-23 16:11:15.06119+03
376db978-6c77-44c8-8ea3-569d40b4e576	02667157-3f8d-4370-a4cf-9551d7f5c025	assignment_made	Staff Assignment Made	null assigned as guide for booking TEL-2605-000016	{"booking_id": "28094257-2c0b-4b80-a6ac-9219eb4494f1", "staff_name": null, "staff_type": "guide", "booking_code": "TEL-2605-000016"}	f	\N	/chat/booking/28094257-2c0b-4b80-a6ac-9219eb4494f1	low	\N	2026-05-23 16:11:15.317306+03
49b3bb26-15a4-4019-af7e-913f2eaf3e3d	5cee148d-439c-422b-b3ca-515a7c847d25	assignment_request	New Tour Assignment	You have been assigned to travel with telas starting Sat May 23 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "3792db4b-c57e-4bdd-8a90-75adf290be92", "tour_name": "travel with telas", "booking_id": "28094257-2c0b-4b80-a6ac-9219eb4494f1", "staff_type": "driver", "start_date": "2026-05-22T21:00:00.000Z", "booking_code": "TEL-2605-000016", "tourist_name": "tesfahundenekew1@gmail.com"}	f	\N	/chat/booking/28094257-2c0b-4b80-a6ac-9219eb4494f1	high	2026-05-23 17:11:15.474575+03	2026-05-23 16:11:15.474575+03
71234dbb-e71e-46d5-9819-46505e9bd44a	02667157-3f8d-4370-a4cf-9551d7f5c025	assignment_made	Staff Assignment Made	null assigned as driver for booking TEL-2605-000016	{"booking_id": "28094257-2c0b-4b80-a6ac-9219eb4494f1", "staff_name": null, "staff_type": "driver", "booking_code": "TEL-2605-000016"}	f	\N	/chat/booking/28094257-2c0b-4b80-a6ac-9219eb4494f1	low	\N	2026-05-23 16:11:15.528163+03
cfb418a3-eec9-4a31-a4bd-8695d95e5500	85b671d7-a4e8-4192-b911-306ac6b46b2c	assignment_request	New Tour Assignment	You have been assigned to travel with telas starting Sat May 23 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "30640cb1-5427-4f84-9777-f76188dd6fba", "tour_name": "travel with telas", "booking_id": "28094257-2c0b-4b80-a6ac-9219eb4494f1", "staff_type": "guide", "start_date": "2026-05-22T21:00:00.000Z", "booking_code": "TEL-2605-000016", "tourist_name": "tesfahundenekew1@gmail.com"}	f	\N	/chat/booking/28094257-2c0b-4b80-a6ac-9219eb4494f1	high	2026-05-23 17:11:15.622301+03	2026-05-23 16:11:15.622301+03
3e9c9cf2-475c-48af-9718-39c735b4bd6b	02667157-3f8d-4370-a4cf-9551d7f5c025	assignment_made	Staff Assignment Made	null assigned as guide for booking TEL-2605-000016	{"booking_id": "28094257-2c0b-4b80-a6ac-9219eb4494f1", "staff_name": null, "staff_type": "guide", "booking_code": "TEL-2605-000016"}	f	\N	/chat/booking/28094257-2c0b-4b80-a6ac-9219eb4494f1	low	\N	2026-05-23 16:11:15.631293+03
a8a29fcb-75b8-4f97-afdd-68ef2104a784	5cee148d-439c-422b-b3ca-515a7c847d25	assignment_request	New Tour Assignment	You have been assigned to travel with telas starting Sat May 23 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "3792db4b-c57e-4bdd-8a90-75adf290be92", "tour_name": "travel with telas", "booking_id": "28094257-2c0b-4b80-a6ac-9219eb4494f1", "staff_type": "driver", "start_date": "2026-05-22T21:00:00.000Z", "booking_code": "TEL-2605-000016", "tourist_name": "tesfahundenekew1@gmail.com"}	f	\N	/chat/booking/28094257-2c0b-4b80-a6ac-9219eb4494f1	high	2026-05-23 17:11:15.64436+03	2026-05-23 16:11:15.64436+03
83d4a8d6-5495-40e3-83d8-4a9e5aed674f	02667157-3f8d-4370-a4cf-9551d7f5c025	assignment_made	Staff Assignment Made	null assigned as driver for booking TEL-2605-000016	{"booking_id": "28094257-2c0b-4b80-a6ac-9219eb4494f1", "staff_name": null, "staff_type": "driver", "booking_code": "TEL-2605-000016"}	f	\N	/chat/booking/28094257-2c0b-4b80-a6ac-9219eb4494f1	low	\N	2026-05-23 16:11:15.654475+03
2b6acd54-7e60-4426-8343-897ce88d716a	85b671d7-a4e8-4192-b911-306ac6b46b2c	assignment_request	New Tour Assignment	You have been assigned to travel with telas starting Sat May 23 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "30640cb1-5427-4f84-9777-f76188dd6fba", "tour_name": "travel with telas", "booking_id": "28094257-2c0b-4b80-a6ac-9219eb4494f1", "staff_type": "guide", "start_date": "2026-05-22T21:00:00.000Z", "booking_code": "TEL-2605-000016", "tourist_name": "tesfahundenekew1@gmail.com"}	f	\N	/chat/booking/28094257-2c0b-4b80-a6ac-9219eb4494f1	high	2026-05-23 17:11:17.391346+03	2026-05-23 16:11:17.391346+03
5cb5e632-72f6-4b17-be11-bd12e4b11265	02667157-3f8d-4370-a4cf-9551d7f5c025	assignment_made	Staff Assignment Made	Amanuel Azanaw assigned as guide for booking TEL-2605-000016	{"booking_id": "28094257-2c0b-4b80-a6ac-9219eb4494f1", "staff_name": "Amanuel Azanaw", "staff_type": "guide", "booking_code": "TEL-2605-000016"}	f	\N	/chat/booking/28094257-2c0b-4b80-a6ac-9219eb4494f1	low	\N	2026-05-23 16:11:17.535672+03
e7905752-d503-49e7-b3ad-7c12d05005d1	5cee148d-439c-422b-b3ca-515a7c847d25	assignment_request	New Tour Assignment	You have been assigned to travel with telas starting Sat May 23 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour.	{"staff_id": "3792db4b-c57e-4bdd-8a90-75adf290be92", "tour_name": "travel with telas", "booking_id": "28094257-2c0b-4b80-a6ac-9219eb4494f1", "staff_type": "driver", "start_date": "2026-05-22T21:00:00.000Z", "booking_code": "TEL-2605-000016", "tourist_name": "tesfahundenekew1@gmail.com"}	f	\N	/chat/booking/28094257-2c0b-4b80-a6ac-9219eb4494f1	high	2026-05-23 17:11:17.601695+03	2026-05-23 16:11:17.601695+03
2e5c6456-2c5a-45e0-bf95-14782fda6f15	02667157-3f8d-4370-a4cf-9551d7f5c025	assignment_made	Staff Assignment Made	Teklu  Kidanemariyam assigned as driver for booking TEL-2605-000016	{"booking_id": "28094257-2c0b-4b80-a6ac-9219eb4494f1", "staff_name": "Teklu  Kidanemariyam", "staff_type": "driver", "booking_code": "TEL-2605-000016"}	f	\N	/chat/booking/28094257-2c0b-4b80-a6ac-9219eb4494f1	low	\N	2026-05-23 16:11:17.755293+03
e093543b-dd24-4135-a8f8-f9bd2c76f509	351b31d4-40b1-4f69-85dd-f5f25031a184	test	Test Notification	This is a test notification from the system	{"test": true}	f	\N	/test	normal	\N	2026-05-24 04:43:29.338278+03
e8cb4671-e005-4c6e-83af-70c2e5b5f40c	02667157-3f8d-4370-a4cf-9551d7f5c025	assignment_made	Staff Assignment Made	null assigned as guide for booking TEL-2605-000002	{"booking_id": "b86582fa-0a79-4999-bd11-157fd8d97fd2", "staff_name": null, "staff_type": "guide", "booking_code": "TEL-2605-000002"}	f	\N	/chat/booking/b86582fa-0a79-4999-bd11-157fd8d97fd2	low	\N	2026-05-24 04:59:10.470402+03
5f225ba9-5021-4e53-bda3-3b23a5338baa	02667157-3f8d-4370-a4cf-9551d7f5c025	assignment_made	Staff Assignment Made	null assigned as driver for booking TEL-2605-000002	{"booking_id": "b86582fa-0a79-4999-bd11-157fd8d97fd2", "staff_name": null, "staff_type": "driver", "booking_code": "TEL-2605-000002"}	f	\N	/chat/booking/b86582fa-0a79-4999-bd11-157fd8d97fd2	low	\N	2026-05-24 04:59:10.56012+03
9fff1825-e0df-4ead-a761-f98bea3b22be	02667157-3f8d-4370-a4cf-9551d7f5c025	assignment_made	Staff Assignment Made	null assigned as guide for booking TEL-2605-000002	{"booking_id": "b86582fa-0a79-4999-bd11-157fd8d97fd2", "staff_name": null, "staff_type": "guide", "booking_code": "TEL-2605-000002"}	f	\N	/chat/booking/b86582fa-0a79-4999-bd11-157fd8d97fd2	low	\N	2026-05-24 04:59:10.687341+03
97e5055b-d8cf-4890-b25f-1ec7f417d6c8	8b228fea-ed40-4ee1-b7f9-c17585adc595	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Mon May 18 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour. (EXPIRED - No response) (EXPIRED - No response) (EXPIRED - No response)	{"staff_id": "2a16833f-49ee-47ec-9c2b-9ec27ab14c49", "tour_name": "discover Ethiopia ", "booking_id": "b86582fa-0a79-4999-bd11-157fd8d97fd2", "staff_type": "driver", "start_date": "2026-05-17T21:00:00.000Z", "booking_code": "TEL-2605-000002", "tourist_name": "hyme21@gmail.com"}	f	\N	/chat/booking/b86582fa-0a79-4999-bd11-157fd8d97fd2	low	2026-05-24 05:59:10.54695+03	2026-05-24 04:59:10.54695+03
32f4f1ca-6296-455a-9740-a95aca936b15	02667157-3f8d-4370-a4cf-9551d7f5c025	assignment_made	Staff Assignment Made	null assigned as driver for booking TEL-2605-000002	{"booking_id": "b86582fa-0a79-4999-bd11-157fd8d97fd2", "staff_name": null, "staff_type": "driver", "booking_code": "TEL-2605-000002"}	f	\N	/chat/booking/b86582fa-0a79-4999-bd11-157fd8d97fd2	low	\N	2026-05-24 04:59:10.746035+03
d0796c37-6677-459d-a5d5-6b8574902656	02667157-3f8d-4370-a4cf-9551d7f5c025	assignment_made	Staff Assignment Made	Natnael Getnet assigned as guide for booking TEL-2605-000002	{"booking_id": "b86582fa-0a79-4999-bd11-157fd8d97fd2", "staff_name": "Natnael Getnet", "staff_type": "guide", "booking_code": "TEL-2605-000002"}	f	\N	/chat/booking/b86582fa-0a79-4999-bd11-157fd8d97fd2	low	\N	2026-05-24 04:59:14.160554+03
3ce81a9b-98cb-4654-ab1b-1cc9788296fc	02667157-3f8d-4370-a4cf-9551d7f5c025	assignment_made	Staff Assignment Made	Natnael Getnet assigned as driver for booking TEL-2605-000002	{"booking_id": "b86582fa-0a79-4999-bd11-157fd8d97fd2", "staff_name": "Natnael Getnet", "staff_type": "driver", "booking_code": "TEL-2605-000002"}	f	\N	/chat/booking/b86582fa-0a79-4999-bd11-157fd8d97fd2	low	\N	2026-05-24 04:59:14.185299+03
de8406a4-2261-4da0-a5c9-57dccfbcdd2d	fcabec9c-3367-45f0-b462-271ee937b40c	new_message	New Message	tnigussie96@gmail.com: 🔔 System: Auto-assignment Confirmed! Guide (Natna...	{"message_id": "b044f39f-82a3-4c8f-85b8-a0b9a0761650", "conversation_id": "6d10d22d-3032-490a-b38d-c39ba3d1072e"}	f	\N	/chat/6d10d22d-3032-490a-b38d-c39ba3d1072e	normal	\N	2026-05-24 04:59:14.273682+03
d342f9fc-f163-4882-bdca-73ee8887aeec	37d4e940-020a-41ae-8203-d694a4dd7bdd	new_message	New Message	teklukide27@gmail.com: Hey Guy's my name is teklu kidanemariyam and i am ...	{"message_id": "aa1576d5-3649-483d-9ebe-efe818932134", "conversation_id": "80e4fd49-a50e-4db0-9a0a-b06d1288d087"}	f	\N	/chat/80e4fd49-a50e-4db0-9a0a-b06d1288d087	normal	\N	2026-05-24 05:14:05.704401+03
4ebb786f-3cd3-4ab4-8a5e-942dfae1984a	85b671d7-a4e8-4192-b911-306ac6b46b2c	new_message	New Message	teklukide27@gmail.com: Hey Guy's my name is teklu kidanemariyam and i am ...	{"message_id": "aa1576d5-3649-483d-9ebe-efe818932134", "conversation_id": "80e4fd49-a50e-4db0-9a0a-b06d1288d087"}	f	\N	/chat/80e4fd49-a50e-4db0-9a0a-b06d1288d087	normal	\N	2026-05-24 05:14:05.755785+03
3431eff1-952e-44f7-aa28-534e1581c513	02667157-3f8d-4370-a4cf-9551d7f5c025	new_message	New Message	teklukide27@gmail.com: Hey Guy's my name is teklu kidanemariyam and i am ...	{"message_id": "aa1576d5-3649-483d-9ebe-efe818932134", "conversation_id": "80e4fd49-a50e-4db0-9a0a-b06d1288d087"}	f	\N	/chat/80e4fd49-a50e-4db0-9a0a-b06d1288d087	normal	\N	2026-05-24 05:14:05.766508+03
afc7c33a-b2dd-4dab-a10b-b990c65e0e4c	fcabec9c-3367-45f0-b462-271ee937b40c	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:18:48.303097+03
8fb1031d-dc03-4ff2-92dd-9b6f0cd6119b	8b228fea-ed40-4ee1-b7f9-c17585adc595	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Mon May 18 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour. (EXPIRED - No response) (EXPIRED - No response) (EXPIRED - No response)	{"staff_id": "2a16833f-49ee-47ec-9c2b-9ec27ab14c49", "tour_name": "discover Ethiopia ", "booking_id": "b86582fa-0a79-4999-bd11-157fd8d97fd2", "staff_type": "driver", "start_date": "2026-05-17T21:00:00.000Z", "booking_code": "TEL-2605-000002", "tourist_name": "hyme21@gmail.com"}	f	\N	/chat/booking/b86582fa-0a79-4999-bd11-157fd8d97fd2	low	2026-05-24 05:59:14.174797+03	2026-05-24 04:59:14.174797+03
e321a645-e755-4200-b911-82d5ce285922	7661899a-97cc-493a-a37d-b783e6335c7f	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:14:14.655755+03
bc765de7-e98b-428c-bd88-9d3c8ce83d27	85b671d7-a4e8-4192-b911-306ac6b46b2c	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:14:14.662464+03
6f690e43-a516-47bf-8f3a-35dffc149db2	351b31d4-40b1-4f69-85dd-f5f25031a184	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Mon May 18 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour. (EXPIRED - No response) (EXPIRED - No response) (EXPIRED - No response)	{"staff_id": "5151f20e-a4a7-464d-8104-921de0ace90b", "tour_name": "discover Ethiopia ", "booking_id": "b86582fa-0a79-4999-bd11-157fd8d97fd2", "staff_type": "guide", "start_date": "2026-05-17T21:00:00.000Z", "booking_code": "TEL-2605-000002", "tourist_name": "hyme21@gmail.com"}	f	\N	/chat/booking/b86582fa-0a79-4999-bd11-157fd8d97fd2	low	2026-05-24 05:59:14.148455+03	2026-05-24 04:59:14.148455+03
f4a77f9d-0852-4f06-a56c-3ec516e0c3d1	351b31d4-40b1-4f69-85dd-f5f25031a184	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Mon May 18 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour. (EXPIRED - No response) (EXPIRED - No response) (EXPIRED - No response)	{"staff_id": "5151f20e-a4a7-464d-8104-921de0ace90b", "tour_name": "discover Ethiopia ", "booking_id": "b86582fa-0a79-4999-bd11-157fd8d97fd2", "staff_type": "guide", "start_date": "2026-05-17T21:00:00.000Z", "booking_code": "TEL-2605-000002", "tourist_name": "hyme21@gmail.com"}	f	\N	/chat/booking/b86582fa-0a79-4999-bd11-157fd8d97fd2	low	2026-05-24 05:59:10.413798+03	2026-05-24 04:59:10.413798+03
0e4c1d16-b08b-42be-a89d-9303bbe5fb5a	351b31d4-40b1-4f69-85dd-f5f25031a184	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:14:14.668511+03
056a7d50-6932-44db-b26e-dc1c4f3f9371	8b228fea-ed40-4ee1-b7f9-c17585adc595	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:14:14.674358+03
036ae12a-1b18-4c96-a0f6-152bdfa6ed16	37d4e940-020a-41ae-8203-d694a4dd7bdd	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:14:14.679524+03
ef5989e0-a0a5-4e34-979c-3065b3a6ca98	7661899a-97cc-493a-a37d-b783e6335c7f	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:18:48.306232+03
1e26ae0b-6e36-4ba9-a53f-70a074377f31	85b671d7-a4e8-4192-b911-306ac6b46b2c	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:18:48.308833+03
bcfd2617-6c96-4c6b-ad93-bfc2dffb76d9	351b31d4-40b1-4f69-85dd-f5f25031a184	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:18:48.312086+03
835ed65d-6d49-497a-b16b-59abc787f3f0	8b228fea-ed40-4ee1-b7f9-c17585adc595	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:18:48.314746+03
30893142-a09a-460b-bcca-f8c8eca9a6eb	37d4e940-020a-41ae-8203-d694a4dd7bdd	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:18:48.317224+03
7273f096-f1da-4f21-89f6-d779d3067796	5cee148d-439c-422b-b3ca-515a7c847d25	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:21:12.127151+03
6d932bf0-a75d-46ba-89ae-a37cb34c367d	02667157-3f8d-4370-a4cf-9551d7f5c025	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:21:12.139004+03
25269bfe-b9f8-494f-96c4-adb3a072b49b	fcabec9c-3367-45f0-b462-271ee937b40c	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:21:12.145294+03
77390610-b9ba-4df4-a957-d8077bb6b210	02667157-3f8d-4370-a4cf-9551d7f5c025	assignment_escalation	Urgent: Manual Assignment Required	No available guide found for booking TEL-2605-000002. Manual assignment required.	{"booking_id": "b86582fa-0a79-4999-bd11-157fd8d97fd2", "staff_type": "guide", "booking_code": "TEL-2605-000002", "escalation_reason": "no_available_staff"}	f	\N	/booking/upcoming/b86582fa-0a79-4999-bd11-157fd8d97fd2	urgent	\N	2026-05-24 05:59:11.10103+03
764b5d5a-6e25-43ff-a752-93c6717ebb73	02667157-3f8d-4370-a4cf-9551d7f5c025	assignment_escalation	Urgent: Manual Assignment Required	No available guide found for booking TEL-2605-000002. Manual assignment required.	{"booking_id": "b86582fa-0a79-4999-bd11-157fd8d97fd2", "staff_type": "guide", "booking_code": "TEL-2605-000002", "escalation_reason": "no_available_staff"}	f	\N	/booking/upcoming/b86582fa-0a79-4999-bd11-157fd8d97fd2	urgent	\N	2026-05-24 05:59:11.108818+03
4a741e55-f413-412b-9878-5349e168af92	02667157-3f8d-4370-a4cf-9551d7f5c025	assignment_escalation	Urgent: Manual Assignment Required	No available driver found for booking TEL-2605-000002. Manual assignment required.	{"booking_id": "b86582fa-0a79-4999-bd11-157fd8d97fd2", "staff_type": "driver", "booking_code": "TEL-2605-000002", "escalation_reason": "no_available_staff"}	f	\N	/booking/upcoming/b86582fa-0a79-4999-bd11-157fd8d97fd2	urgent	\N	2026-05-24 05:59:11.105909+03
4e47a9bf-4bb9-4e3a-9338-f25c088540e8	02667157-3f8d-4370-a4cf-9551d7f5c025	assignment_escalation	Urgent: Manual Assignment Required	No available driver found for booking TEL-2605-000002. Manual assignment required.	{"booking_id": "b86582fa-0a79-4999-bd11-157fd8d97fd2", "staff_type": "driver", "booking_code": "TEL-2605-000002", "escalation_reason": "no_available_staff"}	f	\N	/booking/upcoming/b86582fa-0a79-4999-bd11-157fd8d97fd2	urgent	\N	2026-05-24 05:59:11.158512+03
0bfba0d5-190e-48ff-84a9-a0d883ac4cd0	351b31d4-40b1-4f69-85dd-f5f25031a184	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Mon May 18 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour. (EXPIRED - No response) (EXPIRED - No response) (EXPIRED - No response)	{"staff_id": "5151f20e-a4a7-464d-8104-921de0ace90b", "tour_name": "discover Ethiopia ", "booking_id": "b86582fa-0a79-4999-bd11-157fd8d97fd2", "staff_type": "guide", "start_date": "2026-05-17T21:00:00.000Z", "booking_code": "TEL-2605-000002", "tourist_name": "hyme21@gmail.com"}	f	\N	/chat/booking/b86582fa-0a79-4999-bd11-157fd8d97fd2	low	2026-05-24 05:59:10.677039+03	2026-05-24 04:59:10.677039+03
686ae69f-4023-4796-889a-6d265c760980	8b228fea-ed40-4ee1-b7f9-c17585adc595	assignment_request	New Tour Assignment	You have been assigned to discover Ethiopia  starting Mon May 18 2026 00:00:00 GMT+0300 (East Africa Time). Please confirm within 1 hour. (EXPIRED - No response) (EXPIRED - No response) (EXPIRED - No response)	{"staff_id": "2a16833f-49ee-47ec-9c2b-9ec27ab14c49", "tour_name": "discover Ethiopia ", "booking_id": "b86582fa-0a79-4999-bd11-157fd8d97fd2", "staff_type": "driver", "start_date": "2026-05-17T21:00:00.000Z", "booking_code": "TEL-2605-000002", "tourist_name": "hyme21@gmail.com"}	f	\N	/chat/booking/b86582fa-0a79-4999-bd11-157fd8d97fd2	low	2026-05-24 05:59:10.737308+03	2026-05-24 04:59:10.737308+03
6948694b-6053-4286-a564-97c2bca33989	02667157-3f8d-4370-a4cf-9551d7f5c025	assignment_escalation	Urgent: Manual Assignment Required	No available guide found for booking TEL-2605-000002. Manual assignment required.	{"booking_id": "b86582fa-0a79-4999-bd11-157fd8d97fd2", "staff_type": "guide", "booking_code": "TEL-2605-000002", "escalation_reason": "no_available_staff"}	f	\N	/booking/upcoming/b86582fa-0a79-4999-bd11-157fd8d97fd2	urgent	\N	2026-05-24 05:59:14.238637+03
c46bab1d-4557-457d-a4d4-589b1405a552	02667157-3f8d-4370-a4cf-9551d7f5c025	assignment_escalation	Urgent: Manual Assignment Required	No available driver found for booking TEL-2605-000002. Manual assignment required.	{"booking_id": "b86582fa-0a79-4999-bd11-157fd8d97fd2", "staff_type": "driver", "booking_code": "TEL-2605-000002", "escalation_reason": "no_available_staff"}	f	\N	/booking/upcoming/b86582fa-0a79-4999-bd11-157fd8d97fd2	urgent	\N	2026-05-24 05:59:14.289675+03
1ad30662-be55-443b-9160-7992e97a5911	37d4e940-020a-41ae-8203-d694a4dd7bdd	new_message	New Message	tnigussie96@gmail.com: hey this is your tour operator how is going	{"message_id": "8b6023d4-d6d4-4017-a687-4407cf7a6727", "conversation_id": "80e4fd49-a50e-4db0-9a0a-b06d1288d087"}	f	\N	/chat/80e4fd49-a50e-4db0-9a0a-b06d1288d087	normal	\N	2026-05-25 09:19:45.831347+03
445d5944-cfe2-411e-80da-2c6bd24b0f24	85b671d7-a4e8-4192-b911-306ac6b46b2c	new_message	New Message	tnigussie96@gmail.com: hey this is your tour operator how is going	{"message_id": "8b6023d4-d6d4-4017-a687-4407cf7a6727", "conversation_id": "80e4fd49-a50e-4db0-9a0a-b06d1288d087"}	f	\N	/chat/80e4fd49-a50e-4db0-9a0a-b06d1288d087	normal	\N	2026-05-25 09:19:46.155491+03
901e067a-f5e3-4b5f-8386-923ba09edb8f	5cee148d-439c-422b-b3ca-515a7c847d25	new_message	New Message	tnigussie96@gmail.com: hey this is your tour operator how is going	{"message_id": "8b6023d4-d6d4-4017-a687-4407cf7a6727", "conversation_id": "80e4fd49-a50e-4db0-9a0a-b06d1288d087"}	f	\N	/chat/80e4fd49-a50e-4db0-9a0a-b06d1288d087	normal	\N	2026-05-25 09:19:46.158768+03
0ef3314b-d671-4162-a534-13fa7a8e3d9a	37d4e940-020a-41ae-8203-d694a4dd7bdd	new_message	New Message	teklukide27@gmail.com: Every thing good 👍	{"message_id": "bc33ad3c-7325-4573-8d2a-816456c5b016", "conversation_id": "80e4fd49-a50e-4db0-9a0a-b06d1288d087"}	f	\N	/chat/80e4fd49-a50e-4db0-9a0a-b06d1288d087	normal	\N	2026-05-25 09:20:27.00455+03
43c596c8-febd-487a-adad-577a3d619e45	85b671d7-a4e8-4192-b911-306ac6b46b2c	new_message	New Message	teklukide27@gmail.com: Every thing good 👍	{"message_id": "bc33ad3c-7325-4573-8d2a-816456c5b016", "conversation_id": "80e4fd49-a50e-4db0-9a0a-b06d1288d087"}	f	\N	/chat/80e4fd49-a50e-4db0-9a0a-b06d1288d087	normal	\N	2026-05-25 09:20:27.007708+03
c9b39b7d-4f50-42b0-a4b1-65ce96b4bf94	02667157-3f8d-4370-a4cf-9551d7f5c025	new_message	New Message	teklukide27@gmail.com: Every thing good 👍	{"message_id": "bc33ad3c-7325-4573-8d2a-816456c5b016", "conversation_id": "80e4fd49-a50e-4db0-9a0a-b06d1288d087"}	f	\N	/chat/80e4fd49-a50e-4db0-9a0a-b06d1288d087	normal	\N	2026-05-25 09:20:27.012881+03
963c42df-9608-4d46-a590-273f7e7c83af	37d4e940-020a-41ae-8203-d694a4dd7bdd	new_message	New Message	teklukide27@gmail.com: Ok happy anniversary	{"message_id": "13825f0d-4489-42e2-8e03-cc5ae8dc43f2", "conversation_id": "80e4fd49-a50e-4db0-9a0a-b06d1288d087"}	f	\N	/chat/80e4fd49-a50e-4db0-9a0a-b06d1288d087	normal	\N	2026-05-25 09:20:54.822358+03
b7ca5032-3d76-4521-879d-c9d226ebfab4	85b671d7-a4e8-4192-b911-306ac6b46b2c	new_message	New Message	teklukide27@gmail.com: Ok happy anniversary	{"message_id": "13825f0d-4489-42e2-8e03-cc5ae8dc43f2", "conversation_id": "80e4fd49-a50e-4db0-9a0a-b06d1288d087"}	f	\N	/chat/80e4fd49-a50e-4db0-9a0a-b06d1288d087	normal	\N	2026-05-25 09:20:54.825452+03
3c14e26b-6f52-4ab9-ae98-d55167959aab	02667157-3f8d-4370-a4cf-9551d7f5c025	new_message	New Message	teklukide27@gmail.com: Ok happy anniversary	{"message_id": "13825f0d-4489-42e2-8e03-cc5ae8dc43f2", "conversation_id": "80e4fd49-a50e-4db0-9a0a-b06d1288d087"}	f	\N	/chat/80e4fd49-a50e-4db0-9a0a-b06d1288d087	normal	\N	2026-05-25 09:20:54.830233+03
e657b7b5-0e39-40ae-b9ea-13c75d515947	37d4e940-020a-41ae-8203-d694a4dd7bdd	new_message	New Message	tnigussie96@gmail.com: good	{"message_id": "0ef6eba0-fff3-48dc-bddd-f6f9781b4077", "conversation_id": "80e4fd49-a50e-4db0-9a0a-b06d1288d087"}	f	\N	/chat/80e4fd49-a50e-4db0-9a0a-b06d1288d087	normal	\N	2026-05-25 09:21:18.888892+03
78014ec9-e8b2-4fea-8292-924db147fb8c	85b671d7-a4e8-4192-b911-306ac6b46b2c	new_message	New Message	tnigussie96@gmail.com: good	{"message_id": "0ef6eba0-fff3-48dc-bddd-f6f9781b4077", "conversation_id": "80e4fd49-a50e-4db0-9a0a-b06d1288d087"}	f	\N	/chat/80e4fd49-a50e-4db0-9a0a-b06d1288d087	normal	\N	2026-05-25 09:21:18.95162+03
b3299c6b-ce18-4ea2-a44c-c232795a4a9f	5cee148d-439c-422b-b3ca-515a7c847d25	new_message	New Message	tnigussie96@gmail.com: good	{"message_id": "0ef6eba0-fff3-48dc-bddd-f6f9781b4077", "conversation_id": "80e4fd49-a50e-4db0-9a0a-b06d1288d087"}	f	\N	/chat/80e4fd49-a50e-4db0-9a0a-b06d1288d087	normal	\N	2026-05-25 09:21:18.98439+03
c8940f5a-4f46-40e3-924a-2420378c3bce	02667157-3f8d-4370-a4cf-9551d7f5c025	new_message	New Message	hyme21@gmail.com: Helo	{"message_id": "77634652-3484-4122-9992-2003220dd76e", "conversation_id": "6d10d22d-3032-490a-b38d-c39ba3d1072e"}	f	\N	/chat/6d10d22d-3032-490a-b38d-c39ba3d1072e	normal	\N	2026-05-25 09:31:14.05289+03
2d785d24-427a-4893-bb73-60c30ab4ffc0	fcabec9c-3367-45f0-b462-271ee937b40c	new_message	New Message	tnigussie96@gmail.com: hey there	{"message_id": "2bc5e343-fe56-4193-93b9-6d385c091aff", "conversation_id": "6d10d22d-3032-490a-b38d-c39ba3d1072e"}	f	\N	/chat/6d10d22d-3032-490a-b38d-c39ba3d1072e	normal	\N	2026-05-25 09:32:08.426426+03
5dadc7a2-a3ce-481e-a05c-b7ffe9492cfb	7661899a-97cc-493a-a37d-b783e6335c7f	new_message	New Message	hyme21@gmail.com: Jejkfk	{"message_id": "bbd31863-db48-40a6-a103-174daf17e019", "conversation_id": "f47d9806-42b6-416a-8295-d41474cd0288"}	f	\N	/chat/f47d9806-42b6-416a-8295-d41474cd0288	normal	\N	2026-05-26 16:43:19.606541+03
2a772e8b-7c8a-4bfa-9d2a-f00c0560368d	8b228fea-ed40-4ee1-b7f9-c17585adc595	new_message	New Message	hyme21@gmail.com: Jejkfk	{"message_id": "bbd31863-db48-40a6-a103-174daf17e019", "conversation_id": "f47d9806-42b6-416a-8295-d41474cd0288"}	f	\N	/chat/f47d9806-42b6-416a-8295-d41474cd0288	normal	\N	2026-05-26 16:43:19.675103+03
872f9975-8b3b-4e5f-bbfd-bce95e15fbb2	02667157-3f8d-4370-a4cf-9551d7f5c025	new_message	New Message	hyme21@gmail.com: Jejkfk	{"message_id": "bbd31863-db48-40a6-a103-174daf17e019", "conversation_id": "f47d9806-42b6-416a-8295-d41474cd0288"}	f	\N	/chat/f47d9806-42b6-416a-8295-d41474cd0288	normal	\N	2026-05-26 16:43:19.682075+03
444e7268-9e8d-4cbe-9ab2-e81aa50fbc70	02667157-3f8d-4370-a4cf-9551d7f5c025	new_message	New Message	hyme21@gmail.com: Jehrkjr	{"message_id": "0f6b2bcd-017e-44e9-a875-03069243f226", "conversation_id": "9acdcb55-14fd-460c-870e-68df44de1cd3"}	f	\N	/chat/9acdcb55-14fd-460c-870e-68df44de1cd3	normal	\N	2026-05-26 16:43:29.653943+03
4f5cc5ad-acc1-4195-8b9f-482bbe6b6d0f	5cee148d-439c-422b-b3ca-515a7c847d25	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:14:14.502726+03
6687d91f-fdc0-4e55-a9eb-670506923c36	02667157-3f8d-4370-a4cf-9551d7f5c025	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:14:14.64381+03
8662d1c9-7d48-4045-bee7-94acdfdfa6cc	fcabec9c-3367-45f0-b462-271ee937b40c	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:14:14.649766+03
7ed9c384-85fe-4771-a10a-017dacba5cb9	5cee148d-439c-422b-b3ca-515a7c847d25	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:18:46.242775+03
e684862c-9461-4ca6-b739-22222f14ba52	02667157-3f8d-4370-a4cf-9551d7f5c025	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:18:46.254112+03
b6a064ee-8813-41c1-b4a2-0b0a1df19be1	fcabec9c-3367-45f0-b462-271ee937b40c	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:18:46.259844+03
84dc6b7a-9fe3-460b-aec4-685357c19c78	7661899a-97cc-493a-a37d-b783e6335c7f	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:18:46.263816+03
a1d72017-ca22-4187-b892-ed31131a06ab	85b671d7-a4e8-4192-b911-306ac6b46b2c	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:18:46.267263+03
460666df-08a8-4859-9e39-b59f73471b2e	351b31d4-40b1-4f69-85dd-f5f25031a184	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:18:46.270729+03
7fe62ccf-9062-42ef-9bca-2b33bd4528f6	8b228fea-ed40-4ee1-b7f9-c17585adc595	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:18:46.275294+03
86f7307a-6a0c-4efa-89c4-11abc7a192ff	37d4e940-020a-41ae-8203-d694a4dd7bdd	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:18:46.278504+03
7497ebd4-a8f8-4dc3-9a77-5e023613c23b	5cee148d-439c-422b-b3ca-515a7c847d25	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:18:48.297895+03
a5bb9e70-4353-48af-af36-c17c735798ce	02667157-3f8d-4370-a4cf-9551d7f5c025	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:18:48.30045+03
83b8bdb7-a8cd-40a6-b2a3-3215c77fb443	7661899a-97cc-493a-a37d-b783e6335c7f	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:21:12.150695+03
aec43238-c638-4ec4-9ff6-0700d0413dc8	85b671d7-a4e8-4192-b911-306ac6b46b2c	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:21:12.156573+03
011d6332-c615-411b-a47d-b5e336baf1d4	351b31d4-40b1-4f69-85dd-f5f25031a184	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:21:12.162136+03
efb96ed1-9c57-4ca5-b322-e26304594917	8b228fea-ed40-4ee1-b7f9-c17585adc595	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:21:12.167662+03
4c11b716-96b3-4a8e-8895-20b80b80bba5	37d4e940-020a-41ae-8203-d694a4dd7bdd	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 05:21:12.172819+03
0d6dacce-acc3-4c73-b8d7-1e335fd2fdb4	5cee148d-439c-422b-b3ca-515a7c847d25	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 06:39:41.77599+03
241ae011-b388-43e9-8d3d-a4c897fe7b63	02667157-3f8d-4370-a4cf-9551d7f5c025	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 06:39:41.804614+03
1adaca3d-e303-4803-a85b-fd6ce4e46b73	fcabec9c-3367-45f0-b462-271ee937b40c	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 06:39:41.842165+03
dd7d9b08-0622-44a9-8cc9-93a018784eb9	7661899a-97cc-493a-a37d-b783e6335c7f	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 06:39:41.853171+03
09401414-86ae-4a19-8ae1-0f13fb9f3934	85b671d7-a4e8-4192-b911-306ac6b46b2c	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 06:39:41.860112+03
8745a238-3390-41f5-b947-42e7ab3103c9	351b31d4-40b1-4f69-85dd-f5f25031a184	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 06:39:41.868485+03
efd01792-1d5f-48cf-92d9-dc52dbe37893	8b228fea-ed40-4ee1-b7f9-c17585adc595	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 06:39:41.876168+03
86fe1eb4-c8c0-4d10-b779-4cf7bd365cbf	37d4e940-020a-41ae-8203-d694a4dd7bdd	system_alert	🔧 System Maintenance Mode	The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.	{}	f	\N	\N	high	\N	2026-05-27 06:39:41.884305+03
\.


--
-- Data for Name: package_destinations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.package_destinations (package_id, destination_id) FROM stdin;
\.


--
-- Data for Name: package_itineraries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.package_itineraries (id, package_id, day_number, title, description, accommodation_type, meal_plan, included_activities, optional_activities, distance_km, travel_time_hours, created_at) FROM stdin;
be13aaf7-d425-4fb5-a499-94834aba9dd7	773360e5-2277-4aad-9abd-ba4dcadebed0	1	Day 1	Day 1: Arrival in Addis Ababa. Visit the National Museum to see the fossil "Lucy" and explore the sprawling Merkato market.			\N	\N	0.00	0.00	2026-05-20 17:15:01.111658+03
2d142209-ece6-4651-9ae4-0caf13723f6c	773360e5-2277-4aad-9abd-ba4dcadebed0	2	Day 2	Day 2: Fly to Bahir Dar. Take a boat trip on Lake Tana to see ancient island monasteries, then drive to the majestic Blue Nile Falls.			\N	\N	0.00	0.00	2026-05-20 17:15:01.111658+03
71468945-5170-4f90-95e2-3405b45e4ae2	773360e5-2277-4aad-9abd-ba4dcadebed0	3	Day 3	Day 3: Drive to Gondar. Explore the Royal Enclosure's medieval castles and the Debre Berhan Selassie Church with its famous angel-filled ceiling.			\N	\N	0.00	0.00	2026-05-20 17:15:01.111658+03
918b192a-5208-4327-a7b5-e0e853972cd4	773360e5-2277-4aad-9abd-ba4dcadebed0	4	Day 4	Day 4: Simien Mountains National Park. Trek through this UNESCO site to see troops of Gelada baboons and dramatic mountain vistas.			\N	\N	0.00	0.00	2026-05-20 17:15:01.111658+03
f73e07dc-836c-4175-946b-802e609eda6f	773360e5-2277-4aad-9abd-ba4dcadebed0	5	Day 5	Day 5: Fly to Lalibela. Settle in and visit the first group of rock-hewn churches, including the massive Bet Medhane Alem.			\N	\N	0.00	0.00	2026-05-20 17:15:01.111658+03
410946de-359e-46a3-a94f-af6b70b99ec3	773360e5-2277-4aad-9abd-ba4dcadebed0	6	Day 6	Day 6: Churches & Cooking. Visit the cross-shaped Bet Giorgis (St. George), then enjoy a cultural afternoon with a local family for a traditional coffee ceremony.			\N	\N	0.00	0.00	2026-05-20 17:15:01.111658+03
e30f8838-af93-4aeb-83cc-4c3aee6c6c33	773360e5-2277-4aad-9abd-ba4dcadebed0	7	Day 7	Day 7: Return to Addis. Fly back to the capital for last-minute souvenir shopping and a farewell dinner with live music before your flight home.			\N	\N	0.00	0.00	2026-05-20 17:15:01.111658+03
\.


--
-- Data for Name: package_pricing; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.package_pricing (id, package_id, season, start_month, end_month, price_per_person_local, price_per_person_diaspora, price_per_person_international, child_discount_percentage, infant_discount_percentage, group_discount_percentage, early_bird_discount_percentage, last_minute_discount_percentage, created_at, updated_at) FROM stdin;
d588fba9-97c9-47ac-97c5-cc92ba1dc4dc	ece6dfea-fb15-48f0-8f5e-61df8e647117	both	\N	\N	3000.00	3000.00	3000.00	0.00	0.00	0.00	0.00	0.00	2026-04-01 11:02:20.197948+03	2026-04-01 11:02:20.197948+03
f10be27f-d8f1-4ac7-83d9-5c4931456fa6	326dc86e-58a3-4e79-802b-1a03a1a6bc2d	both	\N	\N	6000.00	6000.00	6000.00	0.00	0.00	0.00	0.00	0.00	2026-04-01 10:44:43.469179+03	2026-04-01 10:44:43.469179+03
1d500328-a667-446b-8205-5984079f8543	773360e5-2277-4aad-9abd-ba4dcadebed0	both	\N	\N	20000.00	20000.00	20000.00	0.00	0.00	0.00	0.00	0.00	2026-05-20 17:15:01.111658+03	2026-05-20 17:15:01.111658+03
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payments (id, payment_code, booking_id, tourist_id, amount, currency, payment_method, payment_gateway, gateway_transaction_id, gateway_response, payment_status, paid_at, receipt_url, refund_amount, refund_reason, refunded_at, created_at, tx_ref, verified_at, chapa_response, method, status) FROM stdin;
\.


--
-- Data for Name: price_adjustment_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.price_adjustment_rules (id, rule_name, rule_type, department_id, applies_to_staff_type, adjustment_type, adjustment_value, min_adjustment, max_adjustment, condition_expression, effective_from_date, effective_to_date, effective_from_time, effective_to_time, days_of_week, is_active, created_by, created_at, updated_at, is_holiday_rule) FROM stdin;
e9a47ac4-0ffb-42b1-9151-3c1daf7e7989	holiday bonus 	seasonal	\N	\N	multiplier	0.50	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	2026-04-13 10:12:55.570801+03	2026-04-13 10:12:55.570801+03	f
c06f62d4-d368-4488-a0b7-5cc7a97de5d8	holiday bonus 	seasonal	\N	\N	multiplier	0.50	\N	\N	\N	\N	\N	\N	\N	\N	t	\N	2026-04-13 11:03:54.330554+03	2026-04-13 11:03:54.330554+03	f
\.


--
-- Data for Name: review_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.review_categories (id, category_name, description, weight, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: review_ratings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.review_ratings (id, review_id, category_id, rating, created_at) FROM stdin;
\.


--
-- Data for Name: reviews; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reviews (id, booking_id, reviewer_id, reviewee_id, reviewee_role, rating, title, comment, photos, response, responded_by, responded_at, is_verified_booking, helpful_count, report_count, is_published, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- Data for Name: staff_base_prices; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.staff_base_prices (id, staff_id, department_id, base_price_per_unit, unit_type, currency, effective_date, expiry_date, notes, is_active, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: staff_departments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.staff_departments (id, department_code, department_name, description, payment_calculation_method, is_active, created_by, created_at, updated_at) FROM stdin;
9fdfe79a-4c33-4719-9f99-ceec4484cd18	DEPT-DRV	Driver	\N	per_km	t	\N	2026-04-13 10:50:24.01707+03	2026-04-13 10:50:24.01707+03
244638fd-e3d4-4039-ae1f-0f4e3177af3f	DEPT-GUI	Guide	\N	per_hour	t	\N	2026-04-13 10:50:24.01707+03	2026-04-13 10:50:24.01707+03
a105c93d-aed4-4106-97a2-b514f4273f2a	DEPT-SCT	Scout	\N	per_day	t	\N	2026-04-13 10:50:24.01707+03	2026-04-13 10:50:24.01707+03
09cb9f89-af1d-4b86-bc4d-019581e72b15	DEPT-CK	Cook	\N	per_day	t	\N	2026-04-13 10:50:24.01707+03	2026-04-13 10:50:24.01707+03
\.


--
-- Data for Name: staff_payment_transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.staff_payment_transactions (id, staff_id, booking_id, assignment_id, payment_period_start, payment_period_end, base_amount, units_worked, unit_price, adjustments, total_amount, currency, payment_method, bank_account_number, bank_name, mobile_money_number, recipient_name, payment_status, paid_at, transaction_reference, failure_reason, calculated_by, approved_by, approved_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: staff_wallets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.staff_wallets (id, user_id, balance, total_earned, total_withdrawn, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: staff_withdrawals; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.staff_withdrawals (id, user_id, amount, bank_name, account_number, account_name, status, admin_notes, created_at, processed_at, processed_by) FROM stdin;
\.


--
-- Data for Name: support_tickets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.support_tickets (id, ticket_code, user_id, booking_id, subject, description, category, priority, status, assigned_to, resolved_by, resolved_at, resolution_notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_app_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.system_app_logs (id, level, category, message, user_id, created_at) FROM stdin;
3f0f875c-bb79-4e31-adc9-556096746d2e	SUCCESS	HTTP_REQUEST	GET /api/settings/performance 200 47.664 ms	\N	2026-05-27 05:34:54.970162+03
cb3a5bbb-32f8-472c-9d74-b617892e24e0	SUCCESS	HTTP_REQUEST	GET /api/settings/performance 200 33.407 ms	\N	2026-05-27 05:34:59.04405+03
c26f974a-729c-4ef1-b8d6-2e375945c888	SUCCESS	HTTP_REQUEST	GET /api/settings/system 304 86.488 ms	\N	2026-05-27 05:37:02.803529+03
a712cffe-ccc8-44e6-9620-77120d3a411d	SUCCESS	HTTP_REQUEST	GET /api/settings/system 304 112.142 ms	\N	2026-05-27 05:37:02.918581+03
121acc88-960a-425d-ab54-d90a99217d2f	SUCCESS	HTTP_REQUEST	GET /api/settings/performance 200 43.325 ms	\N	2026-05-27 05:37:04.72162+03
9fe97752-b94c-4b22-be1b-6759653d7577	SUCCESS	HTTP_REQUEST	GET /api/settings/system 304 77.395 ms	\N	2026-05-27 05:46:13.812173+03
23c2e7cd-7db9-4e29-9f43-c81e172be8fe	SUCCESS	HTTP_REQUEST	GET /api/settings/system 304 203.985 ms	\N	2026-05-27 05:46:14.017813+03
2bbbd200-9baa-4657-935b-8cd88f967b16	SUCCESS	HTTP_REQUEST	GET /api/settings/performance 200 56.865 ms	\N	2026-05-27 05:46:15.680556+03
4e7d2f94-706a-4d0b-b07d-3c509780d8ae	SUCCESS	HTTP_REQUEST	POST /api/maintenance/backup 202 13.630 ms	\N	2026-05-27 05:46:47.193668+03
89807c28-7a30-42ad-885c-7ed33326ebbd	SUCCESS	HTTP_REQUEST	PUT /api/settings/system/maintenance 200 777.333 ms	\N	2026-05-27 06:39:41.898162+03
b2590f54-6375-4cd5-bbc0-3950fa0083e6	SUCCESS	HTTP_REQUEST	PUT /api/settings/system/maintenance 200 10.015 ms	\N	2026-05-27 06:39:43.148541+03
227798bb-c35b-43c3-82db-f34ea3554c24	SUCCESS	HTTP_REQUEST	POST /api/auth/forgot-password 200 5704.213 ms	\N	2026-05-27 06:48:01.686806+03
055da6d4-cb84-4cf6-8a51-a059a8d64613	SUCCESS	HTTP_REQUEST	POST /api/auth/login 200 574.702 ms	\N	2026-05-27 06:48:35.51487+03
de5fa0c2-0af7-4b8f-9e5c-72ffea15dd66	SUCCESS	HTTP_REQUEST	GET /api/booking-summary 304 848.329 ms	\N	2026-05-27 06:48:36.464081+03
6f5a3486-7d25-495d-9c3d-6e78ea98534e	SUCCESS	HTTP_REQUEST	GET /api/users 304 781.496 ms	\N	2026-05-27 06:48:36.713265+03
6cd68850-e71c-41e4-9475-db44dc231d94	SUCCESS	HTTP_REQUEST	GET /api/users 304 21.540 ms	\N	2026-05-27 06:48:36.73701+03
d1257a87-c56a-4979-aac5-779b733bcea8	SUCCESS	HTTP_REQUEST	GET /api/booking-summary 304 343.549 ms	\N	2026-05-27 06:48:36.812541+03
\.


--
-- Data for Name: system_configurations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.system_configurations (id, config_key, config_value, config_type, category, description, is_public, created_by, created_at, updated_at) FROM stdin;
8ff6600d-85e3-4cff-82a3-c3ebc1c62486	maintenance_message	System is currently under maintenance. We will be back shortly.	string	maintenance	Message shown to users during downtime	f	\N	2026-04-08 12:34:41.77269+03	2026-04-08 12:34:41.77269+03
8415b60c-78c7-4eff-9c50-eef8827de908	maintenance_duration_hours	2	integer	maintenance	Estimated maintenance duration	f	\N	2026-04-08 12:34:41.77269+03	2026-04-08 12:34:41.77269+03
371474ed-b9bc-4ebd-9e79-1f9fc39e354f	scheduled_maintenance_date		string	maintenance	Date for future maintenance	f	\N	2026-04-08 12:34:41.77269+03	2026-04-08 12:34:41.77269+03
ebea535b-fead-4c04-ad22-62adf3680274	scheduled_maintenance_time		string	maintenance	Time for future maintenance	f	\N	2026-04-08 12:34:41.77269+03	2026-04-08 12:34:41.77269+03
ff569340-efb9-4aa3-b3ca-9e93029ce682	enable_notifications	true	boolean	system	Global system notification toggle	f	\N	2026-04-08 12:34:41.77269+03	2026-04-08 12:34:41.77269+03
df87f81b-ed77-4d03-876e-9b65eabbbb37	default_currency	USD ($)	string	localization	Default system currency	f	\N	2026-04-08 12:34:41.77269+03	2026-04-08 12:34:41.77269+03
df64a753-97fc-46f9-b8c2-caf5b836fd66	default_timezone	GMT+3 (East Africa Time)	string	localization	System global timezone	f	\N	2026-04-08 12:34:41.77269+03	2026-04-08 12:34:41.77269+03
5fcef956-baac-4a85-9acf-045a24f2c96a	system_version	v2.1.0	string	system	Current version of the Telas Platform	f	\N	2026-04-08 12:34:41.77269+03	2026-04-08 12:34:41.77269+03
a25454d2-af05-44bf-bee3-f75949d68a5a	test_setting	test_value	string	testing	Test configuration for system test	f	\N	2026-05-26 16:06:34.222367+03	2026-05-26 16:06:34.222367+03
7a3ecab5-9d50-4061-8015-76b719c06f72	maintenance_schedule	{"message":"System is currently under maintenance. We will be back shortly.","duration":"2","date":"","time":""}	json	system	Scheduled Maintenance	t	\N	2026-05-27 05:14:19.019374+03	2026-05-27 05:14:19.019374+03
1ad8cd15-1524-4e43-b087-356f03c7fa29	maintenance_mode	false	boolean	maintenance	Is the system currently in maintenance mode?	f	\N	2026-04-08 12:34:41.77269+03	2026-05-27 06:39:43.139869+03
\.


--
-- Data for Name: ticket_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ticket_messages (id, ticket_id, sender_id, message, attachments_urls, is_internal_note, created_at) FROM stdin;
\.


--
-- Data for Name: tour_packages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tour_packages (id, package_code, name, description, tour_type, difficulty, duration_days, duration_nights, min_group_size, max_group_size, season_recommendation, tags, inclusions, exclusions, requirements, important_notes, cancellation_policy, photos_urls, is_customizable, is_active, created_by, created_at, updated_at, base_price) FROM stdin;
ece6dfea-fb15-48f0-8f5e-61df8e647117	PKG-540135-53	discover Ethiopia 	see spectacular cultural places in Ethiopia 	historical	moderate	1	1	1	15	both	{}	{Guide}	{"entry fee "}	{}	\N	\N	{/uploads/1778325926939-572282183.jfif,/uploads/1778325927063-920094709.jfif,/uploads/1778325927067-570741644.jfif,/uploads/1778325927077-874664623.jfif}	f	t	\N	2026-04-01 11:02:20.197948+03	2026-05-09 14:25:27.208074+03	0.00
326dc86e-58a3-4e79-802b-1a03a1a6bc2d	PKG-483152-35	hello Ethiopia 	visiting Ethiopia cultural palaces 	historical	moderate	1	0	1	15	both	{}	{"Guide, meal "}	{"entry fee"}	{}	\N	\N	{}	f	t	\N	2026-04-01 10:44:43.469179+03	2026-05-09 14:33:59.048333+03	0.00
773360e5-2277-4aad-9abd-ba4dcadebed0	PKG-498691-46	travel with telas	visit Ethiopia historical, cultural, and natural places within one week with us come and see what we have and absolutely you like it \r\n\r\n 	historical	moderate	7	7	20	98	dry	{}	{"Guide, transport, meal "}	{"flight and entry fee "}	{}	\N	\N	{/uploads/1779286499350-323810257.jfif,/uploads/1779286499350-813626967.jfif,/uploads/1779286499351-477749106.jfif,/uploads/1779286499401-935344848.jfif,/uploads/1779286499406-553322327.jfif,/uploads/1779286499407-238729164.jfif,/uploads/1779286499427-627230890.jfif}	f	t	\N	2026-05-20 17:15:01.111658+03	2026-05-20 17:15:01.111658+03	0.00
\.


--
-- Data for Name: tourists; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tourists (id, user_id, travel_frequency, preferred_tour_types, preferred_accommodation, preferred_transport, dietary_preferences, disability_access_needs, disability_details, frequent_flyer_numbers, loyalty_points, total_bookings, average_rating_given, created_at, updated_at) FROM stdin;
095acb8f-ead1-47af-9b49-f4205e22f019	fcabec9c-3367-45f0-b462-271ee937b40c	0	\N	\N	\N	\N	f	\N	\N	0	0	\N	2026-05-01 11:32:15.091435+03	2026-05-01 11:32:15.091435+03
9f37ddc4-4d45-4684-83ed-b3eb54394bc2	37d4e940-020a-41ae-8203-d694a4dd7bdd	0	\N	\N	\N	\N	f	\N	\N	0	0	\N	2026-05-23 12:22:01.65221+03	2026-05-23 12:22:01.65221+03
\.


--
-- Data for Name: trip_assignments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trip_assignments (id, booking_id, driver_id, guide_id, vehicle_id, assignment_date, assigned_by, assignment_notes, is_accepted, accepted_at, rejection_reason, created_at) FROM stdin;
\.


--
-- Data for Name: trip_expenses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trip_expenses (id, booking_id, expense_type, amount, currency, description, receipt_url, incurred_by, incurred_at, approved_by, approved_at, created_at) FROM stdin;
\.


--
-- Data for Name: trip_payment_calculation; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trip_payment_calculation (id, booking_id, total_distance_km, distance_rate_used, distance_based_amount, total_hours_worked, hourly_rate_used, time_based_amount, total_persons_served, per_person_rate_used, person_based_amount, fixed_amount, adjustment_amount, calculation_notes, calculated_by, calculated_at, approved_by, approved_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: trip_tracking; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trip_tracking (id, booking_id, location, altitude, speed, heading, accuracy, battery_level, recorded_at) FROM stdin;
\.


--
-- Data for Name: user_profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_profiles (id, user_id, first_name, last_name, middle_name, date_of_birth, gender, nationality, address, city, state, country, postal_code, emergency_contact_name, emergency_contact_phone, emergency_contact_relationship, dietary_restrictions, allergies, medical_conditions, passport_number, passport_expiry, visa_number, visa_expiry, created_at, updated_at, verification_tier, is_diaspora_verified) FROM stdin;
3b943113-9aa3-407e-9c02-665d8e41183d	02667157-3f8d-4370-a4cf-9551d7f5c025	temesgen	niguse	\N	2003-01-02	\N	Ethiopian	gondar	Gondar	\N	Ethiopia	\N	temesgen adigeh niguse	0972097458	\N	\N	\N	\N	21212121	\N	\N	\N	2026-03-28 15:38:43.72549+03	2026-03-28 15:38:43.72549+03	basic	f
055c03ef-2e2d-476d-9e10-4f193e2f5e32	7661899a-97cc-493a-a37d-b783e6335c7f	Tekle	Mihret 	\N	\N	\N	\N	\N	\N	\N	Ethiopia	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-17 09:19:06.524802+03	2026-05-17 09:19:06.524802+03	basic	f
7febff58-5ce7-4c6b-b63a-086e505da6c8	85b671d7-a4e8-4192-b911-306ac6b46b2c	Amanuel	Azanaw	\N	\N	\N	\N	\N	\N	\N	Ethiopia	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-17 10:17:10.479543+03	2026-05-17 10:17:10.479543+03	basic	f
a3d696a5-90f8-450b-8df7-7e280a8a71a4	5cee148d-439c-422b-b3ca-515a7c847d25	Teklu 	Kidanemariyam 	\N	\N	\N	\N	\N	\N	\N	Ethiopia	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-17 09:05:10.897877+03	2026-05-21 18:07:21.813194+03	basic	f
696d5353-c3b7-4d58-b827-f64fc22c8fd2	8b228fea-ed40-4ee1-b7f9-c17585adc595	Natnael	Getnet	\N	\N	\N	\N	\N	\N	\N	Ethiopia	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-23 10:58:09.144814+03	2026-05-23 10:58:09.144814+03	basic	f
31e81636-2598-4e23-8878-ac0d827336ac	37d4e940-020a-41ae-8203-d694a4dd7bdd	Tesfahun 	Denekew 	\N	\N	\N	\N	\N	\N	\N	Ethiopia	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-23 12:22:01.65221+03	2026-05-23 12:22:01.65221+03	basic	f
ce8e9003-e138-4cc4-b0e5-2be279a44a94	fcabec9c-3367-45f0-b462-271ee937b40c	haymanot  	niguse	\N	\N	\N	\N	\N	\N	\N	Ethiopia	\N	\N	\N	\N	\N	\N	\N	6988788	\N	\N	\N	2026-05-01 11:32:15.091435+03	2026-05-25 09:40:53.937721+03	basic	f
7dbdca80-fff5-49ee-a19d-d5e8f4b6f320	351b31d4-40b1-4f69-85dd-f5f25031a184	Natnael	Getnet	\N	\N	\N	\N	\N	\N	\N	Ethiopia	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2026-05-23 12:22:14.851954+03	2026-05-26 18:44:32.152386+03	basic	f
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, user_role, email, phone, phone_country_code, password_hash, is_email_verified, is_phone_verified, verification_token, verification_expires, otp_code, otp_expires, two_factor_enabled, created_at, updated_at, last_login, status, profile_picture_url, preferred_language, timezone) FROM stdin;
37d4e940-020a-41ae-8203-d694a4dd7bdd	tourist	tesfahundenekew1@gmail.com	0982944734	+251	$2b$10$f11YinawSqNGSW2e/S0Aq.AQR8KGHHwSeEnQNA7wZBfS.Y0HpcRfm	f	f	\N	\N	043349	2026-05-23 12:22:46.65221+03	f	2026-05-23 12:22:01.65221+03	2026-05-23 12:26:17.734371+03	2026-05-23 12:26:17.734371+03	active	\N	en	Africa/Addis_Ababa
5cee148d-439c-422b-b3ca-515a7c847d25	driver	teklukide27@gmail.com	0929798060	+251	$2b$10$AOd9MwVnGFoZmB.9lXJ7SO2PeLeuG78BFqK3O4D0hzzyl.44mzlya	t	f	\N	\N	\N	2026-05-17 09:05:55.897877+03	f	2026-05-17 09:05:10.897877+03	2026-05-26 16:35:38.662394+03	2026-05-26 16:35:38.662394+03	active	\N	en	Africa/Addis_Ababa
fcabec9c-3367-45f0-b462-271ee937b40c	tourist	hyme21@gmail.com	0946840741	+251	$2b$10$06ulwzrmnVtnDovxpxUziOQeW3zx8j0nuZwDlmdQMq.lGCtjdqQNO	f	f	\N	\N	645068	2026-05-01 11:33:00.091435+03	f	2026-05-01 11:32:15.091435+03	2026-05-26 16:40:41.273149+03	2026-05-26 16:40:41.273149+03	active	/uploads/1779691251552-105032745.jpg	en	Africa/Addis_Ababa
7661899a-97cc-493a-a37d-b783e6335c7f	guide	tekymary1221@gmail.com	0970442334	+251	$2b$10$9UZJrtn.j/bkhUwGq5XakeHhfZ4Qb/NzHLpdmbha6/fxp25JPihx2	t	f	\N	\N	\N	2026-05-17 09:31:30.085722+03	f	2026-05-17 09:19:06.524802+03	2026-05-17 09:22:42.723775+03	2026-05-17 09:22:42.723775+03	active	/uploads/1778998744360-34421518.jpg	en	Africa/Addis_Ababa
85b671d7-a4e8-4192-b911-306ac6b46b2c	guide	amanualazanaw21@gmail.com	0901930368	+251	$2b$10$J7Gnpe3vhCjxngcMTLdO.eaLuUZCbj88J96xP8B01UOWAw06XgEA.	f	f	\N	\N	998514	2026-05-17 10:17:55.479543+03	f	2026-05-17 10:17:10.479543+03	2026-05-17 11:26:52.16679+03	2026-05-17 11:26:52.16679+03	active	/uploads/1779002219049-226713251.jpg	en	Africa/Addis_Ababa
351b31d4-40b1-4f69-85dd-f5f25031a184	driver	abudt121@gmail.com	0947063070	+251	$2b$10$.SsuVMEssWnIS.aeJNviq.cPfWbCs1ZqPlTICJlIenV5BYsZGvMIW	t	f	\N	\N	\N	2026-05-23 12:22:59.851954+03	f	2026-05-23 12:22:14.851954+03	2026-05-26 18:44:32.152386+03	2026-05-23 12:26:01.797749+03	active	\N	en	Africa/Addis_Ababa
8b228fea-ed40-4ee1-b7f9-c17585adc595	driver	abudt12@gmail.com	0903048588	+251	$2b$10$XwSLmLdjaxPPZsUBwUsY7.YClH7yIxieLxuT8T1hdZSwECyk6ivx6	t	f	\N	\N	\N	2026-05-23 10:58:54.144814+03	f	2026-05-23 10:58:09.144814+03	2026-05-23 11:54:46.731223+03	2026-05-23 11:54:46.731223+03	active	\N	en	Africa/Addis_Ababa
02667157-3f8d-4370-a4cf-9551d7f5c025	admin	tnigussie96@gmail.com	938424259	+251	$2b$10$4/xHU/9GdPAjrvDdnfwrs.YU5vlZSLViBVCfMC.237y9ji/ObLkyq	f	f	\N	\N	117692	2026-05-27 06:57:56.069264+03	f	2026-03-28 15:38:43.72549+03	2026-05-27 06:48:35.509905+03	2026-05-27 06:48:35.509905+03	active	\N	en	Africa/Addis_Ababa
\.


--
-- Data for Name: vehicle_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vehicle_categories (id, name, description, passenger_capacity, luggage_capacity, vehicle_type, icon_url, created_at) FROM stdin;
\.


--
-- Data for Name: vehicles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vehicles (id, driver_id, category_id, plate_number, make, model, year, color, registration_number, registration_expiry, insurance_number, insurance_expiry, insurance_photo_url, fuel_type, transmission, features, photos_urls, is_active, current_mileage, last_service_date, next_service_date, created_at, updated_at, safety_inspection_expiry_date) FROM stdin;
00329e7c-a3a3-4e8b-8dec-21a88ae36f9d	3792db4b-c57e-4bdd-8a90-75adf290be92	\N	5634	Byd	Unknown	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	{/uploads/1778997909604-580430130.jpg}	t	\N	\N	\N	2026-05-17 09:05:10.897877+03	2026-05-17 09:05:10.897877+03	\N
38ee0e91-57d0-418a-ad95-ac9924209258	2a16833f-49ee-47ec-9c2b-9ec27ab14c49	\N	AA 2727	Toyota	Unknown	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	{/uploads/1779523085677-374051281.jpg}	t	\N	\N	\N	2026-05-23 10:58:09.144814+03	2026-05-23 10:58:09.144814+03	\N
\.


--
-- Data for Name: verification_documents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.verification_documents (id, user_id, document_type, document_number, front_image_url, back_image_url, issue_date, expiry_date, issuing_authority, verification_status, verified_by, verified_at, rejection_reason, created_at) FROM stdin;
65f7c794-5e7c-4433-8fdc-3f48bfe296ef	5cee148d-439c-422b-b3ca-515a7c847d25	libre_document	\N	/uploads/1778997910196-169906141.jpg	\N	\N	\N	\N	pending	\N	\N	\N	2026-05-17 09:05:10.897877+03
177980a2-169e-4a4c-b911-0e53e315015f	7661899a-97cc-493a-a37d-b783e6335c7f	language_certification	\N	/uploads/1778998746193-199369205.jpg	\N	\N	\N	\N	pending	\N	\N	\N	2026-05-17 09:19:06.524802+03
3d10489c-b7e5-45f6-af1f-8951c025b94b	85b671d7-a4e8-4192-b911-306ac6b46b2c	language_certification	\N	/uploads/1779002219687-321188664.png	\N	\N	\N	\N	pending	\N	\N	\N	2026-05-17 10:17:10.479543+03
815646d1-facc-4192-bcaf-cfd28d81da70	8b228fea-ed40-4ee1-b7f9-c17585adc595	libre_document	\N	/uploads/1779523088565-557699543.jpg	\N	\N	\N	\N	pending	\N	\N	\N	2026-05-23 10:58:09.144814+03
5b046cdf-33ae-49f7-a877-096feb56ed35	351b31d4-40b1-4f69-85dd-f5f25031a184	language_certification	\N	/uploads/1779528134538-671792393.jpg	\N	\N	\N	\N	pending	\N	\N	\N	2026-05-23 12:22:14.851954+03
\.


--
-- Data for Name: web_traffic_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.web_traffic_logs (id, session_id, user_id, event_type, path_visited, ip_address, device_type, created_at) FROM stdin;
\.


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

\unrestrict FVqpcalBzy9Rg1q9uAjEKCz4GhfnUp1kF1b2qaW4p4sfXf1EIykJNY2QbggcWJQ

