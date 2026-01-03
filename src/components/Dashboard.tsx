import React, { useState, useEffect } from 'react';
import {
  Activity,
  AlertCircle,
  TrendingUp,
  TrendingDown,
  Fuel,
  Shield,
  Users,
  Truck,
  Clock,
  MapPin,
  Zap,
  DollarSign,
  CheckCircle,
  AlertTriangle,
  Navigation,
  BarChart3,
  PieChart,
  LineChart,
  Plug,
  ArrowRight,
  Sparkles
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import { getDashboardStats, getRecentAlerts } from '../api/dashboard';
import { triggerHealthCheck } from '../api/monitoring';
import WelcomeModal from './WelcomeModal';
import OnboardingChecklist from './OnboardingChecklist';

interface VehicleStatus {
  id: string;
  vehicle_number: string;
  status: string;
  current_location?: any;
  driver_name?: string;
}

interface RecentTrip {
  id: string;
  vehicle_number: string;
  driver_name: string;
  distance: number;
  duration: number;
  fuel_used: number;
  efficiency: number;
}

interface DashboardProps {
  onNavigate?: (page: string) => void;
}

const Dashboard: React.FC<DashboardProps> = ({ onNavigate }) => {
  const { user, profile } = useAuth();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    activeVehicles: 0,
    activeDrivers: 0,
    fleetEfficiency: 0,
    safetyScore: 0,
    fuelSavings: 0,
    onTimeRate: 0,
  });
  const [vehicles, setVehicles] = useState<VehicleStatus[]>([]);
  const [recentTrips, setRecentTrips] = useState<RecentTrip[]>([]);
  const [alerts, setAlerts] = useState<any[]>([]);
  const [showWelcomeModal, setShowWelcomeModal] = useState(false);
  const [completedSteps, setCompletedSteps] = useState<string[]>([]);
  const [showChecklist, setShowChecklist] = useState(true);
  const [hasConnectedIntegration, setHasConnectedIntegration] = useState(false);

  useEffect(() => {
    if (user && profile) {
      loadDashboardData();
      checkOnboardingStatus();
      checkIntegrationStatus();
      triggerHealthCheck();

      const interval = setInterval(() => {
        loadDashboardData();
        checkIntegrationStatus();
        triggerHealthCheck();
      }, 30000);

      return () => clearInterval(interval);
    }
  }, [user, profile]);

  const checkOnboardingStatus = async () => {
    if (!profile) return;

    if (!profile.welcome_modal_seen) {
      setShowWelcomeModal(true);
    }

    if (profile.onboarding_steps) {
      setCompletedSteps(profile.onboarding_steps as string[]);
    }

    if (profile.onboarding_dismissed) {
      setShowChecklist(false);
    }
  };

  const checkIntegrationStatus = async () => {
    try {
      const { data, error } = await supabase
        .from('integration_providers')
        .select('connection_status')
        .eq('connection_status', 'connected')
        .limit(1);

      if (error) {
        console.error('Error checking integration status:', error);
        return;
      }

      setHasConnectedIntegration(data && data.length > 0);
    } catch (error) {
      console.error('Error checking integration status:', error);
    }
  };

  const handleWelcomeClose = async () => {
    setShowWelcomeModal(false);
    if (user) {
      await supabase
        .from('user_profiles')
        .update({ welcome_modal_seen: true })
        .eq('id', user.id);
    }
  };

  const handleGetStarted = async () => {
    setShowWelcomeModal(false);
    if (user) {
      await supabase
        .from('user_profiles')
        .update({ welcome_modal_seen: true })
        .eq('id', user.id);
    }
  };

  const handleConnectIntegration = async () => {
    setShowWelcomeModal(false);
    if (user) {
      await supabase
        .from('user_profiles')
        .update({ welcome_modal_seen: true })
        .eq('id', user.id);
    }
    if (onNavigate) {
      onNavigate('integrations');
    }
  };

  const handleStepClick = async (route: string) => {
    const stepMap: Record<string, string> = {
      integrations: 'connect_integration',
      vehicles: 'add_vehicle',
      'drivers-management': 'add_driver',
      'live-tracking': 'view_tracking',
      dashboard: 'check_analytics',
    };

    const stepId = stepMap[route];
    if (stepId && !completedSteps.includes(stepId)) {
      const newSteps = [...completedSteps, stepId];
      setCompletedSteps(newSteps);

      if (user) {
        await supabase
          .from('user_profiles')
          .update({
            onboarding_steps: newSteps,
            onboarding_completed: newSteps.length >= 5,
          })
          .eq('id', user.id);
      }
    }

    if (onNavigate) {
      onNavigate(route);
    }
  };

  const handleDismissChecklist = async () => {
    setShowChecklist(false);
    if (user) {
      await supabase
        .from('user_profiles')
        .update({ onboarding_dismissed: true })
        .eq('id', user.id);
    }
  };

  const loadDashboardData = async () => {
    try {
      setLoading(true);

      const [dashboardStats, alertsData, vehiclesData] = await Promise.all([
        getDashboardStats(),
        getRecentAlerts(),
        supabase
          .from('vehicles')
          .select('id, vehicle_number, status, current_location')
          .limit(6),
      ]);

      setStats(dashboardStats);
      setAlerts(alertsData);
      setVehicles(vehiclesData.data || []);

      const mockTrips: RecentTrip[] = [
        {
          id: '1',
          vehicle_number: 'V001',
          driver_name: 'John Smith',
          distance: 145.3,
          duration: 180,
          fuel_used: 18.2,
          efficiency: 8.0,
        },
        {
          id: '2',
          vehicle_number: 'V003',
          driver_name: 'Sarah Johnson',
          distance: 98.7,
          duration: 120,
          fuel_used: 11.5,
          efficiency: 8.6,
        },
        {
          id: '3',
          vehicle_number: 'V005',
          driver_name: 'Mike Davis',
          distance: 203.4,
          duration: 240,
          fuel_used: 25.8,
          efficiency: 7.9,
        },
      ];
      setRecentTrips(mockTrips);
    } catch (error) {
      console.error('Error loading dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  const hasData = stats.activeVehicles > 0 || stats.activeDrivers > 0;

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-slate-100">
      <WelcomeModal
        isOpen={showWelcomeModal}
        onClose={handleWelcomeClose}
        onGetStarted={handleGetStarted}
        onConnectIntegration={handleConnectIntegration}
        userName={profile?.full_name}
      />

      {showChecklist && !profile?.onboarding_completed && (
        <OnboardingChecklist
          completedSteps={completedSteps}
          onStepClick={handleStepClick}
          onDismiss={handleDismissChecklist}
          isVisible={true}
        />
      )}

      {!hasConnectedIntegration && profile?.demo_mode && (
        <div className="p-6 pb-0">
          <div className="bg-gradient-to-r from-blue-500 via-cyan-500 to-blue-600 rounded-xl shadow-xl p-6 text-white relative overflow-hidden">
            <div className="absolute inset-0 bg-black opacity-5"></div>
            <div className="relative z-10 flex items-start justify-between gap-4">
              <div className="flex-1">
                <div className="flex items-center gap-3 mb-3">
                  <div className="w-12 h-12 bg-white bg-opacity-20 rounded-full flex items-center justify-center backdrop-blur-sm">
                    <Plug className="h-6 w-6 text-white" />
                  </div>
                  <div>
                    <h3 className="text-xl font-bold">You're viewing demo data</h3>
                    <p className="text-blue-100 text-sm">Connect your telematics system to see your real fleet data</p>
                  </div>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 mb-4">
                  <div className="bg-white bg-opacity-10 backdrop-blur-sm rounded-lg p-3">
                    <p className="text-xs text-blue-100 mb-1">Supported Systems</p>
                    <p className="text-sm font-semibold">Geotab, Samsara, Motive</p>
                  </div>
                  <div className="bg-white bg-opacity-10 backdrop-blur-sm rounded-lg p-3">
                    <p className="text-xs text-blue-100 mb-1">Setup Time</p>
                    <p className="text-sm font-semibold">Less than 5 minutes</p>
                  </div>
                  <div className="bg-white bg-opacity-10 backdrop-blur-sm rounded-lg p-3">
                    <p className="text-xs text-blue-100 mb-1">Data Sync</p>
                    <p className="text-sm font-semibold">Automatic & Real-time</p>
                  </div>
                </div>
                <button
                  onClick={() => onNavigate && onNavigate('integrations')}
                  className="bg-white text-blue-600 px-6 py-3 rounded-lg font-bold hover:bg-blue-50 transition-all duration-200 shadow-lg hover:shadow-xl flex items-center gap-2 group"
                >
                  Connect Your Telematics
                  <ArrowRight className="h-5 w-5 group-hover:translate-x-1 transition-transform" />
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="p-6 space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Fleet Command Center</h1>
            <p className="text-gray-600 mt-1">Real-time fleet monitoring and analytics</p>
          </div>
          <div className="flex items-center gap-3">
            {profile?.demo_mode && !hasConnectedIntegration && (
              <div className="flex items-center space-x-2 bg-gradient-to-r from-amber-50 to-orange-50 rounded-lg px-4 py-2 shadow-sm border-2 border-amber-200">
                <Sparkles className="h-4 w-4 text-amber-600" />
                <span className="text-sm font-semibold text-amber-900">Demo Data</span>
              </div>
            )}
            {hasConnectedIntegration && (
              <div className="flex items-center space-x-2 bg-gradient-to-r from-green-50 to-emerald-50 rounded-lg px-4 py-2 shadow-sm border-2 border-green-200">
                <CheckCircle className="h-4 w-4 text-green-600" />
                <span className="text-sm font-semibold text-green-900">Live Data</span>
              </div>
            )}
            <div className="flex items-center space-x-2 bg-white rounded-lg px-4 py-2 shadow-sm border border-gray-200">
              <div className="flex items-center space-x-2">
                <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
                <span className="text-sm text-gray-600">System Live</span>
              </div>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden hover:shadow-xl transition-shadow">
            <div className="p-6">
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  <p className="text-sm font-medium text-gray-600 uppercase tracking-wide">Active Vehicles</p>
                  <div className="flex items-baseline mt-2">
                    <p className="text-4xl font-bold text-gray-900">
                      {loading ? '...' : stats.activeVehicles}
                    </p>
                    <span className="ml-2 text-sm text-green-600 font-medium flex items-center">
                      <TrendingUp className="h-4 w-4 mr-1" />
                      100%
                    </span>
                  </div>
                </div>
                <div className="bg-blue-100 p-4 rounded-2xl">
                  <Truck className="h-8 w-8 text-blue-600" />
                </div>
              </div>
              <div className="mt-4 flex items-center text-xs text-gray-500">
                <Activity className="h-4 w-4 mr-1" />
                <span>All vehicles operational</span>
              </div>
            </div>
            <div className="bg-gradient-to-r from-blue-50 to-blue-100 px-6 py-2">
              <div className="flex justify-between items-center">
                <span className="text-xs text-blue-700 font-medium">Fleet Status</span>
                <CheckCircle className="h-4 w-4 text-blue-600" />
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden hover:shadow-xl transition-shadow">
            <div className="p-6">
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  <p className="text-sm font-medium text-gray-600 uppercase tracking-wide">Active Drivers</p>
                  <div className="flex items-baseline mt-2">
                    <p className="text-4xl font-bold text-gray-900">
                      {loading ? '...' : stats.activeDrivers}
                    </p>
                    <span className="ml-2 text-sm text-green-600 font-medium flex items-center">
                      <TrendingUp className="h-4 w-4 mr-1" />
                      12%
                    </span>
                  </div>
                </div>
                <div className="bg-emerald-100 p-4 rounded-2xl">
                  <Users className="h-8 w-8 text-emerald-600" />
                </div>
              </div>
              <div className="mt-4 flex items-center text-xs text-gray-500">
                <Clock className="h-4 w-4 mr-1" />
                <span>On duty and tracking</span>
              </div>
            </div>
            <div className="bg-gradient-to-r from-emerald-50 to-emerald-100 px-6 py-2">
              <div className="flex justify-between items-center">
                <span className="text-xs text-emerald-700 font-medium">Driver Activity</span>
                <CheckCircle className="h-4 w-4 text-emerald-600" />
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden hover:shadow-xl transition-shadow">
            <div className="p-6">
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  <p className="text-sm font-medium text-gray-600 uppercase tracking-wide">Safety Score</p>
                  <div className="flex items-baseline mt-2">
                    <p className="text-4xl font-bold text-gray-900">
                      {loading ? '...' : Math.round(stats.safetyScore)}%
                    </p>
                    <span className="ml-2 text-sm text-green-600 font-medium flex items-center">
                      <TrendingUp className="h-4 w-4 mr-1" />
                      5%
                    </span>
                  </div>
                </div>
                <div className="bg-green-100 p-4 rounded-2xl">
                  <Shield className="h-8 w-8 text-green-600" />
                </div>
              </div>
              <div className="mt-4 flex items-center text-xs text-gray-500">
                <AlertCircle className="h-4 w-4 mr-1" />
                <span>Excellent performance</span>
              </div>
            </div>
            <div className="bg-gradient-to-r from-green-50 to-green-100 px-6 py-2">
              <div className="flex justify-between items-center">
                <span className="text-xs text-green-700 font-medium">Safety Rating</span>
                <CheckCircle className="h-4 w-4 text-green-600" />
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden hover:shadow-xl transition-shadow">
            <div className="p-6">
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  <p className="text-sm font-medium text-gray-600 uppercase tracking-wide">Fuel Efficiency</p>
                  <div className="flex items-baseline mt-2">
                    <p className="text-4xl font-bold text-gray-900">
                      {loading ? '...' : stats.fleetEfficiency.toFixed(1)}%
                    </p>
                    <span className="ml-2 text-sm text-green-600 font-medium flex items-center">
                      <TrendingUp className="h-4 w-4 mr-1" />
                      8%
                    </span>
                  </div>
                </div>
                <div className="bg-amber-100 p-4 rounded-2xl">
                  <Fuel className="h-8 w-8 text-amber-600" />
                </div>
              </div>
              <div className="mt-4 flex items-center text-xs text-gray-500">
                <Zap className="h-4 w-4 mr-1" />
                <span>Above target efficiency</span>
              </div>
            </div>
            <div className="bg-gradient-to-r from-amber-50 to-amber-100 px-6 py-2">
              <div className="flex justify-between items-center">
                <span className="text-xs text-amber-700 font-medium">Fleet Average</span>
                <TrendingUp className="h-4 w-4 text-amber-600" />
              </div>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-6">
            <div className="bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden">
              <div className="bg-gradient-to-r from-blue-600 to-blue-700 px-6 py-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <BarChart3 className="h-6 w-6 text-white" />
                    <h2 className="text-xl font-bold text-white">Fleet Performance</h2>
                  </div>
                  <select className="bg-blue-800 text-white text-sm rounded-lg px-3 py-1.5 border-0 focus:ring-2 focus:ring-white">
                    <option>Today</option>
                    <option>This Week</option>
                    <option>This Month</option>
                  </select>
                </div>
              </div>
              <div className="p-6">
                <div className="grid grid-cols-3 gap-4 mb-6">
                  <div className="bg-gradient-to-br from-blue-50 to-blue-100 rounded-lg p-4 border border-blue-200">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm font-medium text-blue-900">Total Distance</span>
                      <Navigation className="h-5 w-5 text-blue-600" />
                    </div>
                    <p className="text-2xl font-bold text-blue-900">1,247 mi</p>
                    <p className="text-xs text-blue-600 mt-1">+14% from yesterday</p>
                  </div>
                  <div className="bg-gradient-to-br from-emerald-50 to-emerald-100 rounded-lg p-4 border border-emerald-200">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm font-medium text-emerald-900">Fuel Saved</span>
                      <DollarSign className="h-5 w-5 text-emerald-600" />
                    </div>
                    <p className="text-2xl font-bold text-emerald-900">${stats.fuelSavings.toLocaleString()}</p>
                    <p className="text-xs text-emerald-600 mt-1">This month</p>
                  </div>
                  <div className="bg-gradient-to-br from-amber-50 to-amber-100 rounded-lg p-4 border border-amber-200">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm font-medium text-amber-900">Avg MPG</span>
                      <Fuel className="h-5 w-5 text-amber-600" />
                    </div>
                    <p className="text-2xl font-bold text-amber-900">8.2</p>
                    <p className="text-xs text-amber-600 mt-1">Fleet average</p>
                  </div>
                </div>

                <div className="space-y-3">
                  <h3 className="text-sm font-semibold text-gray-700 uppercase tracking-wide">Recent Trips</h3>
                  {recentTrips.length === 0 ? (
                    <div className="text-center py-8 text-gray-400">
                      <MapPin className="h-12 w-12 mx-auto mb-2 text-gray-300" />
                      <p>No recent trips. Start tracking to see data.</p>
                    </div>
                  ) : (
                    recentTrips.map((trip) => (
                      <div
                        key={trip.id}
                        className="flex items-center justify-between p-4 bg-gradient-to-r from-gray-50 to-slate-50 rounded-lg border border-gray-200 hover:shadow-md transition-shadow"
                      >
                        <div className="flex items-center space-x-4">
                          <div className="bg-blue-100 p-3 rounded-xl">
                            <Truck className="h-5 w-5 text-blue-600" />
                          </div>
                          <div>
                            <p className="font-semibold text-gray-900">{trip.vehicle_number}</p>
                            <p className="text-sm text-gray-600">{trip.driver_name}</p>
                          </div>
                        </div>
                        <div className="flex items-center space-x-6">
                          <div className="text-right">
                            <p className="text-sm font-medium text-gray-900">{trip.distance.toFixed(1)} mi</p>
                            <p className="text-xs text-gray-500">{Math.round(trip.duration / 60)} hrs</p>
                          </div>
                          <div className="text-right">
                            <p className="text-sm font-medium text-gray-900">{trip.fuel_used.toFixed(1)} gal</p>
                            <p className="text-xs text-gray-500">{trip.efficiency.toFixed(1)} MPG</p>
                          </div>
                          <div className={`px-3 py-1 rounded-full ${
                            trip.efficiency >= 8.5 ? 'bg-green-100 text-green-700' :
                            trip.efficiency >= 8.0 ? 'bg-amber-100 text-amber-700' :
                            'bg-red-100 text-red-700'
                          }`}>
                            <span className="text-xs font-semibold">
                              {trip.efficiency >= 8.5 ? 'Excellent' :
                               trip.efficiency >= 8.0 ? 'Good' : 'Low'}
                            </span>
                          </div>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </div>
            </div>

            <div className="bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden">
              <div className="bg-gradient-to-r from-slate-700 to-slate-800 px-6 py-4">
                <div className="flex items-center space-x-3">
                  <MapPin className="h-6 w-6 text-white" />
                  <h2 className="text-xl font-bold text-white">Live Vehicle Status</h2>
                </div>
              </div>
              <div className="p-6">
                {vehicles.length === 0 ? (
                  <div className="text-center py-8 text-gray-400">
                    <Truck className="h-12 w-12 mx-auto mb-2 text-gray-300" />
                    <p>No vehicles found. Add vehicles to track them.</p>
                  </div>
                ) : (
                  <div className="grid grid-cols-2 gap-4">
                    {vehicles.map((vehicle) => (
                      <div
                        key={vehicle.id}
                        className="bg-gradient-to-br from-slate-50 to-gray-100 rounded-lg p-4 border border-gray-200 hover:shadow-lg transition-shadow"
                      >
                        <div className="flex items-center justify-between mb-3">
                          <span className="font-bold text-gray-900 text-lg">{vehicle.vehicle_number}</span>
                          <div className={`w-3 h-3 rounded-full ${
                            vehicle.status === 'active' ? 'bg-green-500 animate-pulse' :
                            vehicle.status === 'maintenance' ? 'bg-amber-500' :
                            'bg-gray-400'
                          }`}></div>
                        </div>
                        <div className="space-y-1">
                          <p className="text-xs text-gray-600 flex items-center">
                            <Activity className="h-3 w-3 mr-1" />
                            Status: <span className="ml-1 font-medium capitalize">{vehicle.status}</span>
                          </p>
                          {vehicle.driver_name && (
                            <p className="text-xs text-gray-600 flex items-center">
                              <Users className="h-3 w-3 mr-1" />
                              Driver: <span className="ml-1 font-medium">{vehicle.driver_name}</span>
                            </p>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>

          <div className="space-y-6">
            <div className="bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden">
              <div className="bg-gradient-to-r from-red-600 to-red-700 px-6 py-4">
                <div className="flex items-center space-x-3">
                  <AlertTriangle className="h-6 w-6 text-white" />
                  <h2 className="text-xl font-bold text-white">Active Alerts</h2>
                </div>
              </div>
              <div className="p-6 max-h-96 overflow-y-auto">
                {alerts.length === 0 ? (
                  <div className="text-center py-8 text-gray-400">
                    <CheckCircle className="h-12 w-12 mx-auto mb-2 text-green-300" />
                    <p className="text-sm">All systems operational</p>
                  </div>
                ) : (
                  <div className="space-y-3">
                    {alerts.map((alert) => (
                      <div
                        key={alert.id}
                        className={`p-4 rounded-lg border-l-4 ${
                          alert.type === 'error' ? 'bg-red-50 border-red-500' :
                          alert.type === 'warning' ? 'bg-amber-50 border-amber-500' :
                          alert.type === 'info' ? 'bg-blue-50 border-blue-500' :
                          'bg-green-50 border-green-500'
                        }`}
                      >
                        <div className="flex items-start justify-between">
                          <div className="flex-1">
                            <p className="text-sm font-medium text-gray-900">{alert.message}</p>
                            <p className="text-xs text-gray-500 mt-1">{alert.time}</p>
                          </div>
                          <span className={`px-2 py-1 rounded text-xs font-semibold ${
                            alert.priority === 'critical' || alert.priority === 'high' ? 'bg-red-100 text-red-700' :
                            alert.priority === 'medium' ? 'bg-amber-100 text-amber-700' :
                            'bg-blue-100 text-blue-700'
                          }`}>
                            {alert.priority}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>

            <div className="bg-gradient-to-br from-blue-600 to-blue-800 rounded-xl shadow-lg border border-blue-700 overflow-hidden">
              <div className="p-6 text-white">
                <div className="flex items-center space-x-3 mb-4">
                  <LineChart className="h-8 w-8" />
                  <h2 className="text-xl font-bold">Quick Stats</h2>
                </div>
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <span className="text-blue-100">On-Time Delivery</span>
                    <span className="text-2xl font-bold">{stats.onTimeRate.toFixed(1)}%</span>
                  </div>
                  <div className="w-full bg-blue-900 rounded-full h-2">
                    <div
                      className="bg-white rounded-full h-2"
                      style={{ width: `${stats.onTimeRate}%` }}
                    ></div>
                  </div>
                  <div className="pt-4 border-t border-blue-700">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <p className="text-xs text-blue-200">Avg Speed</p>
                        <p className="text-lg font-bold">52 mph</p>
                      </div>
                      <div>
                        <p className="text-xs text-blue-200">Idle Time</p>
                        <p className="text-lg font-bold">8.3%</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-gradient-to-r from-blue-600 via-blue-700 to-blue-800 rounded-xl shadow-lg border border-blue-700 overflow-hidden">
          <div className="p-6">
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center space-x-3">
                <Zap className="h-7 w-7 text-yellow-300" />
                <h2 className="text-2xl font-bold text-white">AI-Powered Intelligence</h2>
              </div>
              <span className="px-4 py-2 bg-green-500 text-white text-sm font-semibold rounded-full">
                All Systems Active
              </span>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="bg-white rounded-lg p-5 hover:shadow-2xl transition-all transform hover:-translate-y-1">
                <div className="flex items-center justify-between mb-3">
                  <h3 className="font-bold text-gray-900">Route Optimization</h3>
                  <Navigation className="h-5 w-5 text-blue-600" />
                </div>
                <p className="text-sm text-gray-600 mb-3">
                  AI-powered routing saves fuel and reduces delivery times by up to 23%.
                </p>
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-green-700 bg-green-100 px-3 py-1 rounded-full">
                    Active
                  </span>
                  <span className="text-xs text-gray-500">12 routes optimized today</span>
                </div>
              </div>
              <div className="bg-white rounded-lg p-5 hover:shadow-2xl transition-all transform hover:-translate-y-1">
                <div className="flex items-center justify-between mb-3">
                  <h3 className="font-bold text-gray-900">Driver Behavior AI</h3>
                  <Users className="h-5 w-5 text-emerald-600" />
                </div>
                <p className="text-sm text-gray-600 mb-3">
                  Monitor driving patterns and provide real-time coaching for safer operations.
                </p>
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-green-700 bg-green-100 px-3 py-1 rounded-full">
                    Active
                  </span>
                  <span className="text-xs text-gray-500">{stats.activeDrivers} drivers tracked</span>
                </div>
              </div>
              <div className="bg-white rounded-lg p-5 hover:shadow-2xl transition-all transform hover:-translate-y-1">
                <div className="flex items-center justify-between mb-3">
                  <h3 className="font-bold text-gray-900">Vehicle Health AI</h3>
                  <Activity className="h-5 w-5 text-amber-600" />
                </div>
                <p className="text-sm text-gray-600 mb-3">
                  Predictive maintenance alerts prevent breakdowns and extend vehicle life.
                </p>
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-green-700 bg-green-100 px-3 py-1 rounded-full">
                    Active
                  </span>
                  <span className="text-xs text-gray-500">3 alerts this week</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
