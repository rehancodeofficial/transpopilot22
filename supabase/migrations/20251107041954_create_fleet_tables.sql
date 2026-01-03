/*
  # Create Fleet Management Tables

  ## New Tables
  
  ### `vehicles`
  - `id` (uuid, primary key) - Unique vehicle identifier
  - `vehicle_number` (text, unique) - Vehicle identification number
  - `make` (text) - Vehicle manufacturer
  - `model` (text) - Vehicle model
  - `year` (integer) - Manufacturing year
  - `vin` (text, unique) - Vehicle Identification Number
  - `status` (text) - Vehicle status (active, maintenance, inactive)
  - `current_mileage` (integer) - Current odometer reading
  - `fuel_capacity` (decimal) - Fuel tank capacity in gallons
  - `created_at` (timestamptz) - Record creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### `drivers`
  - `id` (uuid, primary key) - Unique driver identifier
  - `first_name` (text) - Driver first name
  - `last_name` (text) - Driver last name
  - `email` (text, unique) - Driver email address
  - `phone` (text) - Driver phone number
  - `license_number` (text, unique) - Driver's license number
  - `license_expiry` (date) - License expiration date
  - `hire_date` (date) - Date hired
  - `status` (text) - Driver status (active, training, inactive)
  - `safety_score` (decimal) - Driver safety score (0-100)
  - `created_at` (timestamptz) - Record creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### `routes`
  - `id` (uuid, primary key) - Unique route identifier
  - `route_name` (text) - Route name/identifier
  - `origin` (text) - Starting location
  - `destination` (text) - End location
  - `distance_miles` (decimal) - Route distance in miles
  - `estimated_duration_hours` (decimal) - Estimated time in hours
  - `optimized` (boolean) - Whether route is AI-optimized
  - `fuel_savings_estimate` (decimal) - Estimated fuel savings in dollars
  - `status` (text) - Route status (active, completed, planned)
  - `vehicle_id` (uuid, foreign key) - Assigned vehicle
  - `driver_id` (uuid, foreign key) - Assigned driver
  - `created_at` (timestamptz) - Record creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ## Security
  - Enable RLS on all tables
  - Add policies for authenticated access
*/

-- Create vehicles table
CREATE TABLE IF NOT EXISTS vehicles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_number text UNIQUE NOT NULL,
  make text NOT NULL,
  model text NOT NULL,
  year integer NOT NULL CHECK (year >= 1900 AND year <= 2100),
  vin text UNIQUE NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'maintenance', 'inactive')),
  current_mileage integer DEFAULT 0 CHECK (current_mileage >= 0),
  fuel_capacity decimal(10, 2) CHECK (fuel_capacity > 0),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create drivers table
CREATE TABLE IF NOT EXISTS drivers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name text NOT NULL,
  last_name text NOT NULL,
  email text UNIQUE NOT NULL CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  phone text,
  license_number text UNIQUE NOT NULL,
  license_expiry date NOT NULL,
  hire_date date NOT NULL DEFAULT CURRENT_DATE,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'training', 'inactive')),
  safety_score decimal(5, 2) DEFAULT 100.0 CHECK (safety_score >= 0 AND safety_score <= 100),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create routes table
CREATE TABLE IF NOT EXISTS routes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  route_name text NOT NULL,
  origin text NOT NULL,
  destination text NOT NULL,
  distance_miles decimal(10, 2) NOT NULL CHECK (distance_miles > 0),
  estimated_duration_hours decimal(5, 2) CHECK (estimated_duration_hours > 0),
  optimized boolean DEFAULT false,
  fuel_savings_estimate decimal(10, 2) DEFAULT 0,
  status text NOT NULL DEFAULT 'planned' CHECK (status IN ('active', 'completed', 'planned')),
  vehicle_id uuid REFERENCES vehicles(id) ON DELETE SET NULL,
  driver_id uuid REFERENCES drivers(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_vehicles_status ON vehicles(status);
CREATE INDEX IF NOT EXISTS idx_drivers_status ON drivers(status);
CREATE INDEX IF NOT EXISTS idx_routes_status ON routes(status);
CREATE INDEX IF NOT EXISTS idx_routes_vehicle ON routes(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_routes_driver ON routes(driver_id);

-- Enable Row Level Security
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;

-- Create policies for authenticated access
CREATE POLICY "Allow authenticated users to read vehicles"
  ON vehicles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert vehicles"
  ON vehicles FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update vehicles"
  ON vehicles FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to read drivers"
  ON drivers FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert drivers"
  ON drivers FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update drivers"
  ON drivers FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to read routes"
  ON routes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert routes"
  ON routes FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update routes"
  ON routes FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);