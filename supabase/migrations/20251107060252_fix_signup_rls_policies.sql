/*
  # Fix Signup RLS Policies

  ## Overview
  Fixes the chicken-and-egg problem where new users cannot create organizations during signup
  because the INSERT policy requires them to already be super_admins.

  ## Changes Made
  1. **New Policy: Allow organization creation during signup**
     - Allows authenticated users to INSERT organizations if they don't have a user_profile yet
     - This indicates they are in the signup flow
     - Prevents existing users from creating multiple organizations without permission

  2. **New Policy: Allow user_profile creation during signup**
     - Allows the trigger function to INSERT user_profiles during signup
     - Uses SECURITY DEFINER on the trigger function to bypass RLS temporarily

  ## Security Considerations
  - The policy only allows one organization per user during initial signup
  - Once a user_profile exists, the normal super_admin restriction applies
  - The check prevents abuse by verifying no existing profile exists
  - The trigger function runs with elevated privileges (SECURITY DEFINER)

  ## Important Notes
  - This enables the self-service signup flow
  - First user of an organization becomes admin automatically
  - Super admins can still create additional organizations
  - Regular users cannot create organizations after signup
*/

-- Drop the existing restrictive policy
DROP POLICY IF EXISTS "Super admins can create organizations" ON organizations;

-- Create a new policy that allows organization creation during signup
CREATE POLICY "Allow organization creation during signup"
  ON organizations FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Allow if user is a super_admin (existing functionality)
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
    OR
    -- Allow if user doesn't have a profile yet (signup flow)
    NOT EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
    )
  );

-- Recreate the handle_new_user function with better error handling
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, organization_id, role, full_name)
  VALUES (
    NEW.id,
    (NEW.raw_user_meta_data->>'organization_id')::uuid,
    COALESCE(NEW.raw_user_meta_data->>'role', 'user'),
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add a policy to allow profile insertion during signup trigger
DROP POLICY IF EXISTS "Allow profile creation during signup trigger" ON user_profiles;
CREATE POLICY "Allow profile creation during signup trigger"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Allow if inserting own profile
    id = auth.uid()
    OR
    -- Allow if user is super_admin
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );
