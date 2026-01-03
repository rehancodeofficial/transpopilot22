/*
  # Consolidate Multiple Permissive Policies

  ## Overview
  Consolidates multiple permissive policies for the same action into single policies.
  This improves maintainability and makes access control logic more explicit.

  ## Changes
  Consolidates policies for:
  1. document_requirements: 2 SELECT policies → 1 SELECT policy
  2. driver_documents: 2 SELECT + 2 UPDATE policies → 1 SELECT + 1 UPDATE policy
  3. driver_onboarding_progress: 3 SELECT + 2 UPDATE policies → 1 SELECT + 1 UPDATE policy
  4. driver_training_completions: 2 SELECT policies → 1 SELECT policy

  ## Access Control
  - All existing access patterns are preserved
  - Logic is now consolidated and easier to understand
*/

-- Document requirements: Consolidate SELECT policies
DROP POLICY IF EXISTS "Admins can manage document requirements" ON document_requirements;
DROP POLICY IF EXISTS "Users can view org document requirements" ON document_requirements;

CREATE POLICY "Users can view document requirements"
  ON document_requirements FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles WHERE id = (select auth.uid())
    )
  );

CREATE POLICY "Admins can manage document requirements"
  ON document_requirements FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles 
      WHERE id = (select auth.uid()) 
      AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    organization_id IN (
      SELECT organization_id FROM user_profiles 
      WHERE id = (select auth.uid()) 
      AND role IN ('admin', 'super_admin')
    )
  );

-- Driver documents: Consolidate SELECT and UPDATE policies
DROP POLICY IF EXISTS "Admins can view org documents" ON driver_documents;
DROP POLICY IF EXISTS "Drivers can view own documents" ON driver_documents;
DROP POLICY IF EXISTS "Admins can update org documents" ON driver_documents;
DROP POLICY IF EXISTS "Drivers can update own documents" ON driver_documents;

CREATE POLICY "Users can view driver documents"
  ON driver_documents FOR SELECT
  TO authenticated
  USING (
    user_id = (select auth.uid()) OR
    organization_id IN (
      SELECT organization_id FROM user_profiles 
      WHERE id = (select auth.uid()) 
      AND role IN ('admin', 'super_admin', 'fleet_manager')
    )
  );

CREATE POLICY "Users can update driver documents"
  ON driver_documents FOR UPDATE
  TO authenticated
  USING (
    user_id = (select auth.uid()) OR
    organization_id IN (
      SELECT organization_id FROM user_profiles 
      WHERE id = (select auth.uid()) 
      AND role IN ('admin', 'super_admin', 'fleet_manager')
    )
  );

-- Keep INSERT policy for drivers
CREATE POLICY "Drivers can insert documents"
  ON driver_documents FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

-- Driver onboarding progress: Consolidate SELECT and UPDATE policies
DROP POLICY IF EXISTS "Admins can manage org onboarding progress" ON driver_onboarding_progress;
DROP POLICY IF EXISTS "Admins can view org onboarding progress" ON driver_onboarding_progress;
DROP POLICY IF EXISTS "Drivers can view own onboarding progress" ON driver_onboarding_progress;
DROP POLICY IF EXISTS "Drivers can update own onboarding progress" ON driver_onboarding_progress;

CREATE POLICY "Users can view onboarding progress"
  ON driver_onboarding_progress FOR SELECT
  TO authenticated
  USING (
    user_id = (select auth.uid()) OR
    EXISTS (
      SELECT 1 FROM user_profiles up
      INNER JOIN drivers d ON d.organization_id = up.organization_id
      WHERE up.id = (select auth.uid())
      AND up.role IN ('admin', 'super_admin', 'fleet_manager')
      AND d.id = driver_onboarding_progress.driver_id
    )
  );

CREATE POLICY "Users can update onboarding progress"
  ON driver_onboarding_progress FOR UPDATE
  TO authenticated
  USING (
    user_id = (select auth.uid()) OR
    EXISTS (
      SELECT 1 FROM user_profiles up
      INNER JOIN drivers d ON d.organization_id = up.organization_id
      WHERE up.id = (select auth.uid())
      AND up.role IN ('admin', 'super_admin')
      AND d.id = driver_onboarding_progress.driver_id
    )
  );

CREATE POLICY "Admins can insert onboarding progress"
  ON driver_onboarding_progress FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles up
      INNER JOIN drivers d ON d.organization_id = up.organization_id
      WHERE up.id = (select auth.uid())
      AND up.role IN ('admin', 'super_admin')
      AND d.id = driver_onboarding_progress.driver_id
    )
  );

CREATE POLICY "Admins can delete onboarding progress"
  ON driver_onboarding_progress FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      INNER JOIN drivers d ON d.organization_id = up.organization_id
      WHERE up.id = (select auth.uid())
      AND up.role IN ('admin', 'super_admin')
      AND d.id = driver_onboarding_progress.driver_id
    )
  );

-- Driver training completions: Consolidate SELECT policies
DROP POLICY IF EXISTS "Admins can view org training completions" ON driver_training_completions;
DROP POLICY IF EXISTS "Drivers can view own training completions" ON driver_training_completions;

CREATE POLICY "Users can view training completions"
  ON driver_training_completions FOR SELECT
  TO authenticated
  USING (
    user_id = (select auth.uid()) OR
    EXISTS (
      SELECT 1 FROM user_profiles up
      INNER JOIN drivers d ON d.organization_id = up.organization_id
      WHERE up.id = (select auth.uid())
      AND up.role IN ('admin', 'super_admin', 'fleet_manager')
      AND d.id = driver_training_completions.driver_id
    )
  );

-- Keep INSERT policy for drivers
CREATE POLICY "Drivers can insert training completions"
  ON driver_training_completions FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (select auth.uid()));