/*
  # Remove Organizations - Step 3: Drop Organization Columns

  ## Overview
  Removes organization_id foreign key columns from all tables.

  ## Changes
  1. Drop organization_id from user_profiles
  2. Drop organization_id from vehicles
  3. Drop organization_id from drivers
  4. Drop organization_id from routes
  5. Drop organization_id from all other tables that have it

  ## Security
  - Tables remain protected by RLS
  - Existing non-organization policies remain active

  ## Important Notes
  - This removes the foreign key relationship completely
  - Data becomes globally accessible based on role
*/

-- Drop organization_id from user_profiles
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_profiles' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE user_profiles DROP COLUMN organization_id;
  END IF;
END $$;

-- Drop organization_id from vehicles
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'vehicles' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE vehicles DROP COLUMN organization_id;
  END IF;
END $$;

-- Drop organization_id from drivers
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'drivers' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE drivers DROP COLUMN organization_id;
  END IF;
END $$;

-- Drop organization_id from routes
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'routes' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE routes DROP COLUMN organization_id;
  END IF;
END $$;

-- Drop organization_id from driver_locations
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'driver_locations' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE driver_locations DROP COLUMN organization_id;
  END IF;
END $$;

-- Drop organization_id from vehicle_locations
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'vehicle_locations' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE vehicle_locations DROP COLUMN organization_id;
  END IF;
END $$;

-- Drop organization_id from fuel_records
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'fuel_records' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE fuel_records DROP COLUMN organization_id;
  END IF;
END $$;

-- Drop organization_id from safety_incidents
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'safety_incidents' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE safety_incidents DROP COLUMN organization_id;
  END IF;
END $$;

-- Drop organization_id from compliance_items
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'compliance_items' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE compliance_items DROP COLUMN organization_id;
  END IF;
END $$;

-- Drop organization_id from driver_training
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'driver_training' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE driver_training DROP COLUMN organization_id;
  END IF;
END $$;

-- Drop organization_id from geofences
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'geofences' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE geofences DROP COLUMN organization_id;
  END IF;
END $$;

-- Drop organization_id from integration_credentials
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'integration_credentials' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE integration_credentials DROP COLUMN organization_id;
  END IF;
END $$;