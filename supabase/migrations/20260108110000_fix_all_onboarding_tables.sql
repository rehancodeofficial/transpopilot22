-- Master Migration: Fix all Driver Onboarding Tables and Relationships
-- This script ensures all tables exist with correct schemas and Row Level Security.

-- 1. Ensure drivers table has user_id relationship
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'drivers' AND column_name = 'user_id') THEN
        ALTER TABLE public.drivers ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 2. Drop and Recreate driver_onboarding_progress (Surgical Fix for Relationships)
DROP TABLE IF EXISTS public.driver_onboarding_progress CASCADE;
CREATE TABLE public.driver_onboarding_progress (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    driver_id UUID REFERENCES public.drivers(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    current_step TEXT DEFAULT 'welcome',
    completion_percentage INTEGER DEFAULT 0,
    status TEXT DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed')),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(driver_id)
);

-- 3. Ensure training_modules exists
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

-- 4. Ensure driver_training_completions exists
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

-- 5. Ensure document_requirements exists
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

-- 6. Drop and Recreate driver_documents
DROP TABLE IF EXISTS public.driver_documents CASCADE;
CREATE TABLE public.driver_documents (
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
    reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    rejection_reason TEXT,
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on all tables
ALTER TABLE public.driver_onboarding_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.training_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_training_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_documents ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT ALL ON public.driver_onboarding_progress TO authenticated;
GRANT ALL ON public.training_modules TO authenticated;
GRANT ALL ON public.driver_training_completions TO authenticated;
GRANT ALL ON public.document_requirements TO authenticated;
GRANT ALL ON public.driver_documents TO authenticated;

-- Policies (Simplified for broad accessibility within organization)
CREATE POLICY "Onboarding: View own progress" ON public.driver_onboarding_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Onboarding: Admin view org progress" ON public.driver_onboarding_progress FOR SELECT USING (EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND organization_id = driver_onboarding_progress.organization_id));
CREATE POLICY "Documents: View own" ON public.driver_documents FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Documents: Admin manage all" ON public.driver_documents FOR ALL USING (EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND organization_id = driver_documents.organization_id));

-- Refresh Schema Cache
NOTIFY pgrst, 'reload config';
