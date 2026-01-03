/*
  # Fix Function Search Path

  ## Overview
  Fixes the create_organization_for_user function to use an immutable search_path.
  This prevents potential security issues where the search_path could be manipulated
  to redirect function calls to malicious objects.

  ## Changes
  1. Recreates create_organization_for_user with explicit search_path
  2. Sets search_path to 'public, pg_temp' which is immutable

  ## Security Impact
  - Prevents search_path manipulation attacks
  - Ensures function always references correct schema objects
  - Follows PostgreSQL security best practices
*/

-- Recreate function with explicit search_path
CREATE OR REPLACE FUNCTION create_organization_for_user(target_user_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  new_org_id uuid;
  user_email text;
  user_name text;
  org_name text;
  org_slug text;
BEGIN
  -- Get user details
  SELECT email INTO user_email FROM auth.users WHERE id = target_user_id;
  SELECT full_name INTO user_name FROM user_profiles WHERE id = target_user_id;
  
  -- Generate organization name
  org_name := COALESCE(user_name, split_part(user_email, '@', 1)) || ' Organization';
  
  -- Generate unique slug
  org_slug := generate_slug(org_name);
  
  -- Create organization
  INSERT INTO organizations (name, slug, subscription_tier, subscription_status)
  VALUES (org_name, org_slug, 'trial', 'trial')
  RETURNING id INTO new_org_id;
  
  -- Update user profile with organization_id and promote to admin
  UPDATE user_profiles
  SET organization_id = new_org_id,
      role = CASE 
        WHEN role = 'super_admin' THEN 'super_admin'
        ELSE 'admin'
      END,
      updated_at = NOW()
  WHERE id = target_user_id;
  
  -- Update drivers to link to organization (if they have user_id set)
  UPDATE drivers
  SET organization_id = new_org_id,
      updated_at = NOW()
  WHERE user_id = target_user_id
  AND (organization_id IS NULL OR organization_id != new_org_id);
  
  -- Update vehicles to link to organization (vehicles linked through drivers)
  UPDATE vehicles v
  SET organization_id = new_org_id,
      updated_at = NOW()
  WHERE v.driver_id IN (
    SELECT d.id FROM drivers d WHERE d.user_id = target_user_id
  )
  AND (v.organization_id IS NULL OR v.organization_id != new_org_id);
  
  RETURN new_org_id;
END;
$$;

-- Ensure permissions are correct
GRANT EXECUTE ON FUNCTION create_organization_for_user TO authenticated;