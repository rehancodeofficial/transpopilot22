/*
  # Optimize RLS Policies - Part 3 (User-Specific Tables)
  
  Wraps auth.uid() calls with SELECT for user-specific data tables
*/

-- integration_sandbox_tests table
DROP POLICY IF EXISTS "Users can view their sandbox tests" ON integration_sandbox_tests;
CREATE POLICY "Users can view their sandbox tests"
  ON integration_sandbox_tests FOR SELECT
  TO authenticated
  USING (tested_by = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can create sandbox tests" ON integration_sandbox_tests;
CREATE POLICY "Users can create sandbox tests"
  ON integration_sandbox_tests FOR INSERT
  TO authenticated
  WITH CHECK (tested_by = (SELECT auth.uid()));

-- fleet_manager_assignments table
DROP POLICY IF EXISTS "Fleet managers can read own assignments" ON fleet_manager_assignments;
CREATE POLICY "Fleet managers can read own assignments"
  ON fleet_manager_assignments FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Super admins can create assignments" ON fleet_manager_assignments;
CREATE POLICY "Super admins can create assignments"
  ON fleet_manager_assignments FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role = 'super_admin'
    )
  );

DROP POLICY IF EXISTS "Super admins can update assignments" ON fleet_manager_assignments;
CREATE POLICY "Super admins can update assignments"
  ON fleet_manager_assignments FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role = 'super_admin'
    )
  );

DROP POLICY IF EXISTS "Super admins can delete assignments" ON fleet_manager_assignments;
CREATE POLICY "Super admins can delete assignments"
  ON fleet_manager_assignments FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role = 'super_admin'
    )
  );

-- feedback_submissions table
DROP POLICY IF EXISTS "Users can view their own feedback submissions" ON feedback_submissions;
CREATE POLICY "Users can view their own feedback submissions"
  ON feedback_submissions FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can create feedback submissions" ON feedback_submissions;
CREATE POLICY "Users can create feedback submissions"
  ON feedback_submissions FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can update their own pending feedback" ON feedback_submissions;
CREATE POLICY "Users can update their own pending feedback"
  ON feedback_submissions FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()) AND status = 'pending')
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Admins can view all feedback submissions" ON feedback_submissions;
CREATE POLICY "Admins can view all feedback submissions"
  ON feedback_submissions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "Admins can update all feedback submissions" ON feedback_submissions;
CREATE POLICY "Admins can update all feedback submissions"
  ON feedback_submissions FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- testimonials table
DROP POLICY IF EXISTS "Users can create testimonials" ON testimonials;
CREATE POLICY "Users can create testimonials"
  ON testimonials FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Admins can manage all testimonials" ON testimonials;
CREATE POLICY "Admins can manage all testimonials"
  ON testimonials FOR ALL
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

-- app_performance_feedback table
DROP POLICY IF EXISTS "Users can view their own performance feedback" ON app_performance_feedback;
CREATE POLICY "Users can view their own performance feedback"
  ON app_performance_feedback FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can create performance feedback" ON app_performance_feedback;
CREATE POLICY "Users can create performance feedback"
  ON app_performance_feedback FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Admins can view all performance feedback" ON app_performance_feedback;
CREATE POLICY "Admins can view all performance feedback"
  ON app_performance_feedback FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "Admins can update all performance feedback" ON app_performance_feedback;
CREATE POLICY "Admins can update all performance feedback"
  ON app_performance_feedback FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- performance_benchmarks table
DROP POLICY IF EXISTS "Users can view their own benchmarks" ON performance_benchmarks;
CREATE POLICY "Users can view their own benchmarks"
  ON performance_benchmarks FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- api_performance_logs table
DROP POLICY IF EXISTS "Users can view their own API logs" ON api_performance_logs;
CREATE POLICY "Users can view their own API logs"
  ON api_performance_logs FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- sla_agreements table
DROP POLICY IF EXISTS "Users can view their own SLAs" ON sla_agreements;
CREATE POLICY "Users can view their own SLAs"
  ON sla_agreements FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Admins can insert SLAs" ON sla_agreements;
CREATE POLICY "Admins can insert SLAs"
  ON sla_agreements FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- sla_performance_logs table
DROP POLICY IF EXISTS "Users can view their own SLA logs" ON sla_performance_logs;
CREATE POLICY "Users can view their own SLA logs"
  ON sla_performance_logs FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- roi_calculations table
DROP POLICY IF EXISTS "Users can view their own ROI" ON roi_calculations;
CREATE POLICY "Users can view their own ROI"
  ON roi_calculations FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- fleet_kpi_snapshots table
DROP POLICY IF EXISTS "Users can view their own KPIs" ON fleet_kpi_snapshots;
CREATE POLICY "Users can view their own KPIs"
  ON fleet_kpi_snapshots FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- session_tracking table
DROP POLICY IF EXISTS "Users can view their own sessions" ON session_tracking;
CREATE POLICY "Users can view their own sessions"
  ON session_tracking FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));