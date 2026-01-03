/*
  # Seed Sample Data for New Users

  1. Purpose
    - Create a database function that automatically seeds sample/demo data for new user accounts
    - Includes sample vehicles, drivers, and GPS locations
    - Only creates data if user has demo_mode enabled and no existing data

  2. Function
    - `seed_user_demo_data(user_id uuid)` - Creates sample data for a user
    - Should be called from the application after user signup

  3. Sample Data
    - 3 sample vehicles with realistic data
    - 3 sample drivers with realistic data
    - Sample GPS location points for live tracking demo
*/

-- Create function to seed demo data for a new user
CREATE OR REPLACE FUNCTION seed_user_demo_data(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  vehicle1_id uuid;
  vehicle2_id uuid;
  vehicle3_id uuid;
  driver1_id uuid;
  driver2_id uuid;
  driver3_id uuid;
  demo_mode_enabled boolean;
BEGIN
  -- Check if user has demo mode enabled
  SELECT demo_mode INTO demo_mode_enabled
  FROM user_profiles
  WHERE id = target_user_id;

  -- Only seed if demo mode is enabled and user has no vehicles
  IF demo_mode_enabled AND NOT EXISTS (
    SELECT 1 FROM vehicles WHERE user_id = target_user_id
  ) THEN
    
    -- Insert sample drivers
    INSERT INTO drivers (user_id, name, license_number, license_class, phone, email, status, hire_date)
    VALUES
      (target_user_id, 'John Mitchell', 'CDL-A-9847562', 'A', '555-0101', 'john.mitchell@demo.com', 'active', NOW() - INTERVAL '2 years')
      RETURNING id INTO driver1_id;

    INSERT INTO drivers (user_id, name, license_number, license_class, phone, email, status, hire_date)
    VALUES
      (target_user_id, 'Sarah Williams', 'CDL-A-8473621', 'A', '555-0102', 'sarah.williams@demo.com', 'active', NOW() - INTERVAL '1 year')
      RETURNING id INTO driver2_id;

    INSERT INTO drivers (user_id, name, license_number, license_class, phone, email, status, hire_date)
    VALUES
      (target_user_id, 'Mike Rodriguez', 'CDL-B-7362849', 'B', '555-0103', 'mike.rodriguez@demo.com', 'active', NOW() - INTERVAL '6 months')
      RETURNING id INTO driver3_id;

    -- Insert sample vehicles
    INSERT INTO vehicles (user_id, make, model, year, vin, license_plate, status, driver_id, current_location, current_latitude, current_longitude)
    VALUES
      (target_user_id, 'Freightliner', 'Cascadia', 2022, 'VIN1FLT234567890AB', 'TRK-1001', 'active', driver1_id, 'En route to Dallas, TX', 32.7767, -96.7970)
      RETURNING id INTO vehicle1_id;

    INSERT INTO vehicles (user_id, make, model, year, vin, license_plate, status, driver_id, current_location, current_latitude, current_longitude)
    VALUES
      (target_user_id, 'Kenworth', 'T680', 2023, 'VIN2KEN345678901BC', 'TRK-1002', 'active', driver2_id, 'Parked at warehouse - Atlanta, GA', 33.7490, -84.3880)
      RETURNING id INTO vehicle2_id;

    INSERT INTO vehicles (user_id, make, model, year, vin, license_plate, status, driver_id, current_location, current_latitude, current_longitude)
    VALUES
      (target_user_id, 'Peterbilt', '579', 2021, 'VIN3PET456789012CD', 'TRK-1003', 'maintenance', driver3_id, 'Service center - Phoenix, AZ', 33.4484, -112.0740)
      RETURNING id INTO vehicle3_id;

    -- Insert sample GPS tracking data for active vehicles
    INSERT INTO gps_tracking (vehicle_id, latitude, longitude, speed, heading, altitude, timestamp)
    VALUES
      (vehicle1_id, 32.7767, -96.7970, 65.5, 180, 450, NOW()),
      (vehicle2_id, 33.7490, -84.3880, 0, 0, 1050, NOW());

  END IF;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION seed_user_demo_data TO authenticated;
