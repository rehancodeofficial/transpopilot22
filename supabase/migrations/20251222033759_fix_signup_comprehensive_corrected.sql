/*
  # Comprehensive Signup Fix - Corrected Version
  
  ## Problem
  Network errors during signup due to:
  - Conflicting RLS policies on auth.users (should never have policies)
  - Overly complex signup trigger causing timeouts
  - Service role permission issues
  
  ## Solution
  1. Drop ALL policies on auth.users (auth schema manages this)
  2. Simplify user_profiles policies to bare minimum
  3. Create minimal, fast signup trigger
  4. Ensure organizations table has correct policies
  
  ## Changes
  - Drop all auth.users policies (wrong schema for RLS)
  - Create simple user_profiles policies for authenticated users
  - Rewrite handle_new_user trigger to be minimal and fast
  - Add proper error handling
*/

-- ============================================================================
-- STEP 1: Clean up auth.users policies (these should NEVER exist)
-- ============================================================================

DO $$ 
DECLARE
  pol record;
BEGIN
  -- Drop ALL policies on auth.users - this table should NOT have RLS policies
  FOR pol IN 
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'auth' AND tablename = 'users'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON auth.users', pol.policyname);
  END LOOP;
END $$;

-- ============================================================================
-- STEP 2: Simplify user_profiles RLS policies
-- ============================================================================

-- Drop all existing user_profiles policies
DROP POLICY IF EXISTS "Users can read own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Admins can read org profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Admins can update org profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Super admins can create profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.user_profiles;
DROP POLICY IF EXISTS "Allow service role full access to user profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Service role can manage all profiles" ON public.user_profiles;

-- Ensure RLS is enabled
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create simple, non-conflicting policies
CREATE POLICY "profiles_select_own"
  ON public.user_profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "profiles_update_own"
  ON public.user_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Critical: Allow service role to INSERT/SELECT during signup
CREATE POLICY "service_role_all_profiles"
  ON public.user_profiles
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ============================================================================
-- STEP 3: Simplify organizations RLS policies
-- ============================================================================

-- Drop all existing organizations policies
DROP POLICY IF EXISTS "Users can read own organization" ON public.organizations;
DROP POLICY IF EXISTS "Admins can update own organization" ON public.organizations;
DROP POLICY IF EXISTS "Super admins can create organizations" ON public.organizations;
DROP POLICY IF EXISTS "Users can view own organization" ON public.organizations;
DROP POLICY IF EXISTS "Users can update own organization" ON public.organizations;
DROP POLICY IF EXISTS "Users can insert own organization" ON public.organizations;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.organizations;
DROP POLICY IF EXISTS "Enable read access for organization members" ON public.organizations;
DROP POLICY IF EXISTS "Enable update for organization members" ON public.organizations;
DROP POLICY IF EXISTS "Allow service role full access to organizations" ON public.organizations;
DROP POLICY IF EXISTS "org_select_members" ON public.organizations;
DROP POLICY IF EXISTS "org_update_members" ON public.organizations;
DROP POLICY IF EXISTS "service_role_insert_org" ON public.organizations;
DROP POLICY IF EXISTS "service_role_select_org" ON public.organizations;

-- Ensure RLS is enabled
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- Create simple policies
CREATE POLICY "org_select_own"
  ON public.organizations
  FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT organization_id 
      FROM public.user_profiles 
      WHERE id = auth.uid()
    )
  );

CREATE POLICY "org_update_own"
  ON public.organizations
  FOR UPDATE
  TO authenticated
  USING (
    id IN (
      SELECT organization_id 
      FROM public.user_profiles 
      WHERE id = auth.uid()
    )
  )
  WITH CHECK (
    id IN (
      SELECT organization_id 
      FROM public.user_profiles 
      WHERE id = auth.uid()
    )
  );

-- Critical: Allow service role full access during signup
CREATE POLICY "service_role_all_orgs"
  ON public.organizations
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ============================================================================
-- STEP 4: Create minimal, fast signup trigger
-- ============================================================================

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- Create new minimal function that runs FAST
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public, auth
LANGUAGE plpgsql
AS $$
DECLARE
  v_org_id uuid;
  v_org_name text;
  v_org_slug text;
BEGIN
  -- Extract organization name from metadata or use email domain
  v_org_name := COALESCE(
    NEW.raw_user_meta_data->>'organization_name',
    split_part(NEW.email, '@', 2)
  );
  
  -- Create a simple slug
  v_org_slug := lower(regexp_replace(v_org_name, '[^a-zA-Z0-9]+', '-', 'g')) || '-' || substr(NEW.id::text, 1, 8);

  -- Create organization for this user
  INSERT INTO public.organizations (name, slug, created_at)
  VALUES (v_org_name, v_org_slug, now())
  RETURNING id INTO v_org_id;

  -- Create user profile
  INSERT INTO public.user_profiles (
    id,
    full_name,
    role,
    organization_id,
    onboarding_completed,
    created_at
  ) VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    'admin',
    v_org_id,
    false,
    now()
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log error but don't block signup
  RAISE WARNING 'Error in handle_new_user for user %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- STEP 5: Grant necessary permissions
-- ============================================================================

-- Ensure service role can access these tables
GRANT ALL ON public.user_profiles TO service_role;
GRANT ALL ON public.organizations TO service_role;
GRANT USAGE ON SCHEMA public TO service_role;
GRANT USAGE ON SCHEMA auth TO service_role;
