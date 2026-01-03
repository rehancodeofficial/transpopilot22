/*
  # System Health Monitoring Infrastructure
  
  1. New Tables
    - `system_health_checks`
      - `id` (uuid, primary key)
      - `service_name` (text) - Name of the service being monitored
      - `check_type` (text) - Type of check: api, database, integration, external_service
      - `status` (text) - Current status: healthy, degraded, down
      - `response_time_ms` (integer) - Response time in milliseconds
      - `error_message` (text) - Error details if unhealthy
      - `metadata` (jsonb) - Additional check details
      - `checked_at` (timestamptz) - When the check was performed
      - `created_at` (timestamptz)
    
    - `system_alerts`
      - `id` (uuid, primary key)
      - `alert_type` (text) - Type: performance, error, security, data_quality, compliance
      - `severity` (text) - critical, high, medium, low
      - `service_name` (text) - Affected service
      - `message` (text) - Alert description
      - `details` (jsonb) - Full alert context
      - `status` (text) - open, acknowledged, resolved
      - `triggered_at` (timestamptz)
      - `resolved_at` (timestamptz)
      - `resolved_by` (uuid) - User who resolved it
      - `created_at` (timestamptz)
    
    - `api_performance_logs`
      - `id` (uuid, primary key)
      - `endpoint` (text) - API endpoint called
      - `method` (text) - HTTP method
      - `status_code` (integer) - Response status
      - `response_time_ms` (integer)
      - `user_id` (uuid) - User who made the request
      - `error_message` (text)
      - `request_size_bytes` (integer)
      - `response_size_bytes` (integer)
      - `created_at` (timestamptz)
    
    - `system_uptime_metrics`
      - `id` (uuid, primary key)
      - `service_name` (text)
      - `uptime_percentage` (numeric) - Calculated uptime %
      - `total_checks` (integer)
      - `successful_checks` (integer)
      - `failed_checks` (integer)
      - `average_response_time_ms` (integer)
      - `period_start` (timestamptz)
      - `period_end` (timestamptz)
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Only authenticated users can view health data
    - Only admins can resolve alerts
*/

-- System Health Checks Table
CREATE TABLE IF NOT EXISTS system_health_checks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name text NOT NULL,
  check_type text NOT NULL CHECK (check_type IN ('api', 'database', 'integration', 'external_service', 'ai_model')),
  status text NOT NULL CHECK (status IN ('healthy', 'degraded', 'down')),
  response_time_ms integer,
  error_message text,
  metadata jsonb DEFAULT '{}'::jsonb,
  checked_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_health_checks_service ON system_health_checks(service_name, checked_at DESC);
CREATE INDEX IF NOT EXISTS idx_health_checks_status ON system_health_checks(status, checked_at DESC);

-- System Alerts Table
CREATE TABLE IF NOT EXISTS system_alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type text NOT NULL CHECK (alert_type IN ('performance', 'error', 'security', 'data_quality', 'compliance', 'integration')),
  severity text NOT NULL CHECK (severity IN ('critical', 'high', 'medium', 'low')),
  service_name text NOT NULL,
  message text NOT NULL,
  details jsonb DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'acknowledged', 'resolved')),
  triggered_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz,
  resolved_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_alerts_status ON system_alerts(status, triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_severity ON system_alerts(severity, triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_type ON system_alerts(alert_type, triggered_at DESC);

-- API Performance Logs Table
CREATE TABLE IF NOT EXISTS api_performance_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  endpoint text NOT NULL,
  method text NOT NULL,
  status_code integer NOT NULL,
  response_time_ms integer NOT NULL,
  user_id uuid REFERENCES auth.users(id),
  error_message text,
  request_size_bytes integer,
  response_size_bytes integer,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_api_logs_endpoint ON api_performance_logs(endpoint, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_api_logs_user ON api_performance_logs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_api_logs_status ON api_performance_logs(status_code, created_at DESC);

-- System Uptime Metrics Table
CREATE TABLE IF NOT EXISTS system_uptime_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name text NOT NULL,
  uptime_percentage numeric(5,2) NOT NULL,
  total_checks integer NOT NULL DEFAULT 0,
  successful_checks integer NOT NULL DEFAULT 0,
  failed_checks integer NOT NULL DEFAULT 0,
  average_response_time_ms integer,
  period_start timestamptz NOT NULL,
  period_end timestamptz NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_uptime_service ON system_uptime_metrics(service_name, period_start DESC);

-- Enable RLS
ALTER TABLE system_health_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_performance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_uptime_metrics ENABLE ROW LEVEL SECURITY;

-- RLS Policies for system_health_checks
CREATE POLICY "Authenticated users can view health checks"
  ON system_health_checks FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert health checks"
  ON system_health_checks FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS Policies for system_alerts
CREATE POLICY "Authenticated users can view alerts"
  ON system_alerts FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can create alerts"
  ON system_alerts FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Admins can update alerts"
  ON system_alerts FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

-- RLS Policies for api_performance_logs
CREATE POLICY "Users can view their own API logs"
  ON api_performance_logs FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR EXISTS (
    SELECT 1 FROM user_profiles
    WHERE user_profiles.id = auth.uid()
    AND user_profiles.role IN ('admin', 'super_admin')
  ));

CREATE POLICY "System can insert API logs"
  ON api_performance_logs FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS Policies for system_uptime_metrics
CREATE POLICY "Authenticated users can view uptime metrics"
  ON system_uptime_metrics FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert uptime metrics"
  ON system_uptime_metrics FOR INSERT
  TO authenticated
  WITH CHECK (true);
