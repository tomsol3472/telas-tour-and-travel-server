-- =====================================================
-- TELAS CHAT CLEANUP PROCEDURE
-- Deletes chat messages and media files 1 month after 
-- the associated tour has ended.
-- =====================================================

-- 1. Create a function to delete old messages
CREATE OR REPLACE FUNCTION delete_old_tour_messages()
RETURNS void AS $$
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
$$ LANGUAGE plpgsql;

-- 2. Optional: If using pg_cron extension, schedule this function to run daily at midnight
-- SELECT cron.schedule('0 0 * * *', $$SELECT delete_old_tour_messages()$$);
