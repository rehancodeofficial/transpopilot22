/*
  # Fix Signup Trigger Permissions - Comprehensive Fix

  ## Overview
  Ensures the handle_new_user trigger function has all necessary permissions
  to create organizations and user profiles during signup. This prevents
  "failed to fetch" and "network error" messages during account creation.

  ## Root Cause
  The trigger function runs with SECURITY DEFINER but needs explicit grants
  to bypass RLS policies on organizations and user_profiles tables.

  ## Changes
  1. Grants USAGE on schema to trigger function owner
  2. Grants ALL privileges on tables to postgres role
  3. Ensures service role policies exist for system operations
  4. Verifies trigger function ownership and security context
  5. Adds explicit grants for INSERT, UPDATE, SELECT operations

  ## Testing
  After applying this migration, test signup by:
  1. Creating a new account with company name, full name, email, password
  2. Verify organization is created automatically
  3. Verify user profile is created and linked to organization
  4. Verify demo data seeding works (called from frontend)

  ## Security Impact
  - SECURITY DEFINER allows trigger to bypass RLS during user creation
  - Service role policies only apply to system operations
  - User data isolation is maintained through organization_id filtering
  - No changes to existing user-facing RLS policies
*/

-- Ensure postgres role has necessary grants on public schema
GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO service_role;

-- Grant necessary privileges on organizations table
GRANT ALL ON public.organizations TO postgres;
GRANT ALL ON public.organizations TO service_role;

-- Grant necessary privileges on user_profiles table
GRANT ALL ON public.user_profiles TO postgres;
GRANT ALL ON public.user_profiles TO service_role;

-- Ensure service role policies exist for organizations
DROP POLICY IF EXISTS "Service role can manage organizations" ON organizations;
CREATE POLICY "Service role can manage organizations"
  ON organizations FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Ensure service role policies exist for user_profiles
DROP POLICY IF EXISTS "Service role can manage user profiles" ON user_profiles;
CREATE POLICY "Service role can manage user profiles"
  ON user_profiles FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Recreate generate_slug function with proper security context
CREATE OR REPLACE FUNCTION generate_slug(input_text text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
DECLARE
  base_slug text;
  final_slug text;
  counter integer := 0;
BEGIN
  -- Generate base slug from input text
  base_slug := lower(regexp_replace(input_text, '[^a-zA-Z0-9]+', '-', 'g'));
  base_slug := trim(both '-' from base_slug);

  -- Ensure minimum length
  IF length(base_slug) < 3 THEN
    base_slug := 'company-' || base_slug;
  END IF;

  final_slug := base_slug;

  -- Ensure uniqueness
  WHILE EXISTS (SELECT 1 FROM organizations WHERE slug = final_slug) LOOP
    counter := counter + 1;
    final_slug := base_slug || '-' || counter;
  END LOOP;

  RETURN final_slug;
END;
$$;

-- Grant execute on generate_slug to necessary roles
GRANT EXECUTE ON FUNCTION generate_slug(text) TO postgres;
GRANT EXECUTE ON FUNCTION generate_slug(text) TO service_role;
GRANT EXECUTE ON FUNCTION generate_slug(text) TO authenticated;

-- Recreate handle_new_user function with comprehensive error handling
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
DECLARE
  new_org_id uuid;
  org_name text;
  org_slug text;
BEGIN
  -- Log the start of user creation
  RAISE LOG 'Creating new user: %', NEW.id;

  -- Extract organization name from user metadata
  org_name := COALESCE(
    NEW.raw_user_meta_data->>'company_name',
    NEW.raw_user_meta_data->>'organization_name',
    split_part(NEW.email, '@', 1) || ' Organization'
  );

  RAISE LOG 'Organization name: %', org_name;

  -- Generate unique slug
  BEGIN
    org_slug := generate_slug(org_name);
    RAISE LOG 'Generated slug: %', org_slug;
  EXCEPTION WHEN OTHERS THEN
    RAISE LOG 'Error generating slug: %', SQLERRM;
    RAISE;
  END;

  -- Create organization
  BEGIN
    INSERT INTO public.organizations (name, slug, subscription_tier, subscription_status)
    VALUES (org_name, org_slug, 'trial', 'trial')
    RETURNING id INTO new_org_id;

    RAISE LOG 'Created organization: %', new_org_id;
  EXCEPTION WHEN OTHERS THEN
    RAISE LOG 'Error creating organization for user %: %', NEW.id, SQLERRM;
    RAISE EXCEPTION 'Failed to create organization: %', SQLERRM;
  END;

  -- Verify organization was created
  IF new_org_id IS NULL THEN
    RAISE EXCEPTION 'Organization ID is NULL after creation';
  END IF;

  -- Create user profile linked to organization
  BEGIN
    INSERT INTO public.user_profiles (
      id,
      organization_id,
      role,
      full_name,
      demo_mode
    )
    VALUES (
      NEW.id,
      new_org_id,
      COALESCE(NEW.raw_user_meta_data->>'role', 'admin'),
      COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
      true
    );

    RAISE LOG 'Created user profile for user: %', NEW.id;
  EXCEPTION WHEN OTHERS THEN
    RAISE LOG 'Error creating user profile for user %: %', NEW.id, SQLERRM;
    RAISE EXCEPTION 'Failed to create user profile: %', SQLERRM;
  END;

  -- Note: Demo data seeding is handled asynchronously from the frontend
  -- after authentication to prevent timeout issues during signup

  RAISE LOG 'Successfully created user % with organization %', NEW.id, new_org_id;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log any unhandled errors
  RAISE LOG 'Unhandled error in handle_new_user for user %: %', NEW.id, SQLERRM;
  RAISE;
END;
$$;

-- Grant execute on handle_new_user to necessary roles
GRANT EXECUTE ON FUNCTION handle_new_user() TO postgres;
GRANT EXECUTE ON FUNCTION handle_new_user() TO service_role;

-- Ensure trigger exists and is properly configured
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Verify the trigger was created
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'on_auth_user_created'
  ) THEN
    RAISE EXCEPTION 'Trigger on_auth_user_created was not created successfully';
  END IF;

  RAISE LOG 'Trigger on_auth_user_created verified successfully';
END $$;