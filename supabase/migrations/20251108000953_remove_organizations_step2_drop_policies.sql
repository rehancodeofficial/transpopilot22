/*
  # Remove Organizations - Step 2: Drop Organization-Based Policies

  ## Overview
  Drops all RLS policies that reference organizations before removing the columns.

  ## Changes
  1. Drop organization-related policies from organizations table
  2. Drop organization-related policies from user_profiles table
  3. Drop organization-related policies from vehicles table
  4. Drop organization-related policies from drivers table
  5. Drop organization-related policies from routes table

  ## Security
  - Temporarily disables organization-based access control
  - New simplified policies will be added in next step
  - Tables remain protected by RLS being enabled

  ## Important Notes
  - This must happen before dropping columns to avoid policy errors
  - New role-based policies will replace these
*/

-- Drop organizations table policies
DROP POLICY IF EXISTS "Users can read own organization" ON organizations;
DROP POLICY IF EXISTS "Admins can update own organization" ON organizations;
DROP POLICY IF EXISTS "Super admins can create organizations" ON organizations;

-- Drop user_profiles organization-related policies
DROP POLICY IF EXISTS "Admins can read org profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update org profiles" ON user_profiles;
DROP POLICY IF EXISTS "Super admins can create profiles" ON user_profiles;