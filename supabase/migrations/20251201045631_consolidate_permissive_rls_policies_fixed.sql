/*
  # Consolidate Multiple Permissive RLS Policies - Security Fix

  This migration addresses security concerns by consolidating multiple permissive policies
  into single, well-defined policies that are easier to audit and maintain.
  
  ## Problem
  Multiple permissive policies for the same role and action create:
  1. Security audit complexity
  2. Potential for unintended access grants
  3. Performance overhead from evaluating multiple policies
  
  ## Tables Being Fixed (20 tables)
  
  1. app_performance_feedback - SELECT policies
  2. driver_locations - SELECT policies
  3. drivers - SELECT policies
  4. feedback_submissions - SELECT and UPDATE policies
  5. fuel_records - SELECT policies
  6. geofence_events - SELECT policies
  7. geofences - SELECT policies
  8. integration_credentials - SELECT policies
  9. integration_mappings - SELECT policies
  10. integration_providers - SELECT policies
  11. route_analytics - SELECT policies
  12. route_waypoints - SELECT policies
  13. routes - SELECT policies
  14. safety_incidents - SELECT policies
  15. testimonials - INSERT and SELECT policies
  16. user_profiles - INSERT policies
  17. vehicle_locations - SELECT policies
  18. vehicles - SELECT policies
  
  ## Approach
  Drop all conflicting policies and create single consolidated policies that:
  - Combine all legitimate access patterns
  - Use OR conditions to maintain existing functionality
  - Simplify security auditing
  - Improve query performance
*/

-- ============================================================================
-- APP PERFORMANCE FEEDBACK
-- ============================================================================
DROP POLICY IF EXISTS "Admins can view all performance feedback" ON app_performance_feedback;
DROP POLICY IF EXISTS "Users can view their own performance feedback" ON app_performance_feedback;

CREATE POLICY "Users can view relevant performance feedback"
  ON app_performance_feedback
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

-- ============================================================================
-- DRIVER LOCATIONS
-- ============================================================================
DROP POLICY IF EXISTS "Authenticated users can view driver locations" ON driver_locations;
DROP POLICY IF EXISTS "Fleet managers can read assigned driver locations" ON driver_locations;

CREATE POLICY "Users can view authorized driver locations"
  ON driver_locations
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM drivers
      WHERE drivers.id = driver_locations.driver_id
      AND drivers.organization_id IN (
        SELECT organization_id FROM user_profiles WHERE id = auth.uid()
      )
    ) OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'fleet_manager'
      AND EXISTS (
        SELECT 1 FROM fleet_manager_assignments
        WHERE fleet_manager_assignments.user_id = auth.uid()
        AND fleet_manager_assignments.driver_id = driver_locations.driver_id
      )
    )
  );

-- ============================================================================
-- DRIVERS
-- ============================================================================
DROP POLICY IF EXISTS "Fleet managers can read assigned drivers" ON drivers;
DROP POLICY IF EXISTS "Users can read own organization drivers" ON drivers;

CREATE POLICY "Users can view authorized drivers"
  ON drivers
  FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    ) OR
    (
      EXISTS (
        SELECT 1 FROM user_profiles
        WHERE user_profiles.id = auth.uid()
        AND user_profiles.role = 'fleet_manager'
      ) AND
      EXISTS (
        SELECT 1 FROM fleet_manager_assignments
        WHERE fleet_manager_assignments.user_id = auth.uid()
        AND fleet_manager_assignments.driver_id = drivers.id
      )
    )
  );

-- ============================================================================
-- FEEDBACK SUBMISSIONS
-- ============================================================================
DROP POLICY IF EXISTS "Admins can view all feedback submissions" ON feedback_submissions;
DROP POLICY IF EXISTS "Users can view their own feedback submissions" ON feedback_submissions;

CREATE POLICY "Users can view relevant feedback submissions"
  ON feedback_submissions
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "Admins can update all feedback submissions" ON feedback_submissions;
DROP POLICY IF EXISTS "Users can update their own pending feedback" ON feedback_submissions;

CREATE POLICY "Users can update authorized feedback submissions"
  ON feedback_submissions
  FOR UPDATE
  TO authenticated
  USING (
    (user_id = auth.uid() AND status = 'pending') OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

-- ============================================================================
-- FUEL RECORDS
-- ============================================================================
DROP POLICY IF EXISTS "Allow authenticated users to read fuel_records" ON fuel_records;
DROP POLICY IF EXISTS "Fleet managers can read assigned fuel records" ON fuel_records;

CREATE POLICY "Users can view authorized fuel records"
  ON fuel_records
  FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    ) OR
    (
      EXISTS (
        SELECT 1 FROM user_profiles
        WHERE user_profiles.id = auth.uid()
        AND user_profiles.role = 'fleet_manager'
      ) AND
      EXISTS (
        SELECT 1 FROM fleet_manager_assignments
        WHERE fleet_manager_assignments.user_id = auth.uid()
        AND (
          fleet_manager_assignments.vehicle_id = fuel_records.vehicle_id OR
          fleet_manager_assignments.driver_id = fuel_records.driver_id
        )
      )
    )
  );

-- ============================================================================
-- GEOFENCE EVENTS
-- ============================================================================
DROP POLICY IF EXISTS "Authenticated users can view geofence events" ON geofence_events;
DROP POLICY IF EXISTS "Fleet managers can read assigned geofence events" ON geofence_events;

CREATE POLICY "Users can view authorized geofence events"
  ON geofence_events
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM geofences
      WHERE geofences.id = geofence_events.geofence_id
      AND geofences.organization_id IN (
        SELECT organization_id FROM user_profiles WHERE id = auth.uid()
      )
    ) OR
    (
      EXISTS (
        SELECT 1 FROM user_profiles
        WHERE user_profiles.id = auth.uid()
        AND user_profiles.role = 'fleet_manager'
      ) AND
      EXISTS (
        SELECT 1 FROM fleet_manager_assignments
        WHERE fleet_manager_assignments.user_id = auth.uid()
        AND fleet_manager_assignments.vehicle_id = geofence_events.vehicle_id
      )
    )
  );

-- ============================================================================
-- GEOFENCES
-- ============================================================================
DROP POLICY IF EXISTS "Admin users can manage geofences" ON geofences;
DROP POLICY IF EXISTS "Authenticated users can view geofences" ON geofences;

CREATE POLICY "Users can view geofences"
  ON geofences
  FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    )
  );

-- ============================================================================
-- INTEGRATION CREDENTIALS
-- ============================================================================
DROP POLICY IF EXISTS "Admin users can manage credentials" ON integration_credentials;
DROP POLICY IF EXISTS "Admin users can view credentials" ON integration_credentials;

CREATE POLICY "Admins can view integration credentials"
  ON integration_credentials
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
      AND user_profiles.organization_id = integration_credentials.organization_id
    )
  );

-- ============================================================================
-- INTEGRATION MAPPINGS
-- ============================================================================
DROP POLICY IF EXISTS "Admin users can manage mappings" ON integration_mappings;
DROP POLICY IF EXISTS "Admin users can view mappings" ON integration_mappings;

CREATE POLICY "Admins can view integration mappings"
  ON integration_mappings
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

-- ============================================================================
-- INTEGRATION PROVIDERS
-- ============================================================================
DROP POLICY IF EXISTS "Admin users can manage integration providers" ON integration_providers;
DROP POLICY IF EXISTS "Admin users can view integration providers" ON integration_providers;

CREATE POLICY "Users can view integration providers"
  ON integration_providers
  FOR SELECT
  TO authenticated
  USING (true);

-- ============================================================================
-- ROUTE ANALYTICS
-- ============================================================================
DROP POLICY IF EXISTS "Authenticated users can view route analytics" ON route_analytics;
DROP POLICY IF EXISTS "Fleet managers can read assigned route analytics" ON route_analytics;

CREATE POLICY "Users can view authorized route analytics"
  ON route_analytics
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM routes
      WHERE routes.id = route_analytics.route_id
      AND routes.organization_id IN (
        SELECT organization_id FROM user_profiles WHERE id = auth.uid()
      )
    ) OR
    (
      EXISTS (
        SELECT 1 FROM user_profiles
        WHERE user_profiles.id = auth.uid()
        AND user_profiles.role = 'fleet_manager'
      ) AND
      EXISTS (
        SELECT 1 FROM routes
        JOIN fleet_manager_assignments ON (
          fleet_manager_assignments.vehicle_id = routes.vehicle_id OR
          fleet_manager_assignments.driver_id = routes.driver_id
        )
        WHERE routes.id = route_analytics.route_id
        AND fleet_manager_assignments.user_id = auth.uid()
      )
    )
  );

-- ============================================================================
-- ROUTE WAYPOINTS
-- ============================================================================
DROP POLICY IF EXISTS "Admin users can manage waypoints" ON route_waypoints;
DROP POLICY IF EXISTS "Authenticated users can view waypoints" ON route_waypoints;
DROP POLICY IF EXISTS "Fleet managers can read assigned route waypoints" ON route_waypoints;

CREATE POLICY "Users can view authorized route waypoints"
  ON route_waypoints
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM routes
      WHERE routes.id = route_waypoints.route_id
      AND routes.organization_id IN (
        SELECT organization_id FROM user_profiles WHERE id = auth.uid()
      )
    ) OR
    (
      EXISTS (
        SELECT 1 FROM user_profiles
        WHERE user_profiles.id = auth.uid()
        AND user_profiles.role = 'fleet_manager'
      ) AND
      EXISTS (
        SELECT 1 FROM routes
        JOIN fleet_manager_assignments ON (
          fleet_manager_assignments.vehicle_id = routes.vehicle_id OR
          fleet_manager_assignments.driver_id = routes.driver_id
        )
        WHERE routes.id = route_waypoints.route_id
        AND fleet_manager_assignments.user_id = auth.uid()
      )
    )
  );

-- ============================================================================
-- ROUTES
-- ============================================================================
DROP POLICY IF EXISTS "Fleet managers can read assigned routes" ON routes;
DROP POLICY IF EXISTS "Users can read own organization routes" ON routes;

CREATE POLICY "Users can view authorized routes"
  ON routes
  FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    ) OR
    (
      EXISTS (
        SELECT 1 FROM user_profiles
        WHERE user_profiles.id = auth.uid()
        AND user_profiles.role = 'fleet_manager'
      ) AND
      EXISTS (
        SELECT 1 FROM fleet_manager_assignments
        WHERE fleet_manager_assignments.user_id = auth.uid()
        AND (
          fleet_manager_assignments.vehicle_id = routes.vehicle_id OR
          fleet_manager_assignments.driver_id = routes.driver_id
        )
      )
    )
  );

-- ============================================================================
-- SAFETY INCIDENTS
-- ============================================================================
DROP POLICY IF EXISTS "Allow authenticated users to read safety_incidents" ON safety_incidents;
DROP POLICY IF EXISTS "Fleet managers can read assigned safety incidents" ON safety_incidents;

CREATE POLICY "Users can view authorized safety incidents"
  ON safety_incidents
  FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    ) OR
    (
      EXISTS (
        SELECT 1 FROM user_profiles
        WHERE user_profiles.id = auth.uid()
        AND user_profiles.role = 'fleet_manager'
      ) AND
      EXISTS (
        SELECT 1 FROM fleet_manager_assignments
        WHERE fleet_manager_assignments.user_id = auth.uid()
        AND (
          fleet_manager_assignments.vehicle_id = safety_incidents.vehicle_id OR
          fleet_manager_assignments.driver_id = safety_incidents.driver_id
        )
      )
    )
  );

-- ============================================================================
-- TESTIMONIALS
-- ============================================================================
DROP POLICY IF EXISTS "Admins can manage all testimonials" ON testimonials;
DROP POLICY IF EXISTS "Users can create testimonials" ON testimonials;

CREATE POLICY "Users can create testimonials"
  ON testimonials
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Anyone can view approved testimonials" ON testimonials;
DROP POLICY IF EXISTS "Authenticated users can view all testimonials" ON testimonials;

CREATE POLICY "Users can view testimonials"
  ON testimonials
  FOR SELECT
  TO authenticated
  USING (
    approval_status = 'approved' OR
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

-- ============================================================================
-- USER PROFILES
-- ============================================================================
DROP POLICY IF EXISTS "Allow profile creation during signup trigger" ON user_profiles;
DROP POLICY IF EXISTS "Authenticated users can insert own profile" ON user_profiles;

CREATE POLICY "Users can create own profile"
  ON user_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- ============================================================================
-- VEHICLE LOCATIONS
-- ============================================================================
DROP POLICY IF EXISTS "Authenticated users can view vehicle locations" ON vehicle_locations;
DROP POLICY IF EXISTS "Fleet managers can read assigned vehicle locations" ON vehicle_locations;

CREATE POLICY "Users can view authorized vehicle locations"
  ON vehicle_locations
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM vehicles
      WHERE vehicles.id = vehicle_locations.vehicle_id
      AND vehicles.organization_id IN (
        SELECT organization_id FROM user_profiles WHERE id = auth.uid()
      )
    ) OR
    (
      EXISTS (
        SELECT 1 FROM user_profiles
        WHERE user_profiles.id = auth.uid()
        AND user_profiles.role = 'fleet_manager'
      ) AND
      EXISTS (
        SELECT 1 FROM fleet_manager_assignments
        WHERE fleet_manager_assignments.user_id = auth.uid()
        AND fleet_manager_assignments.vehicle_id = vehicle_locations.vehicle_id
      )
    )
  );

-- ============================================================================
-- VEHICLES
-- ============================================================================
DROP POLICY IF EXISTS "Fleet managers can read assigned vehicles" ON vehicles;
DROP POLICY IF EXISTS "Users can read own organization vehicles" ON vehicles;

CREATE POLICY "Users can view authorized vehicles"
  ON vehicles
  FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    ) OR
    (
      EXISTS (
        SELECT 1 FROM user_profiles
        WHERE user_profiles.id = auth.uid()
        AND user_profiles.role = 'fleet_manager'
      ) AND
      EXISTS (
        SELECT 1 FROM fleet_manager_assignments
        WHERE fleet_manager_assignments.user_id = auth.uid()
        AND fleet_manager_assignments.vehicle_id = vehicles.id
      )
    )
  );
