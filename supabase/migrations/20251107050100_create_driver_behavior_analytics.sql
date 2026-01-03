/*
  # Create Driver Behavior Analytics Table

  ## Overview
  This migration creates a comprehensive driver behavior tracking system for AI-powered
  driver performance analysis, safety monitoring, and coaching recommendations.

  ## New Tables

  ### `driver_behavior_analytics`
  Stores detailed driver behavior metrics collected from telematics devices

  **Columns:**
  - `id` (uuid, primary key) - Unique behavior record identifier
  - `driver_id` (uuid, foreign key) - References drivers table
  - `harsh_acceleration_count` (integer) - Number of harsh acceleration events
  - `harsh_braking_count` (integer) - Number of hard braking events
  - `speed_violations_count` (integer) - Number of speed limit violations
  - `idle_time_minutes` (decimal) - Total idle time in minutes
  - `total_distance_miles` (decimal) - Total distance driven in miles
  - `total_drive_time_hours` (decimal) - Total driving time in hours
  - `average_speed_mph` (decimal) - Average speed during the period
  - `max_speed_mph` (decimal) - Maximum speed reached
  - `fuel_consumption_gallons` (decimal) - Fuel consumed during the period
  - `cornering_events` (integer) - Number of aggressive cornering events
  - `nighttime_driving_hours` (decimal) - Hours driven at night
  - `behavior_score` (decimal) - Calculated behavior score (0-100)
  - `recorded_date` (date) - Date of the recorded behavior data
  - `created_at` (timestamptz) - Record creation timestamp

  ## Security
  - Enable RLS on driver_behavior_analytics table
  - Add policies for authenticated users to read and insert behavior data
  - Restrict access to ensure driver privacy and compliance

  ## Indexes
  - Index on driver_id for fast driver-specific queries
  - Index on recorded_date for time-series analysis
  - Index on behavior_score for performance rankings
  - Composite index on driver_id and recorded_date for trend analysis

  ## Important Notes
  1. Data is collected daily or per-trip from telematics devices
  2. Used by AI algorithms for driver coaching and risk assessment
  3. Supports real-time driver behavior monitoring and leaderboards
  4. Privacy considerations: data should be anonymized for fleet-wide analytics
  5. Retention policy should comply with data protection regulations
*/

-- Create driver_behavior_analytics table
CREATE TABLE IF NOT EXISTS driver_behavior_analytics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid REFERENCES drivers(id) ON DELETE CASCADE NOT NULL,
  harsh_acceleration_count integer DEFAULT 0 CHECK (harsh_acceleration_count >= 0),
  harsh_braking_count integer DEFAULT 0 CHECK (harsh_braking_count >= 0),
  speed_violations_count integer DEFAULT 0 CHECK (speed_violations_count >= 0),
  idle_time_minutes decimal(10, 2) DEFAULT 0 CHECK (idle_time_minutes >= 0),
  total_distance_miles decimal(10, 2) DEFAULT 0 CHECK (total_distance_miles >= 0),
  total_drive_time_hours decimal(10, 2) DEFAULT 0 CHECK (total_drive_time_hours >= 0),
  average_speed_mph decimal(5, 2) CHECK (average_speed_mph >= 0 AND average_speed_mph <= 200),
  max_speed_mph decimal(5, 2) CHECK (max_speed_mph >= 0 AND max_speed_mph <= 200),
  fuel_consumption_gallons decimal(10, 2) DEFAULT 0 CHECK (fuel_consumption_gallons >= 0),
  cornering_events integer DEFAULT 0 CHECK (cornering_events >= 0),
  nighttime_driving_hours decimal(10, 2) DEFAULT 0 CHECK (nighttime_driving_hours >= 0),
  behavior_score decimal(5, 2) DEFAULT 100 CHECK (behavior_score >= 0 AND behavior_score <= 100),
  recorded_date date DEFAULT CURRENT_DATE NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create indexes for performance optimization
CREATE INDEX IF NOT EXISTS idx_driver_behavior_driver_id
  ON driver_behavior_analytics(driver_id);

CREATE INDEX IF NOT EXISTS idx_driver_behavior_recorded_date
  ON driver_behavior_analytics(recorded_date DESC);

CREATE INDEX IF NOT EXISTS idx_driver_behavior_score
  ON driver_behavior_analytics(behavior_score);

CREATE INDEX IF NOT EXISTS idx_driver_behavior_driver_date
  ON driver_behavior_analytics(driver_id, recorded_date DESC);

-- Create unique constraint to prevent duplicate daily records per driver
CREATE UNIQUE INDEX IF NOT EXISTS idx_driver_behavior_unique_daily
  ON driver_behavior_analytics(driver_id, recorded_date);

-- Enable Row Level Security
ALTER TABLE driver_behavior_analytics ENABLE ROW LEVEL SECURITY;

-- Create policies for authenticated access
CREATE POLICY "Allow authenticated users to read driver behavior analytics"
  ON driver_behavior_analytics FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert driver behavior analytics"
  ON driver_behavior_analytics FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update driver behavior analytics"
  ON driver_behavior_analytics FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Create a function to calculate driver behavior score
CREATE OR REPLACE FUNCTION calculate_driver_behavior_score(
  p_harsh_acceleration integer,
  p_harsh_braking integer,
  p_speed_violations integer,
  p_idle_time decimal,
  p_total_drive_time decimal,
  p_total_distance decimal,
  p_cornering_events integer
)
RETURNS decimal AS $$
DECLARE
  v_behavior_score decimal := 100;
  v_events_per_100_miles decimal;
BEGIN
  -- Calculate events per 100 miles for normalization
  IF p_total_distance > 0 THEN
    v_events_per_100_miles := (p_harsh_acceleration + p_harsh_braking + p_speed_violations + p_cornering_events) * 100.0 / p_total_distance;
  ELSE
    v_events_per_100_miles := 0;
  END IF;

  -- Deduct points based on harsh acceleration (2 points per event per 100 miles)
  IF p_total_distance > 0 THEN
    v_behavior_score := v_behavior_score - (p_harsh_acceleration * 100.0 / p_total_distance * 2);
  END IF;

  -- Deduct points based on harsh braking (2 points per event per 100 miles)
  IF p_total_distance > 0 THEN
    v_behavior_score := v_behavior_score - (p_harsh_braking * 100.0 / p_total_distance * 2);
  END IF;

  -- Deduct points based on speed violations (3 points per violation per 100 miles)
  IF p_total_distance > 0 THEN
    v_behavior_score := v_behavior_score - (p_speed_violations * 100.0 / p_total_distance * 3);
  END IF;

  -- Deduct points based on excessive idle time (0.5 points per hour of idle time)
  IF p_total_drive_time > 0 THEN
    v_behavior_score := v_behavior_score - ((p_idle_time / 60.0) * 0.5);
  END IF;

  -- Deduct points based on aggressive cornering (1.5 points per event per 100 miles)
  IF p_total_distance > 0 THEN
    v_behavior_score := v_behavior_score - (p_cornering_events * 100.0 / p_total_distance * 1.5);
  END IF;

  -- Ensure score stays within bounds
  IF v_behavior_score < 0 THEN
    v_behavior_score := 0;
  ELSIF v_behavior_score > 100 THEN
    v_behavior_score := 100;
  END IF;

  RETURN v_behavior_score;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create a trigger to automatically calculate behavior score on insert/update
CREATE OR REPLACE FUNCTION auto_calculate_behavior_score()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.behavior_score = 100 OR NEW.behavior_score IS NULL THEN
    NEW.behavior_score := calculate_driver_behavior_score(
      NEW.harsh_acceleration_count,
      NEW.harsh_braking_count,
      NEW.speed_violations_count,
      NEW.idle_time_minutes,
      NEW.total_drive_time_hours,
      NEW.total_distance_miles,
      NEW.cornering_events
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_behavior_score
  BEFORE INSERT OR UPDATE ON driver_behavior_analytics
  FOR EACH ROW
  EXECUTE FUNCTION auto_calculate_behavior_score();

-- Create a view for driver performance summary
CREATE OR REPLACE VIEW driver_performance_summary AS
SELECT
  d.id AS driver_id,
  d.first_name,
  d.last_name,
  d.email,
  d.safety_score AS overall_safety_score,
  COUNT(dba.id) AS total_records,
  AVG(dba.behavior_score) AS avg_behavior_score,
  SUM(dba.total_distance_miles) AS total_miles_driven,
  SUM(dba.harsh_acceleration_count) AS total_harsh_accelerations,
  SUM(dba.harsh_braking_count) AS total_harsh_brakings,
  SUM(dba.speed_violations_count) AS total_speed_violations,
  AVG(dba.idle_time_minutes) AS avg_idle_time,
  MAX(dba.recorded_date) AS last_recorded_date
FROM drivers d
LEFT JOIN driver_behavior_analytics dba ON d.id = dba.driver_id
WHERE d.status = 'active'
GROUP BY d.id, d.first_name, d.last_name, d.email, d.safety_score
ORDER BY avg_behavior_score DESC NULLS LAST;

-- Grant select permission on the view to authenticated users
GRANT SELECT ON driver_performance_summary TO authenticated;
