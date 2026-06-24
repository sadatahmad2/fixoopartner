-- ============================================
-- FIXOO PARTNER APP - DATABASE EXTENSIONS
-- ============================================
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- This adds the necessary tables and columns for the Partner App.
-- ============================================

-- 1. EXTEND PROFILES TABLE
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT true;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- 2. EXTEND BOOKINGS TABLE
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS partner_id UUID REFERENCES profiles(id);
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS price DECIMAL(10,2) DEFAULT 0.00;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS advance_status TEXT DEFAULT 'pending';
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS advance_amount DECIMAL(10,2) DEFAULT 0.00;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS service_cost DECIMAL(10,2) DEFAULT 0.00;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS approval_status TEXT DEFAULT 'none';
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS materials JSONB DEFAULT '[]';
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS before_images TEXT[] DEFAULT '{}';
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS after_images TEXT[] DEFAULT '{}';

-- 3. BANK DETAILS TABLE
CREATE TABLE IF NOT EXISTS bank_details (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  partner_id UUID REFERENCES profiles(id) UNIQUE NOT NULL,
  bank_name TEXT NOT NULL,
  account_number TEXT NOT NULL,
  ifsc TEXT NOT NULL,
  holder_name TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE bank_details ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Partners can view own bank details" ON bank_details FOR SELECT USING (auth.uid() = partner_id);
CREATE POLICY "Partners can update own bank details" ON bank_details FOR ALL USING (auth.uid() = partner_id);

-- 4. DOCUMENTS TABLE (KYC)
CREATE TABLE IF NOT EXISTS documents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  partner_id UUID REFERENCES profiles(id) NOT NULL,
  type TEXT NOT NULL,
  file_url TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'In Review',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Partners can view own documents" ON documents FOR SELECT USING (auth.uid() = partner_id);
CREATE POLICY "Partners can upload own documents" ON documents FOR INSERT WITH CHECK (auth.uid() = partner_id);

-- 5. STORAGE BUCKETS (Manual Setup Recommended)
-- Note: You must also create 'avatars' and 'documents' buckets in Supabase Storage 
-- and set their policies to 'Public' or 'Authenticated' as needed.
