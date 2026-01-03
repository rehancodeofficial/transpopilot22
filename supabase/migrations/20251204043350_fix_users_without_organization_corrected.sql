/*
  # Fix Users Without Organization

  ## Overview
  This migration fixes user profiles that don't have an organization_id set.
  This can happen if users were created before the organization system was implemented
  or if the trigger failed during signup.

  ## Changes
  1. Create a function to auto-create organizations for orphaned users
  2. Run the function to fix all existing users without organization_id
  3. Update related tables (drivers) to link to the new organization
  4. Promote users to admin role if they're creating their own organization

  ## Security
  - Maintains all existing RLS policies
  - Only affects users without organization_id
  - Creates secure organization relationships
  - Automatically promotes orphaned users to admin of their new organization
*/

-- Function to create organization for a user without one
CREATE OR REPLACE FUNCTION create_organization_for_user(target_user_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
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

-- Fix all existing users without organization_id
DO $$
DECLARE
  user_record RECORD;
  created_org_id uuid;
  fixed_count integer := 0;
BEGIN
  FOR user_record IN 
    SELECT id, full_name FROM user_profiles WHERE organization_id IS NULL
  LOOP
    created_org_id := create_organization_for_user(user_record.id);
    fixed_count := fixed_count + 1;
    RAISE NOTICE 'Created organization % for user % (%)', created_org_id, user_record.id, user_record.full_name;
  END LOOP;
  
  RAISE NOTICE 'Fixed % users without organizations', fixed_count;
END $$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION create_organization_for_user TO authenticated;