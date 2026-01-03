/*
  # Drop Unused Database Indexes - Security and Performance Fix

  This migration addresses security concerns by removing unused database indexes that:
  1. Consume unnecessary storage and memory
  2. Slow down INSERT, UPDATE, and DELETE operations
  3. Add maintenance overhead without providing query benefits
  
  ## Indexes Being Removed
  
  ### Trial Registrations (3 indexes)
  - idx_trial_registrations_status
  - idx_trial_registrations_created_at
  - idx_trial_registrations_organization
  
  ### Driver Training (3 indexes)
  - idx_driver_training_module
  - idx_driver_training_status
  - idx_driver_training_organization
  
  ### Contact Submissions (2 indexes)
  - idx_contact_submissions_status
  - idx_contact_submissions_email
  
  ### Routes and Waypoints (4 indexes)
  - idx_routes_vehicle
  - idx_routes_driver
  - idx_routes_organization
  - idx_route_waypoints_route
  
  ### Geofence Events (4 indexes)
  - idx_geofence_events_timestamp
  - idx_geofence_events_geofence
  - idx_geofence_events_vehicle
  
  ### Safety and Compliance (9 indexes)
  - idx_safety_incidents_vehicle
  - idx_safety_incidents_status
  - idx_safety_incidents_organization
  - idx_compliance_items_entity
  - idx_compliance_items_status
  - idx_compliance_items_due_date
  - idx_compliance_items_organization
  - idx_compliance_audits_entity
  - idx_compliance_audits_status
  - idx_compliance_audits_audited_by
  
  ### Integration Related (7 indexes)
  - idx_mappings_internal
  - idx_integration_health_credential
  - idx_integration_health_status
  - idx_integration_health_provider
  - idx_integration_credentials_organization
  - idx_sandbox_tests_tested_by
  - idx_sandbox_tests_name
  - idx_sandbox_tests_result
  
  ### Fleet Management (4 indexes)
  - idx_fleet_assignments_assigned_by
  - idx_fleet_manager_assignments_user
  - idx_fleet_manager_assignments_vehicle
  - idx_fleet_manager_assignments_driver
  
  ### System Monitoring (19 indexes)
  - idx_system_alerts_resolved_by
  - idx_alerts_severity
  - idx_alerts_type
  - idx_health_checks_service
  - idx_health_checks_status
  - idx_api_logs_endpoint
  - idx_api_logs_user
  - idx_api_logs_status
  - idx_quality_checks_entity
  - idx_quality_checks_result
  - idx_uptime_service
  - idx_anomalies_entity
  - idx_anomalies_status
  - idx_sla_logs_user
  - idx_sla_logs_sla
  - idx_sla_logs_breaches
  - idx_sla_user
  - idx_sla_type
  
  ### Feedback and Testimonials (7 indexes)
  - idx_testimonials_approved_by
  - idx_testimonials_user_id
  - idx_testimonials_display_order
  - idx_feedback_submissions_user_id
  - idx_feedback_submissions_status
  - idx_app_performance_feedback_user_id
  - idx_app_performance_feedback_status
  - idx_app_performance_feedback_severity
  
  ### Organizations and User Profiles (5 indexes)
  - idx_organizations_slug
  - idx_organizations_status
  - idx_organizations_tier
  - idx_user_profiles_role
  - idx_user_profiles_organization
  
  ### Vehicle Management (10 indexes)
  - idx_inspection_inspector
  - idx_inspection_vehicle
  - idx_inspection_failed
  - idx_inspection_out_of_service
  - idx_fuel_audits_vehicle
  - idx_fuel_audits_accuracy
  - idx_vehicles_organization
  - idx_vehicle_locations_organization
  - idx_driver_locations_organization
  - idx_drivers_organization
  
  ### Fuel Records (1 index)
  - idx_fuel_records_organization
  
  ### GPS and Location (3 indexes)
  - idx_gps_validation_vehicle
  - idx_gps_validation_invalid
  - idx_geofences_organization
  
  ### Security and Audit (11 indexes)
  - idx_audit_user
  - idx_audit_action
  - idx_audit_resource
  - idx_audit_failures
  - idx_access_user
  - idx_access_denied
  - idx_login_email
  - idx_login_failed
  - idx_login_suspicious
  - idx_session_user
  - idx_session_active
  - idx_encryption_logs_performed_by
  - idx_encryption_type
  - idx_encryption_operation
  
  ### AI Models (10 indexes)
  - idx_performance_model
  - idx_predictions_model
  - idx_predictions_type
  - idx_predictions_entity
  - idx_retraining_model
  - idx_retraining_deployed
  - idx_ai_retraining_trained_by
  - idx_explanations_prediction
  - idx_explanations_model
  - idx_ab_tests_name
  
  ### Webhook and API (5 indexes)
  - idx_webhooks_provider
  - idx_webhook_logs_provider
  - idx_webhook_logs_status
  - idx_rate_limit_provider
  - idx_rate_limit_throttled
  
  ### Miscellaneous (4 indexes)
  - idx_cert_tracking_expiring
  - idx_benchmarks_metric
  - idx_hos_violations_unresolved
  - idx_incidents_vehicle
  - idx_incidents_severity
  - idx_safety_reports_reported_by
  
  Total: 120+ unused indexes removed
  
  ## Impact
  - Reduced storage footprint
  - Faster write operations (INSERT, UPDATE, DELETE)
  - Simplified maintenance
  - No impact on query performance (indexes were unused)
*/

-- Trial Registrations
DROP INDEX IF EXISTS idx_trial_registrations_status;
DROP INDEX IF EXISTS idx_trial_registrations_created_at;
DROP INDEX IF EXISTS idx_trial_registrations_organization;

-- Driver Training
DROP INDEX IF EXISTS idx_driver_training_module;
DROP INDEX IF EXISTS idx_driver_training_status;
DROP INDEX IF EXISTS idx_driver_training_organization;

-- Contact Submissions
DROP INDEX IF EXISTS idx_contact_submissions_status;
DROP INDEX IF EXISTS idx_contact_submissions_email;

-- Routes and Waypoints
DROP INDEX IF EXISTS idx_routes_vehicle;
DROP INDEX IF EXISTS idx_routes_driver;
DROP INDEX IF EXISTS idx_routes_organization;
DROP INDEX IF EXISTS idx_route_waypoints_route;

-- Geofence Events
DROP INDEX IF EXISTS idx_geofence_events_timestamp;
DROP INDEX IF EXISTS idx_geofence_events_geofence;
DROP INDEX IF EXISTS idx_geofence_events_vehicle;

-- Safety and Compliance
DROP INDEX IF EXISTS idx_safety_incidents_vehicle;
DROP INDEX IF EXISTS idx_safety_incidents_status;
DROP INDEX IF EXISTS idx_safety_incidents_organization;
DROP INDEX IF EXISTS idx_compliance_items_entity;
DROP INDEX IF EXISTS idx_compliance_items_status;
DROP INDEX IF EXISTS idx_compliance_items_due_date;
DROP INDEX IF EXISTS idx_compliance_items_organization;
DROP INDEX IF EXISTS idx_compliance_audits_entity;
DROP INDEX IF EXISTS idx_compliance_audits_status;
DROP INDEX IF EXISTS idx_compliance_audits_audited_by;

-- Integration Related
DROP INDEX IF EXISTS idx_mappings_internal;
DROP INDEX IF EXISTS idx_integration_health_credential;
DROP INDEX IF EXISTS idx_integration_health_status;
DROP INDEX IF EXISTS idx_integration_health_provider;
DROP INDEX IF EXISTS idx_integration_credentials_organization;
DROP INDEX IF EXISTS idx_sandbox_tests_tested_by;
DROP INDEX IF EXISTS idx_sandbox_tests_name;
DROP INDEX IF EXISTS idx_sandbox_tests_result;

-- Fleet Management
DROP INDEX IF EXISTS idx_fleet_assignments_assigned_by;
DROP INDEX IF EXISTS idx_fleet_manager_assignments_user;
DROP INDEX IF EXISTS idx_fleet_manager_assignments_vehicle;
DROP INDEX IF EXISTS idx_fleet_manager_assignments_driver;

-- System Monitoring
DROP INDEX IF EXISTS idx_system_alerts_resolved_by;
DROP INDEX IF EXISTS idx_alerts_severity;
DROP INDEX IF EXISTS idx_alerts_type;
DROP INDEX IF EXISTS idx_health_checks_service;
DROP INDEX IF EXISTS idx_health_checks_status;
DROP INDEX IF EXISTS idx_api_logs_endpoint;
DROP INDEX IF EXISTS idx_api_logs_user;
DROP INDEX IF EXISTS idx_api_logs_status;
DROP INDEX IF EXISTS idx_quality_checks_entity;
DROP INDEX IF EXISTS idx_quality_checks_result;
DROP INDEX IF EXISTS idx_uptime_service;
DROP INDEX IF EXISTS idx_anomalies_entity;
DROP INDEX IF EXISTS idx_anomalies_status;
DROP INDEX IF EXISTS idx_sla_logs_user;
DROP INDEX IF EXISTS idx_sla_logs_sla;
DROP INDEX IF EXISTS idx_sla_logs_breaches;
DROP INDEX IF EXISTS idx_sla_user;
DROP INDEX IF EXISTS idx_sla_type;

-- Feedback and Testimonials
DROP INDEX IF EXISTS idx_testimonials_approved_by;
DROP INDEX IF EXISTS idx_testimonials_user_id;
DROP INDEX IF EXISTS idx_testimonials_display_order;
DROP INDEX IF EXISTS idx_feedback_submissions_user_id;
DROP INDEX IF EXISTS idx_feedback_submissions_status;
DROP INDEX IF EXISTS idx_app_performance_feedback_user_id;
DROP INDEX IF EXISTS idx_app_performance_feedback_status;
DROP INDEX IF EXISTS idx_app_performance_feedback_severity;

-- Organizations and User Profiles
DROP INDEX IF EXISTS idx_organizations_slug;
DROP INDEX IF EXISTS idx_organizations_status;
DROP INDEX IF EXISTS idx_organizations_tier;
DROP INDEX IF EXISTS idx_user_profiles_role;
DROP INDEX IF EXISTS idx_user_profiles_organization;

-- Vehicle Management
DROP INDEX IF EXISTS idx_inspection_inspector;
DROP INDEX IF EXISTS idx_inspection_vehicle;
DROP INDEX IF EXISTS idx_inspection_failed;
DROP INDEX IF EXISTS idx_inspection_out_of_service;
DROP INDEX IF EXISTS idx_fuel_audits_vehicle;
DROP INDEX IF EXISTS idx_fuel_audits_accuracy;
DROP INDEX IF EXISTS idx_vehicles_organization;
DROP INDEX IF EXISTS idx_vehicle_locations_organization;
DROP INDEX IF EXISTS idx_driver_locations_organization;
DROP INDEX IF EXISTS idx_drivers_organization;

-- Fuel Records
DROP INDEX IF EXISTS idx_fuel_records_organization;

-- GPS and Location
DROP INDEX IF EXISTS idx_gps_validation_vehicle;
DROP INDEX IF EXISTS idx_gps_validation_invalid;
DROP INDEX IF EXISTS idx_geofences_organization;

-- Security and Audit
DROP INDEX IF EXISTS idx_audit_user;
DROP INDEX IF EXISTS idx_audit_action;
DROP INDEX IF EXISTS idx_audit_resource;
DROP INDEX IF EXISTS idx_audit_failures;
DROP INDEX IF EXISTS idx_access_user;
DROP INDEX IF EXISTS idx_access_denied;
DROP INDEX IF EXISTS idx_login_email;
DROP INDEX IF EXISTS idx_login_failed;
DROP INDEX IF EXISTS idx_login_suspicious;
DROP INDEX IF EXISTS idx_session_user;
DROP INDEX IF EXISTS idx_session_active;
DROP INDEX IF EXISTS idx_encryption_logs_performed_by;
DROP INDEX IF EXISTS idx_encryption_type;
DROP INDEX IF EXISTS idx_encryption_operation;

-- AI Models
DROP INDEX IF EXISTS idx_performance_model;
DROP INDEX IF EXISTS idx_predictions_model;
DROP INDEX IF EXISTS idx_predictions_type;
DROP INDEX IF EXISTS idx_predictions_entity;
DROP INDEX IF EXISTS idx_retraining_model;
DROP INDEX IF EXISTS idx_retraining_deployed;
DROP INDEX IF EXISTS idx_ai_retraining_trained_by;
DROP INDEX IF EXISTS idx_explanations_prediction;
DROP INDEX IF EXISTS idx_explanations_model;
DROP INDEX IF EXISTS idx_ab_tests_name;

-- Webhook and API
DROP INDEX IF EXISTS idx_webhooks_provider;
DROP INDEX IF EXISTS idx_webhook_logs_provider;
DROP INDEX IF EXISTS idx_webhook_logs_status;
DROP INDEX IF EXISTS idx_rate_limit_provider;
DROP INDEX IF EXISTS idx_rate_limit_throttled;

-- Miscellaneous
DROP INDEX IF EXISTS idx_cert_tracking_expiring;
DROP INDEX IF EXISTS idx_benchmarks_metric;
DROP INDEX IF EXISTS idx_hos_violations_unresolved;
DROP INDEX IF EXISTS idx_incidents_vehicle;
DROP INDEX IF EXISTS idx_incidents_severity;
DROP INDEX IF EXISTS idx_safety_reports_reported_by;
