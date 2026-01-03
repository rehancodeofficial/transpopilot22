/*
  # Route Optimization and Planning System

  1. New Tables
    - `routes`
      - `id` (uuid, primary key)
      - `name` (text)
      - `description` (text)
      - `vehicle_id` (uuid, references vehicles)
      - `driver_id` (uuid, references drivers)
      - `status` (text) - 'planned', 'in_progress', 'completed', 'cancelled'
      - `optimization_score` (numeric) - 0-100 efficiency score
      - `estimated_distance` (numeric) - miles
      - `estimated_duration` (numeric) - minutes
      - `actual_distance` (numeric) - miles
      - `actual_duration` (numeric) - minutes
      - `fuel_estimate` (numeric) - gallons
      - `started_at` (timestamptz)
      - `completed_at` (timestamptz)
      - `created_at` (timestamptz)
    
    - `route_waypoints`
      - `id` (uuid, primary key)
      - `route_id` (uuid, references routes)
      - `sequence_number` (integer)
      - `name` (text)
      - `address` (text)
      - `latitude` (numeric)
      - `longitude` (numeric)
      - `estimated_arrival` (timestamptz)
      - `actual_arrival` (timestamptz)
      - `estimated_departure` (timestamptz)
      - `actual_departure` (timestamptz)
      - `status` (text) - 'pending', 'arrived', 'completed', 'skipped'
      - `notes` (text)
      - `created_at` (timestamptz)
    
    - `route_analytics`
      - `id` (uuid, primary key)
      - `route_id` (uuid, references routes)
      - `metric_type` (text) - 'fuel_efficiency', 'time_savings', 'distance_optimization'
      - `baseline_value` (numeric)
      - `optimized_value` (numeric)
      - `improvement_percentage` (numeric)
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Authenticated users can view routes
    - Admin users can create and manage routes
*/

-- Create routes table
CREATE TABLE IF NOT EXISTS routes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  vehicle_id uuid REFERENCES vehicles(id) ON DELETE SET NULL,
  driver_id uuid REFERENCES drivers(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'completed', 'cancelled')),
  optimization_score numeric(5, 2),
  estimated_distance numeric(10, 2),
  estimated_duration numeric(10, 2),
  actual_distance numeric(10, 2),
  actual_duration numeric(10, 2),
  fuel_estimate numeric(8, 2),
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_routes_vehicle ON routes(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_routes_driver ON routes(driver_id);
CREATE INDEX IF NOT EXISTS idx_routes_status ON routes(status);
CREATE INDEX IF NOT EXISTS idx_routes_created_at ON routes(created_at DESC);

ALTER TABLE routes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view routes"
  ON routes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin users can create routes"
  ON routes FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admin users can update routes"
  ON routes FOR UPDATE
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

CREATE POLICY "Admin users can delete routes"
  ON routes FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create route_waypoints table
CREATE TABLE IF NOT EXISTS route_waypoints (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id uuid NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  sequence_number integer NOT NULL,
  name text NOT NULL,
  address text,
  latitude numeric(10, 8) NOT NULL,
  longitude numeric(11, 8) NOT NULL,
  estimated_arrival timestamptz,
  actual_arrival timestamptz,
  estimated_departure timestamptz,
  actual_departure timestamptz,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'arrived', 'completed', 'skipped')),
  notes text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(route_id, sequence_number)
);

CREATE INDEX IF NOT EXISTS idx_route_waypoints_route 
  ON route_waypoints(route_id, sequence_number);

ALTER TABLE route_waypoints ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view waypoints"
  ON route_waypoints FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin users can manage waypoints"
  ON route_waypoints FOR ALL
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

-- Create route_analytics table
CREATE TABLE IF NOT EXISTS route_analytics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id uuid NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  metric_type text NOT NULL CHECK (metric_type IN ('fuel_efficiency', 'time_savings', 'distance_optimization', 'cost_savings')),
  baseline_value numeric(10, 2),
  optimized_value numeric(10, 2),
  improvement_percentage numeric(5, 2),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_route_analytics_route 
  ON route_analytics(route_id);

ALTER TABLE route_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view route analytics"
  ON route_analytics FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert route analytics"
  ON route_analytics FOR INSERT
  TO authenticated
  WITH CHECK (true);