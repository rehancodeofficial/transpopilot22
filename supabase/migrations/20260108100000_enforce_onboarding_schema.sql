-- Drop table if it exists (purging bad schema)
DROP TABLE IF EXISTS public.driver_onboarding_progress CASCADE;

-- Create driver_onboarding_progress table with correct Foreign Keys
CREATE TABLE public.driver_onboarding_progress (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    driver_id UUID REFERENCES public.drivers(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    current_step TEXT,
    completion_percentage INTEGER DEFAULT 0,
    status TEXT DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed')),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(driver_id)
);

-- Enable RLS
ALTER TABLE public.driver_onboarding_progress ENABLE ROW LEVEL SECURITY;

-- Re-apply policies
CREATE POLICY "Users can view their own onboarding progress"
    ON public.driver_onboarding_progress
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Admins and Fleet Managers can view their organization's onboarding progress"
    ON public.driver_onboarding_progress
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE user_profiles.id = auth.uid()
            AND user_profiles.organization_id = driver_onboarding_progress.organization_id
            AND user_profiles.role IN ('admin', 'super_admin', 'fleet_manager')
        )
    );

CREATE POLICY "Users can update their own onboarding progress"
    ON public.driver_onboarding_progress
    FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "System can insert onboarding progress"
    ON public.driver_onboarding_progress
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Grant permissions
GRANT ALL ON public.driver_onboarding_progress TO authenticated;

-- Force schema cache refresh
NOTIFY pgrst, 'reload config';
