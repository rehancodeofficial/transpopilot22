/*
  # Drop Unused Indexes

  ## Overview
  Removes indexes that are not being used by queries. This reduces:
  - Storage space usage
  - Write operation overhead (indexes must be updated on INSERT/UPDATE/DELETE)
  - Maintenance overhead

  ## Changes
  Drops 14 unused indexes from driver onboarding tables:
  - drivers: idx_drivers_user_id
  - training_modules: idx_training_modules_org
  - driver_onboarding_progress: idx_onboarding_progress_driver, idx_onboarding_progress_user, idx_onboarding_progress_status
  - driver_training_completions: idx_training_completions_driver, idx_training_completions_user, idx_training_completions_module, idx_training_completions_org
  - document_requirements: idx_document_requirements_org, idx_document_requirements_order
  - driver_documents: idx_driver_documents_driver, idx_driver_documents_user, idx_driver_documents_org

  ## Performance Impact
  - Reduces write operation overhead
  - Frees up storage space
  - Simplifies query planner decisions
*/

-- Drop unused indexes from drivers table
DROP INDEX IF EXISTS idx_drivers_user_id;

-- Drop unused indexes from training_modules table
DROP INDEX IF EXISTS idx_training_modules_org;

-- Drop unused indexes from driver_onboarding_progress table
DROP INDEX IF EXISTS idx_onboarding_progress_driver;
DROP INDEX IF EXISTS idx_onboarding_progress_user;
DROP INDEX IF EXISTS idx_onboarding_progress_status;

-- Drop unused indexes from driver_training_completions table
DROP INDEX IF EXISTS idx_training_completions_driver;
DROP INDEX IF EXISTS idx_training_completions_user;
DROP INDEX IF EXISTS idx_training_completions_module;
DROP INDEX IF EXISTS idx_training_completions_org;

-- Drop unused indexes from document_requirements table
DROP INDEX IF EXISTS idx_document_requirements_org;
DROP INDEX IF EXISTS idx_document_requirements_order;

-- Drop unused indexes from driver_documents table
DROP INDEX IF EXISTS idx_driver_documents_driver;
DROP INDEX IF EXISTS idx_driver_documents_user;
DROP INDEX IF EXISTS idx_driver_documents_org;