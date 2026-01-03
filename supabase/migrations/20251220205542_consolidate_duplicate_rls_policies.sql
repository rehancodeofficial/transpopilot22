/*
  # Consolidate Duplicate RLS Policies
  
  ## Overview
  Consolidates multiple permissive policies that apply to the same operation.
  Having multiple permissive policies for the same action can cause confusion and
  may lead to unintended access patterns.
  
  ## Changes
  
  ### 1. document_requirements
  - Drops "FOR ALL" policy that includes SELECT
  - Creates separate INSERT, UPDATE, DELETE policies for admins
  - Keeps existing SELECT policy for all users
  
  ### 2. driver_documents
  - Consolidates two INSERT policies into one
  - Removes duplicate "Drivers can insert own documents"
  - Keeps "Drivers can insert documents" with combined logic
  
  ### 3. driver_training_completions
  - Consolidates two INSERT policies into one
  - Removes duplicate "Drivers can insert training completions"
  - Keeps "Drivers can insert own training completions" with combined logic
  
  ## Security Impact
  - Maintains the same access patterns
  - Reduces policy evaluation overhead
  - Makes security model easier to understand and audit
*/

-- ============================================================================
-- Fix document_requirements policies
-- ============================================================================

-- Drop the "FOR ALL" policy that causes multiple permissive policies for SELECT
DROP POLICY IF EXISTS "Admins can manage document requirements" ON document_requirements;

-- Create separate policies for admins (INSERT, UPDATE, DELETE only)
CREATE POLICY "Admins can insert document requirements"
  ON document_requirements FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (select auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Admins can update document requirements"
  ON document_requirements FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (select auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (select auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Admins can delete document requirements"
  ON document_requirements FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (select auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- Keep the existing SELECT policy (it already exists)
-- "Users can view document requirements" FOR SELECT

-- ============================================================================
-- Fix driver_documents policies
-- ============================================================================

-- Drop both existing INSERT policies
DROP POLICY IF EXISTS "Drivers can insert documents" ON driver_documents;
DROP POLICY IF EXISTS "Drivers can insert own documents" ON driver_documents;

-- Create single consolidated INSERT policy
CREATE POLICY "Users can insert driver documents"
  ON driver_documents FOR INSERT
  TO authenticated
  WITH CHECK (
    -- User can insert documents for drivers in their organization
    EXISTS (
      SELECT 1 FROM drivers d
      INNER JOIN user_profiles up ON d.organization_id = up.organization_id
      WHERE d.id = driver_documents.driver_id
      AND up.id = (select auth.uid())
    )
  );

-- ============================================================================
-- Fix driver_training_completions policies
-- ============================================================================

-- Drop both existing INSERT policies
DROP POLICY IF EXISTS "Drivers can insert own training completions" ON driver_training_completions;
DROP POLICY IF EXISTS "Drivers can insert training completions" ON driver_training_completions;

-- Create single consolidated INSERT policy
CREATE POLICY "Users can insert training completions"
  ON driver_training_completions FOR INSERT
  TO authenticated
  WITH CHECK (
    -- User can insert completions for drivers in their organization
    EXISTS (
      SELECT 1 FROM drivers d
      INNER JOIN user_profiles up ON d.organization_id = up.organization_id
      WHERE d.id = driver_training_completions.driver_id
      AND up.id = (select auth.uid())
    )
  );
