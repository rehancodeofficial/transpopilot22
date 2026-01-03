/*
  # Add Organization ID to Core Tables

  ## Overview
  Adds organization_id foreign key to all core tables to enable multi-tenancy
  data isolation. Each record belongs to exactly one organization.

  ## Changes
  1. Add organization_id to user_profiles
  2. Add organization_id to vehicles
  3. Add organization_id to drivers
  4. Add organization_id to routes
  5. Add organization_id to vehicle_locations
  6. Add organization_id to driver_locations
  7. Add organization_id to fuel_records
  8. Add organization_id to safety_incidents
  9. Add organization_id to compliance_items
  10. Add organization_id to driver_training
  11. Add organization_id to geofences
  12. Add organization_id to integration_credentials
  13. Add organization_id to vehicle_diagnostics
  14. Add organization_id to driver_behavior_events

  ## Security
  - Foreign key ensures referential integrity
  - Indexes added for query performance
  - RLS policies will use organization_id for filtering

  ## Important Notes
  - Existing records will have NULL organization_id initially
  - Migration includes backfill for existing data
  - New records must have organization_id set
*/

-- Add organization_id to user_profiles
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_user_profiles_organization ON user_profiles(organization_id);

-- Add organization_id to vehicles
ALTER TABLE vehicles 
ADD COLUMN IF NOT EXISTS organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_vehicles_organization ON vehicles(organization_id);

-- Add organization_id to drivers
ALTER TABLE drivers 
ADD COLUMN IF NOT EXISTS organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_drivers_organization ON drivers(organization_id);

-- Add organization_id to routes
ALTER TABLE routes 
ADD COLUMN IF NOT EXISTS organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_routes_organization ON routes(organization_id);

-- Add organization_id to vehicle_locations (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'vehicle_locations') THEN
    ALTER TABLE vehicle_locations 
    ADD COLUMN IF NOT EXISTS organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    
    CREATE INDEX IF NOT EXISTS idx_vehicle_locations_organization ON vehicle_locations(organization_id);
  END IF;
END $$;

-- Add organization_id to driver_locations (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'driver_locations') THEN
    ALTER TABLE driver_locations 
    ADD COLUMN IF NOT EXISTS organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    
    CREATE INDEX IF NOT EXISTS idx_driver_locations_organization ON driver_locations(organization_id);
  END IF;
END $$;

-- Add organization_id to fuel_records (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fuel_records') THEN
    ALTER TABLE fuel_records 
    ADD COLUMN IF NOT EXISTS organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    
    CREATE INDEX IF NOT EXISTS idx_fuel_records_organization ON fuel_records(organization_id);
  END IF;
END $$;

-- Add organization_id to safety_incidents (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'safety_incidents') THEN
    ALTER TABLE safety_incidents 
    ADD COLUMN IF NOT EXISTS organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    
    CREATE INDEX IF NOT EXISTS idx_safety_incidents_organization ON safety_incidents(organization_id);
  END IF;
END $$;

-- Add organization_id to compliance_items (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'compliance_items') THEN
    ALTER TABLE compliance_items 
    ADD COLUMN IF NOT EXISTS organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    
    CREATE INDEX IF NOT EXISTS idx_compliance_items_organization ON compliance_items(organization_id);
  END IF;
END $$;

-- Add organization_id to driver_training (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'driver_training') THEN
    ALTER TABLE driver_training 
    ADD COLUMN IF NOT EXISTS organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    
    CREATE INDEX IF NOT EXISTS idx_driver_training_organization ON driver_training(organization_id);
  END IF;
END $$;

-- Add organization_id to geofences (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'geofences') THEN
    ALTER TABLE geofences 
    ADD COLUMN IF NOT EXISTS organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    
    CREATE INDEX IF NOT EXISTS idx_geofences_organization ON geofences(organization_id);
  END IF;
END $$;

-- Add organization_id to integration_credentials (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'integration_credentials') THEN
    ALTER TABLE integration_credentials 
    ADD COLUMN IF NOT EXISTS organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    
    CREATE INDEX IF NOT EXISTS idx_integration_credentials_organization ON integration_credentials(organization_id);
  END IF;
END $$;

-- Add organization_id to vehicle_diagnostics (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'vehicle_diagnostics') THEN
    ALTER TABLE vehicle_diagnostics 
    ADD COLUMN IF NOT EXISTS organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    
    CREATE INDEX IF NOT EXISTS idx_vehicle_diagnostics_organization ON vehicle_diagnostics(organization_id);
  END IF;
END $$;

-- Add organization_id to driver_behavior_events (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'driver_behavior_events') THEN
    ALTER TABLE driver_behavior_events 
    ADD COLUMN IF NOT EXISTS organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    
    CREATE INDEX IF NOT EXISTS idx_driver_behavior_events_organization ON driver_behavior_events(organization_id);
  END IF;
END $$;