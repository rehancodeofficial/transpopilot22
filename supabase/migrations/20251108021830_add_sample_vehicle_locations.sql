/*
  # Add Sample Vehicle Location Data

  ## Overview
  Populates the vehicle_locations table with realistic GPS tracking data
  for testing and demonstration of the Live Tracking feature.

  ## Data Added
  - GPS coordinates around Miami, FL area
  - Realistic speeds (0-65 mph)
  - Heading data (0-359 degrees)
  - Recent timestamps
  - Odometer readings

  ## Security
  - Uses existing RLS policies
  - Data is for authenticated users only
*/

-- Insert sample location data for each vehicle with realistic Miami coordinates
INSERT INTO vehicle_locations (
  vehicle_id,
  latitude,
  longitude,
  speed,
  heading,
  altitude,
  odometer,
  timestamp
)
SELECT 
  v.id,
  -- Miami area coordinates with slight variations
  25.7617 + (random() * 0.2 - 0.1) as latitude,
  -80.1918 + (random() * 0.2 - 0.1) as longitude,
  -- Random realistic speeds (0-65 mph)
  (random() * 65)::int as speed,
  -- Random heading (0-359 degrees)
  (random() * 359)::int as heading,
  -- Altitude around sea level with variation
  (10 + random() * 20)::int as altitude,
  -- Odometer reading
  (50000 + random() * 50000)::int as odometer,
  -- Recent timestamp (within last 5 minutes)
  NOW() - (random() * interval '5 minutes') as timestamp
FROM vehicles v
WHERE NOT EXISTS (
  SELECT 1 FROM vehicle_locations vl WHERE vl.vehicle_id = v.id
);

-- Add a few more historical data points for variety
INSERT INTO vehicle_locations (
  vehicle_id,
  latitude,
  longitude,
  speed,
  heading,
  altitude,
  odometer,
  timestamp
)
SELECT 
  v.id,
  25.7617 + (random() * 0.2 - 0.1) as latitude,
  -80.1918 + (random() * 0.2 - 0.1) as longitude,
  (random() * 65)::int as speed,
  (random() * 359)::int as heading,
  (10 + random() * 20)::int as altitude,
  (50000 + random() * 50000)::int as odometer,
  NOW() - interval '10 minutes' - (random() * interval '5 minutes') as timestamp
FROM vehicles v
LIMIT 5;