-- Comprehensive Fix: Align 'routes' and 'route_waypoints' with Frontend code requirements
-- This script ensures all columns used by RouteOptimization.tsx and routes.ts exists

DO $$
BEGIN
  -- 1. Fix 'routes' table columns
  
  -- Ensure 'name' exists (User's schema had 'route_name')
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'name') THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'route_name') THEN
      ALTER TABLE routes RENAME COLUMN route_name TO name;
    ELSE
      ALTER TABLE routes ADD COLUMN name text;
    END IF;
  END IF;

  -- Add description
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'description') THEN
    ALTER TABLE routes ADD COLUMN description text;
  END IF;

  -- Add status (default 'planned')
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'status') THEN
    ALTER TABLE routes ADD COLUMN status text DEFAULT 'planned';
  END IF;

  -- Add optimization_score
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'optimization_score') THEN
    ALTER TABLE routes ADD COLUMN optimization_score decimal;
  END IF;

  -- Add estimated_distance (Frontend uses this)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'estimated_distance') THEN
    ALTER TABLE routes ADD COLUMN estimated_distance decimal;
  END IF;

  -- Add estimated_duration (Frontend uses this)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'estimated_duration') THEN
    ALTER TABLE routes ADD COLUMN estimated_duration decimal;
  END IF;

  -- Add fuel_estimate (Frontend uses this)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'fuel_estimate') THEN
    ALTER TABLE routes ADD COLUMN fuel_estimate decimal;
  END IF;

  -- 2. Create 'route_waypoints' table if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'route_waypoints' AND table_schema = 'public') THEN
    CREATE TABLE public.route_waypoints (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      route_id uuid REFERENCES public.routes(id) ON DELETE CASCADE,
      name text NOT NULL,
      address text,
      latitude decimal NOT NULL,
      longitude decimal NOT NULL,
      sequence_number integer NOT NULL,
      status text DEFAULT 'pending',
      created_at timestamp with time zone DEFAULT now()
    );
    
    -- Enable RLS
    ALTER TABLE public.route_waypoints ENABLE ROW LEVEL SECURITY;
  END IF;

  -- 3. Update RLS Policies for both tables
  
  -- Routes Select
  DROP POLICY IF EXISTS "Users can view own organization routes" ON routes;
  CREATE POLICY "Users can view own organization routes"
    ON routes FOR SELECT
    TO authenticated
    USING (organization_id IN (SELECT organization_id FROM user_profiles WHERE id = auth.uid()));

  -- Routes Insert
  DROP POLICY IF EXISTS "Users can create routes for own organization" ON routes;
  CREATE POLICY "Users can create routes for own organization"
    ON routes FOR INSERT
    TO authenticated
    WITH CHECK (organization_id IN (SELECT organization_id FROM user_profiles WHERE id = auth.uid()));

  -- Waypoints Select (via Route organization)
  DROP POLICY IF EXISTS "Users can view own organization waypoints" ON route_waypoints;
  CREATE POLICY "Users can view own organization waypoints"
    ON route_waypoints FOR SELECT
    TO authenticated
    USING (route_id IN (SELECT id FROM routes));

  -- Waypoints Insert (via Route organization)
  DROP POLICY IF EXISTS "Users can create waypoints for own organization routes" ON route_waypoints;
  CREATE POLICY "Users can create waypoints for own organization routes"
    ON route_waypoints FOR INSERT
    TO authenticated
    WITH CHECK (route_id IN (SELECT id FROM routes));

END $$;
