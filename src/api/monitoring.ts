import { supabase } from '../lib/supabase';

let isLogging = false;
let isAuthenticated = false;

// Queue to store logs when user is not authenticated yet
let logQueue: Array<any> = [];

// Mark user as authenticated (called after successful login)
export function markUserAuthenticated() {
  isAuthenticated = true;
  // Process queued logs
  if (logQueue.length > 0) {
    console.log(`Processing ${logQueue.length} queued logs...`);
    logQueue.forEach(logEntry => {
      logApiPerformanceInternal(logEntry).catch(err => {
        console.debug('Failed to log queued entry:', err);
      });
    });
    logQueue = [];
  }
}

async function logApiPerformanceInternal(entry: any): Promise<void> {
  try {
    await supabase.from('api_performance_logs').insert(entry);
  } catch (error) {
    console.debug('Failed to log API performance:', error);
  }
}

export async function logApiPerformance(
  endpoint: string,
  method: string,
  statusCode: number,
  responseTimeMs: number,
  errorMessage?: string,
  requestSizeBytes?: number,
  responseSizeBytes?: number
): Promise<void> {
  if (isLogging) return;

  try {
    isLogging = true;

    let userId: string | null = null;
    try {
      const sessionStr = sessionStorage.getItem('supabase.auth.token');
      if (sessionStr) {
        const session = JSON.parse(sessionStr);
        userId = session?.currentSession?.user?.id || null;
      }
    } catch {
      userId = null;
    }

    const logEntry = {
      endpoint,
      method,
      status_code: statusCode,
      response_time_ms: responseTimeMs,
      user_id: userId,
      error_message: errorMessage || null,
      request_size_bytes: requestSizeBytes || null,
      response_size_bytes: responseSizeBytes || null,
    };

    // If not authenticated yet, queue the log for later
    if (!isAuthenticated) {
      if (logQueue.length < 100) { // Limit queue size
        logQueue.push(logEntry);
      }
      return;
    }

    // Otherwise, log immediately
    await logApiPerformanceInternal(logEntry);
  } catch (error) {
    console.debug('Failed to log API performance:', error);
  } finally {
    isLogging = false;
  }
}

export async function createHealthCheck(
  serviceName: string,
  checkType: 'api' | 'database' | 'integration' | 'external_service' | 'ai_model',
  status: 'healthy' | 'degraded' | 'down',
  responseTimeMs: number,
  errorMessage?: string,
  metadata?: Record<string, any>
): Promise<void> {
  try {
    await supabase.from('system_health_checks').insert({
      service_name: serviceName,
      check_type: checkType,
      status,
      response_time_ms: responseTimeMs,
      error_message: errorMessage || null,
      metadata: metadata || {},
      checked_at: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Failed to create health check:', error);
  }
}

export async function createSystemAlert(
  alertType: 'performance' | 'error' | 'security' | 'data_quality' | 'compliance' | 'integration',
  severity: 'critical' | 'high' | 'medium' | 'low',
  serviceName: string,
  message: string,
  details?: Record<string, any>
): Promise<void> {
  try {
    await supabase.from('system_alerts').insert({
      alert_type: alertType,
      severity,
      service_name: serviceName,
      message,
      details: details || {},
      status: 'open',
      triggered_at: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Failed to create system alert:', error);
  }
}

export async function triggerHealthCheck(): Promise<void> {
  try {
    const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
    const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

    await fetch(
      `${supabaseUrl}/functions/v1/system-health-monitor?action=check`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${supabaseKey}`,
          'Content-Type': 'application/json',
        },
      }
    );
  } catch (error) {
    console.error('Failed to trigger health check:', error);
  }
}

// Store original fetch for restoration if needed
let originalFetch: typeof window.fetch | null = null;
let interceptorEnabled = false;

export function createApiInterceptor() {
  // Check if monitoring is disabled via environment variable
  const monitoringDisabled = import.meta.env.VITE_DISABLE_API_MONITORING === 'true';

  if (monitoringDisabled) {
    console.log('API monitoring disabled via environment variable');
    return;
  }

  // Don't initialize twice
  if (interceptorEnabled) {
    console.log('API interceptor already enabled');
    return;
  }

  try {
    originalFetch = window.fetch;
    interceptorEnabled = true;

    window.fetch = async (...args) => {
      const [url, options] = args;
      const startTime = Date.now();
      const method = options?.method || 'GET';

      let endpoint = '';
      let urlString = '';

      if (typeof url === 'string') {
        urlString = url;
        try {
          const urlObj = new URL(url);
          endpoint = urlObj.pathname;
        } catch {
          endpoint = url;
        }
      }

      // Comprehensive auth request detection
      // CRITICAL: Do NOT intercept any auth-related requests to prevent interference
      const isAuthRequest =
        endpoint.includes('/auth/v1/') ||
        urlString.includes('/auth/v1/') ||
        endpoint.includes('token?') ||
        endpoint.includes('signup') ||
        endpoint.includes('signin') ||
        endpoint.includes('user') && endpoint.includes('auth') ||
        urlString.includes('grant_type=') ||
        // Storage requests that auth depends on
        endpoint.includes('/storage/v1/') ||
        // Realtime/subscription requests
        endpoint.includes('/realtime/v1/') ||
        // Skip browser extension requests
        urlString.startsWith('chrome-extension://') ||
        urlString.startsWith('moz-extension://');

      // Always pass through auth requests without any modification
      if (isAuthRequest) {
        try {
          return await originalFetch!(...args);
        } catch (error) {
          // Don't interfere with auth errors - pass them through directly
          throw error;
        }
      }

      // For non-auth requests, try to log but NEVER let logging break the request
      try {
        const response = await originalFetch!(...args);
        const duration = Date.now() - startTime;

        // Only log Supabase API calls (not auth)
        const shouldLog =
          (endpoint.includes('/rest/v1/') || endpoint.includes('/functions/v1/')) &&
          !isAuthRequest;

        if (shouldLog) {
          // Fire and forget - don't await, don't let it block
          logApiPerformance(
            endpoint,
            method,
            response.status,
            duration,
            undefined,
            options?.body ? JSON.stringify(options.body).length : undefined
          ).catch(() => {
            // Silently ignore logging errors
          });
        }

        return response;
      } catch (error) {
        const duration = Date.now() - startTime;

        // Try to log the error, but don't let it interfere
        logApiPerformance(
          endpoint,
          method,
          0,
          duration,
          error instanceof Error ? error.message : 'Unknown error'
        ).catch(() => {
          // Silently ignore logging errors
        });

        // Always rethrow the original error
        throw error;
      }
    };

    console.log('API interceptor enabled (auth requests excluded)');
  } catch (error) {
    console.error('Failed to initialize API interceptor:', error);
    // Restore original fetch if initialization fails
    if (originalFetch) {
      window.fetch = originalFetch;
      interceptorEnabled = false;
    }
  }
}

// Utility function to disable the interceptor (for debugging)
export function disableApiInterceptor() {
  if (originalFetch && interceptorEnabled) {
    window.fetch = originalFetch;
    interceptorEnabled = false;
    console.log('API interceptor disabled');
  }
}

// Utility function to check if interceptor is active
export function isInterceptorEnabled(): boolean {
  return interceptorEnabled;
}
