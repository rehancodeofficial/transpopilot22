import React, { useEffect, useState, useCallback } from 'react';
import {
  Activity,
  AlertTriangle,
  CheckCircle,
  TrendingUp,
  Truck,
  Wrench,
  DollarSign,
  Calendar,
  Zap,
  Droplet,
  Gauge,
  ThermometerSun,
  Brain,
  Clock,
  AlertCircle,
  Play,
  Pause,
  RefreshCw
} from 'lucide-react';
import { getVehicleHealthData } from '../api/vehicleHealthAI';

interface VehicleHealth {
  id: string;
  vehicle_number: string;
  make: string;
  model: string;
  health_score: number;
  engine_health: number;
  brake_health: number;
  transmission_health: number;
  tire_health: number;
  overall_status: 'excellent' | 'good' | 'fair' | 'poor';
  next_maintenance_due: number;
  predicted_issues: string[];
  cost_savings_potential: number;
}

const VehicleHealthAI: React.FC = () => {
  const [vehicles, setVehicles] = useState<VehicleHealth[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedVehicle, setSelectedVehicle] = useState<VehicleHealth | null>(null);
  const [simulationActive, setSimulationActive] = useState(false);
  const [simulationInterval, setSimulationInterval] = useState<number | null>(null);

  useEffect(() => {
    loadVehicleHealth();
  }, []);

  useEffect(() => {
    return () => {
      if (simulationInterval) {
        clearInterval(simulationInterval);
      }
    };
  }, [simulationInterval]);

  const loadVehicleHealth = useCallback(async () => {
    try {
      setLoading(true);
      const data = await getVehicleHealthData();
      const mappedData = data.map(v => ({
        id: v.vehicle_id,
        vehicle_number: v.vehicle_number,
        make: v.make,
        model: v.model,
        health_score: v.health_score,
        engine_health: v.engine_health,
        brake_health: v.brake_health,
        transmission_health: v.transmission_health,
        tire_health: v.tire_health,
        overall_status: v.overall_status,
        next_maintenance_due: v.next_maintenance_due,
        predicted_issues: v.predicted_issues,
        cost_savings_potential: v.cost_savings_potential
      }));
      setVehicles(mappedData);
      if (mappedData.length > 0 && !selectedVehicle) {
        setSelectedVehicle(mappedData[0]);
      }
    } catch (error) {
      console.error('Failed to load vehicle health data:', error);
    } finally {
      setLoading(false);
    }
  }, [selectedVehicle]);

  const toggleSimulation = async () => {
    if (simulationActive) {
      if (simulationInterval) {
        clearInterval(simulationInterval);
        setSimulationInterval(null);
      }
      setSimulationActive(false);
    } else {
      await simulateDiagnostics();
      const interval = window.setInterval(async () => {
        await simulateDiagnostics();
      }, 10000);
      setSimulationInterval(interval);
      setSimulationActive(true);
    }
  };

  const simulateDiagnostics = async () => {
    try {
      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/vehicle-health-ai?action=simulate`,
        {
          headers: {
            Authorization: `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
            'Content-Type': 'application/json',
          },
        }
      );
      if (response.ok) {
        await loadVehicleHealth();
      }
    } catch (error) {
      console.error('Failed to simulate diagnostics:', error);
    }
  };


  const getStatusColor = (status: string) => {
    switch (status) {
      case 'excellent':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'good':
        return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'fair':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'poor':
        return 'bg-red-100 text-red-800 border-red-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getHealthColor = (score: number) => {
    if (score >= 90) return 'text-green-600';
    if (score >= 75) return 'text-blue-600';
    if (score >= 60) return 'text-yellow-600';
    return 'text-red-600';
  };

  const getHealthBg = (score: number) => {
    if (score >= 90) return 'bg-green-100';
    if (score >= 75) return 'bg-blue-100';
    if (score >= 60) return 'bg-yellow-100';
    return 'bg-red-100';
  };

  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-teal-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-gray-600">Analyzing vehicle health data...</p>
        </div>
      </div>
    );
  }

  const fleetStats = {
    avgHealthScore: Math.round(vehicles.reduce((sum, v) => sum + v.health_score, 0) / vehicles.length),
    vehiclesNeedingAttention: vehicles.filter(v => v.health_score < 75).length,
    totalPotentialSavings: vehicles.reduce((sum, v) => sum + v.cost_savings_potential, 0),
    criticalAlerts: vehicles.filter(v => v.predicted_issues.length > 2).length
  };

  return (
    <div className="p-6 space-y-6 bg-gray-50 min-h-screen">
      <div className="bg-gradient-to-r from-teal-600 to-cyan-700 rounded-xl p-6 text-white shadow-lg">
        <div className="flex items-center justify-between">
          <div>
            <div className="flex items-center space-x-3 mb-2">
              <div className="p-2 bg-white/20 rounded-lg backdrop-blur-sm">
                <Brain className="h-8 w-8" />
              </div>
              <h1 className="text-3xl font-bold">Vehicle Health AI</h1>
            </div>
            <p className="text-teal-100">AI-powered predictive maintenance and diagnostics</p>
          </div>
          <div className="flex items-center space-x-3">
            <button
              onClick={toggleSimulation}
              className={`flex items-center space-x-2 px-4 py-2 rounded-lg transition-colors ${
                simulationActive
                  ? 'bg-red-500 hover:bg-red-600'
                  : 'bg-green-500 hover:bg-green-600'
              }`}
            >
              {simulationActive ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4" />}
              <span>{simulationActive ? 'Stop' : 'Start'} Simulation</span>
            </button>
            <button
              onClick={loadVehicleHealth}
              className="flex items-center space-x-2 px-4 py-2 bg-white/20 backdrop-blur-sm rounded-lg hover:bg-white/30 transition-colors"
            >
              <RefreshCw className="h-4 w-4" />
              <span>Refresh</span>
            </button>
            <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 backdrop-blur-sm rounded-xl">
              <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
              <span className="text-sm font-medium">Real-time Monitoring</span>
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-all">
          <div className="flex items-center justify-between mb-4">
            <div className={`p-3 rounded-xl ${getHealthBg(fleetStats.avgHealthScore)}`}>
              <Activity className={`h-6 w-6 ${getHealthColor(fleetStats.avgHealthScore)}`} />
            </div>
            <span className={`text-3xl font-bold ${getHealthColor(fleetStats.avgHealthScore)}`}>
              {fleetStats.avgHealthScore}%
            </span>
          </div>
          <h3 className="text-sm font-medium text-gray-600">Fleet Health Score</h3>
          <p className="text-xs text-gray-500 mt-1">Average across all vehicles</p>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-all">
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 rounded-xl bg-yellow-100">
              <AlertTriangle className="h-6 w-6 text-yellow-600" />
            </div>
            <span className="text-3xl font-bold text-yellow-600">{fleetStats.vehiclesNeedingAttention}</span>
          </div>
          <h3 className="text-sm font-medium text-gray-600">Need Attention</h3>
          <p className="text-xs text-gray-500 mt-1">Vehicles requiring maintenance</p>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-all">
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 rounded-xl bg-green-100">
              <DollarSign className="h-6 w-6 text-green-600" />
            </div>
            <span className="text-3xl font-bold text-green-600">${fleetStats.totalPotentialSavings}</span>
          </div>
          <h3 className="text-sm font-medium text-gray-600">Potential Savings</h3>
          <p className="text-xs text-gray-500 mt-1">Through preventive maintenance</p>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-all">
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 rounded-xl bg-red-100">
              <AlertCircle className="h-6 w-6 text-red-600" />
            </div>
            <span className="text-3xl font-bold text-red-600">{fleetStats.criticalAlerts}</span>
          </div>
          <h3 className="text-sm font-medium text-gray-600">Critical Alerts</h3>
          <p className="text-xs text-gray-500 mt-1">Require immediate attention</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-1 bg-white rounded-xl shadow-sm border border-gray-200">
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900 flex items-center">
              <Truck className="h-5 w-5 mr-2 text-teal-600" />
              Fleet Overview
            </h3>
          </div>
          <div className="p-4 space-y-2 max-h-[600px] overflow-y-auto">
            {vehicles.map((vehicle) => (
              <button
                key={vehicle.id}
                onClick={() => setSelectedVehicle(vehicle)}
                className={`w-full text-left p-4 rounded-lg transition-all ${
                  selectedVehicle?.id === vehicle.id
                    ? 'bg-gradient-to-r from-teal-50 to-cyan-50 border-2 border-teal-500'
                    : 'bg-gray-50 border border-gray-200 hover:bg-gray-100'
                }`}
              >
                <div className="flex items-center justify-between mb-2">
                  <span className="font-semibold text-gray-900">{vehicle.vehicle_number}</span>
                  <span className={`text-2xl font-bold ${getHealthColor(vehicle.health_score)}`}>
                    {vehicle.health_score}%
                  </span>
                </div>
                <div className="text-sm text-gray-600 mb-2">
                  {vehicle.make} {vehicle.model}
                </div>
                <div className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium border ${getStatusColor(vehicle.overall_status)}`}>
                  {vehicle.overall_status.charAt(0).toUpperCase() + vehicle.overall_status.slice(1)}
                </div>
              </button>
            ))}
          </div>
        </div>

        <div className="lg:col-span-2 space-y-6">
          {selectedVehicle && (
            <>
              <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                <div className="flex items-center justify-between mb-6">
                  <div>
                    <h3 className="text-2xl font-bold text-gray-900">{selectedVehicle.vehicle_number}</h3>
                    <p className="text-gray-600">{selectedVehicle.make} {selectedVehicle.model}</p>
                  </div>
                  <div className="text-right">
                    <div className={`text-4xl font-bold ${getHealthColor(selectedVehicle.health_score)}`}>
                      {selectedVehicle.health_score}%
                    </div>
                    <p className="text-sm text-gray-500">Overall Health</p>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="bg-gradient-to-br from-blue-50 to-blue-100 rounded-lg p-4 border border-blue-200">
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center space-x-2">
                        <Zap className="h-5 w-5 text-blue-600" />
                        <span className="text-sm font-medium text-gray-700">Engine</span>
                      </div>
                      <span className={`text-xl font-bold ${getHealthColor(selectedVehicle.engine_health)}`}>
                        {selectedVehicle.engine_health}%
                      </span>
                    </div>
                    <div className="w-full bg-white rounded-full h-2">
                      <div
                        className="bg-blue-600 h-2 rounded-full transition-all"
                        style={{ width: `${selectedVehicle.engine_health}%` }}
                      />
                    </div>
                  </div>

                  <div className="bg-gradient-to-br from-red-50 to-red-100 rounded-lg p-4 border border-red-200">
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center space-x-2">
                        <AlertCircle className="h-5 w-5 text-red-600" />
                        <span className="text-sm font-medium text-gray-700">Brakes</span>
                      </div>
                      <span className={`text-xl font-bold ${getHealthColor(selectedVehicle.brake_health)}`}>
                        {selectedVehicle.brake_health}%
                      </span>
                    </div>
                    <div className="w-full bg-white rounded-full h-2">
                      <div
                        className="bg-red-600 h-2 rounded-full transition-all"
                        style={{ width: `${selectedVehicle.brake_health}%` }}
                      />
                    </div>
                  </div>

                  <div className="bg-gradient-to-br from-green-50 to-green-100 rounded-lg p-4 border border-green-200">
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center space-x-2">
                        <Gauge className="h-5 w-5 text-green-600" />
                        <span className="text-sm font-medium text-gray-700">Transmission</span>
                      </div>
                      <span className={`text-xl font-bold ${getHealthColor(selectedVehicle.transmission_health)}`}>
                        {selectedVehicle.transmission_health}%
                      </span>
                    </div>
                    <div className="w-full bg-white rounded-full h-2">
                      <div
                        className="bg-green-600 h-2 rounded-full transition-all"
                        style={{ width: `${selectedVehicle.transmission_health}%` }}
                      />
                    </div>
                  </div>

                  <div className="bg-gradient-to-br from-amber-50 to-amber-100 rounded-lg p-4 border border-amber-200">
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center space-x-2">
                        <ThermometerSun className="h-5 w-5 text-amber-600" />
                        <span className="text-sm font-medium text-gray-700">Tires</span>
                      </div>
                      <span className={`text-xl font-bold ${getHealthColor(selectedVehicle.tire_health)}`}>
                        {selectedVehicle.tire_health}%
                      </span>
                    </div>
                    <div className="w-full bg-white rounded-full h-2">
                      <div
                        className="bg-amber-600 h-2 rounded-full transition-all"
                        style={{ width: `${selectedVehicle.tire_health}%` }}
                      />
                    </div>
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                <div className="flex items-center space-x-3 mb-4">
                  <div className="p-2 bg-teal-100 rounded-lg">
                    <Brain className="h-5 w-5 text-teal-600" />
                  </div>
                  <h3 className="text-lg font-semibold text-gray-900">AI Predictions & Recommendations</h3>
                </div>

                {selectedVehicle.predicted_issues.length > 0 ? (
                  <div className="space-y-3">
                    {selectedVehicle.predicted_issues.map((issue, index) => (
                      <div key={index} className="flex items-start space-x-3 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                        <AlertTriangle className="h-5 w-5 text-yellow-600 flex-shrink-0 mt-0.5" />
                        <div className="flex-1">
                          <p className="text-sm font-medium text-gray-900">{issue}</p>
                          <p className="text-xs text-gray-600 mt-1">Recommended action within {selectedVehicle.next_maintenance_due} miles</p>
                        </div>
                      </div>
                    ))}
                    <div className="flex items-start space-x-3 p-4 bg-green-50 border border-green-200 rounded-lg">
                      <DollarSign className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
                      <div className="flex-1">
                        <p className="text-sm font-medium text-gray-900">Potential Cost Savings</p>
                        <p className="text-xs text-gray-600 mt-1">
                          Addressing these issues proactively could save up to ${selectedVehicle.cost_savings_potential} in emergency repairs
                        </p>
                      </div>
                    </div>
                  </div>
                ) : (
                  <div className="flex items-center space-x-3 p-4 bg-green-50 border border-green-200 rounded-lg">
                    <CheckCircle className="h-6 w-6 text-green-600" />
                    <div>
                      <p className="text-sm font-medium text-gray-900">All Systems Operating Normally</p>
                      <p className="text-xs text-gray-600 mt-1">Next scheduled maintenance in {selectedVehicle.next_maintenance_due} miles</p>
                    </div>
                  </div>
                )}
              </div>

              <div className="bg-gradient-to-r from-teal-600 to-cyan-700 rounded-xl shadow-sm p-6 text-white">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center space-x-2 mb-3">
                      <Calendar className="h-5 w-5" />
                      <h3 className="text-lg font-semibold">Maintenance Schedule</h3>
                    </div>
                    <p className="text-teal-100 mb-4">
                      Based on AI analysis, optimal maintenance window is in {selectedVehicle.next_maintenance_due} miles
                    </p>
                    <button className="px-4 py-2 bg-white text-teal-600 rounded-lg font-medium hover:bg-teal-50 transition-colors">
                      Schedule Maintenance
                    </button>
                  </div>
                  <div className="text-right">
                    <div className="text-3xl font-bold">{selectedVehicle.next_maintenance_due}</div>
                    <div className="text-sm text-teal-100">miles remaining</div>
                  </div>
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default VehicleHealthAI;
