/*
  # Create Organizations and User Profiles Tables

  ## Overview
  Creates the core tables for multi-tenancy support with organizations and user profiles.
  Integrates with Supabase Auth for role-based access control.

  ## New Tables

  ### `organizations`
  - `id` (uuid, primary key) - Unique organization identifier
  - `name` (text, required) - Organization/company name
  - `slug` (text, unique) - URL-friendly organization identifier
  - `subscription_tier` (text) - Subscription plan: 'starter', 'pro', 'enterprise'
  - `subscription_status` (text) - Status: 'trial', 'active', 'cancelled', 'expired'
  - `max_vehicles` (integer) - Maximum vehicles allowed based on tier
  - `max_drivers` (integer) - Maximum drivers allowed based on tier
  - `trial_ends_at` (timestamptz) - When trial period ends
  - `created_at` (timestamptz) - Organization creation date
  - `updated_at` (timestamptz) - Last update timestamp

  ### `user_profiles`
  - `id` (uuid, primary key, references auth.users) - User ID from Supabase Auth
  - `organization_id` (uuid, foreign key) - User's organization
  - `role` (text) - User role: 'user', 'admin', 'super_admin'
  - `full_name` (text) - User's full name
  - `avatar_url` (text) - Profile picture URL
  - `phone` (text) - Contact phone number
  - `last_login_at` (timestamptz) - Last login timestamp
  - `created_at` (timestamptz) - Account creation date
  - `updated_at` (timestamptz) - Last profile update

  ## Security
  - Enable RLS on both tables
  - Users can read their own profile
  - Users can read their organization's info
  - Admins can manage users in their organization
  - Super admins can access everything

  ## Important Notes
  - user_profiles.id directly references auth.users(id) for seamless integration
  - Role is stored both in user_profiles and auth metadata for security
  - Organization_id is also stored in auth metadata for RLS policies
  - Trigger automatically creates user_profile when auth user is created
*/

-- Create organizations table
CREATE TABLE IF NOT EXISTS organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text UNIQUE NOT NULL,
  subscription_tier text NOT NULL DEFAULT 'starter' CHECK (subscription_tier IN ('starter', 'pro', 'enterprise')),
  subscription_status text NOT NULL DEFAULT 'trial' CHECK (subscription_status IN ('trial', 'active', 'cancelled', 'expired')),
  max_vehicles integer NOT NULL DEFAULT 10,
  max_drivers integer NOT NULL DEFAULT 10,
  trial_ends_at timestamptz DEFAULT (now() + interval '30 days'),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin', 'super_admin')),
  full_name text NOT NULL,
  avatar_url text,
  phone text,
  last_login_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_organizations_slug ON organizations(slug);
CREATE INDEX IF NOT EXISTS idx_organizations_status ON organizations(subscription_status);
CREATE INDEX IF NOT EXISTS idx_user_profiles_org ON user_profiles(organization_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);

-- Create updated_at trigger for organizations
DROP TRIGGER IF EXISTS update_organizations_updated_at ON organizations;
CREATE TRIGGER update_organizations_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create updated_at trigger for user_profiles
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, organization_id, role, full_name)
  VALUES (
    NEW.id,
    (NEW.raw_user_meta_data->>'organization_id')::uuid,
    COALESCE(NEW.raw_user_meta_data->>'role', 'user'),
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create user profile
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Enable Row Level Security
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Organizations Policies

-- Users can read their own organization
CREATE POLICY "Users can read own organization"
  ON organizations FOR SELECT
  TO authenticated
  USING (
    id = (
      SELECT organization_id 
      FROM user_profiles 
      WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- Admins can update their organization
CREATE POLICY "Admins can update own organization"
  ON organizations FOR UPDATE
  TO authenticated
  USING (
    id = (
      SELECT organization_id 
      FROM user_profiles 
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    id = (
      SELECT organization_id 
      FROM user_profiles 
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Super admins can insert organizations
CREATE POLICY "Super admins can create organizations"
  ON organizations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- User Profiles Policies

-- Users can read their own profile
CREATE POLICY "Users can read own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Admins can read profiles in their organization
CREATE POLICY "Admins can read org profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (
    organization_id = (
      SELECT organization_id 
      FROM user_profiles 
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
    OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- Users can update their own profile (except role)
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid() 
    AND role = (SELECT role FROM user_profiles WHERE id = auth.uid())
  );

-- Admins can update profiles in their organization
CREATE POLICY "Admins can update org profiles"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (
    organization_id = (
      SELECT organization_id 
      FROM user_profiles 
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    organization_id = (
      SELECT organization_id 
      FROM user_profiles 
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Super admins can insert any profile
CREATE POLICY "Super admins can create profiles"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );