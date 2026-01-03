/*
  # Add Onboarding Fields to User Profiles

  1. Changes
    - Add `onboarding_completed` boolean field to track if user finished onboarding
    - Add `onboarding_steps` jsonb field to track completed onboarding steps
    - Add `welcome_modal_seen` boolean field to track if user saw welcome modal
    - Add `onboarding_dismissed` boolean field to track if user dismissed the checklist
    - Add `demo_mode` boolean field to indicate if user is using demo data

  2. Defaults
    - `onboarding_completed` defaults to false
    - `onboarding_steps` defaults to empty array
    - `welcome_modal_seen` defaults to false
    - `onboarding_dismissed` defaults to false
    - `demo_mode` defaults to true for new users

  3. Notes
    - All fields are nullable for backward compatibility with existing users
    - New users will automatically have demo_mode enabled
*/

-- Add onboarding fields to user_profiles table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_profiles' AND column_name = 'onboarding_completed'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN onboarding_completed boolean DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_profiles' AND column_name = 'onboarding_steps'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN onboarding_steps jsonb DEFAULT '[]'::jsonb;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_profiles' AND column_name = 'welcome_modal_seen'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN welcome_modal_seen boolean DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_profiles' AND column_name = 'onboarding_dismissed'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN onboarding_dismissed boolean DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_profiles' AND column_name = 'demo_mode'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN demo_mode boolean DEFAULT true;
  END IF;
END $$;
