/*
  # Update RLS Policies for Fleet Manager Access

  ## Overview
  Updates Row Level Security policies on key tables to scope data access
  for fleet managers based on their assigned vehicles and drivers.

  ## Modified Tables
  
  ### vehicles
  - Fleet managers can only see vehicles assigned to them
  - Super admins can see all vehicles
  - Regular users/admins maintain existing access
  
  ### drivers
  - Fleet managers can only see drivers assigned to them
  - Super admins can see all drivers
  - Regular users/admins maintain existing access
  
  ### vehicle_locations
  - Fleet managers can only see locations for their assigned vehicles
  - Super admins can see all locations
  
  ### driver_locations
  - Fleet managers can only see locations for their assigned drivers
  - Super admins can see all locations
  
  ### routes
  - Fleet managers can only see routes for their assigned vehicles/drivers
  - Super admins can see all routes
  
  ### fuel_records
  - Fleet managers can only see fuel records for their assigned vehicles
  - Super admins can see all records
  
  ### safety_incidents
  - Fleet managers can only see incidents for their assigned vehicles/drivers
  - Super admins can see all incidents

  ## Security Approach
  - Uses helper functions (is_super_admin(), is_fleet_manager()) for role checks
  - Uses get_user_assigned_vehicles() and get_user_assigned_drivers() for scoping
  - Super admins bypass all restrictions
  - Fleet managers are strictly scoped to their assignments

  ## Important Notes
  - Existing policies for regular users/admins are preserved
  - Fleet managers have read-only access by default
  - Super admins retain full access to all data
  - Policies are additive - fleet managers get additional SELECT policies
*/

-- ============================================
-- VEHICLES TABLE
-- ============================================

-- Drop existing fleet manager policies if they exist
DROP POLICY IF EXISTS "Fleet managers can read assigned vehicles" ON vehicles;

-- Fleet managers can read only their assigned vehicles
CREATE POLICY "Fleet managers can read assigned vehicles"
  ON vehicles FOR SELECT
  TO authenticated
  USING (
    is_super_admin()
    OR
    (is_fleet_manager() AND id IN (SELECT vehicle_id FROM get_user_assigned_vehicles()))
  );

-- ============================================
-- DRIVERS TABLE
-- ============================================

DROP POLICY IF EXISTS "Fleet managers can read assigned drivers" ON drivers;

-- Fleet managers can read only their assigned drivers
CREATE POLICY "Fleet managers can read assigned drivers"
  ON drivers FOR SELECT
  TO authenticated
  USING (
    is_super_admin()
    OR
    (is_fleet_manager() AND id IN (SELECT driver_id FROM get_user_assigned_drivers()))
  );

-- ============================================
-- VEHICLE_LOCATIONS TABLE
-- ============================================

DROP POLICY IF EXISTS "Fleet managers can read assigned vehicle locations" ON vehicle_locations;

-- Fleet managers can read locations for their assigned vehicles
CREATE POLICY "Fleet managers can read assigned vehicle locations"
  ON vehicle_locations FOR SELECT
  TO authenticated
  USING (
    is_super_admin()
    OR
    (is_fleet_manager() AND vehicle_id IN (SELECT vehicle_id FROM get_user_assigned_vehicles()))
  );

-- ============================================
-- DRIVER_LOCATIONS TABLE
-- ============================================

DROP POLICY IF EXISTS "Fleet managers can read assigned driver locations" ON driver_locations;

-- Fleet managers can read locations for their assigned drivers
CREATE POLICY "Fleet managers can read assigned driver locations"
  ON driver_locations FOR SELECT
  TO authenticated
  USING (
    is_super_admin()
    OR
    (is_fleet_manager() AND driver_id IN (SELECT driver_id FROM get_user_assigned_drivers()))
  );

-- ============================================
-- ROUTES TABLE
-- ============================================

DROP POLICY IF EXISTS "Fleet managers can read assigned routes" ON routes;

-- Fleet managers can read routes for their assigned vehicles/drivers
CREATE POLICY "Fleet managers can read assigned routes"
  ON routes FOR SELECT
  TO authenticated
  USING (
    is_super_admin()
    OR
    (is_fleet_manager() AND (
      vehicle_id IN (SELECT vehicle_id FROM get_user_assigned_vehicles())
      OR
      driver_id IN (SELECT driver_id FROM get_user_assigned_drivers())
    ))
  );

-- ============================================
-- FUEL_RECORDS TABLE
-- ============================================

DROP POLICY IF EXISTS "Fleet managers can read assigned fuel records" ON fuel_records;

-- Fleet managers can read fuel records for their assigned vehicles
CREATE POLICY "Fleet managers can read assigned fuel records"
  ON fuel_records FOR SELECT
  TO authenticated
  USING (
    is_super_admin()
    OR
    (is_fleet_manager() AND vehicle_id IN (SELECT vehicle_id FROM get_user_assigned_vehicles()))
  );

-- ============================================
-- SAFETY_INCIDENTS TABLE
-- ============================================

DROP POLICY IF EXISTS "Fleet managers can read assigned safety incidents" ON safety_incidents;

-- Fleet managers can read safety incidents for their assigned vehicles/drivers
CREATE POLICY "Fleet managers can read assigned safety incidents"
  ON safety_incidents FOR SELECT
  TO authenticated
  USING (
    is_super_admin()
    OR
    (is_fleet_manager() AND (
      vehicle_id IN (SELECT vehicle_id FROM get_user_assigned_vehicles())
      OR
      driver_id IN (SELECT driver_id FROM get_user_assigned_drivers())
    ))
  );

-- ============================================
-- ROUTE_WAYPOINTS TABLE
-- ============================================

DROP POLICY IF EXISTS "Fleet managers can read assigned route waypoints" ON route_waypoints;

-- Fleet managers can read waypoints for routes with their assigned vehicles/drivers
CREATE POLICY "Fleet managers can read assigned route waypoints"
  ON route_waypoints FOR SELECT
  TO authenticated
  USING (
    is_super_admin()
    OR
    (is_fleet_manager() AND route_id IN (
      SELECT id FROM routes WHERE 
        vehicle_id IN (SELECT vehicle_id FROM get_user_assigned_vehicles())
        OR
        driver_id IN (SELECT driver_id FROM get_user_assigned_drivers())
    ))
  );

-- ============================================
-- GEOFENCE_EVENTS TABLE
-- ============================================

DROP POLICY IF EXISTS "Fleet managers can read assigned geofence events" ON geofence_events;

-- Fleet managers can read geofence events for their assigned vehicles
CREATE POLICY "Fleet managers can read assigned geofence events"
  ON geofence_events FOR SELECT
  TO authenticated
  USING (
    is_super_admin()
    OR
    (is_fleet_manager() AND vehicle_id IN (SELECT vehicle_id FROM get_user_assigned_vehicles()))
  );

-- ============================================
-- ROUTE_ANALYTICS TABLE
-- ============================================

DROP POLICY IF EXISTS "Fleet managers can read assigned route analytics" ON route_analytics;

-- Fleet managers can read analytics for routes with their assigned vehicles/drivers
CREATE POLICY "Fleet managers can read assigned route analytics"
  ON route_analytics FOR SELECT
  TO authenticated
  USING (
    is_super_admin()
    OR
    (is_fleet_manager() AND route_id IN (
      SELECT id FROM routes WHERE 
        vehicle_id IN (SELECT vehicle_id FROM get_user_assigned_vehicles())
        OR
        driver_id IN (SELECT driver_id FROM get_user_assigned_drivers())
    ))
  );