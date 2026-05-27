-- Fix Assignment Persistence Issues
-- Add missing guide_name and driver_name columns to bookings table

-- Add the missing name columns that the controller expects
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS guide_name VARCHAR(200),
ADD COLUMN IF NOT EXISTS driver_name VARCHAR(200);

-- Create indexes for better performance on assignment queries
CREATE INDEX IF NOT EXISTS idx_bookings_assigned_guide ON bookings(assigned_guide_id);
CREATE INDEX IF NOT EXISTS idx_bookings_assigned_driver ON bookings(assigned_driver_id);
CREATE INDEX IF NOT EXISTS idx_bookings_guide_name ON bookings(guide_name);
CREATE INDEX IF NOT EXISTS idx_bookings_driver_name ON bookings(driver_name);

-- Update existing records to populate name fields from related tables
-- For guides: get name from users table via user_id
UPDATE bookings 
SET guide_name = u.email 
FROM guides g 
JOIN users u ON g.user_id = u.id
WHERE bookings.assigned_guide_id = g.id 
AND bookings.guide_name IS NULL;

-- For drivers: get name from users table via user_id  
UPDATE bookings 
SET driver_name = u.email 
FROM drivers d 
JOIN users u ON d.user_id = u.id
WHERE bookings.assigned_driver_id = d.id 
AND bookings.driver_name IS NULL;

-- Add comment explaining the dual assignment system
COMMENT ON COLUMN bookings.guide_name IS 'Cached guide name for quick display - updated when assigned_guide_id changes';
COMMENT ON COLUMN bookings.driver_name IS 'Cached driver name for quick display - updated when assigned_driver_id changes';