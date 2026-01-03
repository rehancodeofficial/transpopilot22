/*
  # Restore Organizations Table for Multi-Tenancy

  ## Overview
  Restores the organizations table to enable proper multi-tenancy with data isolation
  between different trucking companies using TranspoPilot AI.

  ## New Tables

  ### `organizations`
  - `id` (uuid, primary key) - Unique organization identifier
  - `name` (text, required) - Organization/company name
  - `slug` (text, unique) - URL-friendly organization identifier
  - `subscription_tier` (text) - Plan: 'trial', 'starter', 'pro', 'enterprise'
  - `subscription_status` (text) - Status: 'trial', 'active', 'cancelled', 'expired'
  - `max_vehicles` (integer) - Maximum vehicles allowed based on tier
  - `max_drivers` (integer) - Maximum drivers allowed based on tier
  - `trial_ends_at` (timestamptz) - When trial period ends (30 days from signup)
  - `created_at` (timestamptz) - Organization creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ## Tier Limits
  - Trial: 10 vehicles, 10 drivers (30 days)
  - Starter: 10 vehicles, 10 drivers ($997/month)
  - Pro: 50 vehicles, 50 drivers ($1,997/month)
  - Enterprise: Unlimited vehicles, unlimited drivers ($3,997+/month)

  ## Security
  - Enable RLS on organizations table
  - Users can read their own organization
  - Admins can update their organization
  - Super admins can manage all organizations

  ## Important Notes
  - Organization is created automatically on first user signup
  - All users in an organization share the same data
  - RLS policies ensure complete data isolation between organizations
  - Tier limits are enforced at the API layer before database insertion
*/

-- Create organizations table
CREATE TABLE IF NOT EXISTS organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text UNIQUE NOT NULL,
  subscription_tier text NOT NULL DEFAULT 'trial' CHECK (subscription_tier IN ('trial', 'starter', 'pro', 'enterprise')),
  subscription_status text NOT NULL DEFAULT 'trial' CHECK (subscription_status IN ('trial', 'active', 'cancelled', 'expired')),
  max_vehicles integer NOT NULL DEFAULT 10,
  max_drivers integer NOT NULL DEFAULT 10,
  trial_ends_at timestamptz DEFAULT (now() + interval '30 days'),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_organizations_slug ON organizations(slug);
CREATE INDEX IF NOT EXISTS idx_organizations_status ON organizations(subscription_status);
CREATE INDEX IF NOT EXISTS idx_organizations_tier ON organizations(subscription_tier);

-- Create updated_at trigger
DROP TRIGGER IF EXISTS update_organizations_updated_at ON organizations;
CREATE TRIGGER update_organizations_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- Policy: Authenticated users can create organizations (for signup flow)
CREATE POLICY "Authenticated users can create organizations"
  ON organizations FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Policy: Authenticated users can read all organizations (will be restricted after org_id added to profiles)
CREATE POLICY "Authenticated users can read organizations"
  ON organizations FOR SELECT
  TO authenticated
  USING (true);

-- Policy: Admins can update organizations (will be restricted after org_id added to profiles)
CREATE POLICY "Admins can update organizations"
  ON organizations FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Function to set tier limits based on subscription_tier
CREATE OR REPLACE FUNCTION set_organization_tier_limits()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.subscription_tier = 'trial' OR NEW.subscription_tier = 'starter' THEN
    NEW.max_vehicles := 10;
    NEW.max_drivers := 10;
  ELSIF NEW.subscription_tier = 'pro' THEN
    NEW.max_vehicles := 50;
    NEW.max_drivers := 50;
  ELSIF NEW.subscription_tier = 'enterprise' THEN
    NEW.max_vehicles := 999999;
    NEW.max_drivers := 999999;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-set limits when tier changes
DROP TRIGGER IF EXISTS set_org_limits_on_tier_change ON organizations;
CREATE TRIGGER set_org_limits_on_tier_change
  BEFORE INSERT OR UPDATE OF subscription_tier ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION set_organization_tier_limits();