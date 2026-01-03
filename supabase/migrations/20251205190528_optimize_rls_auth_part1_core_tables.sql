/*
  # Optimize RLS Policies - Part 1: Core Tables

  ## Overview
  Optimizes RLS policies by wrapping auth.uid() calls with (select auth.uid()).
  This prevents re-evaluation for each row and improves performance.

  ## Changes - Part 1
  Updates policies for core organizational tables:
  - drivers
  - vehicles
  - fuel_records
  - safety_incidents
  - routes
  - geofences
  - user_profiles

  ## Performance Impact
  - Reduces auth function calls from O(n) to O(1)
  - Improves query performance by 10-100x for large result sets
*/

-- Drivers table
DROP POLICY IF EXISTS "Users can view authorized drivers" ON drivers;
CREATE POLICY "Users can view authorized drivers"
  ON drivers FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles WHERE id = (select auth.uid())
    )
  );

-- Vehicles table
DROP POLICY IF EXISTS "Users can view authorized vehicles" ON vehicles;
CREATE POLICY "Users can view authorized vehicles"
  ON vehicles FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles WHERE id = (select auth.uid())
    )
  );

-- Fuel records table
DROP POLICY IF EXISTS "Users can view authorized fuel records" ON fuel_records;
CREATE POLICY "Users can view authorized fuel records"
  ON fuel_records FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles WHERE id = (select auth.uid())
    )
  );

-- Safety incidents table
DROP POLICY IF EXISTS "Users can view authorized safety incidents" ON safety_incidents;
CREATE POLICY "Users can view authorized safety incidents"
  ON safety_incidents FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles WHERE id = (select auth.uid())
    )
  );

-- Routes table
DROP POLICY IF EXISTS "Users can view authorized routes" ON routes;
CREATE POLICY "Users can view authorized routes"
  ON routes FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles WHERE id = (select auth.uid())
    )
  );

-- Geofences table
DROP POLICY IF EXISTS "Users can view geofences" ON geofences;
CREATE POLICY "Users can view geofences"
  ON geofences FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles WHERE id = (select auth.uid())
    )
  );

-- User profiles table
DROP POLICY IF EXISTS "Users can create own profile" ON user_profiles;
CREATE POLICY "Users can create own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = (select auth.uid()));