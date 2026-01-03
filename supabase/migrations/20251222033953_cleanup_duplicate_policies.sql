/*
  # Cleanup Duplicate RLS Policies
  
  ## Problem
  Multiple migrations have created duplicate policies on user_profiles and organizations tables,
  which can cause conflicts and confusion.
  
  ## Solution
  Drop all duplicate and old policies, keep only the clean set from the comprehensive fix.
  
  ## Changes
  - Drop duplicate service role policies
  - Drop duplicate INSERT policies for authenticated users
  - Keep only the minimal required policies
*/

-- ============================================================================
-- Clean up user_profiles table policies
-- ============================================================================

-- Drop all old/duplicate policies
DROP POLICY IF EXISTS "Service role can manage user profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can create own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile during signup" ON public.user_profiles;

-- The correct policies from our fix migration remain:
-- - profiles_select_own (for SELECT by authenticated users)
-- - profiles_update_own (for UPDATE by authenticated users)
-- - service_role_all_profiles (for ALL by service_role)

-- ============================================================================
-- Clean up organizations table policies
-- ============================================================================

-- Check current policies on organizations
DO $$ 
DECLARE
  pol record;
BEGIN
  FOR pol IN 
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'organizations'
    AND policyname NOT IN ('org_select_own', 'org_update_own', 'service_role_all_orgs')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.organizations', pol.policyname);
  END LOOP;
END $$;

-- ============================================================================
-- Verify no policies exist on auth.users
-- ============================================================================

DO $$ 
DECLARE
  pol record;
BEGIN
  FOR pol IN 
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'auth' AND tablename = 'users'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON auth.users', pol.policyname);
    RAISE NOTICE 'Dropped unauthorized policy % from auth.users', pol.policyname;
  END LOOP;
END $$;
