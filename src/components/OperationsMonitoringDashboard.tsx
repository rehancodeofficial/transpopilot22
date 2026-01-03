import React, { useState, useEffect } from 'react';
import { AlertTriangle, CheckCircle, Activity, Zap, Database, Globe, TrendingUp, AlertCircle } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { triggerHealthCheck } from '../api/monitoring';

interface SystemHealth {
  service_name: string;
  status: 'healthy' | 'degraded' | 'down';
  response_time_ms: number;
  checked_at: string;
}

interface SystemAlert {
  id: string;
  alert_type: string;
  severity: 'critical' | 'high' | 'medium' | 'low';
  service_name: string;
  message: string;
  status: string;
  triggered_at: string;
}

interface UptimeMetric {
  service_name: string;
  uptime_percentage: number;
  average_response_time_ms: number;
}

const OperationsMonitoringDashboard: React.FC = () => {
  const [healthChecks, setHealthChecks] = useState<SystemHealth[]>([]);
  const [alerts, setAlerts] = useState<SystemAlert[]>([]);
  const [uptimeMetrics, setUptimeMetrics] = useState<UptimeMetric[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    triggerHealthCheck();
    loadDashboardData();
    const interval = setInterval(() => {
      triggerHealthCheck();
      loadDashboardData();
    }, 30000);
    return () => clearInterval(interval);
  }, []);

  const loadDashboardData = async () => {
    try {
      const [healthData, alertsData, uptimeData] = await Promise.all([
        supabase
          .from('system_health_checks')
          .select('*')
          .order('checked_at', { ascending: false })
          .limit(10),
        supabase
          .from('system_alerts')
          .select('*')
          .eq('status', 'open')
          .order('triggered_at', { ascending: false }),
        supabase
          .from('system_uptime_metrics')
          .select('*')
          .order('period_start', { ascending: false })
          .limit(5)
      ]);

      if (healthData.data) setHealthChecks(healthData.data);
      if (alertsData.data) setAlerts(alertsData.data);
      if (uptimeData.data) setUptimeMetrics(uptimeData.data);
      setLoading(false);
    } catch (error) {
      console.error('Error loading dashboard data:', error);
      setLoading(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'healthy': return 'text-green-600 bg-green-100';
      case 'degraded': return 'text-yellow-600 bg-yellow-100';
      case 'down': return 'text-red-600 bg-red-100';
      default: return 'text-gray-600 bg-gray-100';
    }
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return 'text-red-600 bg-red-100 border-red-300';
      case 'high': return 'text-orange-600 bg-orange-100 border-orange-300';
      case 'medium': return 'text-yellow-600 bg-yellow-100 border-yellow-300';
      case 'low': return 'text-blue-600 bg-blue-100 border-blue-300';
      default: return 'text-gray-600 bg-gray-100 border-gray-300';
    }
  };

  const resolveAlert = async (alertId: string) => {
    try {
      await supabase
        .from('system_alerts')
        .update({
          status: 'resolved',
          resolved_at: new Date().toISOString(),
          resolved_by: (await supabase.auth.getUser()).data.user?.id
        })
        .eq('id', alertId);

      loadDashboardData();
    } catch (error) {
      console.error('Error resolving alert:', error);
    }
  };

  const overallStatus = healthChecks.length > 0
    ? healthChecks.every(h => h.status === 'healthy')
      ? 'All Systems Operational'
      : healthChecks.some(h => h.status === 'down')
      ? 'Systems Down'
      : 'Degraded Performance'
    : 'Checking Systems...';

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Operations Monitoring Dashboard</h1>
          <p className="text-gray-600 mt-2">Real-time system health and performance monitoring</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">System Status</p>
                <p className="text-2xl font-bold text-gray-900 mt-1">{overallStatus}</p>
              </div>
              <Activity className="h-8 w-8 text-blue-600" />
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Active Alerts</p>
                <p className="text-2xl font-bold text-gray-900 mt-1">{alerts.length}</p>
              </div>
              <AlertTriangle className={`h-8 w-8 ${alerts.length > 0 ? 'text-red-600' : 'text-green-600'}`} />
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Average Uptime</p>
                <p className="text-2xl font-bold text-gray-900 mt-1">
                  {uptimeMetrics.length > 0
                    ? `${(uptimeMetrics.reduce((sum, m) => sum + m.uptime_percentage, 0) / uptimeMetrics.length).toFixed(2)}%`
                    : 'N/A'}
                </p>
              </div>
              <TrendingUp className="h-8 w-8 text-green-600" />
            </div>
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Avg Response Time</p>
                <p className="text-2xl font-bold text-gray-900 mt-1">
                  {uptimeMetrics.length > 0
                    ? `${Math.round(uptimeMetrics.reduce((sum, m) => sum + m.average_response_time_ms, 0) / uptimeMetrics.length)}ms`
                    : 'N/A'}
                </p>
              </div>
              <Zap className="h-8 w-8 text-yellow-600" />
            </div>
          </div>
        </div>

        {alerts.length > 0 && (
          <div className="bg-white rounded-lg shadow mb-8">
            <div className="p-6 border-b border-gray-200">
              <h2 className="text-xl font-bold text-gray-900">Active Alerts</h2>
            </div>
            <div className="p-6">
              <div className="space-y-4">
                {alerts.map((alert) => (
                  <div
                    key={alert.id}
                    className={`p-4 rounded-lg border ${getSeverityColor(alert.severity)}`}
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <AlertCircle className="h-5 w-5" />
                          <span className="font-semibold">{alert.service_name}</span>
                          <span className="text-xs px-2 py-1 rounded bg-white">{alert.alert_type}</span>
                        </div>
                        <p className="text-sm mb-2">{alert.message}</p>
                        <p className="text-xs opacity-75">
                          Triggered: {new Date(alert.triggered_at).toLocaleString()}
                        </p>
                      </div>
                      <button
                        onClick={() => resolveAlert(alert.id)}
                        className="ml-4 px-4 py-2 bg-white text-gray-700 rounded hover:bg-gray-50 text-sm font-medium"
                      >
                        Resolve
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        <div className="bg-white rounded-lg shadow mb-8">
          <div className="p-6 border-b border-gray-200">
            <h2 className="text-xl font-bold text-gray-900">Service Health Status</h2>
          </div>
          <div className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {healthChecks.map((check, index) => (
                <div key={index} className="border rounded-lg p-4">
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-2">
                      {check.service_name.includes('database') ? (
                        <Database className="h-5 w-5 text-gray-600" />
                      ) : (
                        <Globe className="h-5 w-5 text-gray-600" />
                      )}
                      <span className="font-semibold text-gray-900">{check.service_name}</span>
                    </div>
                    <CheckCircle className={`h-5 w-5 ${check.status === 'healthy' ? 'text-green-600' : 'text-red-600'}`} />
                  </div>
                  <div className="space-y-2">
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-600">Status:</span>
                      <span className={`px-2 py-1 rounded text-xs font-medium ${getStatusColor(check.status)}`}>
                        {check.status}
                      </span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-600">Response Time:</span>
                      <span className="font-medium">{check.response_time_ms}ms</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-600">Last Checked:</span>
                      <span className="text-xs">{new Date(check.checked_at).toLocaleTimeString()}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow">
          <div className="p-6 border-b border-gray-200">
            <h2 className="text-xl font-bold text-gray-900">Uptime Metrics</h2>
          </div>
          <div className="p-6">
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead>
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Service</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Uptime %</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Avg Response</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {uptimeMetrics.map((metric, index) => (
                    <tr key={index}>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        {metric.service_name}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {metric.uptime_percentage.toFixed(2)}%
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {metric.average_response_time_ms}ms
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 rounded text-xs font-medium ${
                          metric.uptime_percentage >= 99.5 ? 'text-green-600 bg-green-100' : 'text-yellow-600 bg-yellow-100'
                        }`}>
                          {metric.uptime_percentage >= 99.5 ? 'Excellent' : 'Good'}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default OperationsMonitoringDashboard;
