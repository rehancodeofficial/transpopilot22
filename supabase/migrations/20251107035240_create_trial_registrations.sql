/*
  # Trial Registrations Table

  ## Overview
  Creates a table to store trial signup information from potential customers who want to start a 30-day free trial of TranspoPilot AI.

  ## New Tables
    - `trial_registrations`
      - `id` (uuid, primary key) - Unique identifier for each trial registration
      - `email` (text, unique, required) - User's business email address
      - `company_name` (text, optional) - Name of the trucking company
      - `fleet_size` (integer, optional) - Number of trucks in their fleet
      - `phone` (text, optional) - Contact phone number
      - `status` (text, required) - Registration status: 'pending', 'contacted', 'activated', 'converted', 'declined'
      - `created_at` (timestamptz) - When the trial registration was submitted
      - `updated_at` (timestamptz) - Last update timestamp

  ## Security
    - Enable RLS on `trial_registrations` table
    - Allow anonymous users to INSERT their own trial registrations
    - Allow authenticated admin users to SELECT and UPDATE all registrations
    - No DELETE policy - data should be preserved for analytics

  ## Important Notes
    - Email must be unique to prevent duplicate trial signups
    - Status defaults to 'pending' for new registrations
    - Timestamps are automatically managed with triggers
*/

-- Create trial_registrations table
CREATE TABLE IF NOT EXISTS trial_registrations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  company_name text,
  fleet_size integer,
  phone text,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  CONSTRAINT valid_status CHECK (status IN ('pending', 'contacted', 'activated', 'converted', 'declined')),
  CONSTRAINT positive_fleet_size CHECK (fleet_size IS NULL OR fleet_size > 0)
);

-- Create index for faster email lookups
CREATE INDEX IF NOT EXISTS idx_trial_registrations_email ON trial_registrations(email);
CREATE INDEX IF NOT EXISTS idx_trial_registrations_status ON trial_registrations(status);
CREATE INDEX IF NOT EXISTS idx_trial_registrations_created_at ON trial_registrations(created_at DESC);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS update_trial_registrations_updated_at ON trial_registrations;
CREATE TRIGGER update_trial_registrations_updated_at
  BEFORE UPDATE ON trial_registrations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE trial_registrations ENABLE ROW LEVEL SECURITY;

-- Policy: Allow anyone to insert trial registrations (anonymous signups)
CREATE POLICY "Anyone can create trial registration"
  ON trial_registrations
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Policy: Authenticated users can view all trial registrations (for admin dashboard)
CREATE POLICY "Authenticated users can view all registrations"
  ON trial_registrations
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy: Authenticated users can update trial registrations (for admin management)
CREATE POLICY "Authenticated users can update registrations"
  ON trial_registrations
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);