-- =====================================================
-- CHAPA PAYMENT INTEGRATION MIGRATION
-- Add necessary columns for Chapa payment tracking
-- =====================================================

-- Add tx_ref column if it doesn't exist (for Chapa transaction reference)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payments' AND column_name = 'tx_ref'
    ) THEN
        ALTER TABLE payments ADD COLUMN tx_ref VARCHAR(100);
        CREATE INDEX idx_payments_tx_ref ON payments(tx_ref);
    END IF;
END $$;

-- Add verified_at column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payments' AND column_name = 'verified_at'
    ) THEN
        ALTER TABLE payments ADD COLUMN verified_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- Add chapa_response column if it doesn't exist (to store full Chapa response)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payments' AND column_name = 'chapa_response'
    ) THEN
        ALTER TABLE payments ADD COLUMN chapa_response JSONB;
    END IF;
END $$;

-- Update payment_code to be nullable and auto-generated if not provided
DO $$ 
BEGIN
    ALTER TABLE payments ALTER COLUMN payment_code DROP NOT NULL;
EXCEPTION
    WHEN OTHERS THEN NULL;
END $$;

-- Add method column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payments' AND column_name = 'method'
    ) THEN
        ALTER TABLE payments ADD COLUMN method VARCHAR(50) DEFAULT 'chapa';
    END IF;
END $$;

-- Add status column if it doesn't exist (separate from payment_status)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payments' AND column_name = 'status'
    ) THEN
        ALTER TABLE payments ADD COLUMN status VARCHAR(50) DEFAULT 'pending';
    END IF;
END $$;

-- Make tourist_id nullable (it can be derived from booking)
DO $$ 
BEGIN
    ALTER TABLE payments ALTER COLUMN tourist_id DROP NOT NULL;
EXCEPTION
    WHEN OTHERS THEN NULL;
END $$;

-- Make payment_code auto-generate if not provided
DO $$ 
BEGIN
    ALTER TABLE payments ALTER COLUMN payment_code SET DEFAULT 'PAY-' || EXTRACT(EPOCH FROM NOW())::BIGINT || '-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8);
EXCEPTION
    WHEN OTHERS THEN NULL;
END $$;

-- Create a function to auto-update payment_code if null
CREATE OR REPLACE FUNCTION generate_payment_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.payment_code IS NULL THEN
        NEW.payment_code := 'PAY-' || EXTRACT(EPOCH FROM NOW())::BIGINT || '-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-generate payment_code
DROP TRIGGER IF EXISTS trg_generate_payment_code ON payments;
CREATE TRIGGER trg_generate_payment_code
    BEFORE INSERT ON payments
    FOR EACH ROW
    EXECUTE FUNCTION generate_payment_code();

-- Add comment to table
COMMENT ON TABLE payments IS 'Payment transactions including Chapa integration';
COMMENT ON COLUMN payments.tx_ref IS 'Chapa transaction reference for tracking';
COMMENT ON COLUMN payments.chapa_response IS 'Full JSON response from Chapa API';
COMMENT ON COLUMN payments.verified_at IS 'Timestamp when payment was verified with Chapa';

-- Display success message
DO $$ 
BEGIN
    RAISE NOTICE 'Chapa payment migration completed successfully!';
END $$;
