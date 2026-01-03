/*
  # Remove Organizations - Step 2c: Drop Organization-Based Policies

  ## Overview
  Drops the specific organization-based RLS policies that exist in the database.

  ## Changes
  1. Drop organization-based policies from vehicles table
  2. Drop organization-based policies from drivers table
  3. Drop organization-based policies from routes table

  ## Security
  - Tables remain protected by RLS being enabled
  - Existing non-organization policies remain active
  - New simplified policies will be added after

  ## Important Notes
  - Only drops the organization-specific policies
  - Preserves other existing policies
*/

-- Drop vehicles organization policies
DROP POLICY IF EXISTS "Users can read vehicles in their organization" ON vehicles;
DROP POLICY IF EXISTS "Users can insert vehicles in their organization" ON vehicles;
DROP POLICY IF EXISTS "Users can update vehicles in their organization" ON vehicles;

-- Drop drivers organization policies
DROP POLICY IF EXISTS "Users can read drivers in their organization" ON drivers;
DROP POLICY IF EXISTS "Users can insert drivers in their organization" ON drivers;
DROP POLICY IF EXISTS "Users can update drivers in their organization" ON drivers;

-- Drop routes organization policies
DROP POLICY IF EXISTS "Users can read routes in their organization" ON routes;
DROP POLICY IF EXISTS "Users can insert routes in their organization" ON routes;
DROP POLICY IF EXISTS "Users can update routes in their organization" ON routes;