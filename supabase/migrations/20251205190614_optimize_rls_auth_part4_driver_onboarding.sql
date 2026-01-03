/*
  # Optimize RLS Policies - Part 4: Driver Onboarding

  ## Overview
  Optimizes RLS policies for driver onboarding and document tables.

  ## Changes - Part 4
  Updates policies for:
  - driver_onboarding_progress
  - driver_training_completions
  - document_requirements
  - driver_documents

  ## Performance Impact
  - Reduces auth function re-evaluation
  - Improves onboarding workflow performance
*/

-- Driver onboarding progress table
DROP POLICY IF EXISTS "Admins can manage org onboarding progress" ON driver_onboarding_progress;
CREATE POLICY "Admins can manage org onboarding progress"
  ON driver_onboarding_progress FOR ALL
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

DROP POLICY IF EXISTS "Admins can view org onboarding progress" ON driver_onboarding_progress;
CREATE POLICY "Admins can view org onboarding progress"
  ON driver_onboarding_progress FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      INNER JOIN drivers d ON d.organization_id = up.organization_id
      WHERE up.id = (select auth.uid())
      AND up.role IN ('admin', 'super_admin', 'fleet_manager')
      AND d.id = driver_onboarding_progress.driver_id
    )
  );

DROP POLICY IF EXISTS "Drivers can update own onboarding progress" ON driver_onboarding_progress;
CREATE POLICY "Drivers can update own onboarding progress"
  ON driver_onboarding_progress FOR UPDATE
  TO authenticated
  USING (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "Drivers can view own onboarding progress" ON driver_onboarding_progress;
CREATE POLICY "Drivers can view own onboarding progress"
  ON driver_onboarding_progress FOR SELECT
  TO authenticated
  USING (user_id = (select auth.uid()));

-- Driver training completions table
DROP POLICY IF EXISTS "Admins can view org training completions" ON driver_training_completions;
CREATE POLICY "Admins can view org training completions"
  ON driver_training_completions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      INNER JOIN drivers d ON d.organization_id = up.organization_id
      WHERE up.id = (select auth.uid())
      AND up.role IN ('admin', 'super_admin', 'fleet_manager')
      AND d.id = driver_training_completions.driver_id
    )
  );

DROP POLICY IF EXISTS "Drivers can insert own training completions" ON driver_training_completions;
CREATE POLICY "Drivers can insert own training completions"
  ON driver_training_completions FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "Drivers can view own training completions" ON driver_training_completions;
CREATE POLICY "Drivers can view own training completions"
  ON driver_training_completions FOR SELECT
  TO authenticated
  USING (user_id = (select auth.uid()));

-- Document requirements table
DROP POLICY IF EXISTS "Admins can manage document requirements" ON document_requirements;
CREATE POLICY "Admins can manage document requirements"
  ON document_requirements FOR ALL
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles 
      WHERE id = (select auth.uid()) 
      AND role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "Users can view org document requirements" ON document_requirements;
CREATE POLICY "Users can view org document requirements"
  ON document_requirements FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles WHERE id = (select auth.uid())
    )
  );

-- Driver documents table
DROP POLICY IF EXISTS "Admins can update org documents" ON driver_documents;
CREATE POLICY "Admins can update org documents"
  ON driver_documents FOR UPDATE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles 
      WHERE id = (select auth.uid()) 
      AND role IN ('admin', 'super_admin', 'fleet_manager')
    )
  );

DROP POLICY IF EXISTS "Admins can view org documents" ON driver_documents;
CREATE POLICY "Admins can view org documents"
  ON driver_documents FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles 
      WHERE id = (select auth.uid()) 
      AND role IN ('admin', 'super_admin', 'fleet_manager')
    )
  );

DROP POLICY IF EXISTS "Drivers can insert own documents" ON driver_documents;
CREATE POLICY "Drivers can insert own documents"
  ON driver_documents FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "Drivers can update own documents" ON driver_documents;
CREATE POLICY "Drivers can update own documents"
  ON driver_documents FOR UPDATE
  TO authenticated
  USING (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "Drivers can view own documents" ON driver_documents;
CREATE POLICY "Drivers can view own documents"
  ON driver_documents FOR SELECT
  TO authenticated
  USING (user_id = (select auth.uid()));