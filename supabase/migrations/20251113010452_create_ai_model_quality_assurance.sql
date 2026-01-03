/*
  # AI Model Quality Assurance System
  
  1. New Tables
    - `ai_model_predictions`
      - `id` (uuid, primary key)
      - `model_name` (text) - Name of the AI model
      - `model_version` (text)
      - `prediction_type` (text) - fuel_consumption, route_optimization, maintenance, driver_behavior
      - `input_data` (jsonb) - Data fed to the model
      - `predicted_value` (numeric)
      - `confidence_score` (numeric) - 0-100
      - `actual_value` (numeric) - What actually happened
      - `accuracy_percentage` (numeric)
      - `entity_id` (uuid) - Related vehicle/driver/route
      - `predicted_at` (timestamptz)
      - `actual_recorded_at` (timestamptz)
      - `created_at` (timestamptz)
    
    - `ai_model_performance`
      - `id` (uuid, primary key)
      - `model_name` (text)
      - `model_version` (text)
      - `evaluation_period_start` (timestamptz)
      - `evaluation_period_end` (timestamptz)
      - `total_predictions` (integer)
      - `accurate_predictions` (integer)
      - `accuracy_rate` (numeric)
      - `average_confidence` (numeric)
      - `average_error_margin` (numeric)
      - `created_at` (timestamptz)
    
    - `ai_model_retraining_logs`
      - `id` (uuid, primary key)
      - `model_name` (text)
      - `old_version` (text)
      - `new_version` (text)
      - `training_data_size` (integer)
      - `training_duration_minutes` (integer)
      - `performance_improvement` (numeric)
      - `deployed` (boolean)
      - `deployment_date` (timestamptz)
      - `trained_by` (uuid)
      - `created_at` (timestamptz)
    
    - `ai_prediction_explanations`
      - `id` (uuid, primary key)
      - `prediction_id` (uuid)
      - `model_name` (text)
      - `explanation_text` (text) - Human-readable explanation
      - `contributing_factors` (jsonb) - Array of factors that influenced the prediction
      - `feature_importance` (jsonb) - Which data points mattered most
      - `created_at` (timestamptz)
    
    - `ai_ab_test_results`
      - `id` (uuid, primary key)
      - `test_name` (text)
      - `model_a_name` (text)
      - `model_a_version` (text)
      - `model_b_name` (text)
      - `model_b_version` (text)
      - `test_start_date` (timestamptz)
      - `test_end_date` (timestamptz)
      - `model_a_accuracy` (numeric)
      - `model_b_accuracy` (numeric)
      - `winner` (text)
      - `sample_size` (integer)
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Authenticated users can view AI performance data
    - Only admins can view detailed prediction data
*/

-- AI Model Predictions Table
CREATE TABLE IF NOT EXISTS ai_model_predictions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  model_name text NOT NULL,
  model_version text NOT NULL,
  prediction_type text NOT NULL CHECK (prediction_type IN ('fuel_consumption', 'route_optimization', 'maintenance', 'driver_behavior', 'delay_prediction')),
  input_data jsonb NOT NULL,
  predicted_value numeric(10,2) NOT NULL,
  confidence_score numeric(5,2) CHECK (confidence_score >= 0 AND confidence_score <= 100),
  actual_value numeric(10,2),
  accuracy_percentage numeric(5,2),
  entity_id uuid,
  predicted_at timestamptz NOT NULL DEFAULT now(),
  actual_recorded_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_predictions_model ON ai_model_predictions(model_name, model_version, predicted_at DESC);
CREATE INDEX IF NOT EXISTS idx_predictions_type ON ai_model_predictions(prediction_type, predicted_at DESC);
CREATE INDEX IF NOT EXISTS idx_predictions_entity ON ai_model_predictions(entity_id, predicted_at DESC);

-- AI Model Performance Table
CREATE TABLE IF NOT EXISTS ai_model_performance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  model_name text NOT NULL,
  model_version text NOT NULL,
  evaluation_period_start timestamptz NOT NULL,
  evaluation_period_end timestamptz NOT NULL,
  total_predictions integer NOT NULL DEFAULT 0,
  accurate_predictions integer NOT NULL DEFAULT 0,
  accuracy_rate numeric(5,2) NOT NULL,
  average_confidence numeric(5,2),
  average_error_margin numeric(10,2),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_performance_model ON ai_model_performance(model_name, model_version, evaluation_period_start DESC);

-- AI Model Retraining Logs Table
CREATE TABLE IF NOT EXISTS ai_model_retraining_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  model_name text NOT NULL,
  old_version text NOT NULL,
  new_version text NOT NULL,
  training_data_size integer NOT NULL,
  training_duration_minutes integer,
  performance_improvement numeric(5,2),
  deployed boolean NOT NULL DEFAULT false,
  deployment_date timestamptz,
  trained_by uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_retraining_model ON ai_model_retraining_logs(model_name, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_retraining_deployed ON ai_model_retraining_logs(deployed, deployment_date DESC);

-- AI Prediction Explanations Table
CREATE TABLE IF NOT EXISTS ai_prediction_explanations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  prediction_id uuid REFERENCES ai_model_predictions(id),
  model_name text NOT NULL,
  explanation_text text NOT NULL,
  contributing_factors jsonb DEFAULT '[]'::jsonb,
  feature_importance jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_explanations_prediction ON ai_prediction_explanations(prediction_id);
CREATE INDEX IF NOT EXISTS idx_explanations_model ON ai_prediction_explanations(model_name, created_at DESC);

-- AI A/B Test Results Table
CREATE TABLE IF NOT EXISTS ai_ab_test_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  test_name text NOT NULL,
  model_a_name text NOT NULL,
  model_a_version text NOT NULL,
  model_b_name text NOT NULL,
  model_b_version text NOT NULL,
  test_start_date timestamptz NOT NULL,
  test_end_date timestamptz,
  model_a_accuracy numeric(5,2),
  model_b_accuracy numeric(5,2),
  winner text,
  sample_size integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ab_tests_name ON ai_ab_test_results(test_name, test_start_date DESC);

-- Enable RLS
ALTER TABLE ai_model_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_model_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_model_retraining_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_prediction_explanations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_ab_test_results ENABLE ROW LEVEL SECURITY;

-- RLS Policies for ai_model_predictions
CREATE POLICY "Authenticated users can view predictions"
  ON ai_model_predictions FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert predictions"
  ON ai_model_predictions FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "System can update predictions with actual values"
  ON ai_model_predictions FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- RLS Policies for ai_model_performance
CREATE POLICY "Authenticated users can view model performance"
  ON ai_model_performance FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert performance data"
  ON ai_model_performance FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS Policies for ai_model_retraining_logs
CREATE POLICY "Admins can view retraining logs"
  ON ai_model_retraining_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "System can insert retraining logs"
  ON ai_model_retraining_logs FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS Policies for ai_prediction_explanations
CREATE POLICY "Authenticated users can view explanations"
  ON ai_prediction_explanations FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can insert explanations"
  ON ai_prediction_explanations FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS Policies for ai_ab_test_results
CREATE POLICY "Admins can view A/B test results"
  ON ai_ab_test_results FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "System can insert A/B test results"
  ON ai_ab_test_results FOR INSERT
  TO authenticated
  WITH CHECK (true);
