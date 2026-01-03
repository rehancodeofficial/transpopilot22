import React, { useState, useEffect } from 'react';
import {
  Plug,
  CheckCircle,
  XCircle,
  Settings,
  RefreshCw,
  Zap,
  Activity,
  Clock,
  Database,
  Key,
  Save,
  TestTube,
  AlertTriangle,
  Network,
  Link,
  ShieldAlert,
} from 'lucide-react';
import {
  getIntegrationProviders,
  getIntegrationCredentials,
  upsertIntegrationCredentials,
  updateIntegrationProvider,
  getIntegrationSyncLogs,
  testIntegrationConnection,
  triggerSync,
  activateMonitoring,
} from '../api/integrations';
import { IntegrationProvider, IntegrationCredentials, IntegrationSyncLog } from '../types/tracking';
import { useAuth } from '../contexts/AuthContext';

const IntegrationsPage: React.FC = () => {
  const { isAdmin } = useAuth();
  const [activeTab, setActiveTab] = useState<'geotab' | 'samsara' | 'motive' | 'all-fleets'>('geotab');
  const [providers, setProviders] = useState<IntegrationProvider[]>([]);
  const [selectedProvider, setSelectedProvider] = useState<IntegrationProvider | null>(null);
  const [credentials, setCredentials] = useState<Partial<IntegrationCredentials>>({});
  const [syncLogs, setSyncLogs] = useState<IntegrationSyncLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [testing, setTesting] = useState(false);
  const [testResult, setTestResult] = useState<{ success: boolean; message: string } | null>(null);
  const [saveMessage, setSaveMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const [customTelematicsConfig, setCustomTelematicsConfig] = useState({
    apiEndpoint: '',
    apiKey: '',
    webhookUrl: '',
    dataFormat: 'json' as 'json' | 'xml',
  });

  useEffect(() => {
    loadProviders();
  }, []);

  useEffect(() => {
    if (activeTab !== 'all-fleets') {
      const provider = providers.find(p => p.name === activeTab);
      if (provider) {
        setSelectedProvider(provider);
      }
    }
  }, [activeTab, providers]);

  useEffect(() => {
    if (selectedProvider) {
      loadCredentials(selectedProvider.id);
      loadSyncLogs(selectedProvider.id);
    }
  }, [selectedProvider]);

  const loadProviders = async () => {
    try {
      setLoading(true);
      const data = await getIntegrationProviders();
      setProviders(data);
    } catch (error) {
      console.error('Failed to load providers:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadCredentials = async (providerId: string) => {
    try {
      const data = await getIntegrationCredentials(providerId);
      if (data) {
        setCredentials(data);
      } else {
        setCredentials({ provider_id: providerId, configuration: {} });
      }
    } catch (error) {
      console.error('Failed to load credentials:', error);
    }
  };

  const loadSyncLogs = async (providerId: string) => {
    try {
      const data = await getIntegrationSyncLogs(providerId, 10);
      setSyncLogs(data);
    } catch (error) {
      console.error('Failed to load sync logs:', error);
    }
  };

  const handleSaveCredentials = async () => {
    if (!selectedProvider) return;

    try {
      setSaving(true);
      setSaveMessage(null);
      await upsertIntegrationCredentials({
        provider_id: selectedProvider.id,
        ...credentials,
        configuration: credentials.configuration || {},
      } as Omit<IntegrationCredentials, 'id' | 'created_at' | 'updated_at'>);

      setSaveMessage({ type: 'success', text: 'Credentials saved successfully!' });
      setTimeout(() => setSaveMessage(null), 5000);
    } catch (error) {
      console.error('Failed to save credentials:', error);
      setSaveMessage({ type: 'error', text: 'Failed to save credentials. Please try again.' });
    } finally {
      setSaving(false);
    }
  };

  const handleTestConnection = async () => {
    if (!selectedProvider) return;

    try {
      setTesting(true);
      setTestResult(null);
      const result = await testIntegrationConnection(selectedProvider.name, credentials);
      setTestResult(result);

      if (result.success) {
        await updateIntegrationProvider(selectedProvider.id, {
          connection_status: 'connected',
          is_enabled: true,
        });

        await activateMonitoring(selectedProvider.id);

        loadProviders();
      }
    } catch (error) {
      console.error('Connection test failed:', error);
      setTestResult({ success: false, message: 'Connection test failed' });
    } finally {
      setTesting(false);
    }
  };

  const handleSync = async (syncType: IntegrationSyncLog['sync_type']) => {
    if (!selectedProvider) return;

    try {
      await triggerSync(selectedProvider.id, syncType);
      setTimeout(() => loadSyncLogs(selectedProvider.id), 2500);
    } catch (error) {
      console.error('Sync failed:', error);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'connected':
        return <CheckCircle className="h-5 w-5 text-green-500" />;
      case 'error':
        return <XCircle className="h-5 w-5 text-red-500" />;
      case 'connecting':
        return <Activity className="h-5 w-5 text-yellow-500 animate-pulse" />;
      default:
        return <XCircle className="h-5 w-5 text-gray-400" />;
    }
  };

  const getSyncStatusColor = (status: string) => {
    switch (status) {
      case 'success':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'partial':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'failed':
        return 'bg-red-100 text-red-800 border-red-200';
      default:
        return 'bg-blue-100 text-blue-800 border-blue-200';
    }
  };

  const renderCredentialForm = () => {
    if (!selectedProvider) return null;

    switch (selectedProvider.name) {
      case 'geotab':
        return (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Username</label>
              <input
                type="text"
                value={credentials.username || ''}
                onChange={(e) => setCredentials({ ...credentials, username: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="your-username"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
              <input
                type="password"
                value={credentials.api_secret || ''}
                onChange={(e) => setCredentials({ ...credentials, api_secret: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="••••••••"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Database Name</label>
              <input
                type="text"
                value={credentials.database_name || ''}
                onChange={(e) => setCredentials({ ...credentials, database_name: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="your-database"
              />
            </div>
          </div>
        );

      case 'samsara':
        return (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">API Token</label>
              <input
                type="password"
                value={credentials.api_key || ''}
                onChange={(e) => setCredentials({ ...credentials, api_key: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="samsara_api_••••••••••••••••"
              />
              <p className="mt-1 text-xs text-gray-500">
                Get your API token from Samsara Dashboard → Settings → API Tokens
              </p>
            </div>
          </div>
        );

      case 'motive':
        return (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">API Key</label>
              <input
                type="password"
                value={credentials.api_key || ''}
                onChange={(e) => setCredentials({ ...credentials, api_key: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="motive_••••••••••••••••"
              />
              <p className="mt-1 text-xs text-gray-500">
                Get your API key from Motive Dashboard → Settings → Integrations
              </p>
            </div>
          </div>
        );

      case 'custom':
        return null;
    }
  };

  if (!isAdmin()) {
    return (
      <div className="p-6">
        <div className="bg-red-50 border-2 border-red-200 rounded-lg p-12 text-center">
          <ShieldAlert className="h-16 w-16 text-red-600 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-red-900 mb-2">Admin Access Required</h2>
          <p className="text-red-700">
            You need administrator privileges to access Fleet Integrations.
          </p>
        </div>
      </div>
    );
  }

  const renderAllFleetsTab = () => (
    <div className="space-y-6">
      <div className="bg-gradient-to-r from-blue-50 to-cyan-50 border border-blue-200 rounded-lg p-6">
        <div className="flex items-start space-x-4">
          <div className="p-3 bg-blue-100 rounded-lg">
            <Network className="h-8 w-8 text-blue-600" />
          </div>
          <div>
            <h3 className="text-xl font-bold text-gray-900 mb-2">Custom Telematics Integration</h3>
            <p className="text-gray-700 mb-4">
              Connect any generic or custom telematics system using REST API. Configure your endpoint,
              authentication, and data format below.
            </p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="p-6 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900">API Configuration</h3>
              <Link className="h-5 w-5 text-gray-400" />
            </div>
          </div>

          <div className="p-6 space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">API Endpoint URL</label>
              <input
                type="url"
                value={customTelematicsConfig.apiEndpoint}
                onChange={(e) => setCustomTelematicsConfig({ ...customTelematicsConfig, apiEndpoint: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="https://api.your-telematics.com/v1"
              />
              <p className="mt-1 text-xs text-gray-500">
                Base URL for your telematics API endpoint
              </p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">API Key / Token</label>
              <input
                type="password"
                value={customTelematicsConfig.apiKey}
                onChange={(e) => setCustomTelematicsConfig({ ...customTelematicsConfig, apiKey: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="••••••••••••••••••••••"
              />
              <p className="mt-1 text-xs text-gray-500">
                Authentication token for API access
              </p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Webhook URL (Optional)</label>
              <input
                type="url"
                value={customTelematicsConfig.webhookUrl}
                onChange={(e) => setCustomTelematicsConfig({ ...customTelematicsConfig, webhookUrl: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="https://your-domain.com/webhooks/telematics"
              />
              <p className="mt-1 text-xs text-gray-500">
                URL to receive real-time updates from telematics system
              </p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Data Format</label>
              <select
                value={customTelematicsConfig.dataFormat}
                onChange={(e) => setCustomTelematicsConfig({ ...customTelematicsConfig, dataFormat: e.target.value as 'json' | 'xml' })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="json">JSON</option>
                <option value="xml">XML</option>
              </select>
            </div>

            <div className="pt-4 border-t border-gray-200 flex space-x-3">
              <button
                onClick={async () => {
                  const customProvider = providers.find(p => p.name === 'custom');
                  if (customProvider) {
                    setTesting(true);
                    const result = await testIntegrationConnection('custom', {
                      api_key: customTelematicsConfig.apiKey,
                      configuration: {
                        apiEndpoint: customTelematicsConfig.apiEndpoint,
                        webhookUrl: customTelematicsConfig.webhookUrl,
                        dataFormat: customTelematicsConfig.dataFormat,
                      },
                    });
                    setTestResult(result);
                    setTesting(false);
                  }
                }}
                disabled={testing}
                className="flex-1 flex items-center justify-center space-x-2 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50"
              >
                <TestTube className="h-4 w-4" />
                <span>{testing ? 'Testing...' : 'Test Connection'}</span>
              </button>
              <button
                onClick={async () => {
                  const customProvider = providers.find(p => p.name === 'custom');
                  if (customProvider) {
                    setSaving(true);
                    setSaveMessage(null);
                    try {
                      await upsertIntegrationCredentials({
                        provider_id: customProvider.id,
                        api_key: customTelematicsConfig.apiKey,
                        configuration: {
                          apiEndpoint: customTelematicsConfig.apiEndpoint,
                          webhookUrl: customTelematicsConfig.webhookUrl,
                          dataFormat: customTelematicsConfig.dataFormat,
                        },
                      } as Omit<IntegrationCredentials, 'id' | 'created_at' | 'updated_at'>);
                      setSaveMessage({ type: 'success', text: 'Configuration saved successfully!' });
                      setTimeout(() => setSaveMessage(null), 5000);
                    } catch (error) {
                      setSaveMessage({ type: 'error', text: 'Failed to save configuration. Please try again.' });
                    } finally {
                      setSaving(false);
                    }
                  }
                }}
                disabled={saving}
                className="flex-1 flex items-center justify-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50"
              >
                <Save className="h-4 w-4" />
                <span>{saving ? 'Saving...' : 'Save Config'}</span>
              </button>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="p-6 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900">Integration Guide</h3>
              <Database className="h-5 w-5 text-gray-400" />
            </div>
          </div>

          <div className="p-6 space-y-4">
            <div>
              <h4 className="font-semibold text-gray-900 mb-2">Required API Endpoints</h4>
              <div className="space-y-2 text-sm text-gray-700">
                <div className="flex items-start space-x-2">
                  <span className="font-mono bg-gray-100 px-2 py-1 rounded">GET</span>
                  <span>/vehicles - List all vehicles</span>
                </div>
                <div className="flex items-start space-x-2">
                  <span className="font-mono bg-gray-100 px-2 py-1 rounded">GET</span>
                  <span>/drivers - List all drivers</span>
                </div>
                <div className="flex items-start space-x-2">
                  <span className="font-mono bg-gray-100 px-2 py-1 rounded">GET</span>
                  <span>/locations - GPS tracking data</span>
                </div>
                <div className="flex items-start space-x-2">
                  <span className="font-mono bg-gray-100 px-2 py-1 rounded">GET</span>
                  <span>/trips - Trip history</span>
                </div>
              </div>
            </div>

            <div className="pt-4 border-t border-gray-200">
              <h4 className="font-semibold text-gray-900 mb-2">Expected Response Format</h4>
              <div className="bg-gray-900 text-gray-100 p-4 rounded-lg text-xs font-mono overflow-x-auto">
                <pre>{`{
  "vehicles": [
    {
      "id": "string",
      "name": "string",
      "vin": "string",
      "status": "active",
      "location": {
        "lat": 0,
        "lng": 0
      }
    }
  ]
}`}</pre>
              </div>
            </div>

            <div className="pt-4 border-t border-gray-200">
              <h4 className="font-semibold text-gray-900 mb-2">Sync Schedule</h4>
              <p className="text-sm text-gray-600">
                Data synchronization runs every 5 minutes for real-time updates. You can also trigger
                manual syncs using the buttons above.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  return (
    <div className="p-6 space-y-6">
      {saveMessage && (
        <div className={`p-4 rounded-lg border ${
          saveMessage.type === 'success'
            ? 'bg-green-50 border-green-200 text-green-800'
            : 'bg-red-50 border-red-200 text-red-800'
        }`}>
          <div className="flex items-center space-x-2">
            {saveMessage.type === 'success' ? (
              <CheckCircle className="h-5 w-5" />
            ) : (
              <XCircle className="h-5 w-5" />
            )}
            <p className="text-sm font-medium">{saveMessage.text}</p>
          </div>
        </div>
      )}

      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Fleet Integrations</h1>
          <p className="text-gray-600">Connect with Geotab, Samsara, Motive, or Custom Telematics</p>
        </div>
        {isAdmin() && (
          <div className="flex items-center space-x-2 px-4 py-2 bg-green-100 text-green-800 rounded-lg border border-green-200">
            <Key className="h-4 w-4" />
            <span className="text-sm font-medium">Admin Access</span>
          </div>
        )}
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="border-b border-gray-200">
          <nav className="flex space-x-1 p-2" aria-label="Tabs">
            <button
              onClick={() => setActiveTab('geotab')}
              className={`px-4 py-2.5 text-sm font-semibold rounded-lg transition-all ${
                activeTab === 'geotab'
                  ? 'bg-gradient-to-r from-blue-600 to-cyan-600 text-white shadow-md'
                  : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
              }`}
            >
              <div className="flex items-center space-x-2">
                <span>Geotab</span>
                {providers.find(p => p.name === 'geotab')?.connection_status === 'connected' && (
                  <CheckCircle className="h-4 w-4" />
                )}
              </div>
            </button>
            <button
              onClick={() => setActiveTab('samsara')}
              className={`px-4 py-2.5 text-sm font-semibold rounded-lg transition-all ${
                activeTab === 'samsara'
                  ? 'bg-gradient-to-r from-blue-600 to-cyan-600 text-white shadow-md'
                  : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
              }`}
            >
              <div className="flex items-center space-x-2">
                <span>Samsara</span>
                {providers.find(p => p.name === 'samsara')?.connection_status === 'connected' && (
                  <CheckCircle className="h-4 w-4" />
                )}
              </div>
            </button>
            <button
              onClick={() => setActiveTab('motive')}
              className={`px-4 py-2.5 text-sm font-semibold rounded-lg transition-all ${
                activeTab === 'motive'
                  ? 'bg-gradient-to-r from-blue-600 to-cyan-600 text-white shadow-md'
                  : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
              }`}
            >
              <div className="flex items-center space-x-2">
                <span>Motive</span>
                {providers.find(p => p.name === 'motive')?.connection_status === 'connected' && (
                  <CheckCircle className="h-4 w-4" />
                )}
              </div>
            </button>
            <button
              onClick={() => setActiveTab('all-fleets')}
              className={`px-4 py-2.5 text-sm font-semibold rounded-lg transition-all ${
                activeTab === 'all-fleets'
                  ? 'bg-gradient-to-r from-emerald-600 to-teal-600 text-white shadow-md'
                  : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
              }`}
            >
              <div className="flex items-center space-x-2">
                <Network className="h-4 w-4" />
                <span>All Fleets Integration</span>
              </div>
            </button>
          </nav>
        </div>
      </div>

      {activeTab === 'all-fleets' ? (
        renderAllFleetsTab()
      ) : (
        <>
          <div className="bg-gradient-to-r from-blue-50 to-cyan-50 border border-blue-200 rounded-lg p-6 mb-6">
            <div className="flex items-start space-x-4">
              <div className="p-3 bg-blue-100 rounded-lg">
                {selectedProvider && (
                  selectedProvider.name === 'geotab' ? <Database className="h-8 w-8 text-blue-600" /> :
                  selectedProvider.name === 'samsara' ? <Zap className="h-8 w-8 text-blue-600" /> :
                  <Activity className="h-8 w-8 text-blue-600" />
                )}
              </div>
              <div className="flex-1">
                <h3 className="text-xl font-bold text-gray-900 mb-1">{selectedProvider?.display_name}</h3>
                <p className="text-gray-700 mb-3">
                  {selectedProvider?.name === 'geotab' && 'Industry-leading GPS fleet tracking and management platform'}
                  {selectedProvider?.name === 'samsara' && 'Complete visibility and real-time insights for your fleet operations'}
                  {selectedProvider?.name === 'motive' && 'Automated fleet management with ELD compliance and safety features'}
                </p>
                <div className="flex items-center space-x-4">
                  <div className="flex items-center space-x-2">
                    {getStatusIcon(selectedProvider?.connection_status || 'disconnected')}
                    <span className="text-sm font-medium text-gray-700">
                      {selectedProvider?.connection_status === 'connected' ? 'Connected' : 'Not Connected'}
                    </span>
                  </div>
                  {selectedProvider?.last_sync_at && (
                    <div className="flex items-center space-x-2 text-sm text-gray-600">
                      <Clock className="h-4 w-4" />
                      <span>Last sync: {new Date(selectedProvider.last_sync_at).toLocaleString()}</span>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>

          {selectedProvider && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold text-gray-900">Connection Settings</h3>
                <Settings className="h-5 w-5 text-gray-400" />
              </div>
            </div>

            <div className="p-6 space-y-6">
              {renderCredentialForm()}

              {testResult && (
                <div
                  className={`p-4 rounded-lg border ${
                    testResult.success
                      ? 'bg-green-50 border-green-200'
                      : 'bg-red-50 border-red-200'
                  }`}
                >
                  <div className="flex items-center space-x-2">
                    {testResult.success ? (
                      <CheckCircle className="h-5 w-5 text-green-600" />
                    ) : (
                      <AlertTriangle className="h-5 w-5 text-red-600" />
                    )}
                    <p
                      className={`text-sm font-medium ${
                        testResult.success ? 'text-green-900' : 'text-red-900'
                      }`}
                    >
                      {testResult.message}
                    </p>
                  </div>
                </div>
              )}

              <div className="flex space-x-3">
                <button
                  onClick={handleTestConnection}
                  disabled={testing}
                  className="flex-1 flex items-center justify-center space-x-2 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50"
                >
                  <TestTube className="h-4 w-4" />
                  <span>{testing ? 'Testing...' : 'Test Connection'}</span>
                </button>
                <button
                  onClick={handleSaveCredentials}
                  disabled={saving}
                  className="flex-1 flex items-center justify-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50"
                >
                  <Save className="h-4 w-4" />
                  <span>{saving ? 'Saving...' : 'Save'}</span>
                </button>
              </div>

              <div className="pt-4 border-t border-gray-200">
                <h4 className="text-sm font-semibold text-gray-900 mb-3">Data Synchronization</h4>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    onClick={() => handleSync('vehicles')}
                    className="flex items-center justify-center space-x-2 px-3 py-2 text-sm border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                  >
                    <RefreshCw className="h-3 w-3" />
                    <span>Sync Vehicles</span>
                  </button>
                  <button
                    onClick={() => handleSync('drivers')}
                    className="flex items-center justify-center space-x-2 px-3 py-2 text-sm border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                  >
                    <RefreshCw className="h-3 w-3" />
                    <span>Sync Drivers</span>
                  </button>
                  <button
                    onClick={() => handleSync('locations')}
                    className="flex items-center justify-center space-x-2 px-3 py-2 text-sm border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                  >
                    <RefreshCw className="h-3 w-3" />
                    <span>Sync Locations</span>
                  </button>
                  <button
                    onClick={() => handleSync('safety')}
                    className="flex items-center justify-center space-x-2 px-3 py-2 text-sm border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                  >
                    <RefreshCw className="h-3 w-3" />
                    <span>Sync Safety</span>
                  </button>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold text-gray-900">Sync History</h3>
                <Database className="h-5 w-5 text-gray-400" />
              </div>
            </div>

            <div className="p-6">
              {syncLogs.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-12 text-gray-500">
                  <Clock className="h-12 w-12 mb-2" />
                  <p className="text-sm">No sync history yet</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {syncLogs.map((log) => (
                    <div
                      key={log.id}
                      className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
                    >
                      <div className="flex items-start justify-between mb-2">
                        <div>
                          <p className="font-medium text-gray-900 capitalize">
                            {log.sync_type.replace('_', ' ')}
                          </p>
                          <p className="text-xs text-gray-600">
                            {new Date(log.started_at).toLocaleString()}
                          </p>
                        </div>
                        <span
                          className={`inline-flex items-center px-2 py-1 rounded text-xs font-medium border ${getSyncStatusColor(
                            log.status
                          )}`}
                        >
                          {log.status}
                        </span>
                      </div>
                      <div className="grid grid-cols-3 gap-2 text-xs text-gray-600">
                        <div>
                          <p className="text-gray-500">Processed</p>
                          <p className="font-medium text-gray-900">{log.records_processed}</p>
                        </div>
                        <div>
                          <p className="text-gray-500">Success</p>
                          <p className="font-medium text-green-600">{log.records_success}</p>
                        </div>
                        <div>
                          <p className="text-gray-500">Failed</p>
                          <p className="font-medium text-red-600">{log.records_failed}</p>
                        </div>
                      </div>
                      {log.error_message && (
                        <p className="mt-2 text-xs text-red-600">{log.error_message}</p>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
          )}
        </>
      )}
    </div>
  );
};

export default IntegrationsPage;
