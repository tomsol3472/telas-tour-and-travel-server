-- =====================================================
-- Fix booking date constraint
-- Drops the CHECK (start_date >= booking_date) rule
-- which rejects bookings when start_date is in the past.
-- The server now normalizes dates in code before inserting.
-- =====================================================

-- Step 1: Drop all unnamed check constraints on bookings
-- PostgreSQL auto-names them bookings_check, bookings_check1, etc.
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_check;
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_check1;
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_check2;
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_check3;
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS valid_dates;
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_start_date_check;
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_end_after_start;

-- Step 2: Add back only the safe constraint (end >= start)
ALTER TABLE bookings ADD CONSTRAINT bookings_end_after_start
    CHECK (end_date >= start_date);

-- Step 3: Verify
SELECT 
    constraint_name,
    check_clause
FROM information_schema.check_constraints
WHERE constraint_name IN (
    SELECT constraint_name 
    FROM information_schema.table_constraints 
    WHERE table_name = 'bookings' AND constraint_type = 'CHECK'
);

SELECT 'Done! Booking date constraint fixed.' AS result;
