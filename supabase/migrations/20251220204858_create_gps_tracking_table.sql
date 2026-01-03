/*
  # Create GPS Tracking Table
  
  ## Overview
  Creates the gps_tracking table that is referenced by the seed_user_demo_data function.
  This table stores real-time GPS tracking data for vehicles.
  
  ## Changes
  1. Create gps_tracking table with columns:
     - id (uuid, primary key)
     - vehicle_id (uuid, references vehicles)
     - latitude (numeric)
     - longitude (numeric)
     - speed (numeric) - miles per hour
     - heading (numeric) - degrees 0-360
     - altitude (numeric) - feet above sea level
     - timestamp (timestamptz) - when the GPS reading was captured
     - created_at (timestamptz) - when the record was created
  
  2. Security
     - Enable RLS on gps_tracking table
     - Add policy for authenticated users to view GPS tracking data within their organization
     - Add policy for authenticated users to insert GPS tracking data
  
  ## Important Notes
  - This table is used by seed_user_demo_data function to create sample GPS data
  - Indexes on vehicle_id and timestamp for efficient queries
  - GPS data is scoped to organization through vehicle relationship
*/

-- Create gps_tracking table
CREATE TABLE IF NOT EXISTS gps_tracking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id uuid NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  latitude numeric(10, 8) NOT NULL,
  longitude numeric(11, 8) NOT NULL,
  speed numeric(6, 2) DEFAULT 0,
  heading numeric(5, 2),
  altitude numeric(8, 2),
  timestamp timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_gps_tracking_vehicle_timestamp 
  ON gps_tracking(vehicle_id, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_gps_tracking_timestamp 
  ON gps_tracking(timestamp DESC);

-- Enable RLS
ALTER TABLE gps_tracking ENABLE ROW LEVEL SECURITY;

-- Policy: Authenticated users can view GPS tracking data for vehicles in their organization
CREATE POLICY "Users can view GPS tracking in their organization"
  ON gps_tracking FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM vehicles v
      INNER JOIN user_profiles up ON v.organization_id = up.organization_id
      WHERE v.id = gps_tracking.vehicle_id
      AND up.id = auth.uid()
    )
  );

-- Policy: Authenticated users can insert GPS tracking data
CREATE POLICY "Users can insert GPS tracking data"
  ON gps_tracking FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM vehicles v
      INNER JOIN user_profiles up ON v.organization_id = up.organization_id
      WHERE v.id = gps_tracking.vehicle_id
      AND up.id = auth.uid()
    )
  );

-- Policy: Service role can manage all GPS tracking data (for edge functions)
CREATE POLICY "Service role can manage GPS tracking"
  ON gps_tracking FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
