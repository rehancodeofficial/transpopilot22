/*
  # Drop Unused Indexes

  1. Purpose
    - Remove unused indexes to improve database performance
    - Reduce index maintenance overhead during writes
    - Free up storage space

  2. Affected Tables
    - gps_tracking (2 indexes)
    - driver_onboarding_progress (1 index)
    - driver_training_completions (3 indexes)
    - drivers (2 indexes)
    - training_modules (1 index)
    - document_requirements (1 index)
    - driver_documents (4 indexes)
    - access_control_logs (1 index)
    - security_audit_logs (1 index)
    - session_tracking (1 index)
    - data_encryption_logs (1 index)
    - ai_model_retraining_logs (1 index)
    - ai_prediction_explanations (1 index)
    - api_performance_logs (1 index)
    - api_rate_limit_tracking (1 index)
    - app_performance_feedback (1 index)
    - compliance_audits (1 index)
    - compliance_items (1 index)
    - driver_locations (1 index)
    - driver_training (2 indexes)
    - feedback_submissions (1 index)
    - testimonials (2 indexes)
    - fleet_manager_assignments (4 indexes)
    - fuel_records (1 index)
    - fuel_accuracy_audits (1 index)
    - geofence_events (2 indexes)
    - geofences (1 index)
    - gps_validation_logs (1 index)
    - vehicle_locations (1 index)
    - integration_credentials (1 index)
    - integration_health_checks (2 indexes)
    - integration_sandbox_tests (1 index)
    - webhook_configurations (1 index)
    - webhook_delivery_logs (1 index)
    - routes (3 indexes)
    - safety_incident_reports (2 indexes)
    - safety_incidents (2 indexes)
    - sla_agreements (1 index)
    - sla_performance_logs (2 indexes)
    - system_alerts (1 index)
    - user_profiles (1 index)
    - vehicle_inspection_records (2 indexes)
    - vehicles (1 index)

  3. Notes
    - Uses IF EXISTS to prevent errors if indexes don't exist
    - Indexes can be recreated later if needed based on actual query patterns
*/

-- GPS Tracking indexes
DROP INDEX IF EXISTS public.idx_gps_tracking_vehicle_timestamp;
DROP INDEX IF EXISTS public.idx_gps_tracking_timestamp;

-- Driver Onboarding indexes
DROP INDEX IF EXISTS public.idx_driver_onboarding_progress_user_id;

-- Driver Training Completions indexes
DROP INDEX IF EXISTS public.idx_driver_training_completions_organization_id;
DROP INDEX IF EXISTS public.idx_driver_training_completions_training_module_id;
DROP INDEX IF EXISTS public.idx_driver_training_completions_user_id;

-- Drivers indexes
DROP INDEX IF EXISTS public.idx_drivers_user_id;
DROP INDEX IF EXISTS public.idx_drivers_organization_id;

-- Training Modules indexes
DROP INDEX IF EXISTS public.idx_training_modules_organization_id;

-- Document Requirements indexes
DROP INDEX IF EXISTS public.idx_document_requirements_organization_id;

-- Driver Documents indexes
DROP INDEX IF EXISTS public.idx_driver_documents_driver_id;
DROP INDEX IF EXISTS public.idx_driver_documents_user_id;
DROP INDEX IF EXISTS public.idx_driver_documents_document_requirement_id;
DROP INDEX IF EXISTS public.idx_driver_documents_reviewed_by;

-- Security and Audit indexes
DROP INDEX IF EXISTS public.idx_access_control_logs_user_id;
DROP INDEX IF EXISTS public.idx_security_audit_logs_user_id;
DROP INDEX IF EXISTS public.idx_session_tracking_user_id;
DROP INDEX IF EXISTS public.idx_data_encryption_logs_performed_by;

-- AI Model indexes
DROP INDEX IF EXISTS public.idx_ai_model_retraining_logs_trained_by;
DROP INDEX IF EXISTS public.idx_ai_prediction_explanations_prediction_id;

-- API Performance indexes
DROP INDEX IF EXISTS public.idx_api_performance_logs_user_id;
DROP INDEX IF EXISTS public.idx_api_rate_limit_tracking_provider_id;
DROP INDEX IF EXISTS public.idx_app_performance_feedback_user_id;

-- Compliance indexes
DROP INDEX IF EXISTS public.idx_compliance_audits_audited_by;
DROP INDEX IF EXISTS public.idx_compliance_items_organization_id;

-- Driver Location indexes
DROP INDEX IF EXISTS public.idx_driver_locations_organization_id;

-- Driver Training indexes
DROP INDEX IF EXISTS public.idx_driver_training_module_id;
DROP INDEX IF EXISTS public.idx_driver_training_organization_id;

-- Feedback indexes
DROP INDEX IF EXISTS public.idx_feedback_submissions_user_id;
DROP INDEX IF EXISTS public.idx_testimonials_approved_by;
DROP INDEX IF EXISTS public.idx_testimonials_user_id;

-- Fleet Manager Assignment indexes
DROP INDEX IF EXISTS public.idx_fleet_manager_assignments_assigned_by;
DROP INDEX IF EXISTS public.idx_fleet_manager_assignments_driver_id;
DROP INDEX IF EXISTS public.idx_fleet_manager_assignments_user_id;
DROP INDEX IF EXISTS public.idx_fleet_manager_assignments_vehicle_id;

-- Fuel indexes
DROP INDEX IF EXISTS public.idx_fuel_records_organization_id;
DROP INDEX IF EXISTS public.idx_fuel_accuracy_audits_vehicle_id;

-- Geofence indexes
DROP INDEX IF EXISTS public.idx_geofence_events_geofence_id;
DROP INDEX IF EXISTS public.idx_geofence_events_vehicle_id;
DROP INDEX IF EXISTS public.idx_geofences_organization_id;

-- GPS Validation indexes
DROP INDEX IF EXISTS public.idx_gps_validation_logs_vehicle_id;

-- Vehicle Location indexes
DROP INDEX IF EXISTS public.idx_vehicle_locations_organization_id;

-- Integration indexes
DROP INDEX IF EXISTS public.idx_integration_credentials_organization_id;
DROP INDEX IF EXISTS public.idx_integration_health_checks_credential_id;
DROP INDEX IF EXISTS public.idx_integration_health_checks_provider_id;
DROP INDEX IF EXISTS public.idx_integration_sandbox_tests_tested_by;

-- Webhook indexes
DROP INDEX IF EXISTS public.idx_webhook_configurations_provider_id;
DROP INDEX IF EXISTS public.idx_webhook_delivery_logs_provider_id;

-- Routes indexes
DROP INDEX IF EXISTS public.idx_routes_driver_id;
DROP INDEX IF EXISTS public.idx_routes_organization_id;
DROP INDEX IF EXISTS public.idx_routes_vehicle_id;

-- Safety indexes
DROP INDEX IF EXISTS public.idx_safety_incident_reports_reported_by;
DROP INDEX IF EXISTS public.idx_safety_incident_reports_vehicle_id;
DROP INDEX IF EXISTS public.idx_safety_incidents_organization_id;
DROP INDEX IF EXISTS public.idx_safety_incidents_vehicle_id;

-- SLA indexes
DROP INDEX IF EXISTS public.idx_sla_agreements_user_id;
DROP INDEX IF EXISTS public.idx_sla_performance_logs_sla_id;
DROP INDEX IF EXISTS public.idx_sla_performance_logs_user_id;

-- System Alert indexes
DROP INDEX IF EXISTS public.idx_system_alerts_resolved_by;

-- User Profile indexes
DROP INDEX IF EXISTS public.idx_user_profiles_organization_id;

-- Vehicle Inspection indexes
DROP INDEX IF EXISTS public.idx_vehicle_inspection_records_inspector_id;
DROP INDEX IF EXISTS public.idx_vehicle_inspection_records_vehicle_id;

-- Vehicles indexes
DROP INDEX IF EXISTS public.idx_vehicles_organization_id;
