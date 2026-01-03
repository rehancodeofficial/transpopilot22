/*
  # Optimize RLS Policies - Part 2 (Integration & Admin Tables)
  
  Wraps auth.uid() calls with SELECT for integration and admin tables
*/

-- integration_providers table
DROP POLICY IF EXISTS "Admin users can view integration providers" ON integration_providers;
CREATE POLICY "Admin users can view integration providers"
  ON integration_providers FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "Admin users can manage integration providers" ON integration_providers;
CREATE POLICY "Admin users can manage integration providers"
  ON integration_providers FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- integration_credentials table
DROP POLICY IF EXISTS "Admin users can view credentials" ON integration_credentials;
CREATE POLICY "Admin users can view credentials"
  ON integration_credentials FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "Admin users can manage credentials" ON integration_credentials;
CREATE POLICY "Admin users can manage credentials"
  ON integration_credentials FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- integration_sync_logs table
DROP POLICY IF EXISTS "Admin users can view sync logs" ON integration_sync_logs;
CREATE POLICY "Admin users can view sync logs"
  ON integration_sync_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "Admin users can update sync logs" ON integration_sync_logs;
CREATE POLICY "Admin users can update sync logs"
  ON integration_sync_logs FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- integration_mappings table
DROP POLICY IF EXISTS "Admin users can view mappings" ON integration_mappings;
CREATE POLICY "Admin users can view mappings"
  ON integration_mappings FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "Admin users can manage mappings" ON integration_mappings;
CREATE POLICY "Admin users can manage mappings"
  ON integration_mappings FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- webhook_configurations table
DROP POLICY IF EXISTS "Admin users can manage webhooks" ON webhook_configurations;
CREATE POLICY "Admin users can manage webhooks"
  ON webhook_configurations FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- geofences table
DROP POLICY IF EXISTS "Admin users can manage geofences" ON geofences;
CREATE POLICY "Admin users can manage geofences"
  ON geofences FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- route_waypoints table
DROP POLICY IF EXISTS "Admin users can manage waypoints" ON route_waypoints;
CREATE POLICY "Admin users can manage waypoints"
  ON route_waypoints FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );