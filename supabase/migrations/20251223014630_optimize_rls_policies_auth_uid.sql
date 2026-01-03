/*
  # Optimize RLS Policies for Auth Performance

  1. Purpose
    - Fix RLS policies that re-evaluate auth.uid() for each row
    - Replace auth.uid() with (select auth.uid()) for better performance
    - Affects: user_profiles and organizations tables

  2. Changes
    - Drop existing policies: profiles_select_own, profiles_update_own, org_select_own, org_update_own
    - Recreate policies with optimized auth function calls
    
  3. Security
    - Maintains same security posture
    - Improves query performance at scale
*/

-- Drop and recreate user_profiles policies with optimized auth calls
DROP POLICY IF EXISTS "profiles_select_own" ON public.user_profiles;
CREATE POLICY "profiles_select_own"
  ON public.user_profiles
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = id);

DROP POLICY IF EXISTS "profiles_update_own" ON public.user_profiles;
CREATE POLICY "profiles_update_own"
  ON public.user_profiles
  FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = id)
  WITH CHECK ((select auth.uid()) = id);

-- Drop and recreate organizations policies with optimized auth calls
DROP POLICY IF EXISTS "org_select_own" ON public.organizations;
CREATE POLICY "org_select_own"
  ON public.organizations
  FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT organization_id
      FROM public.user_profiles
      WHERE id = (select auth.uid())
    )
  );

DROP POLICY IF EXISTS "org_update_own" ON public.organizations;
CREATE POLICY "org_update_own"
  ON public.organizations
  FOR UPDATE
  TO authenticated
  USING (
    id IN (
      SELECT organization_id
      FROM public.user_profiles
      WHERE id = (select auth.uid())
        AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    id IN (
      SELECT organization_id
      FROM public.user_profiles
      WHERE id = (select auth.uid())
        AND role IN ('admin', 'super_admin')
    )
  );
