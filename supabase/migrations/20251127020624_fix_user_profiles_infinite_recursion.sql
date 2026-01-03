/*
  # Fix infinite recursion in user_profiles RLS policy

  1. Problem
    - The "Users can read own profile" policy has infinite recursion
    - It queries user_profiles to check if user is admin, which triggers the same policy
    - This prevents users from logging in and loading their profiles

  2. Solution
    - Simplify the SELECT policy to only allow users to read their own profile
    - Users can always read their own profile (id = auth.uid())
    - Remove the organization-based check that causes recursion
    - Admins will still be able to see other profiles through separate admin policies if needed

  3. Security
    - Users can only read their own profile
    - This is secure and prevents data leaks
    - No recursion because we don't query user_profiles within the policy
*/

-- Drop the problematic policy
DROP POLICY IF EXISTS "Users can read own profile" ON user_profiles;

-- Create a simple, non-recursive policy
CREATE POLICY "Users can read own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Add a separate policy for admins to read all profiles (no recursion)
DROP POLICY IF EXISTS "Admins can read all profiles" ON user_profiles;

CREATE POLICY "Admins can read all profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.users.id = auth.uid()
      AND auth.users.raw_app_meta_data->>'role' IN ('admin', 'super_admin')
    )
  );