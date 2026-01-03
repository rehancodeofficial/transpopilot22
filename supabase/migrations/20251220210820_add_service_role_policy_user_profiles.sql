/*
  # Add Service Role Policy for User Profiles
  
  ## Overview
  Adds a service role policy to user_profiles table to ensure the handle_new_user
  trigger function can insert profiles even when RLS is enabled. This prevents
  signup failures caused by RLS blocking the trigger.
  
  ## Changes
  1. Adds service_role policy for user_profiles table
  2. Allows service_role to perform all operations
  
  ## Security Impact
  - Service role is only used by edge functions and triggers
  - Does not affect authenticated user policies
  - Maintains security while allowing system operations
*/

-- Drop existing service role policy if it exists
DROP POLICY IF EXISTS "Service role can manage user profiles" ON user_profiles;

-- Add service role policy for user_profiles
CREATE POLICY "Service role can manage user profiles"
  ON user_profiles FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
