/*
  # Driver Self-Service Onboarding System

  ## Overview
  Enables drivers to manage their own onboarding process with training modules,
  document uploads, and progress tracking. Admins can oversee all drivers.

  ## New Tables

  ### `driver_onboarding_progress`
  - `id` (uuid, primary key) - Unique progress record identifier
  - `driver_id` (uuid, foreign key) - References drivers table
  - `user_id` (uuid, foreign key) - References auth.users
  - `organization_id` (uuid, foreign key) - References organizations
  - `current_step` (text) - Current onboarding step
  - `completion_percentage` (integer) - Overall progress 0-100
  - `status` (text) - 'not_started', 'in_progress', 'completed'
  - `started_at` (timestamptz) - When onboarding began
  - `completed_at` (timestamptz) - When fully completed
  - `created_at` (timestamptz) - Record creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### `driver_training_completions`
  - `id` (uuid, primary key) - Unique completion record
  - `driver_id` (uuid, foreign key) - References drivers table
  - `user_id` (uuid, foreign key) - References auth.users
  - `training_module_id` (uuid, foreign key) - References training_modules
  - `organization_id` (uuid, foreign key) - References organizations
  - `completed_at` (timestamptz) - Completion timestamp
  - `time_spent_minutes` (integer) - Time spent on module
  - `quiz_score` (integer) - Score if module had a quiz
  - `status` (text) - 'completed', 'in_progress', 'failed'
  - `created_at` (timestamptz) - Record creation timestamp

  ### `document_requirements`
  - `id` (uuid, primary key) - Unique requirement identifier
  - `organization_id` (uuid, foreign key) - References organizations
  - `document_type` (text, required) - Type of document needed
  - `title` (text, required) - Display name for document
  - `description` (text) - Instructions for driver
  - `is_required` (boolean) - Whether document is mandatory
  - `display_order` (integer) - Order to display requirements
  - `accepted_file_types` (text[]) - Array of allowed file extensions
  - `max_file_size_mb` (integer) - Maximum file size allowed
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### `driver_documents`
  - `id` (uuid, primary key) - Unique document identifier
  - `driver_id` (uuid, foreign key) - References drivers table
  - `user_id` (uuid, foreign key) - References auth.users
  - `document_requirement_id` (uuid, foreign key) - References document_requirements
  - `organization_id` (uuid, foreign key) - References organizations
  - `file_name` (text, required) - Original file name
  - `file_path` (text, required) - Storage path in Supabase Storage
  - `file_size_bytes` (bigint) - File size
  - `file_type` (text) - MIME type
  - `approval_status` (text) - 'pending', 'approved', 'rejected'
  - `reviewed_by` (uuid) - User who reviewed the document
  - `reviewed_at` (timestamptz) - Review timestamp
  - `rejection_reason` (text) - Why document was rejected
  - `uploaded_at` (timestamptz) - Upload timestamp
  - `created_at` (timestamptz) - Record creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ## Schema Changes
  - Add `user_id` to drivers table to link with auth.users
  - Add `organization_id` to training_modules table (if not exists)

  ## Security
  - Enable RLS on all tables
  - Drivers can read/update their own onboarding data
  - Admins and fleet managers can manage all onboarding in their organization
  - Super admins have full access

  ## Important Notes
  - user_id links drivers to auth.users for self-service access
  - Progress is automatically calculated based on completions
  - Documents are stored in Supabase Storage with secure access
*/

-- Add user_id to drivers table to link with auth.users
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'drivers' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE drivers ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;
    CREATE INDEX IF NOT EXISTS idx_drivers_user_id ON drivers(user_id);
  END IF;
END $$;

-- Add organization_id to training_modules table (if not exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'training_modules' AND column_name = 'organization_id'
  ) THEN
    ALTER TABLE training_modules ADD COLUMN organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_training_modules_org ON training_modules(organization_id);
  END IF;
END $$;

-- Create driver_onboarding_progress table
CREATE TABLE IF NOT EXISTS driver_onboarding_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  current_step text NOT NULL DEFAULT 'welcome',
  completion_percentage integer NOT NULL DEFAULT 0 CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
  status text NOT NULL DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed')),
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(driver_id)
);

-- Create driver_training_completions table
CREATE TABLE IF NOT EXISTS driver_training_completions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  training_module_id uuid NOT NULL REFERENCES training_modules(id) ON DELETE CASCADE,
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  completed_at timestamptz DEFAULT now(),
  time_spent_minutes integer DEFAULT 0,
  quiz_score integer CHECK (quiz_score >= 0 AND quiz_score <= 100),
  status text NOT NULL DEFAULT 'completed' CHECK (status IN ('completed', 'in_progress', 'failed')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(driver_id, training_module_id)
);

-- Create document_requirements table
CREATE TABLE IF NOT EXISTS document_requirements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  document_type text NOT NULL,
  title text NOT NULL,
  description text,
  is_required boolean DEFAULT true,
  display_order integer DEFAULT 0,
  accepted_file_types text[] DEFAULT ARRAY['pdf', 'jpg', 'jpeg', 'png'],
  max_file_size_mb integer DEFAULT 10 CHECK (max_file_size_mb > 0),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create driver_documents table
CREATE TABLE IF NOT EXISTS driver_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  document_requirement_id uuid REFERENCES document_requirements(id) ON DELETE SET NULL,
  organization_id uuid REFERENCES organizations(id) ON DELETE CASCADE,
  file_name text NOT NULL,
  file_path text NOT NULL,
  file_size_bytes bigint NOT NULL CHECK (file_size_bytes > 0),
  file_type text NOT NULL,
  approval_status text NOT NULL DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  reviewed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  rejection_reason text,
  uploaded_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_onboarding_progress_driver ON driver_onboarding_progress(driver_id);
CREATE INDEX IF NOT EXISTS idx_onboarding_progress_user ON driver_onboarding_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_onboarding_progress_org ON driver_onboarding_progress(organization_id);
CREATE INDEX IF NOT EXISTS idx_onboarding_progress_status ON driver_onboarding_progress(status);

CREATE INDEX IF NOT EXISTS idx_training_completions_driver ON driver_training_completions(driver_id);
CREATE INDEX IF NOT EXISTS idx_training_completions_user ON driver_training_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_training_completions_module ON driver_training_completions(training_module_id);
CREATE INDEX IF NOT EXISTS idx_training_completions_org ON driver_training_completions(organization_id);

CREATE INDEX IF NOT EXISTS idx_document_requirements_org ON document_requirements(organization_id);
CREATE INDEX IF NOT EXISTS idx_document_requirements_order ON document_requirements(display_order);

CREATE INDEX IF NOT EXISTS idx_driver_documents_driver ON driver_documents(driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_documents_user ON driver_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_driver_documents_org ON driver_documents(organization_id);
CREATE INDEX IF NOT EXISTS idx_driver_documents_status ON driver_documents(approval_status);

-- Enable Row Level Security
ALTER TABLE driver_onboarding_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_training_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_documents ENABLE ROW LEVEL SECURITY;

-- RLS Policies for driver_onboarding_progress

-- Drivers can view their own progress
CREATE POLICY "Drivers can view own onboarding progress"
  ON driver_onboarding_progress FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Drivers can update their own progress
CREATE POLICY "Drivers can update own onboarding progress"
  ON driver_onboarding_progress FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Admins and fleet managers can view all progress in their org
CREATE POLICY "Admins can view org onboarding progress"
  ON driver_onboarding_progress FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.organization_id = driver_onboarding_progress.organization_id
      AND user_profiles.role IN ('admin', 'super_admin', 'fleet_manager')
    )
  );

-- Admins can manage all progress in their org
CREATE POLICY "Admins can manage org onboarding progress"
  ON driver_onboarding_progress FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.organization_id = driver_onboarding_progress.organization_id
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

-- RLS Policies for driver_training_completions

-- Drivers can view their own completions
CREATE POLICY "Drivers can view own training completions"
  ON driver_training_completions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Drivers can insert their own completions
CREATE POLICY "Drivers can insert own training completions"
  ON driver_training_completions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Admins can view all completions in their org
CREATE POLICY "Admins can view org training completions"
  ON driver_training_completions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.organization_id = driver_training_completions.organization_id
      AND user_profiles.role IN ('admin', 'super_admin', 'fleet_manager')
    )
  );

-- RLS Policies for document_requirements

-- All authenticated users can view document requirements in their org
CREATE POLICY "Users can view org document requirements"
  ON document_requirements FOR SELECT
  TO authenticated
  USING (
    organization_id IS NULL OR
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.organization_id = document_requirements.organization_id
    )
  );

-- Only admins can manage document requirements
CREATE POLICY "Admins can manage document requirements"
  ON document_requirements FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND (
        user_profiles.organization_id = document_requirements.organization_id
        OR document_requirements.organization_id IS NULL
      )
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

-- RLS Policies for driver_documents

-- Drivers can view their own documents
CREATE POLICY "Drivers can view own documents"
  ON driver_documents FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Drivers can insert their own documents
CREATE POLICY "Drivers can insert own documents"
  ON driver_documents FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Drivers can update their own documents (for resubmission)
CREATE POLICY "Drivers can update own documents"
  ON driver_documents FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Admins can view all documents in their org
CREATE POLICY "Admins can view org documents"
  ON driver_documents FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.organization_id = driver_documents.organization_id
      AND user_profiles.role IN ('admin', 'super_admin', 'fleet_manager')
    )
  );

-- Admins can update documents (for approval/rejection)
CREATE POLICY "Admins can update org documents"
  ON driver_documents FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.organization_id = driver_documents.organization_id
      AND user_profiles.role IN ('admin', 'super_admin', 'fleet_manager')
    )
  );

-- Create updated_at triggers
CREATE TRIGGER update_driver_onboarding_progress_updated_at
  BEFORE UPDATE ON driver_onboarding_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_document_requirements_updated_at
  BEFORE UPDATE ON document_requirements
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_driver_documents_updated_at
  BEFORE UPDATE ON driver_documents
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Seed some default document requirements
INSERT INTO document_requirements (document_type, title, description, is_required, display_order)
VALUES
  ('drivers_license', 'Valid Driver License', 'Upload a clear photo or scan of your current driver license (front and back)', true, 1),
  ('medical_certificate', 'Medical Examiner Certificate', 'DOT medical card showing you are medically qualified to drive', true, 2),
  ('cdl_endorsements', 'CDL Endorsements', 'If you have additional CDL endorsements, upload documentation', false, 3),
  ('background_check', 'Background Check Authorization', 'Signed authorization form for background check', true, 4),
  ('drug_test', 'Drug Test Results', 'Recent drug test results or authorization form', true, 5),
  ('proof_of_address', 'Proof of Address', 'Recent utility bill or bank statement showing your current address', true, 6)
ON CONFLICT DO NOTHING;
