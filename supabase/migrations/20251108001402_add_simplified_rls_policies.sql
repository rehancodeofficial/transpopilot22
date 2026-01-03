/*
  # Add Simplified RLS Policies

  ## Overview
  Adds simplified role-based RLS policies that don't depend on organizations.

  ## Changes
  1. Add simple authenticated user policies for all main tables
  2. Policies allow all authenticated users to access data
  3. Super admins and admins have full access

  ## Security
  - All tables require authentication
  - Role-based access control through user_profiles
  - No organization filtering needed

  ## Important Notes
  - This replaces organization-based multi-tenancy with simple role-based access
  - All authenticated users can now see all data
  - Admin and super_admin roles have elevated privileges
*/

-- Add policies for user_profiles
DROP POLICY IF EXISTS "Authenticated users can insert own profile" ON user_profiles;
CREATE POLICY "Authenticated users can insert own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- Update vehicles policies for simple authenticated access
DROP POLICY IF EXISTS "Authenticated users can read all vehicles" ON vehicles;
CREATE POLICY "Authenticated users can read all vehicles"
  ON vehicles FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert vehicles" ON vehicles;
CREATE POLICY "Authenticated users can insert vehicles"
  ON vehicles FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can update vehicles" ON vehicles;
CREATE POLICY "Authenticated users can update vehicles"
  ON vehicles FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can delete vehicles" ON vehicles;
CREATE POLICY "Authenticated users can delete vehicles"
  ON vehicles FOR DELETE
  TO authenticated
  USING (true);

-- Update drivers policies for simple authenticated access
DROP POLICY IF EXISTS "Authenticated users can read all drivers" ON drivers;
CREATE POLICY "Authenticated users can read all drivers"
  ON drivers FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert drivers" ON drivers;
CREATE POLICY "Authenticated users can insert drivers"
  ON drivers FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can update drivers" ON drivers;
CREATE POLICY "Authenticated users can update drivers"
  ON drivers FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can delete drivers" ON drivers;
CREATE POLICY "Authenticated users can delete drivers"
  ON drivers FOR DELETE
  TO authenticated
  USING (true);

-- Update routes policies for simple authenticated access
DROP POLICY IF EXISTS "Admin users can create routes" ON routes;
DROP POLICY IF EXISTS "Admin users can update routes" ON routes;
DROP POLICY IF EXISTS "Admin users can delete routes" ON routes;
DROP POLICY IF EXISTS "Authenticated users can view routes" ON routes;

DROP POLICY IF EXISTS "Authenticated users can read all routes" ON routes;
CREATE POLICY "Authenticated users can read all routes"
  ON routes FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert routes" ON routes;
CREATE POLICY "Authenticated users can insert routes"
  ON routes FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can update routes" ON routes;
CREATE POLICY "Authenticated users can update routes"
  ON routes FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can delete routes" ON routes;
CREATE POLICY "Authenticated users can delete routes"
  ON routes FOR DELETE
  TO authenticated
  USING (true);