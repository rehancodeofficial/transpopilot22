/*
  # Remove admin policy that accesses auth.users

  1. Problem
    - The "Admins can read all profiles" policy tries to access auth.users
    - auth.users is not accessible from RLS policies
    - This causes "permission denied for table users" error
    - Profile loading fails completely

  2. Solution
    - Drop the problematic admin policy
    - Keep only the simple "Users can read own profile" policy
    - This allows users to log in and see their own profile
    - Admin buttons will work once profile.role is loaded

  3. Security
    - Users can only read their own profile
    - This is secure and prevents unauthorized access
    - Admins accessing other profiles can be handled through service role or functions
*/

-- Drop the problematic admin policy
DROP POLICY IF EXISTS "Admins can read all profiles" ON user_profiles;
