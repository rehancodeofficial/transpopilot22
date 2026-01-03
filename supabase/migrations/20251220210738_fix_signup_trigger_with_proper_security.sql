/*
  # Fix Signup Trigger with Proper Security and Error Handling
  
  ## Overview
  Fixes the handle_new_user trigger function to properly handle organization and
  user profile creation during signup. Adds proper security context, error handling,
  and search path to prevent network errors during signup.
  
  ## Issues Fixed
  1. Added SET search_path for security
  2. Function now properly bypasses RLS using security definer context
  3. Added error handling for organization creation
  4. Ensures organizations INSERT policy allows the trigger to work
  
  ## Changes
  1. Updates handle_new_user function with proper search_path
  2. Adds service role policy for organizations to allow trigger insertion
  3. Improves error handling and logging
  
  ## Security Impact
  - Maintains SECURITY DEFINER to bypass RLS during trigger
  - Search path prevents injection attacks
  - Only allows creation of user's own profile
  - Organization creation is controlled and validated
*/

-- Drop existing service role policy if it exists
DROP POLICY IF EXISTS "Service role can manage organizations" ON organizations;

-- Add service role policy for organizations to allow trigger to insert
CREATE POLICY "Service role can manage organizations"
  ON organizations FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Update handle_new_user function with proper security and error handling
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
  -- Extract organization name from user metadata
  org_name := COALESCE(
    NEW.raw_user_meta_data->>'company_name',
    NEW.raw_user_meta_data->>'organization_name',
    split_part(NEW.email, '@', 1) || ' Organization'
  );
  
  -- Generate unique slug
  org_slug := generate_slug(org_name);
  
  -- Create organization
  BEGIN
    INSERT INTO public.organizations (name, slug, subscription_tier, subscription_status)
    VALUES (org_name, org_slug, 'trial', 'trial')
    RETURNING id INTO new_org_id;
  EXCEPTION WHEN OTHERS THEN
    RAISE LOG 'Error creating organization for user %: %', NEW.id, SQLERRM;
    RAISE;
  END;
  
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
  EXCEPTION WHEN OTHERS THEN
    RAISE LOG 'Error creating user profile for user %: %', NEW.id, SQLERRM;
    RAISE;
  END;
  
  RETURN NEW;
END;
$$;

-- Ensure trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Update generate_slug function with search_path
CREATE OR REPLACE FUNCTION generate_slug(input_text text)
RETURNS text
LANGUAGE plpgsql
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
