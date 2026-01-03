/*
  # Fix Security and Performance Issues - Part 1

  1. Critical Fixes
    - Enable RLS on trial_registrations
    - Add missing foreign key indexes (14 indexes)
    - Fix function search paths (prevents schema hijacking)

  2. Performance Improvements
    - Add covering indexes for foreign keys
*/

-- ============================================================================
-- PART 1: Enable RLS on trial_registrations
-- ============================================================================

ALTER TABLE trial_registrations ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PART 2: Add Missing Foreign Key Indexes
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_ai_retraining_trained_by
  ON ai_model_retraining_logs(trained_by);

CREATE INDEX IF NOT EXISTS idx_compliance_audits_audited_by
  ON compliance_audits(audited_by);

CREATE INDEX IF NOT EXISTS idx_encryption_logs_performed_by
  ON data_encryption_logs(performed_by);

CREATE INDEX IF NOT EXISTS idx_fleet_assignments_assigned_by
  ON fleet_manager_assignments(assigned_by);

CREATE INDEX IF NOT EXISTS idx_geofence_events_geofence
  ON geofence_events(geofence_id);

CREATE INDEX IF NOT EXISTS idx_geofence_events_vehicle
  ON geofence_events(vehicle_id);

CREATE INDEX IF NOT EXISTS idx_sandbox_tests_tested_by
  ON integration_sandbox_tests(tested_by);

CREATE INDEX IF NOT EXISTS idx_safety_reports_reported_by
  ON safety_incident_reports(reported_by);

CREATE INDEX IF NOT EXISTS idx_sla_logs_user
  ON sla_performance_logs(user_id);

CREATE INDEX IF NOT EXISTS idx_system_alerts_resolved_by
  ON system_alerts(resolved_by);

CREATE INDEX IF NOT EXISTS idx_testimonials_approved_by
  ON testimonials(approved_by);

CREATE INDEX IF NOT EXISTS idx_inspection_inspector
  ON vehicle_inspection_records(inspector_id);

CREATE INDEX IF NOT EXISTS idx_vehicles_driver
  ON vehicles(driver_id);

CREATE INDEX IF NOT EXISTS idx_webhooks_provider
  ON webhook_configurations(provider_id);

-- ============================================================================
-- PART 3: Fix Function Search Paths (Security)
-- ============================================================================

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'set_organization_tier_limits') THEN
    ALTER FUNCTION set_organization_tier_limits SET search_path = public, pg_temp;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'generate_slug') THEN
    ALTER FUNCTION generate_slug SET search_path = public, pg_temp;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'calculate_uptime_metrics') THEN
    ALTER FUNCTION calculate_uptime_metrics SET search_path = public, pg_temp;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_user_assigned_vehicles') THEN
    ALTER FUNCTION get_user_assigned_vehicles SET search_path = public, pg_temp;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_user_assigned_drivers') THEN
    ALTER FUNCTION get_user_assigned_drivers SET search_path = public, pg_temp;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'is_fleet_manager') THEN
    ALTER FUNCTION is_fleet_manager SET search_path = public, pg_temp;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'is_super_admin') THEN
    ALTER FUNCTION is_super_admin SET search_path = public, pg_temp;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'update_updated_at_column') THEN
    ALTER FUNCTION update_updated_at_column SET search_path = public, pg_temp;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_new_user') THEN
    ALTER FUNCTION handle_new_user SET search_path = public, pg_temp;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'promote_user_to_admin') THEN
    ALTER FUNCTION promote_user_to_admin SET search_path = public, pg_temp;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'promote_to_super_admin') THEN
    ALTER FUNCTION promote_to_super_admin SET search_path = public, pg_temp;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'demote_admin_to_user') THEN
    ALTER FUNCTION demote_admin_to_user SET search_path = public, pg_temp;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'grant_super_admin') THEN
    ALTER FUNCTION grant_super_admin SET search_path = public, pg_temp;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'seed_user_demo_data') THEN
    ALTER FUNCTION seed_user_demo_data SET search_path = public, pg_temp;
  END IF;
END $$;