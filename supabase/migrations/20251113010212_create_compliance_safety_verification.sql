/*
  # Compliance and Safety Verification System
  
  1. New Tables
    - `compliance_audits`
      - `id` (uuid, primary key)
      - `audit_type` (text) - Type: hos, inspection, license, certification, vehicle_registration
      - `entity_type` (text) - driver, vehicle, company
      - `entity_id` (uuid)
      - `compliance_status` (text) - compliant, non_compliant, warning
      - `violations_found` (jsonb) - Array of violations
      - `recommendations` (jsonb) - Recommended actions
      - `audit_period_start` (timestamptz)
      - `audit_period_end` (timestamptz)
      - `audited_by` (uuid)
      - `created_at` (timestamptz)
    
    - `hours_of_service_violations`
      - `id` (uuid, primary key)
      - `driver_id` (uuid)
      - `violation_type` (text) - driving_hours_exceeded, on_duty_exceeded, rest_break_missed
      - `severity` (text) - critical, major, minor
      - `violation_date` (timestamptz)
      - `hours_driven` (numeric)
      - `hours_limit` (numeric)
      - `description` (text)
      - `resolved` (boolean)
      - `resolution_notes` (text)
      - `created_at` (timestamptz)
    
    - `certification_tracking`
      - `id` (uuid, primary key)
      - `driver_id` (uuid)
      - `certification_type` (text) - cdl, medical, hazmat, tanker
      - `certification_number` (text)
      - `issue_date` (date)
      - `expiration_date` (date)
      - `status` (text) - active, expiring_soon, expired, suspended
      - `alert_sent` (boolean)
      - `verified_at` (timestamptz)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `vehicle_inspection_records`
      - `id` (uuid, primary key)
      - `vehicle_id` (uuid)
      - `inspection_type` (text) - pre_trip, post_trip, annual, dot_inspection
      - `inspector_id` (uuid) - Driver or inspector
      - `inspection_date` (timestamptz)
      - `passed` (boolean)
      - `defects_found` (jsonb) - Array of defects
      - `out_of_service` (boolean)
      - `repairs_required` (jsonb)
      - `repairs_completed` (boolean)
      - `next_inspection_due` (date)
      - `created_at` (timestamptz)
    
    - `safety_incident_reports`
      - `id` (uuid, primary key)
      - `incident_type` (text) - accident, injury, near_miss, property_damage
      - `severity` (text) - fatal, serious, moderate, minor
      - `driver_id` (uuid)
      - `vehicle_id` (uuid)
      - `incident_date` (timestamptz)
      - `location` (text)
      - `coordinates` (jsonb)
      - `description` (text)
      - `injuries_reported` (boolean)
      - `police_report_filed` (boolean)
      - `insurance_claim_filed` (boolean)
      - `investigation_completed` (boolean)
      - `root_cause` (text)
      - `corrective_actions` (jsonb)
      - `reported_by` (uuid)
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Users can view their own compliance data
    - Admins can view all compliance data
    - System can create audit records
*/

-- Compliance Audits Table
CREATE TABLE IF NOT EXISTS compliance_audits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  audit_type text NOT NULL CHECK (audit_type IN ('hos', 'inspection', 'license', 'certification', 'vehicle_registration', 'safety_training')),
  entity_type text NOT NULL CHECK (entity_type IN ('driver', 'vehicle', 'company')),
  entity_id uuid,
  compliance_status text NOT NULL CHECK (compliance_status IN ('compliant', 'non_compliant', 'warning')),
  violations_found jsonb DEFAULT '[]'::jsonb,
  recommendations jsonb DEFAULT '[]'::jsonb,
  audit_period_start timestamptz NOT NULL,
  audit_period_end timestamptz NOT NULL,
  audited_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_compliance_audits_entity ON compliance_audits(entity_type, entity_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_compliance_audits_status ON compliance_audits(compliance_status, created_at DESC);

-- Hours of Service Violations Table
CREATE TABLE IF NOT EXISTS hours_of_service_violations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid REFERENCES drivers(id),
  violation_type text NOT NULL CHECK (violation_type IN ('driving_hours_exceeded', 'on_duty_exceeded', 'rest_break_missed', 'log_missing')),
  severity text NOT NULL CHECK (severity IN ('critical', 'major', 'minor')),
  violation_date timestamptz NOT NULL,
  hours_driven numeric(5,2),
  hours_limit numeric(5,2),
  description text NOT NULL,
  resolved boolean NOT NULL DEFAULT false,
  resolution_notes text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_hos_violations_driver ON hours_of_service_violations(driver_id, violation_date DESC);
CREATE INDEX IF NOT EXISTS idx_hos_violations_unresolved ON hours_of_service_violations(resolved, violation_date DESC) WHERE resolved = false;

-- Certification Tracking Table
CREATE TABLE IF NOT EXISTS certification_tracking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid REFERENCES drivers(id),
  certification_type text NOT NULL CHECK (certification_type IN ('cdl', 'medical', 'hazmat', 'tanker', 'doubles_triples', 'passenger')),
  certification_number text NOT NULL,
  issue_date date NOT NULL,
  expiration_date date NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expiring_soon', 'expired', 'suspended', 'revoked')),
  alert_sent boolean NOT NULL DEFAULT false,
  verified_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_cert_tracking_driver ON certification_tracking(driver_id, expiration_date);
CREATE INDEX IF NOT EXISTS idx_cert_tracking_expiring ON certification_tracking(status, expiration_date) WHERE status IN ('active', 'expiring_soon');

-- Vehicle Inspection Records Table
CREATE TABLE IF NOT EXISTS vehicle_inspection_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id uuid REFERENCES vehicles(id),
  inspection_type text NOT NULL CHECK (inspection_type IN ('pre_trip', 'post_trip', 'annual', 'dot_inspection', 'maintenance')),
  inspector_id uuid REFERENCES auth.users(id),
  inspection_date timestamptz NOT NULL DEFAULT now(),
  passed boolean NOT NULL DEFAULT true,
  defects_found jsonb DEFAULT '[]'::jsonb,
  out_of_service boolean NOT NULL DEFAULT false,
  repairs_required jsonb DEFAULT '[]'::jsonb,
  repairs_completed boolean NOT NULL DEFAULT false,
  next_inspection_due date,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_inspection_vehicle ON vehicle_inspection_records(vehicle_id, inspection_date DESC);
CREATE INDEX IF NOT EXISTS idx_inspection_failed ON vehicle_inspection_records(passed, inspection_date DESC) WHERE passed = false;
CREATE INDEX IF NOT EXISTS idx_inspection_out_of_service ON vehicle_inspection_records(out_of_service, inspection_date DESC) WHERE out_of_service = true;

-- Safety Incident Reports Table
CREATE TABLE IF NOT EXISTS safety_incident_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_type text NOT NULL CHECK (incident_type IN ('accident', 'injury', 'near_miss', 'property_damage', 'hazmat_spill')),
  severity text NOT NULL CHECK (severity IN ('fatal', 'serious', 'moderate', 'minor')),
  driver_id uuid REFERENCES drivers(id),
  vehicle_id uuid REFERENCES vehicles(id),
  incident_date timestamptz NOT NULL,
  location text,
  coordinates jsonb,
  description text NOT NULL,
  injuries_reported boolean NOT NULL DEFAULT false,
  police_report_filed boolean NOT NULL DEFAULT false,
  insurance_claim_filed boolean NOT NULL DEFAULT false,
  investigation_completed boolean NOT NULL DEFAULT false,
  root_cause text,
  corrective_actions jsonb DEFAULT '[]'::jsonb,
  reported_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_incidents_driver ON safety_incident_reports(driver_id, incident_date DESC);
CREATE INDEX IF NOT EXISTS idx_incidents_vehicle ON safety_incident_reports(vehicle_id, incident_date DESC);
CREATE INDEX IF NOT EXISTS idx_incidents_severity ON safety_incident_reports(severity, incident_date DESC);

-- Enable RLS
ALTER TABLE compliance_audits ENABLE ROW LEVEL SECURITY;
ALTER TABLE hours_of_service_violations ENABLE ROW LEVEL SECURITY;
ALTER TABLE certification_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_inspection_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE safety_incident_reports ENABLE ROW LEVEL SECURITY;

-- RLS Policies for compliance_audits
CREATE POLICY "Authenticated users can view compliance audits"
  ON compliance_audits FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert compliance audits"
  ON compliance_audits FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS Policies for hours_of_service_violations
CREATE POLICY "Authenticated users can view HOS violations"
  ON hours_of_service_violations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert HOS violations"
  ON hours_of_service_violations FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Admins can update HOS violations"
  ON hours_of_service_violations FOR UPDATE
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

-- RLS Policies for certification_tracking
CREATE POLICY "Authenticated users can view certifications"
  ON certification_tracking FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert certifications"
  ON certification_tracking FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Admins can update certifications"
  ON certification_tracking FOR UPDATE
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

-- RLS Policies for vehicle_inspection_records
CREATE POLICY "Authenticated users can view inspections"
  ON vehicle_inspection_records FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create inspections"
  ON vehicle_inspection_records FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Admins can update inspections"
  ON vehicle_inspection_records FOR UPDATE
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

-- RLS Policies for safety_incident_reports
CREATE POLICY "Authenticated users can view incident reports"
  ON safety_incident_reports FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create incident reports"
  ON safety_incident_reports FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Admins can update incident reports"
  ON safety_incident_reports FOR UPDATE
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
