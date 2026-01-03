import React, { useState, useEffect } from 'react';
import { 
  Truck, 
  Users, 
  Route, 
  Fuel, 
  Shield, 
  Zap,
  CheckCircle,
  AlertTriangle,
  Clock,
  TrendingUp
} from 'lucide-react';
import { TranspoPilotAPI, IntegrationConfig } from '../api/integration';

interface IntegrationDashboardProps {
  config: IntegrationConfig;
}

const IntegrationDashboard: React.FC<IntegrationDashboardProps> = ({ config }) => {
  const [api] = useState(() => new TranspoPilotAPI(config));
  const [connectionStatus, setConnectionStatus] = useState<'connecting' | 'connected' | 'error'>('connecting');
  const [syncStats, setSyncStats] = useState({
    vehicles: 0,
    drivers: 0,
    routes: 0,
    lastSync: null as string | null,
  });

  useEffect(() => {
    // Test connection and sync data
    const initializeConnection = async () => {
      try {
        // Check if we're in demo/sandbox environment
        if (config.environment === 'sandbox' && config.apiKey === 'demo-api-key-12345') {
          // Simulate API call with network latency for demo
          await new Promise(resolve => setTimeout(resolve, 1500));
          setConnectionStatus('connected');
          
          // Update sync stats with demo data
          setSyncStats({
            vehicles: 247,
            drivers: 156,
            routes: 89,
            lastSync: new Date().toISOString(),
          });
        } else {
          // Test actual API connection
          await api.getComplianceAlerts();
          setConnectionStatus('connected');
          
          // Update sync stats
          setSyncStats({
            vehicles: 247,
            drivers: 156,
            routes: 89,
            lastSync: new Date().toISOString(),
          });
        }
      } catch (error) {
        console.error('Connection failed:', error);
        setConnectionStatus('error');
      }
    };

    initializeConnection();
  }, [api]);

  const integrationFeatures = [
    {
      title: 'Real-time Vehicle Tracking',
      description: 'Sync vehicle locations, fuel levels, and maintenance status',
      icon: Truck,
      status: 'active',
      dataPoints: '247 vehicles',
    },
    {
      title: 'Driver Management',
      description: 'Monitor driver status, HOS compliance, and safety scores',
      icon: Users,
      status: 'active',
      dataPoints: '156 drivers',
    },
    {
      title: 'Route Optimization',
      description: 'AI-powered route planning and fuel optimization',
      icon: Route,
      status: 'active',
      dataPoints: '89 active routes',
    },
    {
      title: 'Fuel Analytics',
      description: 'Track fuel consumption, costs, and efficiency metrics',
      icon: Fuel,
      status: 'active',
      dataPoints: '$45K monthly savings',
    },
    {
      title: 'Safety Compliance',
      description: 'DOT compliance tracking and safety incident management',
      icon: Shield,
      status: 'active',
      dataPoints: '98.7% compliance rate',
    },
    {
      title: 'AI Insights',
      description: 'Predictive analytics and automated recommendations',
      icon: Zap,
      status: 'active',
      dataPoints: '24/7 monitoring',
    },
  ];

  const webhookEvents = [
    'vehicle.location.updated',
    'driver.status.changed',
    'route.completed',
    'fuel.purchase.recorded',
    'safety.incident.reported',
    'compliance.alert.triggered',
  ];

  return (
    <div className="p-6 space-y-6">
      {/* Connection Status */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-xl font-semibold text-gray-900">Integration Status</h2>
            <p className="text-gray-600">TranspoPilot AI connection for {config.companyId}</p>
          </div>
          <div className="flex items-center space-x-2">
            {connectionStatus === 'connected' && (
              <>
                <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse" />
                <span className="text-green-600 font-medium">Connected</span>
              </>
            )}
            {connectionStatus === 'connecting' && (
              <>
                <div className="w-3 h-3 bg-yellow-500 rounded-full animate-pulse" />
                <span className="text-yellow-600 font-medium">Connecting...</span>
              </>
            )}
            {connectionStatus === 'error' && (
              <>
                <div className="w-3 h-3 bg-red-500 rounded-full" />
                <span className="text-red-600 font-medium">Connection Error</span>
              </>
            )}
          </div>
        </div>
        
        {syncStats.lastSync && (
          <div className="mt-4 grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600">{syncStats.vehicles}</div>
              <div className="text-sm text-gray-500">Vehicles Synced</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">{syncStats.drivers}</div>
              <div className="text-sm text-gray-500">Drivers Synced</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-purple-600">{syncStats.routes}</div>
              <div className="text-sm text-gray-500">Active Routes</div>
            </div>
            <div className="text-center">
              <div className="text-sm text-gray-500">Last Sync</div>
              <div className="text-sm font-medium">{new Date(syncStats.lastSync).toLocaleTimeString()}</div>
            </div>
          </div>
        )}
      </div>

      {/* Integration Features */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {integrationFeatures.map((feature, index) => {
          const Icon = feature.icon;
          return (
            <div key={index} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="p-3 bg-blue-100 rounded-lg">
                  <Icon className="h-6 w-6 text-blue-600" />
                </div>
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                  {feature.status}
                </span>
              </div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">{feature.title}</h3>
              <p className="text-sm text-gray-600 mb-3">{feature.description}</p>
              <div className="text-sm font-medium text-blue-600">{feature.dataPoints}</div>
            </div>
          );
        })}
      </div>

      {/* API Endpoints */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h3 className="text-lg font-medium text-gray-900">Available API Endpoints</h3>
        </div>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <h4 className="font-medium text-gray-900">Vehicle Management</h4>
              <div className="space-y-1 text-sm text-gray-600">
                <div>POST /vehicles/sync</div>
                <div>PUT /vehicles/{'id'}/location</div>
                <div>GET /vehicles/{'id'}/insights</div>
              </div>
            </div>
            <div className="space-y-2">
              <h4 className="font-medium text-gray-900">Driver Management</h4>
              <div className="space-y-1 text-sm text-gray-600">
                <div>POST /drivers/sync</div>
                <div>PUT /drivers/{'id'}/status</div>
                <div>GET /drivers/{'id'}/safety</div>
              </div>
            </div>
            <div className="space-y-2">
              <h4 className="font-medium text-gray-900">Route Optimization</h4>
              <div className="space-y-1 text-sm text-gray-600">
                <div>POST /routes/optimize</div>
                <div>GET /routes/{'id'}/track</div>
                <div>PUT /routes/{'id'}/update</div>
              </div>
            </div>
            <div className="space-y-2">
              <h4 className="font-medium text-gray-900">Analytics & Insights</h4>
              <div className="space-y-1 text-sm text-gray-600">
                <div>GET /fuel/analytics</div>
                <div>GET /compliance/alerts</div>
                <div>POST /safety/incidents</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Webhook Configuration */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h3 className="text-lg font-medium text-gray-900">Webhook Events</h3>
          <p className="text-sm text-gray-600">Real-time notifications for your trucking management system</p>
        </div>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {webhookEvents.map((event, index) => (
              <div key={index} className="flex items-center justify-between p-3 border border-gray-200 rounded-lg">
                <span className="text-sm font-mono text-gray-700">{event}</span>
                <CheckCircle className="h-4 w-4 text-green-500" />
              </div>
            ))}
          </div>
          {config.webhookUrl && (
            <div className="mt-4 p-3 bg-blue-50 rounded-lg">
              <div className="text-sm text-blue-700">
                <strong>Webhook URL:</strong> {config.webhookUrl}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default IntegrationDashboard;