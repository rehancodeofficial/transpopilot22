/*
  # Add Display Fields to Vehicles Table

  ## Overview
  Adds user-friendly display fields to the vehicles table to support
  the Live Tracking interface and other UI components.

  ## Changes
  
  1. New Columns
    - `name` (text) - Display name for the vehicle (e.g., "Delivery Truck 1")
    - `license_plate` (text) - Vehicle license plate number
    - `driver_id` (uuid) - Foreign key reference to drivers table
  
  2. Data Population
    - Auto-generates names from make/model
    - Creates license plates in format: ABC-1234
  
  ## Security
  - No RLS policy changes needed
  - Existing policies cover these new fields
*/

-- Add new columns to vehicles table
ALTER TABLE vehicles 
ADD COLUMN IF NOT EXISTS name text,
ADD COLUMN IF NOT EXISTS license_plate text,
ADD COLUMN IF NOT EXISTS driver_id uuid REFERENCES drivers(id);

-- Populate name field with make + model + year
UPDATE vehicles
SET name = make || ' ' || model || ' ' || year::text
WHERE name IS NULL;

-- Populate license_plate with simple sequential plates
WITH numbered_vehicles AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) as row_num
  FROM vehicles
  WHERE license_plate IS NULL
)
UPDATE vehicles v
SET license_plate = 'FL-' || LPAD(nv.row_num::text, 4, '0')
FROM numbered_vehicles nv
WHERE v.id = nv.id;