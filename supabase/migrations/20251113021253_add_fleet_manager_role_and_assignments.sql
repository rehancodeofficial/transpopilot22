/*
  # Add Fleet Manager Role and Fleet Assignments

  ## Overview
  Adds fleet_manager role to the system and creates a fleet assignment mechanism
  to scope fleet managers to specific vehicles and drivers.

  ## Changes

  ### 1. Update user_profiles role enum
  - Adds 'fleet_manager' as a valid role option
  - Existing roles: 'user', 'admin', 'super_admin', 'fleet_manager'

  ### 2. New Table: fleet_manager_assignments
  - `id` (uuid, primary key) - Assignment identifier
  - `user_id` (uuid, foreign key) - References user_profiles.id
  - `vehicle_id` (uuid, foreign key, nullable) - Assigned vehicle
  - `driver_id` (uuid, foreign key, nullable) - Assigned driver
  - `assigned_at` (timestamptz) - When assignment was made
  - `assigned_by` (uuid, foreign key) - Who made the assignment (super_admin)
  - `is_active` (boolean) - Whether assignment is currently active
  - `created_at` (timestamptz) - Record creation timestamp

  ### 3. Helper Functions
  - `get_user_assigned_vehicles()` - Returns vehicle IDs assigned to current user
  - `get_user_assigned_drivers()` - Returns driver IDs assigned to current user
  - `is_fleet_manager()` - Checks if current user is a fleet manager

  ## Security
  - Enable RLS on fleet_manager_assignments table
  - Fleet managers can read their own assignments
  - Super admins can manage all assignments
  - Data access is scoped by fleet assignments in other tables

  ## Important Notes
  - Fleet managers can be assigned to multiple vehicles and drivers
  - Assignments can be deactivated without deletion for audit purposes
  - Super admins have access to all data regardless of assignments
  - Regular admins and users are not affected by this change
*/

-- Step 1: Add fleet_manager to role enum
-- We need to alter the check constraint on user_profiles table
ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS user_profiles_role_check;
ALTER TABLE user_profiles ADD CONSTRAINT user_profiles_role_check 
  CHECK (role IN ('user', 'admin', 'super_admin', 'fleet_manager'));

-- Step 2: Create fleet_manager_assignments table
CREATE TABLE IF NOT EXISTS fleet_manager_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  vehicle_id uuid REFERENCES vehicles(id) ON DELETE CASCADE,
  driver_id uuid REFERENCES drivers(id) ON DELETE CASCADE,
  assigned_at timestamptz DEFAULT now(),
  assigned_by uuid REFERENCES user_profiles(id),
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  
  -- Ensure at least one assignment type (vehicle or driver)
  CONSTRAINT at_least_one_assignment CHECK (vehicle_id IS NOT NULL OR driver_id IS NOT NULL)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_fleet_manager_assignments_user ON fleet_manager_assignments(user_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_fleet_manager_assignments_vehicle ON fleet_manager_assignments(vehicle_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_fleet_manager_assignments_driver ON fleet_manager_assignments(driver_id) WHERE is_active = true;

-- Step 3: Enable RLS
ALTER TABLE fleet_manager_assignments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for fleet_manager_assignments

-- Fleet managers can read their own assignments
CREATE POLICY "Fleet managers can read own assignments"
  ON fleet_manager_assignments FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- Super admins can insert assignments
CREATE POLICY "Super admins can create assignments"
  ON fleet_manager_assignments FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- Super admins can update assignments
CREATE POLICY "Super admins can update assignments"
  ON fleet_manager_assignments FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- Super admins can delete assignments
CREATE POLICY "Super admins can delete assignments"
  ON fleet_manager_assignments FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- Step 4: Create helper functions

-- Function to get vehicle IDs assigned to current user
CREATE OR REPLACE FUNCTION get_user_assigned_vehicles()
RETURNS TABLE(vehicle_id uuid) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT fma.vehicle_id
  FROM fleet_manager_assignments fma
  WHERE fma.user_id = auth.uid()
    AND fma.is_active = true
    AND fma.vehicle_id IS NOT NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get driver IDs assigned to current user
CREATE OR REPLACE FUNCTION get_user_assigned_drivers()
RETURNS TABLE(driver_id uuid) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT fma.driver_id
  FROM fleet_manager_assignments fma
  WHERE fma.user_id = auth.uid()
    AND fma.is_active = true
    AND fma.driver_id IS NOT NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user is a fleet manager
CREATE OR REPLACE FUNCTION is_fleet_manager()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() AND role = 'fleet_manager'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user is super admin
CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() AND role = 'super_admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;