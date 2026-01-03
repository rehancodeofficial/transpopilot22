/*
  # Optimize GPS Tracking RLS Policies
  
  ## Overview
  Optimizes the gps_tracking table RLS policies to prevent re-evaluation of auth.uid() 
  for each row. This significantly improves query performance at scale.
  
  ## Changes
  - Drops existing policies that use auth.uid() directly
  - Recreates policies using (select auth.uid()) which is evaluated once per query
  
  ## Performance Impact
  - Prevents O(n) evaluation of auth.uid() where n = number of rows
  - Changes to O(1) evaluation - auth.uid() called once per query
  - Significantly improves performance for queries returning many rows
  
  ## Security
  - Maintains the same security model
  - Still restricts access to organization-scoped data
  - Service role maintains full access for edge functions
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view GPS tracking in their organization" ON gps_tracking;
DROP POLICY IF EXISTS "Users can insert GPS tracking data" ON gps_tracking;

-- Recreate optimized SELECT policy
CREATE POLICY "Users can view GPS tracking in their organization"
  ON gps_tracking FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM vehicles v
      INNER JOIN user_profiles up ON v.organization_id = up.organization_id
      WHERE v.id = gps_tracking.vehicle_id
      AND up.id = (select auth.uid())
    )
  );

-- Recreate optimized INSERT policy
CREATE POLICY "Users can insert GPS tracking data"
  ON gps_tracking FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM vehicles v
      INNER JOIN user_profiles up ON v.organization_id = up.organization_id
      WHERE v.id = gps_tracking.vehicle_id
      AND up.id = (select auth.uid())
    )
  );
