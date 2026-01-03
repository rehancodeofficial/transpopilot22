/*
  # Optimize RLS Policies - Part 1 (Core Tables)
  
  Wraps auth.uid() calls with SELECT to prevent row-by-row evaluation.
  This significantly improves query performance at scale.
*/

-- user_profiles table
DROP POLICY IF EXISTS "Users can read own profile" ON user_profiles;
CREATE POLICY "Users can read own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (id = (SELECT auth.uid()))
  WITH CHECK (id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Authenticated users can insert own profile" ON user_profiles;
CREATE POLICY "Authenticated users can insert own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Allow profile creation during signup trigger" ON user_profiles;
CREATE POLICY "Allow profile creation during signup trigger"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = (SELECT auth.uid()));

-- organizations table
DROP POLICY IF EXISTS "Users can read own organization" ON organizations;
CREATE POLICY "Users can read own organization"
  ON organizations FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT organization_id FROM user_profiles
      WHERE id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Admins can update own organization" ON organizations;
CREATE POLICY "Admins can update own organization"
  ON organizations FOR UPDATE
  TO authenticated
  USING (
    id IN (
      SELECT organization_id FROM user_profiles
      WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- vehicles table
DROP POLICY IF EXISTS "Users can read own organization vehicles" ON vehicles;
CREATE POLICY "Users can read own organization vehicles"
  ON vehicles FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles
      WHERE id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can insert vehicles in own organization" ON vehicles;
CREATE POLICY "Users can insert vehicles in own organization"
  ON vehicles FOR INSERT
  TO authenticated
  WITH CHECK (
    organization_id IN (
      SELECT organization_id FROM user_profiles
      WHERE id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can update own organization vehicles" ON vehicles;
CREATE POLICY "Users can update own organization vehicles"
  ON vehicles FOR UPDATE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles
      WHERE id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can delete own organization vehicles" ON vehicles;
CREATE POLICY "Users can delete own organization vehicles"
  ON vehicles FOR DELETE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles
      WHERE id = (SELECT auth.uid())
    )
  );

-- drivers table
DROP POLICY IF EXISTS "Users can read own organization drivers" ON drivers;
CREATE POLICY "Users can read own organization drivers"
  ON drivers FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles
      WHERE id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can insert drivers in own organization" ON drivers;
CREATE POLICY "Users can insert drivers in own organization"
  ON drivers FOR INSERT
  TO authenticated
  WITH CHECK (
    organization_id IN (
      SELECT organization_id FROM user_profiles
      WHERE id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can update own organization drivers" ON drivers;
CREATE POLICY "Users can update own organization drivers"
  ON drivers FOR UPDATE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles
      WHERE id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can delete own organization drivers" ON drivers;
CREATE POLICY "Users can delete own organization drivers"
  ON drivers FOR DELETE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles
      WHERE id = (SELECT auth.uid())
    )
  );

-- routes table
DROP POLICY IF EXISTS "Users can read own organization routes" ON routes;
CREATE POLICY "Users can read own organization routes"
  ON routes FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles
      WHERE id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can insert routes in own organization" ON routes;
CREATE POLICY "Users can insert routes in own organization"
  ON routes FOR INSERT
  TO authenticated
  WITH CHECK (
    organization_id IN (
      SELECT organization_id FROM user_profiles
      WHERE id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can update own organization routes" ON routes;
CREATE POLICY "Users can update own organization routes"
  ON routes FOR UPDATE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles
      WHERE id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can delete own organization routes" ON routes;
CREATE POLICY "Users can delete own organization routes"
  ON routes FOR DELETE
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles
      WHERE id = (SELECT auth.uid())
    )
  );