/*
  # Create Feedback and Testimonials System

  1. New Tables
    - `feedback_submissions`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key to auth.users, nullable for anonymous feedback)
      - `feedback_type` (text: general, technical, feature_request)
      - `category` (text: ui_ux, performance, bug, feature, other)
      - `rating` (integer, 1-5 stars, nullable)
      - `title` (text, short summary)
      - `message` (text, detailed feedback)
      - `status` (text: new, reviewed, in_progress, resolved)
      - `admin_response` (text, nullable)
      - `metadata` (jsonb, for browser info, device, etc.)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

    - `testimonials`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key to auth.users, nullable)
      - `name` (text)
      - `company` (text)
      - `fleet_size` (text)
      - `position` (text, nullable)
      - `quote` (text)
      - `savings_metric` (text, e.g., "$18,000/month")
      - `avatar_initials` (text, 2-3 characters)
      - `approval_status` (text: pending, approved, rejected)
      - `is_featured` (boolean)
      - `display_order` (integer)
      - `approved_by` (uuid, foreign key to auth.users, nullable)
      - `approved_at` (timestamptz, nullable)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

    - `app_performance_feedback`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key to auth.users, nullable)
      - `issue_type` (text: bug, crash, slow_performance, error)
      - `severity` (text: low, medium, high, critical)
      - `page_url` (text)
      - `browser` (text)
      - `device` (text)
      - `description` (text)
      - `steps_to_reproduce` (text, nullable)
      - `error_message` (text, nullable)
      - `status` (text: new, investigating, resolved, wont_fix)
      - `resolved_at` (timestamptz, nullable)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Authenticated users can create their own feedback
    - Anyone can view approved testimonials
    - Admins can view and manage all feedback
    - Super admins have full access to all operations

  3. Indexes
    - Index on user_id for all tables
    - Index on status for filtering
    - Index on approval_status for testimonials
    - Index on created_at for sorting
*/

CREATE TABLE IF NOT EXISTS feedback_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  feedback_type text NOT NULL CHECK (feedback_type IN ('general', 'technical', 'feature_request')),
  category text NOT NULL CHECK (category IN ('ui_ux', 'performance', 'bug', 'feature', 'other')),
  rating integer CHECK (rating >= 1 AND rating <= 5),
  title text NOT NULL,
  message text NOT NULL,
  status text NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'reviewed', 'in_progress', 'resolved')),
  admin_response text,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS testimonials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  name text NOT NULL,
  company text NOT NULL,
  fleet_size text,
  position text,
  quote text NOT NULL,
  savings_metric text,
  avatar_initials text NOT NULL,
  approval_status text NOT NULL DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  is_featured boolean DEFAULT false,
  display_order integer DEFAULT 0,
  approved_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  approved_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS app_performance_feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  issue_type text NOT NULL CHECK (issue_type IN ('bug', 'crash', 'slow_performance', 'error')),
  severity text NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  page_url text NOT NULL,
  browser text,
  device text,
  description text NOT NULL,
  steps_to_reproduce text,
  error_message text,
  status text NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'investigating', 'resolved', 'wont_fix')),
  resolved_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_feedback_submissions_user_id ON feedback_submissions(user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_submissions_status ON feedback_submissions(status);
CREATE INDEX IF NOT EXISTS idx_feedback_submissions_created_at ON feedback_submissions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_testimonials_user_id ON testimonials(user_id);
CREATE INDEX IF NOT EXISTS idx_testimonials_approval_status ON testimonials(approval_status);
CREATE INDEX IF NOT EXISTS idx_testimonials_display_order ON testimonials(display_order);
CREATE INDEX IF NOT EXISTS idx_testimonials_created_at ON testimonials(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_app_performance_feedback_user_id ON app_performance_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_app_performance_feedback_status ON app_performance_feedback(status);
CREATE INDEX IF NOT EXISTS idx_app_performance_feedback_severity ON app_performance_feedback(severity);
CREATE INDEX IF NOT EXISTS idx_app_performance_feedback_created_at ON app_performance_feedback(created_at DESC);

ALTER TABLE feedback_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE testimonials ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_performance_feedback ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own feedback submissions"
  ON feedback_submissions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create feedback submissions"
  ON feedback_submissions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own pending feedback"
  ON feedback_submissions FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id AND status = 'new')
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all feedback submissions"
  ON feedback_submissions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Admins can update all feedback submissions"
  ON feedback_submissions FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Anyone can view approved testimonials"
  ON testimonials FOR SELECT
  USING (approval_status = 'approved');

CREATE POLICY "Authenticated users can view all testimonials"
  ON testimonials FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create testimonials"
  ON testimonials FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can manage all testimonials"
  ON testimonials FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Users can view their own performance feedback"
  ON app_performance_feedback FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create performance feedback"
  ON app_performance_feedback FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all performance feedback"
  ON app_performance_feedback FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Admins can update all performance feedback"
  ON app_performance_feedback FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );