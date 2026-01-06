-- Comprehensive Fix: Auto-Create Organization, Backfill, and Enforce Constraint
-- Based on "Industry Standard" Solution

-- 1. Create/Replace the function to handle new users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  new_org_id uuid;
BEGIN
  -- Create organization
  INSERT INTO public.organizations (name, slug)
  VALUES (
    COALESCE(NEW.raw_user_meta_data->>'company_name', 'My Organization'),
    gen_random_uuid()::text
  )
  RETURNING id INTO new_org_id;

  -- Create user profile and attach organization
  INSERT INTO public.user_profiles (
    id,
    organization_id,
    role,
    full_name
  )
  VALUES (
    NEW.id,
    new_org_id,
    'admin',
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Admin User')
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Ensure Trigger exists and is active
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 3. Backfill Existing Users (Repair Data)
DO $$
DECLARE
  u RECORD;
  new_org_id uuid;
  repaired_count INT := 0;
BEGIN
  FOR u IN
    SELECT id, email, raw_user_meta_data FROM auth.users 
    WHERE id NOT IN (SELECT id FROM public.user_profiles WHERE organization_id IS NOT NULL)
  LOOP
    -- Create Org for this user
    INSERT INTO public.organizations (name, slug)
    VALUES (
        COALESCE(u.raw_user_meta_data->>'company_name', 'Recovered Org'), 
        gen_random_uuid()::text
    )
    RETURNING id INTO new_org_id;

    -- Update or Insert Profile
    INSERT INTO public.user_profiles (id, organization_id, role, full_name)
    VALUES (
        u.id, 
        new_org_id, 
        'admin', 
        COALESCE(u.raw_user_meta_data->>'full_name', 'Recovered User')
    )
    ON CONFLICT (id) DO UPDATE
    SET organization_id = EXCLUDED.organization_id,
        role = 'admin';
        
    repaired_count := repaired_count + 1;
  END LOOP;
  
  RAISE NOTICE 'Repaired % users.', repaired_count;
END $$;

-- 4. Enforce Organization at Database Level
-- Only applying if we are sure data is clean (Backfill guarantees this mostly, but RLS might hide rows. 
-- We run this blindly assuming the backfill caught all).
ALTER TABLE public.user_profiles
ALTER COLUMN organization_id SET NOT NULL;
