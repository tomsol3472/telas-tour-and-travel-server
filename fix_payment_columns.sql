-- =====================================================
-- FIX PAYMENT TABLE COLUMNS
-- Add missing columns for Chapa integration
-- =====================================================

-- Add tx_ref column (transaction reference from Chapa)
ALTER TABLE payments 
ADD COLUMN IF NOT EXISTS tx_ref VARCHAR(200);

-- Add method column (alias for payment_method for backward compatibility)
ALTER TABLE payments 
ADD COLUMN IF NOT EXISTS method VARCHAR(50);

-- Add status column (alias for payment_status for backward compatibility)
ALTER TABLE payments 
ADD COLUMN IF NOT EXISTS status VARCHAR(50);

-- Add verified_at column
ALTER TABLE payments 
ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP WITH TIME ZONE;

-- Add chapa_response column (alias for gateway_response)
ALTER TABLE payments 
ADD COLUMN IF NOT EXISTS chapa_response JSONB;

-- Create index on tx_ref for faster lookups
CREATE INDEX IF NOT EXISTS idx_payments_tx_ref ON payments(tx_ref);

-- Update existing records to sync method and status with payment_method and payment_status
UPDATE payments 
SET method = payment_method,
    status = payment_status::text
WHERE method IS NULL OR status IS NULL;

-- Add comment
COMMENT ON COLUMN payments.tx_ref IS 'Transaction reference from payment gateway (Chapa)';
COMMENT ON COLUMN payments.method IS 'Payment method (backward compatibility alias for payment_method)';
COMMENT ON COLUMN payments.status IS 'Payment status (backward compatibility alias for payment_status)';

-- =====================================================
-- END OF PAYMENT TABLE FIX
-- =====================================================
