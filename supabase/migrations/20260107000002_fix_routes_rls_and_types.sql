-- Migration: Fix Routes RLS and Types
-- Ensures organization_id exists, enables RLS, and fixes waypoint policies

DO $$
BEGIN
  -- 1. Ensure organization_id exists in routes
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'routes' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE public.routes ADD COLUMN organization_id uuid NOT NULL;
  ELSE
    -- If it exists, ensure it is NOT NULL
    ALTER TABLE public.routes ALTER COLUMN organization_id SET NOT NULL;
  END IF;

  -- 2. Enable RLS on routes
  ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;

  -- 3. Update RLS Policies for 'routes'
  
  -- Routes Select
  DROP POLICY IF EXISTS "Users can view own organization routes" ON public.routes;
  DROP POLICY IF EXISTS "Authenticated users can view routes" ON public.routes; -- Old policy from previous migration
  CREATE POLICY "Users can view own organization routes"
    ON public.routes FOR SELECT
    TO authenticated
    USING (organization_id IN (SELECT organization_id FROM user_profiles WHERE id = auth.uid()));

  -- Routes Insert
  DROP POLICY IF EXISTS "Users can create routes for own organization" ON public.routes;
  DROP POLICY IF EXISTS "Admin users can create routes" ON public.routes; -- Old policy
  CREATE POLICY "Users can create routes for own organization"
    ON public.routes FOR INSERT
    TO authenticated
    WITH CHECK (organization_id IN (SELECT organization_id FROM user_profiles WHERE id = auth.uid()));

  -- Routes Update
  DROP POLICY IF EXISTS "Users can update own organization routes" ON public.routes;
  DROP POLICY IF EXISTS "Admin users can update routes" ON public.routes; -- Old policy
  CREATE POLICY "Users can update own organization routes"
    ON public.routes FOR UPDATE
    TO authenticated
    USING (organization_id IN (SELECT organization_id FROM user_profiles WHERE id = auth.uid()))
    WITH CHECK (organization_id IN (SELECT organization_id FROM user_profiles WHERE id = auth.uid()));

  -- Routes Delete
  DROP POLICY IF EXISTS "Users can delete own organization routes" ON public.routes;
  DROP POLICY IF EXISTS "Admin users can delete routes" ON public.routes; -- Old policy
  CREATE POLICY "Users can delete own organization routes"
    ON public.routes FOR DELETE
    TO authenticated
    USING (organization_id IN (SELECT organization_id FROM user_profiles WHERE id = auth.uid()));

  -- 4. Update RLS Policies for 'route_waypoints'
  
  -- Waypoints Select (via Route organization)
  DROP POLICY IF EXISTS "Users can view own organization waypoints" ON public.route_waypoints;
  DROP POLICY IF EXISTS "Authenticated users can view waypoints" ON public.route_waypoints; -- Old policy
  CREATE POLICY "Users can view own organization waypoints"
    ON public.route_waypoints FOR SELECT
    TO authenticated
    USING (
      route_id IN (
        SELECT r.id
        FROM public.routes r
        JOIN public.user_profiles u ON u.organization_id = r.organization_id
        WHERE u.id = auth.uid()
      )
    );

  -- Waypoints Insert (via Route organization)
  DROP POLICY IF EXISTS "Users can create waypoints for own organization routes" ON public.route_waypoints;
  DROP POLICY IF EXISTS "Admin users can manage waypoints" ON public.route_waypoints; -- Old policy
  CREATE POLICY "Users can create waypoints for own organization routes"
    ON public.route_waypoints FOR INSERT
    TO authenticated
    WITH CHECK (
      route_id IN (
        SELECT r.id
        FROM public.routes r
        JOIN public.user_profiles u ON u.organization_id = r.organization_id
        WHERE u.id = auth.uid()
      )
    );

  -- Waypoints Update/Delete
  DROP POLICY IF EXISTS "Users can manage own organization waypoints" ON public.route_waypoints;
  CREATE POLICY "Users can manage own organization waypoints"
    ON public.route_waypoints FOR ALL
    TO authenticated
    USING (
      route_id IN (
        SELECT r.id
        FROM public.routes r
        JOIN public.user_profiles u ON u.organization_id = r.organization_id
        WHERE u.id = auth.uid()
      )
    );

  -- 5. Fix Type Mismatch for estimated_duration
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'routes' AND column_name = 'estimated_duration'
  ) THEN
    ALTER TABLE public.routes
    ALTER COLUMN estimated_duration TYPE integer
    USING estimated_duration::integer;
  END IF;

END $$;
