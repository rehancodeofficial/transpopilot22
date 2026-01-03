/*
  # Seed Initial Demo Data

  ## Purpose
  Populate the database with sample data for demonstration and testing purposes.
  This includes vehicles, drivers, routes, fuel records, safety incidents, compliance items, and training modules.

  ## Data Created
  - 10 sample vehicles
  - 10 sample drivers
  - 5 sample routes
  - Sample fuel records
  - Sample safety incidents
  - Sample compliance items
  - Sample training modules
*/

-- Insert sample vehicles
INSERT INTO vehicles (vehicle_number, make, model, year, vin, status, current_mileage, fuel_capacity) VALUES
  ('TRK-1205', 'Freightliner', 'Cascadia', 2022, '1FUJGHDV8NLAA1205', 'active', 45230, 150.0),
  ('TRK-1156', 'Kenworth', 'T680', 2021, '1XKDD49X1LJ123456', 'active', 67890, 150.0),
  ('TRK-1089', 'Peterbilt', '579', 2023, '1XPWD40X6FD089123', 'active', 23450, 150.0),
  ('TRK-1247', 'Volvo', 'VNL', 2022, '4V4NC9EH9HN247890', 'maintenance', 89234, 150.0),
  ('TRK-1203', 'International', 'LT Series', 2021, '3AKJGLDR5LSLA1203', 'active', 56780, 150.0),
  ('TRK-1178', 'Freightliner', 'Cascadia', 2023, '1FUJGHDV9NLAA1178', 'active', 12340, 150.0),
  ('TRK-1192', 'Kenworth', 'T680', 2022, '1XKDD49X3LJ192456', 'active', 34560, 150.0),
  ('TRK-1234', 'Peterbilt', '389', 2021, '1XPWD40X8FD234567', 'active', 78900, 150.0),
  ('TRK-1256', 'Volvo', 'VNL', 2023, '4V4NC9EH1HN256789', 'active', 15670, 150.0),
  ('TRK-1267', 'Mack', 'Anthem', 2022, '1M1AE16Y9LM267890', 'active', 45670, 150.0)
ON CONFLICT (vehicle_number) DO NOTHING;

-- Insert sample drivers
INSERT INTO drivers (first_name, last_name, email, phone, license_number, license_expiry, hire_date, status, safety_score) VALUES
  ('John', 'Smith', 'john.smith@example.com', '555-0101', 'DL12345678', '2026-06-15', '2020-03-15', 'active', 98.7),
  ('Sarah', 'Wilson', 'sarah.wilson@example.com', '555-0102', 'DL23456789', '2025-08-20', '2019-07-22', 'active', 99.2),
  ('Mike', 'Johnson', 'mike.johnson@example.com', '555-0103', 'DL34567890', '2026-03-10', '2021-01-10', 'active', 97.5),
  ('Tom', 'Anderson', 'tom.anderson@example.com', '555-0104', 'DL45678901', '2025-11-30', '2022-05-18', 'active', 96.8),
  ('Lisa', 'Brown', 'lisa.brown@example.com', '555-0105', 'DL56789012', '2026-09-25', '2020-11-03', 'active', 98.1),
  ('David', 'Lee', 'david.lee@example.com', '555-0106', 'DL67890123', '2025-12-15', '2021-08-14', 'active', 95.6),
  ('Alex', 'Rodriguez', 'alex.rodriguez@example.com', '555-0107', 'DL78901234', '2027-02-28', '2024-01-10', 'training', 0.0),
  ('Emma', 'Thompson', 'emma.thompson@example.com', '555-0108', 'DL89012345', '2027-01-15', '2024-01-08', 'training', 0.0),
  ('Marcus', 'Johnson', 'marcus.j@example.com', '555-0109', 'DL90123456', '2026-10-20', '2024-01-12', 'training', 0.0),
  ('Jennifer', 'Davis', 'jennifer.davis@example.com', '555-0110', 'DL01234567', '2025-07-18', '2019-04-25', 'active', 99.5)
ON CONFLICT (email) DO NOTHING;

-- Insert sample routes
INSERT INTO routes (route_name, origin, destination, distance_miles, estimated_duration_hours, optimized, fuel_savings_estimate, status, vehicle_id, driver_id)
SELECT 
  'Route A-15',
  'Los Angeles, CA',
  'Phoenix, AZ',
  373.0,
  5.5,
  true,
  45.20,
  'active',
  v.id,
  d.id
FROM vehicles v, drivers d
WHERE v.vehicle_number = 'TRK-1205' AND d.email = 'john.smith@example.com'
LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO routes (route_name, origin, destination, distance_miles, estimated_duration_hours, optimized, fuel_savings_estimate, status, vehicle_id, driver_id)
SELECT 
  'Route B-22',
  'Dallas, TX',
  'Houston, TX',
  239.0,
  3.5,
  true,
  32.80,
  'completed',
  v.id,
  d.id
FROM vehicles v, drivers d
WHERE v.vehicle_number = 'TRK-1156' AND d.email = 'sarah.wilson@example.com'
LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO routes (route_name, origin, destination, distance_miles, estimated_duration_hours, optimized, fuel_savings_estimate, status, vehicle_id, driver_id)
SELECT 
  'Route C-08',
  'Chicago, IL',
  'Indianapolis, IN',
  183.0,
  2.8,
  true,
  28.50,
  'active',
  v.id,
  d.id
FROM vehicles v, drivers d
WHERE v.vehicle_number = 'TRK-1089' AND d.email = 'mike.johnson@example.com'
LIMIT 1
ON CONFLICT DO NOTHING;

-- Insert sample training modules
INSERT INTO training_modules (title, description, duration_hours, module_type, required) VALUES
  ('Company Orientation', 'Introduction to company policies and procedures', 2.0, 'video', true),
  ('DOT Regulations', 'Federal transportation regulations and compliance', 3.0, 'interactive', true),
  ('Vehicle Safety Inspection', 'Pre-trip and post-trip inspection procedures', 1.5, 'hands_on', true),
  ('Defensive Driving', 'Advanced safety techniques and hazard awareness', 4.0, 'simulation', true),
  ('Customer Service', 'Professional interaction and service standards', 1.0, 'video', false)
ON CONFLICT DO NOTHING;

-- Insert sample compliance items
INSERT INTO compliance_items (item_type, entity_type, entity_id, due_date, status, priority)
SELECT 
  'dot_inspection',
  'vehicle',
  v.id,
  CURRENT_DATE - INTERVAL '5 days',
  'overdue',
  'critical'
FROM vehicles v
WHERE v.vehicle_number = 'TRK-1205'
LIMIT 1;

INSERT INTO compliance_items (item_type, entity_type, entity_id, due_date, status, priority)
SELECT 
  'license_renewal',
  'driver',
  d.id,
  CURRENT_DATE + INTERVAL '3 days',
  'due_soon',
  'high'
FROM drivers d
WHERE d.email = 'mike.johnson@example.com'
LIMIT 1;

INSERT INTO compliance_items (item_type, entity_type, entity_id, due_date, status, priority)
SELECT 
  'medical_certificate',
  'driver',
  d.id,
  CURRENT_DATE + INTERVAL '10 days',
  'pending',
  'medium'
FROM drivers d
WHERE d.email = 'sarah.wilson@example.com'
LIMIT 1;

-- Insert sample safety incidents
INSERT INTO safety_incidents (vehicle_id, driver_id, incident_type, severity, description, location, incident_date, status)
SELECT 
  v.id,
  d.id,
  'near_miss',
  'low',
  'Close call with pedestrian at intersection',
  'Downtown LA',
  now() - INTERVAL '2 hours',
  'resolved'
FROM vehicles v, drivers d
WHERE v.vehicle_number = 'TRK-1156' AND d.email = 'tom.anderson@example.com'
LIMIT 1;

INSERT INTO safety_incidents (vehicle_id, driver_id, incident_type, severity, description, location, incident_date, status)
SELECT 
  v.id,
  d.id,
  'traffic_violation',
  'medium',
  'Speeding ticket - 10 mph over limit',
  'Highway 101',
  now() - INTERVAL '4 hours',
  'under_review'
FROM vehicles v, drivers d
WHERE v.vehicle_number = 'TRK-1089' AND d.email = 'lisa.brown@example.com'
LIMIT 1;