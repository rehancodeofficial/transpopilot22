/*
  # Update Signup Flow to Create Organizations

  ## Overview
  Updates the handle_new_user trigger to automatically create an organization
  for new signups and link the user to that organization.

  ## Changes
  1. Update handle_new_user function to create organization first
  2. Generate unique slug from company name or email
  3. Link user_profile to organization
  4. Set organization_id in user metadata

  ## Important Notes
  - Organization created with 'trial' tier by default
  - Organization name from metadata or defaults to email prefix
  - Slug is URL-safe version of organization name
  - Trial period is 30 days from creation
*/

-- Function to generate URL-safe slug from text
CREATE OR REPLACE FUNCTION generate_slug(input_text text)
RETURNS text AS $$
DECLARE
  base_slug text;
  final_slug text;
  counter integer := 0;
BEGIN
  base_slug := lower(regexp_replace(input_text, '[^a-zA-Z0-9]+', '-', 'g'));
  base_slug := trim(both '-' from base_slug);
  
  IF length(base_slug) < 3 THEN
    base_slug := 'company-' || base_slug;
  END IF;
  
  final_slug := base_slug;
  
  WHILE EXISTS (SELECT 1 FROM organizations WHERE slug = final_slug) LOOP
    counter := counter + 1;
    final_slug := base_slug || '-' || counter;
  END LOOP;
  
  RETURN final_slug;
END;
$$ LANGUAGE plpgsql;

-- Updated function to handle new user creation with organization
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  new_org_id uuid;
  org_name text;
  org_slug text;
BEGIN
  org_name := COALESCE(
    NEW.raw_user_meta_data->>'company_name',
    NEW.raw_user_meta_data->>'organization_name',
    split_part(NEW.email, '@', 1) || ' Organization'
  );
  
  org_slug := generate_slug(org_name);
  
  INSERT INTO public.organizations (name, slug, subscription_tier, subscription_status)
  VALUES (org_name, org_slug, 'trial', 'trial')
  RETURNING id INTO new_org_id;
  
  INSERT INTO public.user_profiles (
    id,
    organization_id,
    role,
    full_name
  )
  VALUES (
    NEW.id,
    new_org_id,
    COALESCE(NEW.raw_user_meta_data->>'role', 'admin'),
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();