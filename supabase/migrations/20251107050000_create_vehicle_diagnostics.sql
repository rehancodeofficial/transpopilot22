/*
  # Create Vehicle Diagnostics Table

  ## Overview
  This migration creates a comprehensive vehicle diagnostics tracking system for AI-powered
  vehicle health monitoring and predictive maintenance.

  ## New Tables

  ### `vehicle_diagnostics`
  Stores real-time diagnostic data and sensor readings from vehicles

  **Columns:**
  - `id` (uuid, primary key) - Unique diagnostic record identifier
  - `vehicle_id` (uuid, foreign key) - References vehicles table
  - `engine_temperature` (decimal) - Engine temperature in Fahrenheit
  - `oil_pressure` (decimal) - Oil pressure in PSI
  - `brake_wear_percentage` (decimal) - Brake pad wear percentage (0-100)
  - `tire_pressure_fl` (decimal) - Front left tire pressure in PSI
  - `tire_pressure_fr` (decimal) - Front right tire pressure in PSI
  - `tire_pressure_rl` (decimal) - Rear left tire pressure in PSI
  - `tire_pressure_rr` (decimal) - Rear right tire pressure in PSI
  - `transmission_temp` (decimal) - Transmission temperature in Fahrenheit
  - `diagnostic_codes` (text[]) - Array of diagnostic trouble codes (DTCs)
  - `health_score` (decimal) - Overall health score (0-100)
  - `recorded_at` (timestamptz) - Timestamp when diagnostics were recorded
  - `created_at` (timestamptz) - Record creation timestamp

  ## Security
  - Enable RLS on vehicle_diagnostics table
  - Add policies for authenticated users to read and insert diagnostic data
  - Restrict updates to maintain data integrity

  ## Indexes
  - Index on vehicle_id for fast vehicle-specific queries
  - Index on recorded_at for time-based queries and trending analysis
  - Index on health_score for identifying vehicles needing attention

  ## Important Notes
  1. Diagnostic data is append-only to preserve historical records
  2. Used by AI algorithms for predictive maintenance
  3. Supports real-time vehicle health monitoring
  4. Data retention policy should be defined separately
*/

-- Create vehicle_diagnostics table
CREATE TABLE IF NOT EXISTS vehicle_diagnostics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id uuid REFERENCES vehicles(id) ON DELETE CASCADE NOT NULL,
  engine_temperature decimal(5, 2) CHECK (engine_temperature >= 0 AND engine_temperature <= 500),
  oil_pressure decimal(5, 2) CHECK (oil_pressure >= 0 AND oil_pressure <= 200),
  brake_wear_percentage decimal(5, 2) DEFAULT 0 CHECK (brake_wear_percentage >= 0 AND brake_wear_percentage <= 100),
  tire_pressure_fl decimal(5, 2) CHECK (tire_pressure_fl >= 0 AND tire_pressure_fl <= 150),
  tire_pressure_fr decimal(5, 2) CHECK (tire_pressure_fr >= 0 AND tire_pressure_fr <= 150),
  tire_pressure_rl decimal(5, 2) CHECK (tire_pressure_rl >= 0 AND tire_pressure_rl <= 150),
  tire_pressure_rr decimal(5, 2) CHECK (tire_pressure_rr >= 0 AND tire_pressure_rr <= 150),
  transmission_temp decimal(5, 2) CHECK (transmission_temp >= 0 AND transmission_temp <= 400),
  diagnostic_codes text[] DEFAULT '{}',
  health_score decimal(5, 2) DEFAULT 100 CHECK (health_score >= 0 AND health_score <= 100),
  recorded_at timestamptz DEFAULT now() NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create indexes for performance optimization
CREATE INDEX IF NOT EXISTS idx_vehicle_diagnostics_vehicle_id
  ON vehicle_diagnostics(vehicle_id);

CREATE INDEX IF NOT EXISTS idx_vehicle_diagnostics_recorded_at
  ON vehicle_diagnostics(recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_vehicle_diagnostics_health_score
  ON vehicle_diagnostics(health_score);

CREATE INDEX IF NOT EXISTS idx_vehicle_diagnostics_vehicle_recorded
  ON vehicle_diagnostics(vehicle_id, recorded_at DESC);

-- Enable Row Level Security
ALTER TABLE vehicle_diagnostics ENABLE ROW LEVEL SECURITY;

-- Create policies for authenticated access
CREATE POLICY "Allow authenticated users to read vehicle diagnostics"
  ON vehicle_diagnostics FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert vehicle diagnostics"
  ON vehicle_diagnostics FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Create a function to automatically calculate health score based on diagnostic data
CREATE OR REPLACE FUNCTION calculate_vehicle_health_score(
  p_engine_temp decimal,
  p_oil_pressure decimal,
  p_brake_wear decimal,
  p_tire_pressures decimal[],
  p_transmission_temp decimal,
  p_diagnostic_codes text[]
)
RETURNS decimal AS $$
DECLARE
  v_health_score decimal := 100;
  v_optimal_engine_temp decimal := 195;
  v_optimal_oil_pressure decimal := 30;
  v_optimal_tire_pressure decimal := 110;
  v_optimal_transmission_temp decimal := 195;
BEGIN
  -- Deduct points for engine temperature deviation
  IF p_engine_temp IS NOT NULL THEN
    IF p_engine_temp > 220 OR p_engine_temp < 160 THEN
      v_health_score := v_health_score - 10;
    ELSIF p_engine_temp > 210 OR p_engine_temp < 170 THEN
      v_health_score := v_health_score - 5;
    END IF;
  END IF;

  -- Deduct points for low oil pressure
  IF p_oil_pressure IS NOT NULL THEN
    IF p_oil_pressure < 15 THEN
      v_health_score := v_health_score - 15;
    ELSIF p_oil_pressure < 20 THEN
      v_health_score := v_health_score - 8;
    END IF;
  END IF;

  -- Deduct points for brake wear
  IF p_brake_wear IS NOT NULL THEN
    IF p_brake_wear > 80 THEN
      v_health_score := v_health_score - 20;
    ELSIF p_brake_wear > 60 THEN
      v_health_score := v_health_score - 10;
    ELSIF p_brake_wear > 40 THEN
      v_health_score := v_health_score - 5;
    END IF;
  END IF;

  -- Deduct points for tire pressure issues
  IF p_tire_pressures IS NOT NULL AND array_length(p_tire_pressures, 1) >= 4 THEN
    FOR i IN 1..4 LOOP
      IF p_tire_pressures[i] < 90 OR p_tire_pressures[i] > 130 THEN
        v_health_score := v_health_score - 5;
      END IF;
    END LOOP;
  END IF;

  -- Deduct points for transmission temperature
  IF p_transmission_temp IS NOT NULL THEN
    IF p_transmission_temp > 230 THEN
      v_health_score := v_health_score - 15;
    ELSIF p_transmission_temp > 210 THEN
      v_health_score := v_health_score - 7;
    END IF;
  END IF;

  -- Deduct points for diagnostic trouble codes
  IF p_diagnostic_codes IS NOT NULL AND array_length(p_diagnostic_codes, 1) > 0 THEN
    v_health_score := v_health_score - (array_length(p_diagnostic_codes, 1) * 10);
  END IF;

  -- Ensure score stays within bounds
  IF v_health_score < 0 THEN
    v_health_score := 0;
  END IF;

  RETURN v_health_score;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create a trigger to automatically calculate health score on insert
CREATE OR REPLACE FUNCTION auto_calculate_health_score()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.health_score = 100 OR NEW.health_score IS NULL THEN
    NEW.health_score := calculate_vehicle_health_score(
      NEW.engine_temperature,
      NEW.oil_pressure,
      NEW.brake_wear_percentage,
      ARRAY[NEW.tire_pressure_fl, NEW.tire_pressure_fr, NEW.tire_pressure_rl, NEW.tire_pressure_rr],
      NEW.transmission_temp,
      NEW.diagnostic_codes
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_health_score
  BEFORE INSERT ON vehicle_diagnostics
  FOR EACH ROW
  EXECUTE FUNCTION auto_calculate_health_score();
