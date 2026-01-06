-- Migration to backfill missing organizations for existing users
-- This ensures Requirement #3: "Fix Existing Users"

DO $$
DECLARE
  missing_user RECORD;
  new_org_id UUID;
  user_email TEXT;
  user_name TEXT;
  new_slug TEXT;
  org_count INT := 0;
BEGIN
  -- Iterate through users who have no organization_id
  FOR missing_user IN 
    SELECT up.id, u.email, u.raw_user_meta_data
    FROM user_profiles up
    JOIN auth.users u ON u.id = up.id
    WHERE up.organization_id IS NULL
  LOOP
    
    -- Extract info
    user_name := COALESCE(missing_user.raw_user_meta_data->>'full_name', split_part(missing_user.email, '@', 1));
    
    -- Generate unique slug
    new_slug := lower(regexp_replace(user_name, '[^a-zA-Z0-9]', '-', 'g')) || '-' || substr(missing_user.id::text, 1, 8);
    
    -- Create Organization
    INSERT INTO organizations (name, slug, subscription_tier, created_at)
    VALUES (
      user_name || '''s Organization',
      new_slug,
      'free',
      NOW()
    )
    RETURNING id INTO new_org_id;
    
    -- Update Profile
    UPDATE user_profiles
    SET organization_id = new_org_id,
        role = 'admin' -- Default to admin for their own org
    WHERE id = missing_user.id;
    
    org_count := org_count + 1;
    
    RAISE NOTICE 'Created organization for user % (Org ID: %)', missing_user.email, new_org_id;
    
  END LOOP;
  
  RAISE NOTICE 'Backfill complete. Fixed % users.', org_count;
END $$;
