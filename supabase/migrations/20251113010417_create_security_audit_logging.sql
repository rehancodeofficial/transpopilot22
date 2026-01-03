/*
  # Security and Audit Logging System
  
  1. New Tables
    - `security_audit_logs`
      - `id` (uuid, primary key)
      - `user_id` (uuid) - User who performed the action
      - `action_type` (text) - Type: login, logout, data_access, data_modify, permission_change
      - `resource_type` (text) - What was accessed: vehicle, driver, route, user, settings
      - `resource_id` (uuid) - ID of the resource
      - `action_details` (jsonb) - Details about what was done
      - `ip_address` (text)
      - `user_agent` (text)
      - `success` (boolean)
      - `failure_reason` (text)
      - `created_at` (timestamptz)
    
    - `access_control_logs`
      - `id` (uuid, primary key)
      - `user_id` (uuid)
      - `attempted_action` (text)
      - `resource_type` (text)
      - `resource_id` (uuid)
      - `access_granted` (boolean)
      - `denial_reason` (text)
      - `user_role` (text)
      - `required_role` (text)
      - `created_at` (timestamptz)
    
    - `login_attempts`
      - `id` (uuid, primary key)
      - `email` (text)
      - `success` (boolean)
      - `failure_reason` (text)
      - `ip_address` (text)
      - `user_agent` (text)
      - `country` (text)
      - `suspicious` (boolean)
      - `created_at` (timestamptz)
    
    - `session_tracking`
      - `id` (uuid, primary key)
      - `user_id` (uuid)
      - `session_token` (text)
      - `ip_address` (text)
      - `user_agent` (text)
      - `login_at` (timestamptz)
      - `last_activity_at` (timestamptz)
      - `logout_at` (timestamptz)
      - `session_duration_minutes` (integer)
      - `created_at` (timestamptz)
    
    - `data_encryption_logs`
      - `id` (uuid, primary key)
      - `data_type` (text) - Type of data encrypted
      - `encryption_method` (text)
      - `key_version` (text)
      - `operation` (text) - encrypt, decrypt, re_encrypt
      - `success` (boolean)
      - `performed_by` (uuid)
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Only admins can view audit logs
    - System can insert audit logs
*/

-- Security Audit Logs Table
CREATE TABLE IF NOT EXISTS security_audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  action_type text NOT NULL CHECK (action_type IN ('login', 'logout', 'data_access', 'data_modify', 'data_delete', 'permission_change', 'settings_change')),
  resource_type text CHECK (resource_type IN ('vehicle', 'driver', 'route', 'user', 'settings', 'integration', 'report')),
  resource_id uuid,
  action_details jsonb DEFAULT '{}'::jsonb,
  ip_address text,
  user_agent text,
  success boolean NOT NULL DEFAULT true,
  failure_reason text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_user ON security_audit_logs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_action ON security_audit_logs(action_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_resource ON security_audit_logs(resource_type, resource_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_failures ON security_audit_logs(success, created_at DESC) WHERE success = false;

-- Access Control Logs Table
CREATE TABLE IF NOT EXISTS access_control_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  attempted_action text NOT NULL,
  resource_type text NOT NULL,
  resource_id uuid,
  access_granted boolean NOT NULL,
  denial_reason text,
  user_role text,
  required_role text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_access_user ON access_control_logs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_access_denied ON access_control_logs(access_granted, created_at DESC) WHERE access_granted = false;

-- Login Attempts Table
CREATE TABLE IF NOT EXISTS login_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL,
  success boolean NOT NULL,
  failure_reason text,
  ip_address text,
  user_agent text,
  country text,
  suspicious boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_login_email ON login_attempts(email, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_login_failed ON login_attempts(success, created_at DESC) WHERE success = false;
CREATE INDEX IF NOT EXISTS idx_login_suspicious ON login_attempts(suspicious, created_at DESC) WHERE suspicious = true;

-- Session Tracking Table
CREATE TABLE IF NOT EXISTS session_tracking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  session_token text NOT NULL,
  ip_address text,
  user_agent text,
  login_at timestamptz NOT NULL DEFAULT now(),
  last_activity_at timestamptz NOT NULL DEFAULT now(),
  logout_at timestamptz,
  session_duration_minutes integer,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_session_user ON session_tracking(user_id, login_at DESC);
CREATE INDEX IF NOT EXISTS idx_session_active ON session_tracking(user_id, logout_at) WHERE logout_at IS NULL;

-- Data Encryption Logs Table
CREATE TABLE IF NOT EXISTS data_encryption_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  data_type text NOT NULL,
  encryption_method text NOT NULL,
  key_version text,
  operation text NOT NULL CHECK (operation IN ('encrypt', 'decrypt', 're_encrypt')),
  success boolean NOT NULL DEFAULT true,
  performed_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_encryption_type ON data_encryption_logs(data_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_encryption_operation ON data_encryption_logs(operation, created_at DESC);

-- Enable RLS
ALTER TABLE security_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE access_control_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE login_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_encryption_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for security_audit_logs
CREATE POLICY "Only admins can view audit logs"
  ON security_audit_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "System can insert audit logs"
  ON security_audit_logs FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS Policies for access_control_logs
CREATE POLICY "Only admins can view access logs"
  ON access_control_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "System can insert access logs"
  ON access_control_logs FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS Policies for login_attempts
CREATE POLICY "Only admins can view login attempts"
  ON login_attempts FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "System can insert login attempts"
  ON login_attempts FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS Policies for session_tracking
CREATE POLICY "Users can view their own sessions"
  ON session_tracking FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "System can insert session data"
  ON session_tracking FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "System can update session data"
  ON session_tracking FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- RLS Policies for data_encryption_logs
CREATE POLICY "Only admins can view encryption logs"
  ON data_encryption_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "System can insert encryption logs"
  ON data_encryption_logs FOR INSERT
  TO authenticated
  WITH CHECK (true);
