/*
  # Add Organization Support to Existing Tables

  ## Overview
  Adds organization_id foreign key to all existing fleet management tables
  to support multi-tenancy. Updates RLS policies to filter by organization.

  ## Changes

  ### Tables Updated
  - `vehicles` - Add organization_id column
  - `drivers` - Add organization_id column
  - `routes` - Add organization_id column
  - `trial_registrations` - Add organization_id column (nullable for unconverted trials)

  ## Security Updates
  - Update all RLS policies to filter by user's organization
  - Super admins bypass organization filtering
  - Maintain backward compatibility with existing data

  ## Important Notes
  - Existing records get NULL organization_id initially
  - organization_id will be populated when users are assigned to organizations
  - Policies ensure users only see data from their organization
*/

-- Add organization_id to vehicles table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'vehicles' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE vehicles ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_vehicles_organization ON vehicles(organization_id);
  END IF;
END $$;

-- Add organization_id to drivers table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'drivers' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE drivers ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_drivers_organization ON drivers(organization_id);
  END IF;
END $$;

-- Add organization_id to routes table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'routes' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE routes ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_routes_organization ON routes(organization_id);
  END IF;
END $$;

-- Add organization_id to trial_registrations table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'trial_registrations' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE trial_registrations ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE SET NULL;
    CREATE INDEX IF NOT EXISTS idx_trial_registrations_organization ON trial_registrations(organization_id);
  END IF;
END $$;

-- Drop old policies and create new organization-aware policies for vehicles
DROP POLICY IF EXISTS "Allow authenticated users to read vehicles" ON vehicles;
DROP POLICY IF EXISTS "Allow authenticated users to insert vehicles" ON vehicles;
DROP POLICY IF EXISTS "Allow authenticated users to update vehicles" ON vehicles;

CREATE POLICY "Users can read vehicles in their organization"
  ON vehicles FOR SELECT
  TO authenticated
  USING (
    organization_id = (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

CREATE POLICY "Users can insert vehicles in their organization"
  ON vehicles FOR INSERT
  TO authenticated
  WITH CHECK (
    organization_id = (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

CREATE POLICY "Users can update vehicles in their organization"
  ON vehicles FOR UPDATE
  TO authenticated
  USING (
    organization_id = (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'super_admin'
    )
  )
  WITH CHECK (
    organization_id = (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- Drop old policies and create new organization-aware policies for drivers
DROP POLICY IF EXISTS "Allow authenticated users to read drivers" ON drivers;
DROP POLICY IF EXISTS "Allow authenticated users to insert drivers" ON drivers;
DROP POLICY IF EXISTS "Allow authenticated users to update drivers" ON drivers;

CREATE POLICY "Users can read drivers in their organization"
  ON drivers FOR SELECT
  TO authenticated
  USING (
    organization_id = (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

CREATE POLICY "Users can insert drivers in their organization"
  ON drivers FOR INSERT
  TO authenticated
  WITH CHECK (
    organization_id = (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

CREATE POLICY "Users can update drivers in their organization"
  ON drivers FOR UPDATE
  TO authenticated
  USING (
    organization_id = (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'super_admin'
    )
  )
  WITH CHECK (
    organization_id = (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- Drop old policies and create new organization-aware policies for routes
DROP POLICY IF EXISTS "Allow authenticated users to read routes" ON routes;
DROP POLICY IF EXISTS "Allow authenticated users to insert routes" ON routes;
DROP POLICY IF EXISTS "Allow authenticated users to update routes" ON routes;

CREATE POLICY "Users can read routes in their organization"
  ON routes FOR SELECT
  TO authenticated
  USING (
    organization_id = (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

CREATE POLICY "Users can insert routes in their organization"
  ON routes FOR INSERT
  TO authenticated
  WITH CHECK (
    organization_id = (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

CREATE POLICY "Users can update routes in their organization"
  ON routes FOR UPDATE
  TO authenticated
  USING (
    organization_id = (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'super_admin'
    )
  )
  WITH CHECK (
    organization_id = (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'super_admin'
    )
  );