/*
  # Performance Benchmarking and SLA Tracking System
  
  1. New Tables
    - `performance_benchmarks`
      - `id` (uuid, primary key)
      - `user_id` (uuid) - Owner of the fleet
      - `metric_type` (text) - Type: fuel_savings, compliance_rate, uptime, response_time
      - `current_value` (numeric)
      - `target_value` (numeric)
      - `industry_average` (numeric)
      - `performance_percentage` (numeric) - How well performing vs target
      - `period_start` (timestamptz)
      - `period_end` (timestamptz)
      - `created_at` (timestamptz)
    
    - `sla_agreements`
      - `id` (uuid, primary key)
      - `user_id` (uuid)
      - `sla_type` (text) - uptime, response_time, data_accuracy, support_response
      - `commitment_percentage` (numeric) - e.g., 99.9% uptime
      - `measurement_period` (text) - daily, weekly, monthly
      - `penalties` (jsonb) - What happens if SLA is breached
      - `active` (boolean)
      - `created_at` (timestamptz)
    
    - `sla_performance_logs`
      - `id` (uuid, primary key)
      - `sla_id` (uuid)
      - `user_id` (uuid)
      - `period_start` (timestamptz)
      - `period_end` (timestamptz)
      - `achieved_percentage` (numeric)
      - `target_percentage` (numeric)
      - `sla_met` (boolean)
      - `breach_details` (jsonb)
      - `created_at` (timestamptz)
    
    - `roi_calculations`
      - `id` (uuid, primary key)
      - `user_id` (uuid)
      - `calculation_period_start` (timestamptz)
      - `calculation_period_end` (timestamptz)
      - `subscription_cost` (numeric)
      - `fuel_savings` (numeric)
      - `compliance_savings` (numeric) - Savings from avoiding fines
      - `time_savings_value` (numeric)
      - `total_savings` (numeric)
      - `roi_percentage` (numeric)
      - `created_at` (timestamptz)
    
    - `fleet_kpi_snapshots`
      - `id` (uuid, primary key)
      - `user_id` (uuid)
      - `snapshot_date` (timestamptz)
      - `total_vehicles` (integer)
      - `active_vehicles` (integer)
      - `total_drivers` (integer)
      - `active_drivers` (integer)
      - `total_miles_driven` (numeric)
      - `fuel_consumed_gallons` (numeric)
      - `average_mpg` (numeric)
      - `compliance_rate` (numeric)
      - `safety_incidents` (integer)
      - `on_time_delivery_rate` (numeric)
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Users can view their own performance data
    - Admins can view all performance data
*/

-- Performance Benchmarks Table
CREATE TABLE IF NOT EXISTS performance_benchmarks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  metric_type text NOT NULL CHECK (metric_type IN ('fuel_savings', 'compliance_rate', 'uptime', 'response_time', 'safety_score', 'on_time_delivery')),
  current_value numeric(10,2) NOT NULL,
  target_value numeric(10,2) NOT NULL,
  industry_average numeric(10,2),
  performance_percentage numeric(5,2),
  period_start timestamptz NOT NULL,
  period_end timestamptz NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_benchmarks_user ON performance_benchmarks(user_id, period_start DESC);
CREATE INDEX IF NOT EXISTS idx_benchmarks_metric ON performance_benchmarks(metric_type, period_start DESC);

-- SLA Agreements Table
CREATE TABLE IF NOT EXISTS sla_agreements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  sla_type text NOT NULL CHECK (sla_type IN ('uptime', 'response_time', 'data_accuracy', 'support_response', 'fuel_accuracy')),
  commitment_percentage numeric(5,2) NOT NULL CHECK (commitment_percentage > 0 AND commitment_percentage <= 100),
  measurement_period text NOT NULL CHECK (measurement_period IN ('daily', 'weekly', 'monthly', 'quarterly')),
  penalties jsonb DEFAULT '{}'::jsonb,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sla_user ON sla_agreements(user_id, active);
CREATE INDEX IF NOT EXISTS idx_sla_type ON sla_agreements(sla_type, active) WHERE active = true;

-- SLA Performance Logs Table
CREATE TABLE IF NOT EXISTS sla_performance_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sla_id uuid REFERENCES sla_agreements(id),
  user_id uuid REFERENCES auth.users(id),
  period_start timestamptz NOT NULL,
  period_end timestamptz NOT NULL,
  achieved_percentage numeric(5,2) NOT NULL,
  target_percentage numeric(5,2) NOT NULL,
  sla_met boolean NOT NULL,
  breach_details jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sla_logs_sla ON sla_performance_logs(sla_id, period_start DESC);
CREATE INDEX IF NOT EXISTS idx_sla_logs_breaches ON sla_performance_logs(sla_met, period_start DESC) WHERE sla_met = false;

-- ROI Calculations Table
CREATE TABLE IF NOT EXISTS roi_calculations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  calculation_period_start timestamptz NOT NULL,
  calculation_period_end timestamptz NOT NULL,
  subscription_cost numeric(10,2) NOT NULL,
  fuel_savings numeric(10,2) NOT NULL DEFAULT 0,
  compliance_savings numeric(10,2) NOT NULL DEFAULT 0,
  time_savings_value numeric(10,2) NOT NULL DEFAULT 0,
  total_savings numeric(10,2) NOT NULL,
  roi_percentage numeric(10,2) NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_roi_user ON roi_calculations(user_id, calculation_period_start DESC);

-- Fleet KPI Snapshots Table
CREATE TABLE IF NOT EXISTS fleet_kpi_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  snapshot_date timestamptz NOT NULL DEFAULT now(),
  total_vehicles integer NOT NULL DEFAULT 0,
  active_vehicles integer NOT NULL DEFAULT 0,
  total_drivers integer NOT NULL DEFAULT 0,
  active_drivers integer NOT NULL DEFAULT 0,
  total_miles_driven numeric(10,2) NOT NULL DEFAULT 0,
  fuel_consumed_gallons numeric(10,2) NOT NULL DEFAULT 0,
  average_mpg numeric(5,2),
  compliance_rate numeric(5,2),
  safety_incidents integer NOT NULL DEFAULT 0,
  on_time_delivery_rate numeric(5,2),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_kpi_user ON fleet_kpi_snapshots(user_id, snapshot_date DESC);

-- Enable RLS
ALTER TABLE performance_benchmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE sla_agreements ENABLE ROW LEVEL SECURITY;
ALTER TABLE sla_performance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE roi_calculations ENABLE ROW LEVEL SECURITY;
ALTER TABLE fleet_kpi_snapshots ENABLE ROW LEVEL SECURITY;

-- RLS Policies for performance_benchmarks
CREATE POLICY "Users can view their own benchmarks"
  ON performance_benchmarks FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "System can insert benchmarks"
  ON performance_benchmarks FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS Policies for sla_agreements
CREATE POLICY "Users can view their own SLAs"
  ON sla_agreements FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Admins can insert SLAs"
  ON sla_agreements FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

-- RLS Policies for sla_performance_logs
CREATE POLICY "Users can view their own SLA logs"
  ON sla_performance_logs FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "System can insert SLA logs"
  ON sla_performance_logs FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS Policies for roi_calculations
CREATE POLICY "Users can view their own ROI"
  ON roi_calculations FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "System can insert ROI calculations"
  ON roi_calculations FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS Policies for fleet_kpi_snapshots
CREATE POLICY "Users can view their own KPIs"
  ON fleet_kpi_snapshots FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "System can insert KPI snapshots"
  ON fleet_kpi_snapshots FOR INSERT
  TO authenticated
  WITH CHECK (true);
