/*
  # Fix Integration RLS Policies

  1. Changes
    - Drop existing RLS policies that reference admin_users table
    - Create new RLS policies that use user_profiles table
    - Check for 'admin' or 'super_admin' roles in user_profiles
    - Maintain same security model: only admin users can access integrations

  2. Security
    - All integration tables remain admin-only accessible
    - Policies check user_profiles.role IN ('admin', 'super_admin')
    - Maintains restrictive access control for sensitive integration data
*/

-- Drop existing policies for integration_providers
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'integration_providers' 
    AND policyname = 'Admin users can view integration providers'
  ) THEN
    DROP POLICY "Admin users can view integration providers" ON integration_providers;
  END IF;
END $$;

DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'integration_providers' 
    AND policyname = 'Admin users can manage integration providers'
  ) THEN
    DROP POLICY "Admin users can manage integration providers" ON integration_providers;
  END IF;
END $$;

-- Create new policies for integration_providers
CREATE POLICY "Admin users can view integration providers"
  ON integration_providers FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Admin users can manage integration providers"
  ON integration_providers FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
    )
  );

-- Drop existing policies for integration_credentials
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'integration_credentials' 
    AND policyname = 'Admin users can view credentials'
  ) THEN
    DROP POLICY "Admin users can view credentials" ON integration_credentials;
  END IF;
END $$;

DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'integration_credentials' 
    AND policyname = 'Admin users can manage credentials'
  ) THEN
    DROP POLICY "Admin users can manage credentials" ON integration_credentials;
  END IF;
END $$;

-- Create new policies for integration_credentials
CREATE POLICY "Admin users can view credentials"
  ON integration_credentials FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Admin users can manage credentials"
  ON integration_credentials FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
    )
  );

-- Drop existing policies for integration_sync_logs
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'integration_sync_logs' 
    AND policyname = 'Admin users can view sync logs'
  ) THEN
    DROP POLICY "Admin users can view sync logs" ON integration_sync_logs;
  END IF;
END $$;

-- Create new policy for integration_sync_logs
CREATE POLICY "Admin users can view sync logs"
  ON integration_sync_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Admin users can update sync logs"
  ON integration_sync_logs FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
    )
  );

-- Drop existing policies for integration_mappings
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'integration_mappings' 
    AND policyname = 'Admin users can view mappings'
  ) THEN
    DROP POLICY "Admin users can view mappings" ON integration_mappings;
  END IF;
END $$;

DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'integration_mappings' 
    AND policyname = 'System can manage mappings'
  ) THEN
    DROP POLICY "System can manage mappings" ON integration_mappings;
  END IF;
END $$;

-- Create new policies for integration_mappings
CREATE POLICY "Admin users can view mappings"
  ON integration_mappings FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Admin users can manage mappings"
  ON integration_mappings FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
    )
  );

-- Drop existing policies for webhook_configurations if they exist
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'webhook_configurations' 
    AND policyname = 'Admin users can manage webhooks'
  ) THEN
    DROP POLICY "Admin users can manage webhooks" ON webhook_configurations;
  END IF;
END $$;

-- Create new policy for webhook_configurations
CREATE POLICY "Admin users can manage webhooks"
  ON webhook_configurations FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() 
      AND role IN ('admin', 'super_admin')
    )
  );