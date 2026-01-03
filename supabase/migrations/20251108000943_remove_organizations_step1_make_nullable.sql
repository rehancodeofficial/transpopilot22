/*
  # Remove Organizations - Step 1: Make organization_id Nullable

  ## Overview
  First step in removing organization multi-tenancy. Makes organization_id nullable
  in all tables to prepare for removal.

  ## Changes
  1. Make organization_id nullable in user_profiles
  2. Make organization_id nullable in vehicles (if exists)
  3. Make organization_id nullable in drivers (if exists)
  4. Make organization_id nullable in routes (if exists)

  ## Security
  - Maintains existing RLS policies temporarily
  - No breaking changes to existing data

  ## Important Notes
  - This is a safe first step that doesn't break anything
  - Next migration will remove the columns entirely
*/

-- Make organization_id nullable in user_profiles
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_profiles' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE user_profiles ALTER COLUMN organization_id DROP NOT NULL;
  END IF;
END $$;

-- Make organization_id nullable in vehicles if column exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'vehicles' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE vehicles ALTER COLUMN organization_id DROP NOT NULL;
  END IF;
END $$;

-- Make organization_id nullable in drivers if column exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'drivers' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE drivers ALTER COLUMN organization_id DROP NOT NULL;
  END IF;
END $$;

-- Make organization_id nullable in routes if column exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'routes' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE routes ALTER COLUMN organization_id DROP NOT NULL;
  END IF;
END $$;