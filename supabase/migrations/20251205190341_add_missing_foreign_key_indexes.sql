/*
  # Add Missing Foreign Key Indexes

  ## Overview
  Adds indexes for all foreign key columns that don't have covering indexes.
  This improves query performance when joining tables and filtering by foreign keys.

  ## Changes
  Creates indexes for 53 foreign key columns across multiple tables:
  - access_control_logs (user_id)
  - ai_model_retraining_logs (trained_by)
  - ai_prediction_explanations (prediction_id)
  - api_performance_logs (user_id)
  - api_rate_limit_tracking (provider_id)
  - app_performance_feedback (user_id)
  - compliance_audits (audited_by)
  - compliance_items (organization_id)
  - data_encryption_logs (performed_by)
  - driver_documents (document_requirement_id, reviewed_by)
  - driver_locations (organization_id)
  - driver_training (module_id, organization_id)
  - drivers (organization_id)
  - feedback_submissions (user_id)
  - fleet_manager_assignments (assigned_by, driver_id, user_id, vehicle_id)
  - fuel_accuracy_audits (vehicle_id)
  - fuel_records (organization_id)
  - geofence_events (geofence_id, vehicle_id)
  - geofences (organization_id)
  - gps_validation_logs (vehicle_id)
  - integration_credentials (organization_id)
  - integration_health_checks (credential_id, provider_id)
  - integration_sandbox_tests (tested_by)
  - routes (driver_id, organization_id, vehicle_id)
  - safety_incident_reports (reported_by, vehicle_id)
  - safety_incidents (organization_id, vehicle_id)
  - security_audit_logs (user_id)
  - session_tracking (user_id)
  - sla_agreements (user_id)
  - sla_performance_logs (sla_id, user_id)
  - system_alerts (resolved_by)
  - testimonials (approved_by, user_id)
  - user_profiles (organization_id)
  - vehicle_inspection_records (inspector_id, vehicle_id)
  - vehicle_locations (organization_id)
  - vehicles (organization_id)
  - webhook_configurations (provider_id)
  - webhook_delivery_logs (provider_id)

  ## Performance Impact
  - Improves JOIN performance
  - Speeds up foreign key constraint checks
  - Optimizes filtering by foreign key columns
*/

-- Access control and security tables
CREATE INDEX IF NOT EXISTS idx_access_control_logs_user_id ON access_control_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_security_audit_logs_user_id ON security_audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_session_tracking_user_id ON session_tracking(user_id);
CREATE INDEX IF NOT EXISTS idx_data_encryption_logs_performed_by ON data_encryption_logs(performed_by);

-- AI and prediction tables
CREATE INDEX IF NOT EXISTS idx_ai_model_retraining_logs_trained_by ON ai_model_retraining_logs(trained_by);
CREATE INDEX IF NOT EXISTS idx_ai_prediction_explanations_prediction_id ON ai_prediction_explanations(prediction_id);

-- API and performance tables
CREATE INDEX IF NOT EXISTS idx_api_performance_logs_user_id ON api_performance_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_api_rate_limit_tracking_provider_id ON api_rate_limit_tracking(provider_id);
CREATE INDEX IF NOT EXISTS idx_app_performance_feedback_user_id ON app_performance_feedback(user_id);

-- Compliance tables
CREATE INDEX IF NOT EXISTS idx_compliance_audits_audited_by ON compliance_audits(audited_by);
CREATE INDEX IF NOT EXISTS idx_compliance_items_organization_id ON compliance_items(organization_id);

-- Driver and onboarding tables
CREATE INDEX IF NOT EXISTS idx_driver_documents_document_requirement_id ON driver_documents(document_requirement_id);
CREATE INDEX IF NOT EXISTS idx_driver_documents_reviewed_by ON driver_documents(reviewed_by);
CREATE INDEX IF NOT EXISTS idx_driver_locations_organization_id ON driver_locations(organization_id);
CREATE INDEX IF NOT EXISTS idx_driver_training_module_id ON driver_training(module_id);
CREATE INDEX IF NOT EXISTS idx_driver_training_organization_id ON driver_training(organization_id);
CREATE INDEX IF NOT EXISTS idx_drivers_organization_id ON drivers(organization_id);

-- Feedback tables
CREATE INDEX IF NOT EXISTS idx_feedback_submissions_user_id ON feedback_submissions(user_id);
CREATE INDEX IF NOT EXISTS idx_testimonials_approved_by ON testimonials(approved_by);
CREATE INDEX IF NOT EXISTS idx_testimonials_user_id ON testimonials(user_id);

-- Fleet manager tables
CREATE INDEX IF NOT EXISTS idx_fleet_manager_assignments_assigned_by ON fleet_manager_assignments(assigned_by);
CREATE INDEX IF NOT EXISTS idx_fleet_manager_assignments_driver_id ON fleet_manager_assignments(driver_id);
CREATE INDEX IF NOT EXISTS idx_fleet_manager_assignments_user_id ON fleet_manager_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_fleet_manager_assignments_vehicle_id ON fleet_manager_assignments(vehicle_id);

-- Fuel tables
CREATE INDEX IF NOT EXISTS idx_fuel_accuracy_audits_vehicle_id ON fuel_accuracy_audits(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_fuel_records_organization_id ON fuel_records(organization_id);

-- Geofence tables
CREATE INDEX IF NOT EXISTS idx_geofence_events_geofence_id ON geofence_events(geofence_id);
CREATE INDEX IF NOT EXISTS idx_geofence_events_vehicle_id ON geofence_events(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_geofences_organization_id ON geofences(organization_id);

-- GPS and tracking tables
CREATE INDEX IF NOT EXISTS idx_gps_validation_logs_vehicle_id ON gps_validation_logs(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_locations_organization_id ON vehicle_locations(organization_id);

-- Integration tables
CREATE INDEX IF NOT EXISTS idx_integration_credentials_organization_id ON integration_credentials(organization_id);
CREATE INDEX IF NOT EXISTS idx_integration_health_checks_credential_id ON integration_health_checks(credential_id);
CREATE INDEX IF NOT EXISTS idx_integration_health_checks_provider_id ON integration_health_checks(provider_id);
CREATE INDEX IF NOT EXISTS idx_integration_sandbox_tests_tested_by ON integration_sandbox_tests(tested_by);
CREATE INDEX IF NOT EXISTS idx_webhook_configurations_provider_id ON webhook_configurations(provider_id);
CREATE INDEX IF NOT EXISTS idx_webhook_delivery_logs_provider_id ON webhook_delivery_logs(provider_id);

-- Route tables
CREATE INDEX IF NOT EXISTS idx_routes_driver_id ON routes(driver_id);
CREATE INDEX IF NOT EXISTS idx_routes_organization_id ON routes(organization_id);
CREATE INDEX IF NOT EXISTS idx_routes_vehicle_id ON routes(vehicle_id);

-- Safety tables
CREATE INDEX IF NOT EXISTS idx_safety_incident_reports_reported_by ON safety_incident_reports(reported_by);
CREATE INDEX IF NOT EXISTS idx_safety_incident_reports_vehicle_id ON safety_incident_reports(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_safety_incidents_organization_id ON safety_incidents(organization_id);
CREATE INDEX IF NOT EXISTS idx_safety_incidents_vehicle_id ON safety_incidents(vehicle_id);

-- SLA tables
CREATE INDEX IF NOT EXISTS idx_sla_agreements_user_id ON sla_agreements(user_id);
CREATE INDEX IF NOT EXISTS idx_sla_performance_logs_sla_id ON sla_performance_logs(sla_id);
CREATE INDEX IF NOT EXISTS idx_sla_performance_logs_user_id ON sla_performance_logs(user_id);

-- System tables
CREATE INDEX IF NOT EXISTS idx_system_alerts_resolved_by ON system_alerts(resolved_by);
CREATE INDEX IF NOT EXISTS idx_user_profiles_organization_id ON user_profiles(organization_id);

-- Vehicle tables
CREATE INDEX IF NOT EXISTS idx_vehicle_inspection_records_inspector_id ON vehicle_inspection_records(inspector_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_inspection_records_vehicle_id ON vehicle_inspection_records(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_organization_id ON vehicles(organization_id);