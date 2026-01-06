-- Create a function to safely create an organization for a user
-- This is used by the frontend AuthContext to ensure every user has an organization
CREATE OR REPLACE FUNCTION create_organization_for_user(target_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_org_id UUID;
  user_email TEXT;
  user_name TEXT;
  new_slug TEXT;
BEGIN
  -- Get user details
  SELECT email, raw_user_meta_data->>'full_name'
  INTO user_email, user_name
  FROM auth.users
  WHERE id = target_user_id;

  -- Generate slug
  new_slug := lower(regexp_replace(COALESCE(user_name, 'org'), '[^a-zA-Z0-9]', '-', 'g')) || '-' || extract(epoch from now())::text;

  -- Create new organization
  INSERT INTO organizations (name, slug, subscription_tier)
  VALUES (
    COALESCE(user_name || '''s Organization', 'My Organization'),
    new_slug,
    'free'
  )
  RETURNING id INTO new_org_id;

  -- Update user profile
  UPDATE user_profiles
  SET organization_id = new_org_id,
      role = 'admin' -- First user is admin
  WHERE id = target_user_id;

  RETURN new_org_id;
END;
$$;
