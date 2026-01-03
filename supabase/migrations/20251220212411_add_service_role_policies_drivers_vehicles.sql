/*
  # Add Service Role Policies for Drivers and Vehicles
  
  ## Overview
  Adds service role policies to drivers and vehicles tables to allow
  the seed_user_demo_data function to insert demo data during signup.
  Without these policies, the demo data seeding fails due to RLS restrictions.
  
  ## Changes
  1. Adds service_role policy for drivers table
  2. Adds service_role policy for vehicles table
  
  ## Security Impact
  - Service role is only used by triggers and edge functions
  - Does not affect authenticated user policies
  - Maintains security while allowing system operations
*/

-- Add service role policy for drivers
DROP POLICY IF EXISTS "Service role can manage drivers" ON drivers;

CREATE POLICY "Service role can manage drivers"
  ON drivers FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Add service role policy for vehicles
DROP POLICY IF EXISTS "Service role can manage vehicles" ON vehicles;

CREATE POLICY "Service role can manage vehicles"
  ON vehicles FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
