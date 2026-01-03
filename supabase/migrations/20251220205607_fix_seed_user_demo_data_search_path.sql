/*
  # Fix seed_user_demo_data Function Search Path
  
  ## Overview
  Updates the seed_user_demo_data function to have an immutable search_path.
  Functions with mutable search_paths can be vulnerable to search_path hijacking attacks.
  
  ## Changes
  - Adds SET search_path to 'public', 'pg_temp' to the function definition
  - This prevents malicious users from injecting their own schemas into the search path
  
  ## Security Impact
  - Protects against search_path hijacking attacks
  - Ensures function always uses the correct schema
  - Follows PostgreSQL security best practices
*/

-- Drop and recreate the function with proper search_path
CREATE OR REPLACE FUNCTION public.seed_user_demo_data(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  vehicle1_id uuid;
  vehicle2_id uuid;
  vehicle3_id uuid;
  driver1_id uuid;
  driver2_id uuid;
  driver3_id uuid;
  demo_mode_enabled boolean;
  user_organization_id uuid;
  unique_suffix text;
BEGIN
  -- Get user's demo mode status and organization_id
  SELECT demo_mode, organization_id INTO demo_mode_enabled, user_organization_id
  FROM user_profiles
  WHERE id = target_user_id;

  -- Generate unique suffix based on user ID (first 8 chars)
  unique_suffix := SUBSTRING(target_user_id::text, 1, 8);

  -- Only seed if demo mode is enabled, user has an organization, and user has no vehicles
  IF demo_mode_enabled AND user_organization_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM vehicles WHERE organization_id = user_organization_id
  ) THEN

    -- Insert sample drivers with organization_id
    INSERT INTO drivers (
      user_id,
      organization_id,
      name,
      license_number,
      license_class,
      phone,
      email,
      status,
      hire_date
    )
    VALUES
    (
      target_user_id,
      user_organization_id,
      'John Mitchell',
      'CDL-A-' || unique_suffix || '-01',
      'A',
      '555-0101',
      'john.mitchell.' || unique_suffix || '@demo.com',
      'active',
      NOW() - INTERVAL '2 years'
    )
    RETURNING id INTO driver1_id;

    INSERT INTO drivers (
      user_id,
      organization_id,
      name,
      license_number,
      license_class,
      phone,
      email,
      status,
      hire_date
    )
    VALUES
    (
      target_user_id,
      user_organization_id,
      'Sarah Williams',
      'CDL-A-' || unique_suffix || '-02',
      'A',
      '555-0102',
      'sarah.williams.' || unique_suffix || '@demo.com',
      'active',
      NOW() - INTERVAL '1 year'
    )
    RETURNING id INTO driver2_id;

    INSERT INTO drivers (
      user_id,
      organization_id,
      name,
      license_number,
      license_class,
      phone,
      email,
      status,
      hire_date
    )
    VALUES
    (
      target_user_id,
      user_organization_id,
      'Mike Rodriguez',
      'CDL-B-' || unique_suffix || '-03',
      'B',
      '555-0103',
      'mike.rodriguez.' || unique_suffix || '@demo.com',
      'active',
      NOW() - INTERVAL '6 months'
    )
    RETURNING id INTO driver3_id;

    -- Insert sample vehicles with organization_id
    INSERT INTO vehicles (
      user_id,
      organization_id,
      make,
      model,
      year,
      vin,
      license_plate,
      status,
      driver_id,
      current_location,
      current_latitude,
      current_longitude
    )
    VALUES
    (
      target_user_id,
      user_organization_id,
      'Freightliner',
      'Cascadia',
      2022,
      'VIN1FLT' || unique_suffix || 'AB',
      'TRK-' || unique_suffix || '-01',
      'active',
      driver1_id,
      'En route to Dallas, TX',
      32.7767,
      -96.7970
    )
    RETURNING id INTO vehicle1_id;

    INSERT INTO vehicles (
      user_id,
      organization_id,
      make,
      model,
      year,
      vin,
      license_plate,
      status,
      driver_id,
      current_location,
      current_latitude,
      current_longitude
    )
    VALUES
    (
      target_user_id,
      user_organization_id,
      'Kenworth',
      'T680',
      2023,
      'VIN2KEN' || unique_suffix || 'BC',
      'TRK-' || unique_suffix || '-02',
      'active',
      driver2_id,
      'Parked at warehouse - Atlanta, GA',
      33.7490,
      -84.3880
    )
    RETURNING id INTO vehicle2_id;

    INSERT INTO vehicles (
      user_id,
      organization_id,
      make,
      model,
      year,
      vin,
      license_plate,
      status,
      driver_id,
      current_location,
      current_latitude,
      current_longitude
    )
    VALUES
    (
      target_user_id,
      user_organization_id,
      'Peterbilt',
      '579',
      2021,
      'VIN3PET' || unique_suffix || 'CD',
      'TRK-' || unique_suffix || '-03',
      'maintenance',
      driver3_id,
      'Service center - Phoenix, AZ',
      33.4484,
      -112.0740
    )
    RETURNING id INTO vehicle3_id;

    -- Insert sample GPS tracking data for active vehicles
    INSERT INTO gps_tracking (vehicle_id, latitude, longitude, speed, heading, altitude, timestamp)
    VALUES
      (vehicle1_id, 32.7767, -96.7970, 65.5, 180, 450, NOW()),
      (vehicle2_id, 33.7490, -84.3880, 0, 0, 1050, NOW());

  END IF;
END;
$function$;
