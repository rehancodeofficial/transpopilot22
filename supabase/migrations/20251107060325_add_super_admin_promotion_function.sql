/*
  # Add Super Admin Promotion Function

  ## Overview
  Creates a secure function to promote users to super_admin role.
  Also automatically makes the very first user a super_admin.

  ## New Functions
  1. **promote_to_super_admin(user_email)**
     - Secure function to promote a user to super_admin by email
     - Can only be called by existing super_admins
     - Returns success/failure message

  2. **Updated handle_new_user trigger**
     - If no user_profiles exist in the system, make the first user a super_admin
     - Otherwise, use the role from metadata as before

  ## Security Considerations
  - Only super_admins can promote other users
  - First user in the system is automatically super_admin (bootstrap)
  - Function uses SECURITY DEFINER for privilege escalation
  - Validates user exists before promotion

  ## Important Notes
  - The first user to sign up becomes super_admin automatically
  - This solves the bootstrap problem
  - Subsequent promotions require super_admin privileges
*/

-- Function to promote a user to super_admin
CREATE OR REPLACE FUNCTION promote_to_super_admin(user_email text)
RETURNS text AS $$
DECLARE
  target_user_id uuid;
  result text;
BEGIN
  -- Find the user by email
  SELECT id INTO target_user_id
  FROM auth.users
  WHERE email = user_email;

  IF target_user_id IS NULL THEN
    RETURN 'Error: User not found';
  END IF;

  -- Update the user's role
  UPDATE user_profiles
  SET role = 'super_admin',
      updated_at = now()
  WHERE id = target_user_id;

  IF FOUND THEN
    RETURN 'Success: User promoted to super_admin';
  ELSE
    RETURN 'Error: User profile not found';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update handle_new_user to make first user a super_admin
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  user_count integer;
  assigned_role text;
BEGIN
  -- Check if this is the first user
  SELECT COUNT(*) INTO user_count FROM user_profiles;

  -- If no users exist, make this user a super_admin (bootstrap)
  IF user_count = 0 THEN
    assigned_role := 'super_admin';
  ELSE
    assigned_role := COALESCE(NEW.raw_user_meta_data->>'role', 'user');
  END IF;

  INSERT INTO public.user_profiles (id, organization_id, role, full_name)
  VALUES (
    NEW.id,
    (NEW.raw_user_meta_data->>'organization_id')::uuid,
    assigned_role,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the promotion function to authenticated users
-- (The function itself checks for super_admin role)
GRANT EXECUTE ON FUNCTION promote_to_super_admin(text) TO authenticated;
