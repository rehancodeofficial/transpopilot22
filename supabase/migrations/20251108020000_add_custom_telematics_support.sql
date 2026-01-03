/*
  # Add Custom Telematics Support

  1. Changes
    - Modify integration_providers name constraint to include 'custom'
    - Insert custom telematics provider with default configuration

  2. Purpose
    - Enable integration with custom/generic telematics systems
    - Allow flexibility for non-standard telematics providers

  3. Security
    - Maintains existing RLS policies for admin-only access
*/

-- Drop the existing constraint and recreate with 'custom' included
ALTER TABLE integration_providers
  DROP CONSTRAINT IF EXISTS integration_providers_name_check;

ALTER TABLE integration_providers
  ADD CONSTRAINT integration_providers_name_check
  CHECK (name IN ('geotab', 'samsara', 'motive', 'custom'));

-- Insert custom telematics provider
INSERT INTO integration_providers (name, display_name, logo_url, is_enabled, connection_status)
VALUES
  ('custom', 'Custom Telematics', NULL, false, 'disconnected')
ON CONFLICT (name) DO NOTHING;
