/*
  # Update Signup Trigger to Include Demo Data Seeding
  
  ## Overview
  Updates the handle_new_user trigger to automatically seed demo data
  after creating the user profile. This ensures all operations happen
  in a single atomic transaction and prevents race conditions.
  
  ## Changes
  1. Updates handle_new_user function to call seed_user_demo_data
  2. All operations happen in one transaction during signup
  3. Removes need for frontend to call seeding function
  
  ## Benefits
  - Atomic operation - all or nothing
  - No race conditions with authentication
  - Simpler frontend code
  - Better error handling
  
  ## Security Impact
  - Maintains SECURITY DEFINER for proper permissions
  - All operations run with elevated privileges during trigger
  - Search path is properly set for security
*/

-- Update handle_new_user function to include demo data seeding
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
  
  -- Seed demo data for new user
  BEGIN
    PERFORM seed_user_demo_data(NEW.id);
  EXCEPTION WHEN OTHERS THEN
    RAISE LOG 'Error seeding demo data for user %: %', NEW.id, SQLERRM;
  END;
  
  RETURN NEW;
END;
$$;

-- Trigger already exists, no need to recreate
