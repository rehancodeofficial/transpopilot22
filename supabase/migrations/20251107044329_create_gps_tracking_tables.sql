/*
  # GPS Tracking and Fleet Management System

  1. New Tables
    - `admin_users`
      - `id` (uuid, primary key)
      - `email` (text, unique)
      - `password_hash` (text)
      - `full_name` (text)
      - `role` (text) - 'admin' or 'user'
      - `created_at` (timestamptz)
      - `last_login` (timestamptz)
    
    - `vehicle_locations`
      - `id` (uuid, primary key)
      - `vehicle_id` (uuid, references vehicles)
      - `latitude` (numeric)
      - `longitude` (numeric)
      - `speed` (numeric) - mph
      - `heading` (numeric) - degrees 0-360
      - `altitude` (numeric) - feet
      - `odometer` (numeric) - miles
      - `timestamp` (timestamptz)
      - `created_at` (timestamptz)
      - Index on vehicle_id and timestamp for efficient queries
    
    - `driver_locations`
      - `id` (uuid, primary key)
      - `driver_id` (uuid, references drivers)
      - `latitude` (numeric)
      - `longitude` (numeric)
      - `status` (text) - 'active', 'break', 'off_duty', 'driving'
      - `timestamp` (timestamptz)
      - `created_at` (timestamptz)
      - Index on driver_id and timestamp
    
    - `geofences`
      - `id` (uuid, primary key)
      - `name` (text)
      - `type` (text) - 'circular', 'polygon'
      - `coordinates` (jsonb) - stores center/radius or polygon points
      - `alert_on_entry` (boolean)
      - `alert_on_exit` (boolean)
      - `created_at` (timestamptz)
    
    - `geofence_events`
      - `id` (uuid, primary key)
      - `geofence_id` (uuid, references geofences)
      - `vehicle_id` (uuid, references vehicles)
      - `event_type` (text) - 'entry' or 'exit'
      - `timestamp` (timestamptz)
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Admin users can read all data
    - Regular users have restricted access
    - Integration settings require admin role
*/

-- Create admin_users table
CREATE TABLE IF NOT EXISTS admin_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  password_hash text NOT NULL,
  full_name text NOT NULL,
  role text NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user')),
  created_at timestamptz DEFAULT now(),
  last_login timestamptz
);

ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin users can read all users"
  ON admin_users FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      WHERE au.id = auth.uid() AND au.role = 'admin'
    )
    OR id = auth.uid()
  );

CREATE POLICY "Users can update own profile"
  ON admin_users FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Create vehicle_locations table
CREATE TABLE IF NOT EXISTS vehicle_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id uuid NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  latitude numeric(10, 8) NOT NULL,
  longitude numeric(11, 8) NOT NULL,
  speed numeric(6, 2) DEFAULT 0,
  heading numeric(5, 2),
  altitude numeric(8, 2),
  odometer numeric(10, 2),
  timestamp timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_vehicle_locations_vehicle_timestamp 
  ON vehicle_locations(vehicle_id, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_vehicle_locations_timestamp 
  ON vehicle_locations(timestamp DESC);

ALTER TABLE vehicle_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view vehicle locations"
  ON vehicle_locations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin users can insert vehicle locations"
  ON vehicle_locations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create driver_locations table
CREATE TABLE IF NOT EXISTS driver_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
  latitude numeric(10, 8) NOT NULL,
  longitude numeric(11, 8) NOT NULL,
  status text NOT NULL DEFAULT 'off_duty' CHECK (status IN ('active', 'break', 'off_duty', 'driving')),
  timestamp timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_driver_locations_driver_timestamp 
  ON driver_locations(driver_id, timestamp DESC);

ALTER TABLE driver_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view driver locations"
  ON driver_locations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin users can insert driver locations"
  ON driver_locations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create geofences table
CREATE TABLE IF NOT EXISTS geofences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  type text NOT NULL CHECK (type IN ('circular', 'polygon')),
  coordinates jsonb NOT NULL,
  alert_on_entry boolean DEFAULT false,
  alert_on_exit boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE geofences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view geofences"
  ON geofences FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin users can manage geofences"
  ON geofences FOR ALL
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

-- Create geofence_events table
CREATE TABLE IF NOT EXISTS geofence_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  geofence_id uuid NOT NULL REFERENCES geofences(id) ON DELETE CASCADE,
  vehicle_id uuid NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  event_type text NOT NULL CHECK (event_type IN ('entry', 'exit')),
  timestamp timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_geofence_events_timestamp 
  ON geofence_events(timestamp DESC);

ALTER TABLE geofence_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view geofence events"
  ON geofence_events FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert geofence events"
  ON geofence_events FOR INSERT
  TO authenticated
  WITH CHECK (true);