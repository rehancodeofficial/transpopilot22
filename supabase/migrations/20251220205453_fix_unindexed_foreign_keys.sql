/*
  # Fix Unindexed Foreign Keys
  
  ## Overview
  Adds indexes to foreign key columns that are missing them to improve query performance.
  Foreign keys without indexes can cause slow joins and suboptimal query execution plans.
  
  ## Changes
  Adds indexes for the following foreign keys:
  
  1. document_requirements.organization_id
  2. driver_documents.driver_id
  3. driver_documents.organization_id
  4. driver_documents.user_id
  5. driver_onboarding_progress.user_id
  6. driver_training_completions.organization_id
  7. driver_training_completions.training_module_id
  8. driver_training_completions.user_id
  9. drivers.user_id
  10. training_modules.organization_id
  
  ## Performance Impact
  - Significantly improves JOIN performance on these columns
  - Speeds up foreign key constraint checks
  - Reduces query planning time for complex queries involving these tables
*/

-- Add index for document_requirements.organization_id
CREATE INDEX IF NOT EXISTS idx_document_requirements_organization_id 
  ON document_requirements(organization_id);

-- Add indexes for driver_documents foreign keys
CREATE INDEX IF NOT EXISTS idx_driver_documents_driver_id 
  ON driver_documents(driver_id);

CREATE INDEX IF NOT EXISTS idx_driver_documents_organization_id 
  ON driver_documents(organization_id);

CREATE INDEX IF NOT EXISTS idx_driver_documents_user_id 
  ON driver_documents(user_id);

-- Add index for driver_onboarding_progress.user_id
CREATE INDEX IF NOT EXISTS idx_driver_onboarding_progress_user_id 
  ON driver_onboarding_progress(user_id);

-- Add indexes for driver_training_completions foreign keys
CREATE INDEX IF NOT EXISTS idx_driver_training_completions_organization_id 
  ON driver_training_completions(organization_id);

CREATE INDEX IF NOT EXISTS idx_driver_training_completions_training_module_id 
  ON driver_training_completions(training_module_id);

CREATE INDEX IF NOT EXISTS idx_driver_training_completions_user_id 
  ON driver_training_completions(user_id);

-- Add index for drivers.user_id
CREATE INDEX IF NOT EXISTS idx_drivers_user_id 
  ON drivers(user_id);

-- Add index for training_modules.organization_id
CREATE INDEX IF NOT EXISTS idx_training_modules_organization_id 
  ON training_modules(organization_id);
