/*
  # Add Uptime Calculation Function

  1. New Functions
    - `calculate_uptime_metrics()` - Calculates uptime metrics from health checks
      - Runs hourly to aggregate health check data
      - Computes uptime percentage, avg response time
      - Creates entries in system_uptime_metrics table
  
  2. Changes
    - Creates a function to automate uptime metric generation
    - Can be called manually or scheduled via cron job
*/

-- Function to calculate and store uptime metrics
CREATE OR REPLACE FUNCTION calculate_uptime_metrics()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  service_record RECORD;
  period_start_time timestamptz;
  period_end_time timestamptz;
BEGIN
  -- Set time period to last hour
  period_end_time := now();
  period_start_time := now() - interval '1 hour';

  -- Get all unique services that have health checks
  FOR service_record IN
    SELECT DISTINCT service_name
    FROM system_health_checks
    WHERE checked_at >= period_start_time
  LOOP
    -- Calculate metrics for this service
    INSERT INTO system_uptime_metrics (
      service_name,
      uptime_percentage,
      total_checks,
      successful_checks,
      failed_checks,
      average_response_time_ms,
      period_start,
      period_end
    )
    SELECT
      service_record.service_name,
      ROUND(
        (COUNT(*) FILTER (WHERE status = 'healthy')::numeric / COUNT(*)::numeric * 100),
        2
      ) as uptime_percentage,
      COUNT(*) as total_checks,
      COUNT(*) FILTER (WHERE status = 'healthy') as successful_checks,
      COUNT(*) FILTER (WHERE status IN ('degraded', 'down')) as failed_checks,
      ROUND(AVG(response_time_ms)) as average_response_time_ms,
      period_start_time,
      period_end_time
    FROM system_health_checks
    WHERE service_name = service_record.service_name
      AND checked_at >= period_start_time
      AND checked_at <= period_end_time;
  END LOOP;
END;
$$;
