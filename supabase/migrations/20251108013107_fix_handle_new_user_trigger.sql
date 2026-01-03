/*
  # Fix User Profile Creation Trigger
  
  ## Overview
  Fixes the handle_new_user() trigger function to remove organization_id reference
  which was causing signup failures after organizations table was dropped.
  
  ## Changes Made
  1. Update handle_new_user() function to only insert fields that exist in user_profiles
  2. Remove organization_id from the INSERT statement
  3. Keep role and full_name handling from raw_user_meta_data
  4. Maintain SECURITY DEFINER to bypass RLS during trigger execution
  
  ## Security
  - Function runs with SECURITY DEFINER to allow profile creation
  - Only inserts the user's own profile (NEW.id)
  - Role defaults to 'user' if not specified in metadata
  - Uses ON CONFLICT DO NOTHING to prevent duplicate insertions
  
  ## Important Notes
  - This fixes the "database error saving new user" message during signup
  - User profiles are automatically created when auth.users records are created
  - The trigger handles missing metadata gracefully with defaults
*/

-- Recreate the handle_new_user function without organization_id
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, role, full_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'role', 'user'),
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure the trigger exists (recreate if needed)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();
