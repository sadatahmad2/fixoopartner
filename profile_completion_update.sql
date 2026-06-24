-- ============================================
-- FIXOO PARTNER APP - PROFILE COMPLETION UPDATES
-- ============================================
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================

-- 1. ADD NEW COLUMNS TO PROFILES
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS skills TEXT[] DEFAULT '{}';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS work_video_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_profile_complete BOOLEAN DEFAULT false;

-- 2. UPDATE BOOKINGS TABLE FOR REAL-TIME REQUESTS
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS customer_name TEXT;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS customer_phone TEXT;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS partner_name TEXT;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS partner_avatar TEXT;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS arrived_at TIMESTAMPTZ;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

-- 3. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  icon_name TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. ENSURE STORAGE BUCKETS (Manual)
-- You must create 'videos' bucket in Supabase Storage and set policies.
