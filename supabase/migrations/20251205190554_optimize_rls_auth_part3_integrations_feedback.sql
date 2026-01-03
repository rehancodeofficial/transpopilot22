/*
  # Optimize RLS Policies - Part 3: Integrations & Feedback

  ## Overview
  Optimizes RLS policies for integration and feedback tables.

  ## Changes - Part 3
  Updates policies for:
  - integration_credentials
  - integration_mappings
  - feedback_submissions
  - testimonials
  - app_performance_feedback

  ## Performance Impact
  - Reduces auth function re-evaluation
  - Improves admin query performance
*/

-- Integration credentials table
DROP POLICY IF EXISTS "Admins can view integration credentials" ON integration_credentials;
CREATE POLICY "Admins can view integration credentials"
  ON integration_credentials FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles 
      WHERE id = (select auth.uid()) 
      AND role IN ('admin', 'super_admin')
    )
  );

-- Integration mappings table
DROP POLICY IF EXISTS "Admins can view integration mappings" ON integration_mappings;
CREATE POLICY "Admins can view integration mappings"
  ON integration_mappings FOR SELECT
  TO authenticated
  USING (
    provider_id IN (
      SELECT ip.id FROM integration_providers ip
      WHERE EXISTS (
        SELECT 1 FROM integration_credentials ic
        INNER JOIN user_profiles up ON ic.organization_id = up.organization_id
        WHERE ic.provider_id = ip.id
        AND up.id = (select auth.uid()) 
        AND up.role IN ('admin', 'super_admin')
      )
    )
  );

-- Feedback submissions table
DROP POLICY IF EXISTS "Users can update authorized feedback submissions" ON feedback_submissions;
CREATE POLICY "Users can update authorized feedback submissions"
  ON feedback_submissions FOR UPDATE
  TO authenticated
  USING (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "Users can view relevant feedback submissions" ON feedback_submissions;
CREATE POLICY "Users can view relevant feedback submissions"
  ON feedback_submissions FOR SELECT
  TO authenticated
  USING (
    user_id = (select auth.uid()) OR
    EXISTS (
      SELECT 1 FROM user_profiles 
      WHERE id = (select auth.uid()) 
      AND role IN ('admin', 'super_admin')
    )
  );

-- Testimonials table
DROP POLICY IF EXISTS "Users can create testimonials" ON testimonials;
CREATE POLICY "Users can create testimonials"
  ON testimonials FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "Users can view testimonials" ON testimonials;
CREATE POLICY "Users can view testimonials"
  ON testimonials FOR SELECT
  TO authenticated
  USING (
    approval_status = 'approved' OR
    user_id = (select auth.uid()) OR
    EXISTS (
      SELECT 1 FROM user_profiles 
      WHERE id = (select auth.uid()) 
      AND role IN ('admin', 'super_admin')
    )
  );

-- App performance feedback table
DROP POLICY IF EXISTS "Users can view relevant performance feedback" ON app_performance_feedback;
CREATE POLICY "Users can view relevant performance feedback"
  ON app_performance_feedback FOR SELECT
  TO authenticated
  USING (
    user_id = (select auth.uid()) OR
    EXISTS (
      SELECT 1 FROM user_profiles 
      WHERE id = (select auth.uid()) 
      AND role IN ('admin', 'super_admin')
    )
  );