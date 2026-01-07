-- Create driver_onboarding_progress table
CREATE TABLE IF NOT EXISTS public.driver_onboarding_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  organization_id uuid,
  step text NOT NULL,
  is_completed boolean DEFAULT false,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (driver_id, step)
);

ALTER TABLE public.driver_onboarding_progress ENABLE ROW LEVEL SECURITY;

-- Allow drivers to view their own onboarding progress
CREATE POLICY "Drivers can view their onboarding progress"
ON public.driver_onboarding_progress
FOR SELECT
USING (auth.uid() = driver_id);

-- Allow drivers to insert/update their onboarding progress
CREATE POLICY "Drivers can manage their onboarding progress"
ON public.driver_onboarding_progress
FOR ALL
USING (auth.uid() = driver_id)
WITH CHECK (auth.uid() = driver_id);

GRANT ALL ON public.driver_onboarding_progress TO authenticated;
