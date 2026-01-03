/*
  # Optimize RLS Policies - Part 4 (Security & Monitoring Tables)
  
  Wraps auth.uid() calls with SELECT for security audit and monitoring tables
*/

-- security_audit_logs table
DROP POLICY IF EXISTS "Only admins can view audit logs" ON security_audit_logs;
CREATE POLICY "Only admins can view audit logs"
  ON security_audit_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- access_control_logs table
DROP POLICY IF EXISTS "Only admins can view access logs" ON access_control_logs;
CREATE POLICY "Only admins can view access logs"
  ON access_control_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- login_attempts table
DROP POLICY IF EXISTS "Only admins can view login attempts" ON login_attempts;
CREATE POLICY "Only admins can view login attempts"
  ON login_attempts FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- data_encryption_logs table
DROP POLICY IF EXISTS "Only admins can view encryption logs" ON data_encryption_logs;
CREATE POLICY "Only admins can view encryption logs"
  ON data_encryption_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- ai_model_retraining_logs table
DROP POLICY IF EXISTS "Admins can view retraining logs" ON ai_model_retraining_logs;
CREATE POLICY "Admins can view retraining logs"
  ON ai_model_retraining_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- ai_ab_test_results table
DROP POLICY IF EXISTS "Admins can view A/B test results" ON ai_ab_test_results;
CREATE POLICY "Admins can view A/B test results"
  ON ai_ab_test_results FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- system_alerts table
DROP POLICY IF EXISTS "Admins can update alerts" ON system_alerts;
CREATE POLICY "Admins can update alerts"
  ON system_alerts FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- data_anomalies table
DROP POLICY IF EXISTS "Admins can update anomalies" ON data_anomalies;
CREATE POLICY "Admins can update anomalies"
  ON data_anomalies FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- hours_of_service_violations table
DROP POLICY IF EXISTS "Admins can update HOS violations" ON hours_of_service_violations;
CREATE POLICY "Admins can update HOS violations"
  ON hours_of_service_violations FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- certification_tracking table
DROP POLICY IF EXISTS "Admins can update certifications" ON certification_tracking;
CREATE POLICY "Admins can update certifications"
  ON certification_tracking FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- vehicle_inspection_records table
DROP POLICY IF EXISTS "Admins can update inspections" ON vehicle_inspection_records;
CREATE POLICY "Admins can update inspections"
  ON vehicle_inspection_records FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- safety_incident_reports table
DROP POLICY IF EXISTS "Admins can update incident reports" ON safety_incident_reports;
CREATE POLICY "Admins can update incident reports"
  ON safety_incident_reports FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- vehicle_locations table
DROP POLICY IF EXISTS "Admin users can insert vehicle locations" ON vehicle_locations;
CREATE POLICY "Admin users can insert vehicle locations"
  ON vehicle_locations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- driver_locations table
DROP POLICY IF EXISTS "Admin users can insert driver locations" ON driver_locations;
CREATE POLICY "Admin users can insert driver locations"
  ON driver_locations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- admin_users table
DROP POLICY IF EXISTS "Admin users can read all users" ON admin_users;
CREATE POLICY "Admin users can read all users"
  ON admin_users FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = (SELECT auth.uid()) AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Users can update own profile" ON admin_users;
CREATE POLICY "Users can update own profile"
  ON admin_users FOR UPDATE
  TO authenticated
  USING (id = (SELECT auth.uid()))
  WITH CHECK (id = (SELECT auth.uid()));