/*
  # Implement Organization-Based RLS Policies

  ## Overview
  Replaces the existing "USING (true)" policies with organization-based filtering
  to ensure complete data isolation between different trucking companies.

  ## Security Changes
  1. Drop existing permissive policies
  2. Create organization-scoped policies for all core tables
  3. Ensure users can only access data from their own organization
  4. Super admins can access all organizations

  ## Policy Pattern
  - SELECT: Filter by organization_id matching user's organization
  - INSERT: Enforce organization_id matches user's organization
  - UPDATE: Filter and enforce organization_id
  - DELETE: Filter by organization_id

  ## Important Notes
  - All queries now automatically filtered by organization
  - Cross-organization data access is impossible
  - Super admins bypass organization filtering
  - NULL organization_id records are not accessible (cleanup required)
*/

-- =====================================================
-- UPDATE ORGANIZATIONS POLICIES
-- =====================================================

DROP POLICY IF EXISTS "Authenticated users can read organizations" ON organizations;
DROP POLICY IF EXISTS "Admins can update organizations" ON organizations;

-- Users can read their own organization
CREATE POLICY "Users can read own organization"
  ON organizations FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- Admins can update their organization
CREATE POLICY "Admins can update own organization"
  ON organizations FOR UPDATE
  TO authenticated
  USING (
    id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- =====================================================
-- USER PROFILES POLICIES
-- =====================================================

DROP POLICY IF EXISTS "Users can read own profile" ON user_profiles;

CREATE POLICY "Users can read own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (
    id = auth.uid()
    OR
    (organization_id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid()
    ) AND EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    ))
  );

-- =====================================================
-- VEHICLES POLICIES
-- =====================================================

DROP POLICY IF EXISTS "Allow authenticated users to read vehicles" ON vehicles;
DROP POLICY IF EXISTS "Allow authenticated users to insert vehicles" ON vehicles;
DROP POLICY IF EXISTS "Allow authenticated users to update vehicles" ON vehicles;
DROP POLICY IF EXISTS "Authenticated users can read all vehicles" ON vehicles;
DROP POLICY IF EXISTS "Authenticated users can insert vehicles" ON vehicles;
DROP POLICY IF EXISTS "Authenticated users can update vehicles" ON vehicles;
DROP POLICY IF EXISTS "Authenticated users can delete vehicles" ON vehicles;

CREATE POLICY "Users can read own organization vehicles"
  ON vehicles FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

CREATE POLICY "Users can insert vehicles in own organization"
  ON vehicles FOR INSERT
  TO authenticated
  WITH CHECK (
    organization_id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can update own organization vehicles"
  ON vehicles FOR UPDATE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid()
    )
  )
  WITH CHECK (
    organization_id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own organization vehicles"
  ON vehicles FOR DELETE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid()
    )
  );

-- =====================================================
-- DRIVERS POLICIES
-- =====================================================

DROP POLICY IF EXISTS "Allow authenticated users to read drivers" ON drivers;
DROP POLICY IF EXISTS "Allow authenticated users to insert drivers" ON drivers;
DROP POLICY IF EXISTS "Allow authenticated users to update drivers" ON drivers;
DROP POLICY IF EXISTS "Authenticated users can read all drivers" ON drivers;
DROP POLICY IF EXISTS "Authenticated users can insert drivers" ON drivers;
DROP POLICY IF EXISTS "Authenticated users can update drivers" ON drivers;
DROP POLICY IF EXISTS "Authenticated users can delete drivers" ON drivers;

CREATE POLICY "Users can read own organization drivers"
  ON drivers FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

CREATE POLICY "Users can insert drivers in own organization"
  ON drivers FOR INSERT
  TO authenticated
  WITH CHECK (
    organization_id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can update own organization drivers"
  ON drivers FOR UPDATE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid()
    )
  )
  WITH CHECK (
    organization_id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own organization drivers"
  ON drivers FOR DELETE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid()
    )
  );

-- =====================================================
-- ROUTES POLICIES
-- =====================================================

DROP POLICY IF EXISTS "Allow authenticated users to read routes" ON routes;
DROP POLICY IF EXISTS "Allow authenticated users to insert routes" ON routes;
DROP POLICY IF EXISTS "Allow authenticated users to update routes" ON routes;
DROP POLICY IF EXISTS "Authenticated users can read all routes" ON routes;
DROP POLICY IF EXISTS "Authenticated users can insert routes" ON routes;
DROP POLICY IF EXISTS "Authenticated users can update routes" ON routes;
DROP POLICY IF EXISTS "Authenticated users can delete routes" ON routes;

CREATE POLICY "Users can read own organization routes"
  ON routes FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

CREATE POLICY "Users can insert routes in own organization"
  ON routes FOR INSERT
  TO authenticated
  WITH CHECK (
    organization_id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can update own organization routes"
  ON routes FOR UPDATE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid()
    )
  )
  WITH CHECK (
    organization_id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own organization routes"
  ON routes FOR DELETE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id
      FROM user_profiles
      WHERE id = auth.uid()
    )
  );