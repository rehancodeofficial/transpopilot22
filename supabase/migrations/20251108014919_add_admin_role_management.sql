/*
  # Add Admin Role Management Functions
  
  ## Overview
  Creates secure functions for managing user roles and admin access.
  Only super admins can promote/demote users to/from admin roles.
  
  ## New Functions
  
  ### `promote_user_to_admin(user_id uuid)`
  - Promotes a regular user to admin role
  - Only callable by super_admin users
  - Updates the user_profiles role field
  - Returns success/error status
  
  ### `demote_admin_to_user(user_id uuid)`
  - Demotes an admin user back to regular user role
  - Only callable by super_admin users
  - Cannot demote super_admins
  - Returns success/error status
  
  ### `grant_super_admin(user_id uuid)`
  - Promotes a user to super_admin role
  - Only callable by existing super_admin users
  - Returns success/error status
  
  ## Security
  - All functions use SECURITY DEFINER to run with elevated privileges
  - Built-in validation ensures only super_admins can execute these functions
  - Cannot demote or modify super_admin roles through regular admin functions
  - Audit trail automatically maintained through updated_at timestamps
  
  ## Important Notes
  - These functions bypass RLS policies using SECURITY DEFINER
  - Role validation happens at function level for security
  - Super admin promotion requires existing super admin authorization
*/

-- Function to promote a user to admin role
CREATE OR REPLACE FUNCTION promote_user_to_admin(target_user_id uuid)
RETURNS json AS $$
DECLARE
  caller_role text;
  target_role text;
BEGIN
  -- Check if caller is super_admin
  SELECT role INTO caller_role
  FROM user_profiles
  WHERE id = auth.uid();
  
  IF caller_role != 'super_admin' THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Only super admins can promote users to admin'
    );
  END IF;
  
  -- Get target user's current role
  SELECT role INTO target_role
  FROM user_profiles
  WHERE id = target_user_id;
  
  IF target_role IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'message', 'User not found'
    );
  END IF;
  
  IF target_role = 'super_admin' THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Cannot modify super admin role'
    );
  END IF;
  
  IF target_role = 'admin' THEN
    RETURN json_build_object(
      'success', false,
      'message', 'User is already an admin'
    );
  END IF;
  
  -- Update user role to admin
  UPDATE user_profiles
  SET role = 'admin', updated_at = now()
  WHERE id = target_user_id;
  
  RETURN json_build_object(
    'success', true,
    'message', 'User successfully promoted to admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to demote an admin to regular user
CREATE OR REPLACE FUNCTION demote_admin_to_user(target_user_id uuid)
RETURNS json AS $$
DECLARE
  caller_role text;
  target_role text;
BEGIN
  -- Check if caller is super_admin
  SELECT role INTO caller_role
  FROM user_profiles
  WHERE id = auth.uid();
  
  IF caller_role != 'super_admin' THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Only super admins can demote admins'
    );
  END IF;
  
  -- Get target user's current role
  SELECT role INTO target_role
  FROM user_profiles
  WHERE id = target_user_id;
  
  IF target_role IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'message', 'User not found'
    );
  END IF;
  
  IF target_role = 'super_admin' THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Cannot demote super admin through this function'
    );
  END IF;
  
  IF target_role = 'user' THEN
    RETURN json_build_object(
      'success', false,
      'message', 'User is already a regular user'
    );
  END IF;
  
  -- Update user role to user
  UPDATE user_profiles
  SET role = 'user', updated_at = now()
  WHERE id = target_user_id;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Admin successfully demoted to user'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to grant super admin access
CREATE OR REPLACE FUNCTION grant_super_admin(target_user_id uuid)
RETURNS json AS $$
DECLARE
  caller_role text;
  target_role text;
BEGIN
  -- Check if caller is super_admin
  SELECT role INTO caller_role
  FROM user_profiles
  WHERE id = auth.uid();
  
  IF caller_role != 'super_admin' THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Only super admins can grant super admin access'
    );
  END IF;
  
  -- Get target user's current role
  SELECT role INTO target_role
  FROM user_profiles
  WHERE id = target_user_id;
  
  IF target_role IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'message', 'User not found'
    );
  END IF;
  
  IF target_role = 'super_admin' THEN
    RETURN json_build_object(
      'success', false,
      'message', 'User is already a super admin'
    );
  END IF;
  
  -- Update user role to super_admin
  UPDATE user_profiles
  SET role = 'super_admin', updated_at = now()
  WHERE id = target_user_id;
  
  RETURN json_build_object(
    'success', true,
    'message', 'User successfully promoted to super admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;