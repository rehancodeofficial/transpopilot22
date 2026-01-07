-- Create driver_onboarding_progress table
CREATE TABLE IF NOT EXISTS public.driver_onboarding_progress (
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
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.driver_onboarding_progress ENABLE ROW LEVEL SECURITY;

-- Create policies for driver_onboarding_progress
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

-- Create training_modules table if not exists
CREATE TABLE IF NOT EXISTS public.training_modules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    content_type TEXT CHECK (content_type IN ('video', 'document', 'quiz', 'interactive')),
    content_url TEXT,
    duration_minutes INTEGER,
    is_required BOOLEAN DEFAULT false,
    display_order INTEGER,
    passing_score INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.training_modules ENABLE ROW LEVEL SECURITY;

-- Policies for training_modules
CREATE POLICY "Users can view training modules in their organization"
    ON public.training_modules
    FOR SELECT
    USING (
        organization_id IS NULL OR
        organization_id = (SELECT organization_id FROM public.user_profiles WHERE id = auth.uid())
    );

CREATE POLICY "Admins can manage training modules"
    ON public.training_modules
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE user_profiles.id = auth.uid()
            AND user_profiles.organization_id = training_modules.organization_id
            AND user_profiles.role IN ('admin', 'super_admin')
        )
    );

-- Create driver_training_completions table if not exists
CREATE TABLE IF NOT EXISTS public.driver_training_completions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    driver_id UUID REFERENCES public.drivers(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    training_module_id UUID REFERENCES public.training_modules(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    time_spent_minutes INTEGER DEFAULT 0,
    quiz_score INTEGER,
    status TEXT DEFAULT 'completed' CHECK (status IN ('completed', 'in_progress', 'failed')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(driver_id, training_module_id)
);

-- Enable RLS
ALTER TABLE public.driver_training_completions ENABLE ROW LEVEL SECURITY;

-- Policies for training completions
CREATE POLICY "Users can view and manage their own completions"
    ON public.driver_training_completions
    FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can view organization completions"
    ON public.driver_training_completions
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE user_profiles.id = auth.uid()
            AND user_profiles.organization_id = driver_training_completions.organization_id
            AND user_profiles.role IN ('admin', 'super_admin', 'fleet_manager')
        )
    );

-- Create document_requirements table if not exists
CREATE TABLE IF NOT EXISTS public.document_requirements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    is_required BOOLEAN DEFAULT true,
    display_order INTEGER,
    accepted_file_types TEXT[] DEFAULT ARRAY['application/pdf', 'image/jpeg', 'image/png'],
    max_file_size_mb INTEGER DEFAULT 5,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.document_requirements ENABLE ROW LEVEL SECURITY;

-- Policies for document requirements
CREATE POLICY "Users can view requirements"
    ON public.document_requirements
    FOR SELECT
    USING (
        organization_id IS NULL OR
        organization_id = (SELECT organization_id FROM public.user_profiles WHERE id = auth.uid())
    );

CREATE POLICY "Admins can manage requirements"
    ON public.document_requirements
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE user_profiles.id = auth.uid()
            AND user_profiles.organization_id = document_requirements.organization_id
            AND user_profiles.role IN ('admin', 'super_admin')
        )
    );

-- Create driver_documents table if not exists
CREATE TABLE IF NOT EXISTS public.driver_documents (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    driver_id UUID REFERENCES public.drivers(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    document_requirement_id UUID REFERENCES public.document_requirements(id) ON DELETE SET NULL,
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size_bytes BIGINT,
    file_type TEXT,
    approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    reviewed_by UUID REFERENCES auth.users(id),
    reviewed_at TIMESTAMPTZ,
    rejection_reason TEXT,
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.driver_documents ENABLE ROW LEVEL SECURITY;

-- Policies for driver documents
CREATE POLICY "Users can view and upload their own documents"
    ON public.driver_documents
    FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can view and manage organization documents"
    ON public.driver_documents
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE user_profiles.id = auth.uid()
            AND user_profiles.organization_id = driver_documents.organization_id
            AND user_profiles.role IN ('admin', 'super_admin', 'fleet_manager')
        )
    );

-- Grant permissions to authenticated users
GRANT ALL ON public.driver_onboarding_progress TO authenticated;
GRANT ALL ON public.training_modules TO authenticated;
GRANT ALL ON public.driver_training_completions TO authenticated;
GRANT ALL ON public.document_requirements TO authenticated;
GRANT ALL ON public.driver_documents TO authenticated;

-- Force schema cache refresh by notifying pgrst
NOTIFY pgrst, 'reload config';
