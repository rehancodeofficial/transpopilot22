/*
  # Create Training and Contact Tables

  ## New Tables
  
  ### `training_modules`
  - `id` (uuid, primary key) - Unique module identifier
  - `title` (text) - Module title
  - `description` (text) - Module description
  - `duration_hours` (decimal) - Duration in hours
  - `module_type` (text) - Type of training
  - `required` (boolean) - Whether module is required
  - `content_url` (text) - URL to training content
  - `created_at` (timestamptz) - Record creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### `driver_training`
  - `id` (uuid, primary key) - Unique training record identifier
  - `driver_id` (uuid, foreign key) - Driver taking training
  - `module_id` (uuid, foreign key) - Training module
  - `status` (text) - Completion status
  - `progress_percent` (integer) - Progress percentage
  - `started_at` (timestamptz) - When training started
  - `completed_at` (timestamptz) - When training completed
  - `score` (decimal) - Test score if applicable
  - `created_at` (timestamptz) - Record creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### `contact_submissions`
  - `id` (uuid, primary key) - Unique submission identifier
  - `name` (text) - Contact name
  - `email` (text) - Contact email
  - `company` (text) - Company name
  - `phone` (text) - Phone number
  - `fleet_size` (text) - Fleet size range
  - `inquiry_type` (text) - Type of inquiry
  - `message` (text) - Message content
  - `status` (text) - Follow-up status
  - `created_at` (timestamptz) - Record creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ## Security
  - Enable RLS on all tables
  - Add policies for authenticated access
*/

-- Create training_modules table
CREATE TABLE IF NOT EXISTS training_modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  duration_hours decimal(5, 2) NOT NULL CHECK (duration_hours > 0),
  module_type text NOT NULL CHECK (module_type IN ('video', 'interactive', 'hands_on', 'simulation', 'document')),
  required boolean DEFAULT false,
  content_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create driver_training table
CREATE TABLE IF NOT EXISTS driver_training (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid REFERENCES drivers(id) ON DELETE CASCADE NOT NULL,
  module_id uuid REFERENCES training_modules(id) ON DELETE CASCADE NOT NULL,
  status text NOT NULL DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed', 'failed')),
  progress_percent integer DEFAULT 0 CHECK (progress_percent >= 0 AND progress_percent <= 100),
  started_at timestamptz,
  completed_at timestamptz,
  score decimal(5, 2) CHECK (score >= 0 AND score <= 100),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(driver_id, module_id)
);

-- Create contact_submissions table
CREATE TABLE IF NOT EXISTS contact_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text NOT NULL CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  company text,
  phone text,
  fleet_size text,
  inquiry_type text NOT NULL DEFAULT 'demo' CHECK (inquiry_type IN ('demo', 'trial', 'pricing', 'integration', 'support', 'general')),
  message text,
  status text NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'contacted', 'qualified', 'converted', 'closed')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_driver_training_driver ON driver_training(driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_training_module ON driver_training(module_id);
CREATE INDEX IF NOT EXISTS idx_driver_training_status ON driver_training(status);
CREATE INDEX IF NOT EXISTS idx_contact_submissions_status ON contact_submissions(status);
CREATE INDEX IF NOT EXISTS idx_contact_submissions_email ON contact_submissions(email);

-- Enable Row Level Security
ALTER TABLE training_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_training ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_submissions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow authenticated users to read training_modules"
  ON training_modules FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert training_modules"
  ON training_modules FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update training_modules"
  ON training_modules FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to read driver_training"
  ON driver_training FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert driver_training"
  ON driver_training FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update driver_training"
  ON driver_training FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to read contact_submissions"
  ON contact_submissions FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert contact_submissions"
  ON contact_submissions FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update contact_submissions"
  ON contact_submissions FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);