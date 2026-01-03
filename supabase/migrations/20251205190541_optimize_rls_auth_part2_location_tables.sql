/*
  # Optimize RLS Policies - Part 2: Location & Events Tables

  ## Overview
  Optimizes RLS policies for location tracking and event tables.

  ## Changes - Part 2
  Updates policies for location and event tables:
  - vehicle_locations
  - driver_locations
  - geofence_events
  - route_waypoints
  - route_analytics

  ## Performance Impact
  - Reduces auth function re-evaluation
  - Improves JOIN performance
*/

-- Vehicle locations table
DROP POLICY IF EXISTS "Users can view authorized vehicle locations" ON vehicle_locations;
CREATE POLICY "Users can view authorized vehicle locations"
  ON vehicle_locations FOR SELECT
  TO authenticated
  USING (
    vehicle_id IN (
      SELECT v.id FROM vehicles v
      INNER JOIN user_profiles up ON v.organization_id = up.organization_id
      WHERE up.id = (select auth.uid())
    )
  );

-- Driver locations table
DROP POLICY IF EXISTS "Users can view authorized driver locations" ON driver_locations;
CREATE POLICY "Users can view authorized driver locations"
  ON driver_locations FOR SELECT
  TO authenticated
  USING (
    driver_id IN (
      SELECT d.id FROM drivers d
      INNER JOIN user_profiles up ON d.organization_id = up.organization_id
      WHERE up.id = (select auth.uid())
    )
  );

-- Geofence events table
DROP POLICY IF EXISTS "Users can view authorized geofence events" ON geofence_events;
CREATE POLICY "Users can view authorized geofence events"
  ON geofence_events FOR SELECT
  TO authenticated
  USING (
    vehicle_id IN (
      SELECT v.id FROM vehicles v
      INNER JOIN user_profiles up ON v.organization_id = up.organization_id
      WHERE up.id = (select auth.uid())
    )
  );

-- Route waypoints table
DROP POLICY IF EXISTS "Users can view authorized route waypoints" ON route_waypoints;
CREATE POLICY "Users can view authorized route waypoints"
  ON route_waypoints FOR SELECT
  TO authenticated
  USING (
    route_id IN (
      SELECT r.id FROM routes r
      INNER JOIN user_profiles up ON r.organization_id = up.organization_id
      WHERE up.id = (select auth.uid())
    )
  );

-- Route analytics table
DROP POLICY IF EXISTS "Users can view authorized route analytics" ON route_analytics;
CREATE POLICY "Users can view authorized route analytics"
  ON route_analytics FOR SELECT
  TO authenticated
  USING (
    route_id IN (
      SELECT r.id FROM routes r
      INNER JOIN user_profiles up ON r.organization_id = up.organization_id
      WHERE up.id = (select auth.uid())
    )
  );