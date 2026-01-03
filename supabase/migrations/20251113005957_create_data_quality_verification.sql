/*
  # Data Quality Verification System
  
  1. New Tables
    - `data_quality_checks`
      - `id` (uuid, primary key)
      - `check_name` (text) - Name of the quality check
      - `entity_type` (text) - Type: vehicle, driver, route, fuel, gps
      - `entity_id` (uuid) - ID of the entity being checked
      - `check_result` (text) - passed, failed, warning
      - `issues_found` (jsonb) - Array of issues detected
      - `metrics` (jsonb) - Quality metrics and scores
      - `checked_at` (timestamptz)
      - `created_at` (timestamptz)
    
    - `data_anomalies`
      - `id` (uuid, primary key)
      - `anomaly_type` (text) - Type: gps_outlier, sensor_malfunction, missing_data, stale_data
      - `entity_type` (text)
      - `entity_id` (uuid)
      - `severity` (text) - critical, high, medium, low
      - `description` (text)
      - `expected_value` (text)
      - `actual_value` (text)
      - `metadata` (jsonb)
      - `status` (text) - open, investigating, resolved, false_positive
      - `detected_at` (timestamptz)
      - `resolved_at` (timestamptz)
      - `created_at` (timestamptz)
    
    - `fuel_accuracy_audits`
      - `id` (uuid, primary key)
      - `vehicle_id` (uuid)
      - `predicted_consumption` (numeric) - AI predicted fuel consumption
      - `actual_consumption` (numeric) - Actual measured consumption
      - `variance_percentage` (numeric) - Difference between predicted and actual
      - `route_id` (uuid)
      - `audit_period_start` (timestamptz)
      - `audit_period_end` (timestamptz)
      - `accuracy_score` (numeric) - 0-100 score
      - `created_at` (timestamptz)
    
    - `gps_validation_logs`
      - `id` (uuid, primary key)
      - `vehicle_id` (uuid)
      - `latitude` (numeric)
      - `longitude` (numeric)
      - `is_valid` (boolean)
      - `validation_errors` (jsonb) - Array of validation failures
      - `speed_mph` (numeric)
      - `is_speed_reasonable` (boolean)
      - `time_since_last_update` (integer) - Seconds since last GPS ping
      - `is_update_timely` (boolean)
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Only authenticated users can view quality data
    - System can insert validation records
*/

-- Data Quality Checks Table
CREATE TABLE IF NOT EXISTS data_quality_checks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  check_name text NOT NULL,
  entity_type text NOT NULL CHECK (entity_type IN ('vehicle', 'driver', 'route', 'fuel', 'gps', 'sensor')),
  entity_id uuid,
  check_result text NOT NULL CHECK (check_result IN ('passed', 'failed', 'warning')),
  issues_found jsonb DEFAULT '[]'::jsonb,
  metrics jsonb DEFAULT '{}'::jsonb,
  checked_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_quality_checks_entity ON data_quality_checks(entity_type, entity_id, checked_at DESC);
CREATE INDEX IF NOT EXISTS idx_quality_checks_result ON data_quality_checks(check_result, checked_at DESC);

-- Data Anomalies Table
CREATE TABLE IF NOT EXISTS data_anomalies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  anomaly_type text NOT NULL CHECK (anomaly_type IN ('gps_outlier', 'sensor_malfunction', 'missing_data', 'stale_data', 'invalid_reading', 'suspicious_pattern')),
  entity_type text NOT NULL CHECK (entity_type IN ('vehicle', 'driver', 'route', 'fuel', 'gps', 'sensor')),
  entity_id uuid,
  severity text NOT NULL CHECK (severity IN ('critical', 'high', 'medium', 'low')),
  description text NOT NULL,
  expected_value text,
  actual_value text,
  metadata jsonb DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved', 'false_positive')),
  detected_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_anomalies_entity ON data_anomalies(entity_type, entity_id, detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_anomalies_status ON data_anomalies(status, severity, detected_at DESC);

-- Fuel Accuracy Audits Table
CREATE TABLE IF NOT EXISTS fuel_accuracy_audits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id uuid REFERENCES vehicles(id),
  predicted_consumption numeric(10,2) NOT NULL,
  actual_consumption numeric(10,2) NOT NULL,
  variance_percentage numeric(5,2) NOT NULL,
  route_id uuid,
  audit_period_start timestamptz NOT NULL,
  audit_period_end timestamptz NOT NULL,
  accuracy_score numeric(5,2) NOT NULL CHECK (accuracy_score >= 0 AND accuracy_score <= 100),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_fuel_audits_vehicle ON fuel_accuracy_audits(vehicle_id, audit_period_start DESC);
CREATE INDEX IF NOT EXISTS idx_fuel_audits_accuracy ON fuel_accuracy_audits(accuracy_score, created_at DESC);

-- GPS Validation Logs Table
CREATE TABLE IF NOT EXISTS gps_validation_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id uuid REFERENCES vehicles(id),
  latitude numeric(10,8) NOT NULL,
  longitude numeric(11,8) NOT NULL,
  is_valid boolean NOT NULL DEFAULT true,
  validation_errors jsonb DEFAULT '[]'::jsonb,
  speed_mph numeric(5,2),
  is_speed_reasonable boolean NOT NULL DEFAULT true,
  time_since_last_update integer,
  is_update_timely boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_gps_validation_vehicle ON gps_validation_logs(vehicle_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_gps_validation_invalid ON gps_validation_logs(is_valid, created_at DESC) WHERE is_valid = false;

-- Enable RLS
ALTER TABLE data_quality_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_anomalies ENABLE ROW LEVEL SECURITY;
ALTER TABLE fuel_accuracy_audits ENABLE ROW LEVEL SECURITY;
ALTER TABLE gps_validation_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for data_quality_checks
CREATE POLICY "Authenticated users can view quality checks"
  ON data_quality_checks FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert quality checks"
  ON data_quality_checks FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS Policies for data_anomalies
CREATE POLICY "Authenticated users can view anomalies"
  ON data_anomalies FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert anomalies"
  ON data_anomalies FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Admins can update anomalies"
  ON data_anomalies FOR UPDATE
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

-- RLS Policies for fuel_accuracy_audits
CREATE POLICY "Authenticated users can view fuel audits"
  ON fuel_accuracy_audits FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert fuel audits"
  ON fuel_accuracy_audits FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS Policies for gps_validation_logs
CREATE POLICY "Authenticated users can view GPS validation"
  ON gps_validation_logs FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert GPS validation"
  ON gps_validation_logs FOR INSERT
  TO authenticated
  WITH CHECK (true);
