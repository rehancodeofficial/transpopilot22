/*
  # Integration Testing and Validation Infrastructure
  
  1. New Tables
    - `integration_health_checks`
      - `id` (uuid, primary key)
      - `provider_id` (uuid) - Reference to integration provider
      - `credential_id` (uuid) - Reference to credentials being tested
      - `check_type` (text) - Type: connectivity, auth, data_sync, webhook
      - `status` (text) - healthy, degraded, failed
      - `response_time_ms` (integer)
      - `error_details` (jsonb)
      - `test_payload` (jsonb) - What was tested
      - `test_response` (jsonb) - Response received
      - `checked_at` (timestamptz)
      - `created_at` (timestamptz)
    
    - `webhook_delivery_logs`
      - `id` (uuid, primary key)
      - `provider_id` (uuid)
      - `event_type` (text) - Type of webhook event
      - `payload` (jsonb)
      - `delivery_status` (text) - pending, delivered, failed, retrying
      - `attempts` (integer) - Number of delivery attempts
      - `response_status_code` (integer)
      - `response_body` (text)
      - `next_retry_at` (timestamptz)
      - `delivered_at` (timestamptz)
      - `created_at` (timestamptz)
    
    - `api_rate_limit_tracking`
      - `id` (uuid, primary key)
      - `provider_id` (uuid)
      - `endpoint` (text)
      - `requests_count` (integer)
      - `limit_threshold` (integer)
      - `window_start` (timestamptz)
      - `window_end` (timestamptz)
      - `throttled` (boolean)
      - `created_at` (timestamptz)
    
    - `integration_sandbox_tests`
      - `id` (uuid, primary key)
      - `integration_name` (text)
      - `test_scenario` (text)
      - `test_data` (jsonb)
      - `expected_result` (jsonb)
      - `actual_result` (jsonb)
      - `test_passed` (boolean)
      - `execution_time_ms` (integer)
      - `error_message` (text)
      - `tested_by` (uuid)
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Users can view their integration health data
    - Admins can view all integration data
*/

-- Integration Health Checks Table
CREATE TABLE IF NOT EXISTS integration_health_checks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid REFERENCES integration_providers(id),
  credential_id uuid REFERENCES integration_credentials(id),
  check_type text NOT NULL CHECK (check_type IN ('connectivity', 'auth', 'data_sync', 'webhook', 'api_response')),
  status text NOT NULL CHECK (status IN ('healthy', 'degraded', 'failed')),
  response_time_ms integer,
  error_details jsonb DEFAULT '{}'::jsonb,
  test_payload jsonb DEFAULT '{}'::jsonb,
  test_response jsonb DEFAULT '{}'::jsonb,
  checked_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_integration_health_provider ON integration_health_checks(provider_id, checked_at DESC);
CREATE INDEX IF NOT EXISTS idx_integration_health_credential ON integration_health_checks(credential_id, checked_at DESC);
CREATE INDEX IF NOT EXISTS idx_integration_health_status ON integration_health_checks(status, checked_at DESC);

-- Webhook Delivery Logs Table
CREATE TABLE IF NOT EXISTS webhook_delivery_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid REFERENCES integration_providers(id),
  event_type text NOT NULL,
  payload jsonb NOT NULL,
  delivery_status text NOT NULL DEFAULT 'pending' CHECK (delivery_status IN ('pending', 'delivered', 'failed', 'retrying')),
  attempts integer NOT NULL DEFAULT 0,
  response_status_code integer,
  response_body text,
  next_retry_at timestamptz,
  delivered_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_webhook_logs_provider ON webhook_delivery_logs(provider_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_webhook_logs_status ON webhook_delivery_logs(delivery_status, next_retry_at);

-- API Rate Limit Tracking Table
CREATE TABLE IF NOT EXISTS api_rate_limit_tracking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id uuid REFERENCES integration_providers(id),
  endpoint text NOT NULL,
  requests_count integer NOT NULL DEFAULT 0,
  limit_threshold integer NOT NULL,
  window_start timestamptz NOT NULL,
  window_end timestamptz NOT NULL,
  throttled boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_rate_limit_provider ON api_rate_limit_tracking(provider_id, window_start DESC);
CREATE INDEX IF NOT EXISTS idx_rate_limit_throttled ON api_rate_limit_tracking(throttled, window_start DESC) WHERE throttled = true;

-- Integration Sandbox Tests Table
CREATE TABLE IF NOT EXISTS integration_sandbox_tests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  integration_name text NOT NULL,
  test_scenario text NOT NULL,
  test_data jsonb NOT NULL,
  expected_result jsonb NOT NULL,
  actual_result jsonb,
  test_passed boolean NOT NULL DEFAULT false,
  execution_time_ms integer,
  error_message text,
  tested_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sandbox_tests_name ON integration_sandbox_tests(integration_name, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sandbox_tests_result ON integration_sandbox_tests(test_passed, created_at DESC);

-- Enable RLS
ALTER TABLE integration_health_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhook_delivery_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_rate_limit_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE integration_sandbox_tests ENABLE ROW LEVEL SECURITY;

-- RLS Policies for integration_health_checks
CREATE POLICY "Authenticated users can view integration health checks"
  ON integration_health_checks FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert integration health checks"
  ON integration_health_checks FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS Policies for webhook_delivery_logs
CREATE POLICY "Authenticated users can view webhook logs"
  ON webhook_delivery_logs FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert webhook logs"
  ON webhook_delivery_logs FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "System can update webhook logs"
  ON webhook_delivery_logs FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- RLS Policies for api_rate_limit_tracking
CREATE POLICY "Authenticated users can view rate limits"
  ON api_rate_limit_tracking FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert rate limit data"
  ON api_rate_limit_tracking FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS Policies for integration_sandbox_tests
CREATE POLICY "Users can view their sandbox tests"
  ON integration_sandbox_tests FOR SELECT
  TO authenticated
  USING (
    tested_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Users can create sandbox tests"
  ON integration_sandbox_tests FOR INSERT
  TO authenticated
  WITH CHECK (tested_by = auth.uid());
