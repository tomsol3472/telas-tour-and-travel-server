-- Fix: Add tx_ref column to payments table if it doesn't exist

DO $$ 
BEGIN
    -- Add tx_ref column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payments' AND column_name = 'tx_ref'
    ) THEN
        ALTER TABLE payments ADD COLUMN tx_ref VARCHAR(100);
        CREATE INDEX idx_payments_tx_ref ON payments(tx_ref);
        RAISE NOTICE 'Added tx_ref column to payments table';
    ELSE
        RAISE NOTICE 'tx_ref column already exists';
    END IF;

    -- Add verified_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payments' AND column_name = 'verified_at'
    ) THEN
        ALTER TABLE payments ADD COLUMN verified_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Added verified_at column to payments table';
    ELSE
        RAISE NOTICE 'verified_at column already exists';
    END IF;

    -- Add chapa_response column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payments' AND column_name = 'chapa_response'
    ) THEN
        ALTER TABLE payments ADD COLUMN chapa_response JSONB;
        RAISE NOTICE 'Added chapa_response column to payments table';
    ELSE
        RAISE NOTICE 'chapa_response column already exists';
    END IF;

    -- Add method column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payments' AND column_name = 'method'
    ) THEN
        ALTER TABLE payments ADD COLUMN method VARCHAR(50) DEFAULT 'chapa';
        RAISE NOTICE 'Added method column to payments table';
    ELSE
        RAISE NOTICE 'method column already exists';
    END IF;

    -- Add status column if it doesn't exist (separate from payment_status)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payments' AND column_name = 'status'
    ) THEN
        ALTER TABLE payments ADD COLUMN status VARCHAR(50) DEFAULT 'pending';
        RAISE NOTICE 'Added status column to payments table';
    ELSE
        RAISE NOTICE 'status column already exists';
    END IF;
END $$;

-- Display success message
SELECT 'Payment table columns fixed successfully!' as message;
