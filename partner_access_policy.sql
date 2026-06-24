-- ============================================
-- PARTNER ACCESS TO PENDING BOOKINGS
-- ============================================
-- Run this in your Supabase SQL Editor
-- ============================================

-- 1. Enable RLS on bookings (if not already enabled)
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- 2. Policy: Partners can view PENDING bookings OR bookings assigned to THEM
-- We assume partners are authenticated users.
-- We check if status is 'Pending' (unassigned) or if partner_id matches their UID.
CREATE POLICY "Partners can view relevant bookings"
ON bookings
FOR SELECT
USING (
  status = 'Pending' 
  OR partner_id = auth.uid() 
  OR user_id = auth.uid() -- Customers can still see their own bookings
);

-- 3. Policy: Partners can update bookings they accept
CREATE POLICY "Partners can accept pending bookings"
ON bookings
FOR UPDATE
USING (
  status = 'Pending' 
  OR partner_id = auth.uid()
)
WITH CHECK (
  status IN ('Accepted', 'Arrived', 'Quoted', 'In Progress', 'Completed', 'Rejected')
);
