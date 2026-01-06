/*
  # Ensure Organization Creation RPC Exists

  ## Problem
  The `create_organization_for_user` RPC function seems strictly missing or inaccessible,
  causing fallback mechanisms to fail when the signup trigger doesn't work.

  ## Solution
  1. Recreate `create_organization_for_user` with `SECURITY DEFINER` to bypass RLS.
  2. Grant explicit execute permissions to authenticated users and service role.
  3. Ensure it handles cases where the user might already have an org.
*/

CREATE OR REPLACE FUNCTION public.create_organization_for_user(target_user_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_email text;
  v_user_meta jsonb;
  v_org_id uuid;
  v_org_name text;
  v_org_slug text;
  v_existing_org_id uuid;
BEGIN
  -- 1. Check if user already has an organization
  SELECT organization_id INTO v_existing_org_id
  FROM public.user_profiles
  WHERE id = target_user_id;

  IF v_existing_org_id IS NOT NULL THEN
    RETURN v_existing_org_id;
  END IF;

  -- 2. Get user email and metadata from auth.users
  SELECT email, raw_user_meta_data INTO v_user_email, v_user_meta
  FROM auth.users
  WHERE id = target_user_id;

  IF v_user_email IS NULL THEN
    RAISE EXCEPTION 'User not found in auth.users';
  END IF;

  -- 3. Determine Organization Name
  v_org_name := COALESCE(
    v_user_meta->>'organization_name',
    v_user_meta->>'company_name',
    split_part(v_user_email, '@', 2)
  );

  -- 4. Generate Slug
  v_org_slug := lower(regexp_replace(v_org_name, '[^a-zA-Z0-9]+', '-', 'g')) || '-' || substr(target_user_id::text, 1, 8);

  -- 5. Create Organization
  INSERT INTO public.organizations (name, slug, created_at)
  VALUES (v_org_name, v_org_slug, now())
  RETURNING id INTO v_org_id;

  -- 6. Update User Profile
  -- Note: We use UPSERT here just in case the profile doesn't exist yet
  INSERT INTO public.user_profiles (id, organization_id, full_name, role, created_at)
  VALUES (
    target_user_id,
    v_org_id,
    COALESCE(v_user_meta->>'full_name', split_part(v_user_email, '@', 1)),
    'admin', -- Default to admin for the creator
    now()
  )
  ON CONFLICT (id) DO UPDATE
  SET organization_id = v_org_id,
      role = COALESCE(public.user_profiles.role, 'admin'); -- Keep existing role if set, otherwise admin

  RETURN v_org_id;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.create_organization_for_user(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_organization_for_user(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.create_organization_for_user(uuid) TO postgres;

-- Verify it worked
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc
    JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid
    WHERE proname = 'create_organization_for_user'
    AND nspname = 'public'
  ) THEN
    RAISE EXCEPTION 'Function create_organization_for_user was not created';
  END IF;
END $$;
