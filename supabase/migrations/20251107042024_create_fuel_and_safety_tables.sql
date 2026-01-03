/*
  # Create Fuel and Safety Tables

  ## New Tables
  
  ### `fuel_records`
  - `id` (uuid, primary key) - Unique fuel record identifier
  - `vehicle_id` (uuid, foreign key) - Vehicle that refueled
  - `driver_id` (uuid, foreign key) - Driver who refueled
  - `gallons` (decimal) - Gallons purchased
  - `cost_per_gallon` (decimal) - Price per gallon
  - `total_cost` (decimal) - Total transaction cost
  - `station_name` (text) - Fuel station name
  - `location` (text) - Station location
  - `odometer_reading` (integer) - Vehicle odometer at time of fuel
  - `mpg` (decimal) - Calculated miles per gallon
  - `transaction_date` (timestamptz) - Date and time of transaction
  - `created_at` (timestamptz) - Record creation timestamp

  ### `safety_incidents`
  - `id` (uuid, primary key) - Unique incident identifier
  - `vehicle_id` (uuid, foreign key) - Vehicle involved
  - `driver_id` (uuid, foreign key) - Driver involved
  - `incident_type` (text) - Type of incident
  - `severity` (text) - Severity level (low, medium, high, critical)
  - `description` (text) - Incident description
  - `location` (text) - Where incident occurred
  - `incident_date` (timestamptz) - When incident occurred
  - `status` (text) - Resolution status
  - `resolved_at` (timestamptz) - When incident was resolved
  - `created_at` (timestamptz) - Record creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### `compliance_items`
  - `id` (uuid, primary key) - Unique compliance item identifier
  - `item_type` (text) - Type of compliance item
  - `entity_type` (text) - What the item applies to (vehicle, driver)
  - `entity_id` (uuid) - ID of the entity
  - `due_date` (date) - When item is due
  - `completed_date` (date) - When item was completed
  - `status` (text) - Current status
  - `priority` (text) - Priority level
  - `notes` (text) - Additional notes
  - `created_at` (timestamptz) - Record creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ## Security
  - Enable RLS on all tables
  - Add policies for authenticated access
*/

-- Create fuel_records table
CREATE TABLE IF NOT EXISTS fuel_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id uuid REFERENCES vehicles(id) ON DELETE CASCADE NOT NULL,
  driver_id uuid REFERENCES drivers(id) ON DELETE SET NULL,
  gallons decimal(10, 2) NOT NULL CHECK (gallons > 0),
  cost_per_gallon decimal(10, 2) NOT NULL CHECK (cost_per_gallon > 0),
  total_cost decimal(10, 2) NOT NULL CHECK (total_cost > 0),
  station_name text,
  location text,
  odometer_reading integer CHECK (odometer_reading >= 0),
  mpg decimal(5, 2) CHECK (mpg > 0),
  transaction_date timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Create safety_incidents table
CREATE TABLE IF NOT EXISTS safety_incidents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id uuid REFERENCES vehicles(id) ON DELETE SET NULL,
  driver_id uuid REFERENCES drivers(id) ON DELETE SET NULL,
  incident_type text NOT NULL CHECK (incident_type IN ('near_miss', 'traffic_violation', 'minor_accident', 'major_accident', 'equipment_failure')),
  severity text NOT NULL DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  description text NOT NULL,
  location text,
  incident_date timestamptz NOT NULL DEFAULT now(),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'resolved', 'escalated')),
  resolved_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create compliance_items table
CREATE TABLE IF NOT EXISTS compliance_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  item_type text NOT NULL CHECK (item_type IN ('dot_inspection', 'license_renewal', 'medical_certificate', 'safety_training', 'vehicle_registration', 'insurance_renewal')),
  entity_type text NOT NULL CHECK (entity_type IN ('vehicle', 'driver')),
  entity_id uuid NOT NULL,
  due_date date NOT NULL,
  completed_date date,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'due_soon', 'overdue', 'completed')),
  priority text NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_fuel_records_vehicle ON fuel_records(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_fuel_records_driver ON fuel_records(driver_id);
CREATE INDEX IF NOT EXISTS idx_fuel_records_date ON fuel_records(transaction_date);
CREATE INDEX IF NOT EXISTS idx_safety_incidents_vehicle ON safety_incidents(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_safety_incidents_driver ON safety_incidents(driver_id);
CREATE INDEX IF NOT EXISTS idx_safety_incidents_status ON safety_incidents(status);
CREATE INDEX IF NOT EXISTS idx_compliance_items_entity ON compliance_items(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_compliance_items_status ON compliance_items(status);
CREATE INDEX IF NOT EXISTS idx_compliance_items_due_date ON compliance_items(due_date);

-- Enable Row Level Security
ALTER TABLE fuel_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE safety_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_items ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow authenticated users to read fuel_records"
  ON fuel_records FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert fuel_records"
  ON fuel_records FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to read safety_incidents"
  ON safety_incidents FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert safety_incidents"
  ON safety_incidents FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update safety_incidents"
  ON safety_incidents FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to read compliance_items"
  ON compliance_items FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert compliance_items"
  ON compliance_items FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update compliance_items"
  ON compliance_items FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);