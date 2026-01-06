-- Migration to align 'routes' table with Frontend Code
-- Fixes "Failed to save route" (Missing columns)

DO $$
BEGIN
  -- 1. Ensure 'name' column exists (User schema had 'route_name')
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'name') THEN
    -- If route_name exists, rename it, otherwise add name
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'route_name') THEN
        ALTER TABLE routes RENAME COLUMN route_name TO name;
    ELSE
        ALTER TABLE routes ADD COLUMN name text;
    END IF;
  END IF;

  -- 2. Add 'description'
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'description') THEN
    ALTER TABLE routes ADD COLUMN description text;
  END IF;

  -- 3. Add 'status'
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'status') THEN
    ALTER TABLE routes ADD COLUMN status text DEFAULT 'planned';
  END IF;

  -- 4. Add 'optimization_score'
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'optimization_score') THEN
    ALTER TABLE routes ADD COLUMN optimization_score numeric;
  END IF;

  -- 5. Add 'estimated_distance'
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'estimated_distance') THEN
    ALTER TABLE routes ADD COLUMN estimated_distance numeric;
  END IF;

  -- 6. Add 'estimated_duration'
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'routes' AND column_name = 'estimated_duration') THEN
    ALTER TABLE routes ADD COLUMN estimated_duration numeric;
  END IF;

  -- 7. Ensure RLS allows insert (Fix "Failed to save" permission error)
  -- Allow Authenticated users to insert routes if they belong to the org
  DROP POLICY IF EXISTS "Users can insert routes for their org" ON routes;
  CREATE POLICY "Users can insert routes for their org"
  ON routes FOR INSERT
  TO authenticated
  WITH CHECK (
    organization_id IN (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    )
  );
  
  -- Allow Select
  DROP POLICY IF EXISTS "Users can view routes for their org" ON routes;
  CREATE POLICY "Users can view routes for their org"
  ON routes FOR SELECT
  TO authenticated
  USING (
    organization_id IN (
      SELECT organization_id FROM user_profiles WHERE id = auth.uid()
    )
  );

END $$;
