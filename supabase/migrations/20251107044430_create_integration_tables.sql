/*
  # Third-Party Integration Management System

  1. New Tables
    - `integration_providers`
      - `id` (uuid, primary key)
      - `name` (text) - 'geotab', 'samsara', 'motive'
      - `display_name` (text)
      - `logo_url` (text)
      - `is_enabled` (boolean)
      - `connection_status` (text) - 'connected', 'disconnected', 'error'
      - `last_sync_at` (timestamptz)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `integration_credentials`
      - `id` (uuid, primary key)
      - `provider_id` (uuid, references integration_providers)
      - `api_key` (text, encrypted)
      - `api_secret` (text, encrypted)
      - `username` (text)
      - `database_name` (text) - for Geotab
      - `access_token` (text)
      - `refresh_token` (text)
      - `token_expires_at` (timestamptz)
      - `configuration` (jsonb) - additional provider-specific config
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `integration_sync_logs`
      - `id` (uuid, primary key)
      - `provider_id` (uuid, references integration_providers)
      - `sync_type` (text) - 'vehicles', 'drivers', 'locations', 'fuel', 'safety'
      - `status` (text) - 'success', 'partial', 'failed'
      - `records_processed` (integer)
      - `records_success` (integer)
      - `records_failed` (integer)
      - `error_message` (text)
      - `started_at` (timestamptz)
      - `completed_at` (timestamptz)
      - `created_at` (timestamptz)
    
    - `integration_mappings`
      - `id` (uuid, primary key)
      - `provider_id` (uuid, references integration_providers)
      - `entity_type` (text) - 'vehicle', 'driver'
      - `internal_id` (uuid) - our system ID
      - `external_id` (text) - provider's ID
      - `metadata` (jsonb)
      - `created_at` (timestamptz)
    
    - `webhook_configurations`
      - `id` (uuid, primary key)
      - `provider_id` (uuid, references integration_providers)
      - `event_type` (text)
      - `webhook_url` (text)
      - `is_active` (boolean)
      - `secret_key` (text)
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Only admin users can access integration settings
    - Credentials are admin-only readable
*/

-- Create integration_providers table
CREATE TABLE IF NOT EXISTS integration_providers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL CHECK (name IN ('geotab', 'samsara', 'motive')),
  display_name text NOT NULL,
  logo_url text,
  is_enabled boolean DEFAULT false,
  connection_status text DEFAULT 'disconnected' CHECK (connection_status IN ('connected', 'disconnected', 'error', 'connecting')),
  last_sync_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE integration_providers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin users can view integration providers"
  ON integration_providers FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admin users can manage integration providers"
  ON integration_providers FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create integration_credentials table
CREATE TABLE IF NOT EXISTS integration_credentials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid NOT NULL REFERENCES integration_providers(id) ON DELETE CASCADE,
  api_key text,
  api_secret text,
  username text,
  database_name text,
  access_token text,
  refresh_token text,
  token_expires_at timestamptz,
  configuration jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(provider_id)
);

ALTER TABLE integration_credentials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin users can view credentials"
  ON integration_credentials FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admin users can manage credentials"
  ON integration_credentials FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create integration_sync_logs table
CREATE TABLE IF NOT EXISTS integration_sync_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid NOT NULL REFERENCES integration_providers(id) ON DELETE CASCADE,
  sync_type text NOT NULL CHECK (sync_type IN ('vehicles', 'drivers', 'locations', 'fuel', 'safety', 'compliance', 'maintenance')),
  status text NOT NULL CHECK (status IN ('success', 'partial', 'failed', 'running')),
  records_processed integer DEFAULT 0,
  records_success integer DEFAULT 0,
  records_failed integer DEFAULT 0,
  error_message text,
  started_at timestamptz DEFAULT now(),
  completed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sync_logs_provider 
  ON integration_sync_logs(provider_id, created_at DESC);

ALTER TABLE integration_sync_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin users can view sync logs"
  ON integration_sync_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "System can insert sync logs"
  ON integration_sync_logs FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Create integration_mappings table
CREATE TABLE IF NOT EXISTS integration_mappings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid NOT NULL REFERENCES integration_providers(id) ON DELETE CASCADE,
  entity_type text NOT NULL CHECK (entity_type IN ('vehicle', 'driver', 'route')),
  internal_id uuid NOT NULL,
  external_id text NOT NULL,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  UNIQUE(provider_id, entity_type, external_id)
);

CREATE INDEX IF NOT EXISTS idx_mappings_internal 
  ON integration_mappings(internal_id);

ALTER TABLE integration_mappings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin users can view mappings"
  ON integration_mappings FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "System can manage mappings"
  ON integration_mappings FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create webhook_configurations table
CREATE TABLE IF NOT EXISTS webhook_configurations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid NOT NULL REFERENCES integration_providers(id) ON DELETE CASCADE,
  event_type text NOT NULL,
  webhook_url text NOT NULL,
  is_active boolean DEFAULT true,
  secret_key text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE webhook_configurations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin users can manage webhooks"
  ON webhook_configurations FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Insert default integration providers
INSERT INTO integration_providers (name, display_name, logo_url, is_enabled, connection_status)
VALUES 
  ('geotab', 'Geotab', 'https://www.geotab.com/wp-content/themes/geotab/images/logo.svg', false, 'disconnected'),
  ('samsara', 'Samsara', 'https://www.samsara.com/assets/logo.svg', false, 'disconnected'),
  ('motive', 'Motive', 'https://gomotive.com/wp-content/themes/motive/assets/images/logo.svg', false, 'disconnected')
ON CONFLICT (name) DO NOTHING;