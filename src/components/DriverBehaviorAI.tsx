import React, { useEffect, useState, useCallback } from 'react';
import {
  Activity,
  AlertTriangle,
  Award,
  TrendingUp,
  TrendingDown,
  Users,
  Zap,
  AlertCircle,
  CheckCircle,
  Brain,
  Target,
  Clock,
  Gauge,
  Fuel,
  Shield,
  Play,
  Pause,
  RefreshCw
} from 'lucide-react';
import { getDriverBehaviorData } from '../api/driverBehaviorAI';

interface DriverBehavior {
  id: string;
  name: string;
  email: string;
  behavior_score: number;
  safety_rating: number;
  fuel_efficiency_rating: number;
  acceleration_score: number;
  braking_score: number;
  speed_compliance: number;
  idle_time_score: number;
  total_miles: number;
  incidents_count: number;
  risk_level: 'low' | 'medium' | 'high';
  recommendations: string[];
  improvement_trend: 'improving' | 'stable' | 'declining';
}

const DriverBehaviorAI: React.FC = () => {
  const [drivers, setDrivers] = useState<DriverBehavior[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedDriver, setSelectedDriver] = useState<DriverBehavior | null>(null);
  const [sortBy, setSortBy] = useState<'score' | 'safety' | 'fuel'>('score');
  const [simulationActive, setSimulationActive] = useState(false);
  const [simulationInterval, setSimulationInterval] = useState<number | null>(null);

  useEffect(() => {
    loadDriverBehavior();
  }, []);

  useEffect(() => {
    return () => {
      if (simulationInterval) {
        clearInterval(simulationInterval);
      }
    };
  }, [simulationInterval]);

  const loadDriverBehavior = useCallback(async () => {
    try {
      setLoading(true);
      const data = await getDriverBehaviorData();
      const mappedData = data.map(d => ({
        id: d.driver_id,
        name: d.name,
        email: d.email,
        behavior_score: d.behavior_score,
        safety_rating: d.safety_rating,
        fuel_efficiency_rating: d.fuel_efficiency_rating,
        acceleration_score: d.acceleration_score,
        braking_score: d.braking_score,
        speed_compliance: d.speed_compliance,
        idle_time_score: d.idle_time_score,
        total_miles: d.total_miles,
        incidents_count: d.incidents_count,
        risk_level: d.risk_level,
        recommendations: d.recommendations,
        improvement_trend: d.improvement_trend
      }));
      setDrivers(mappedData);
      if (mappedData.length > 0 && !selectedDriver) {
        setSelectedDriver(mappedData[0]);
      }
    } catch (error) {
      console.error('Failed to load driver behavior data:', error);
    } finally {
      setLoading(false);
    }
  }, [selectedDriver]);

  const toggleSimulation = async () => {
    if (simulationActive) {
      if (simulationInterval) {
        clearInterval(simulationInterval);
        setSimulationInterval(null);
      }
      setSimulationActive(false);
    } else {
      await simulateBehaviorData();
      const interval = window.setInterval(async () => {
        await simulateBehaviorData();
      }, 15000);
      setSimulationInterval(interval);
      setSimulationActive(true);
    }
  };

  const simulateBehaviorData = async () => {
    try {
      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/driver-behavior-ai?action=simulate`,
        {
          headers: {
            Authorization: `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
            'Content-Type': 'application/json',
          },
        }
      );
      if (response.ok) {
        await loadDriverBehavior();
      }
    } catch (error) {
      console.error('Failed to simulate behavior data:', error);
    }
  };

  const sortedDrivers = [...drivers].sort((a, b) => {
    if (sortBy === 'score') return b.behavior_score - a.behavior_score;
    if (sortBy === 'safety') return b.safety_rating - a.safety_rating;
    if (sortBy === 'fuel') return b.fuel_efficiency_rating - a.fuel_efficiency_rating;
    return 0;
  });

  const getScoreColor = (score: number) => {
    if (score >= 90) return 'text-green-600';
    if (score >= 75) return 'text-blue-600';
    if (score >= 60) return 'text-yellow-600';
    return 'text-red-600';
  };

  const getScoreBg = (score: number) => {
    if (score >= 90) return 'bg-green-100';
    if (score >= 75) return 'bg-blue-100';
    if (score >= 60) return 'bg-yellow-100';
    return 'bg-red-100';
  };

  const getRiskColor = (risk: string) => {
    switch (risk) {
      case 'low':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'medium':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'high':
        return 'bg-red-100 text-red-800 border-red-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'improving':
        return <TrendingUp className="h-4 w-4 text-green-600" />;
      case 'declining':
        return <TrendingDown className="h-4 w-4 text-red-600" />;
      default:
        return <Activity className="h-4 w-4 text-blue-600" />;
    }
  };

  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-emerald-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-gray-600">Analyzing driver behavior patterns...</p>
        </div>
      </div>
    );
  }

  const fleetStats = {
    avgBehaviorScore: Math.round(drivers.reduce((sum, d) => sum + d.behavior_score, 0) / drivers.length),
    avgSafetyRating: Math.round(drivers.reduce((sum, d) => sum + d.safety_rating, 0) / drivers.length),
    highRiskDrivers: drivers.filter(d => d.risk_level === 'high').length,
    topPerformers: drivers.filter(d => d.behavior_score >= 90).length
  };

  return (
    <div className="p-6 space-y-6 bg-gray-50 min-h-screen">
      <div className="bg-gradient-to-r from-emerald-600 to-green-700 rounded-xl p-6 text-white shadow-lg">
        <div className="flex items-center justify-between">
          <div>
            <div className="flex items-center space-x-3 mb-2">
              <div className="p-2 bg-white/20 rounded-lg backdrop-blur-sm">
                <Brain className="h-8 w-8" />
              </div>
              <h1 className="text-3xl font-bold">Driver Behavior AI</h1>
            </div>
            <p className="text-emerald-100">AI-powered driver analytics and performance optimization</p>
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
              onClick={loadDriverBehavior}
              className="flex items-center space-x-2 px-4 py-2 bg-white/20 backdrop-blur-sm rounded-lg hover:bg-white/30 transition-colors"
            >
              <RefreshCw className="h-4 w-4" />
              <span>Refresh</span>
            </button>
            <div className="flex items-center space-x-2 px-4 py-2 bg-white/20 backdrop-blur-sm rounded-xl">
              <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
              <span className="text-sm font-medium">Live Analysis</span>
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-all">
          <div className="flex items-center justify-between mb-4">
            <div className={`p-3 rounded-xl ${getScoreBg(fleetStats.avgBehaviorScore)}`}>
              <Target className={`h-6 w-6 ${getScoreColor(fleetStats.avgBehaviorScore)}`} />
            </div>
            <span className={`text-3xl font-bold ${getScoreColor(fleetStats.avgBehaviorScore)}`}>
              {fleetStats.avgBehaviorScore}%
            </span>
          </div>
          <h3 className="text-sm font-medium text-gray-600">Avg Behavior Score</h3>
          <p className="text-xs text-gray-500 mt-1">Fleet-wide average</p>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-all">
          <div className="flex items-center justify-between mb-4">
            <div className={`p-3 rounded-xl ${getScoreBg(fleetStats.avgSafetyRating)}`}>
              <Shield className={`h-6 w-6 ${getScoreColor(fleetStats.avgSafetyRating)}`} />
            </div>
            <span className={`text-3xl font-bold ${getScoreColor(fleetStats.avgSafetyRating)}`}>
              {fleetStats.avgSafetyRating}%
            </span>
          </div>
          <h3 className="text-sm font-medium text-gray-600">Safety Rating</h3>
          <p className="text-xs text-gray-500 mt-1">Average safety score</p>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-all">
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 rounded-xl bg-green-100">
              <Award className="h-6 w-6 text-green-600" />
            </div>
            <span className="text-3xl font-bold text-green-600">{fleetStats.topPerformers}</span>
          </div>
          <h3 className="text-sm font-medium text-gray-600">Top Performers</h3>
          <p className="text-xs text-gray-500 mt-1">Drivers scoring 90%+</p>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-all">
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 rounded-xl bg-red-100">
              <AlertCircle className="h-6 w-6 text-red-600" />
            </div>
            <span className="text-3xl font-bold text-red-600">{fleetStats.highRiskDrivers}</span>
          </div>
          <h3 className="text-sm font-medium text-gray-600">High Risk</h3>
          <p className="text-xs text-gray-500 mt-1">Require immediate attention</p>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-semibold text-gray-900 flex items-center">
            <Users className="h-5 w-5 mr-2 text-emerald-600" />
            Driver Leaderboard
          </h3>
          <div className="flex items-center space-x-2">
            <span className="text-sm text-gray-600">Sort by:</span>
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value as 'score' | 'safety' | 'fuel')}
              className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
            >
              <option value="score">Behavior Score</option>
              <option value="safety">Safety Rating</option>
              <option value="fuel">Fuel Efficiency</option>
            </select>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {sortedDrivers.map((driver, index) => (
            <button
              key={driver.id}
              onClick={() => setSelectedDriver(driver)}
              className={`text-left p-4 rounded-lg transition-all border-2 ${
                selectedDriver?.id === driver.id
                  ? 'bg-gradient-to-r from-emerald-50 to-green-50 border-emerald-500'
                  : 'bg-gray-50 border-gray-200 hover:bg-gray-100'
              }`}
            >
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center space-x-3">
                  <div className={`w-10 h-10 rounded-full ${getScoreBg(driver.behavior_score)} flex items-center justify-center font-bold ${getScoreColor(driver.behavior_score)}`}>
                    #{index + 1}
                  </div>
                  <div>
                    <div className="font-semibold text-gray-900">{driver.name}</div>
                    <div className="text-xs text-gray-500">{driver.total_miles.toLocaleString()} miles</div>
                  </div>
                </div>
                <div className="text-right">
                  <div className={`text-2xl font-bold ${getScoreColor(driver.behavior_score)}`}>
                    {driver.behavior_score}%
                  </div>
                  <div className="flex items-center justify-end space-x-1 mt-1">
                    {getTrendIcon(driver.improvement_trend)}
                  </div>
                </div>
              </div>
              <div className="flex items-center justify-between">
                <div className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium border ${getRiskColor(driver.risk_level)}`}>
                  {driver.risk_level.toUpperCase()} RISK
                </div>
                <div className="text-xs text-gray-600">
                  {driver.incidents_count} {driver.incidents_count === 1 ? 'incident' : 'incidents'}
                </div>
              </div>
            </button>
          ))}
        </div>
      </div>

      {selectedDriver && (
        <div className="space-y-6">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div className="flex items-center justify-between mb-6">
              <div>
                <h3 className="text-2xl font-bold text-gray-900">{selectedDriver.name}</h3>
                <p className="text-gray-600">{selectedDriver.email}</p>
              </div>
              <div className="text-right">
                <div className={`text-4xl font-bold ${getScoreColor(selectedDriver.behavior_score)}`}>
                  {selectedDriver.behavior_score}%
                </div>
                <p className="text-sm text-gray-500">Behavior Score</p>
              </div>
            </div>

            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
              <div className="bg-gradient-to-br from-blue-50 to-blue-100 rounded-lg p-4 border border-blue-200">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center space-x-2">
                    <Shield className="h-5 w-5 text-blue-600" />
                    <span className="text-sm font-medium text-gray-700">Safety</span>
                  </div>
                  <span className={`text-xl font-bold ${getScoreColor(selectedDriver.safety_rating)}`}>
                    {selectedDriver.safety_rating}%
                  </span>
                </div>
                <div className="w-full bg-white rounded-full h-2">
                  <div
                    className="bg-blue-600 h-2 rounded-full transition-all"
                    style={{ width: `${selectedDriver.safety_rating}%` }}
                  />
                </div>
              </div>

              <div className="bg-gradient-to-br from-green-50 to-green-100 rounded-lg p-4 border border-green-200">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center space-x-2">
                    <Fuel className="h-5 w-5 text-green-600" />
                    <span className="text-sm font-medium text-gray-700">Fuel Efficiency</span>
                  </div>
                  <span className={`text-xl font-bold ${getScoreColor(selectedDriver.fuel_efficiency_rating)}`}>
                    {selectedDriver.fuel_efficiency_rating}%
                  </span>
                </div>
                <div className="w-full bg-white rounded-full h-2">
                  <div
                    className="bg-green-600 h-2 rounded-full transition-all"
                    style={{ width: `${selectedDriver.fuel_efficiency_rating}%` }}
                  />
                </div>
              </div>

              <div className="bg-gradient-to-br from-amber-50 to-amber-100 rounded-lg p-4 border border-amber-200">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center space-x-2">
                    <Zap className="h-5 w-5 text-amber-600" />
                    <span className="text-sm font-medium text-gray-700">Acceleration</span>
                  </div>
                  <span className={`text-xl font-bold ${getScoreColor(selectedDriver.acceleration_score)}`}>
                    {selectedDriver.acceleration_score}%
                  </span>
                </div>
                <div className="w-full bg-white rounded-full h-2">
                  <div
                    className="bg-amber-600 h-2 rounded-full transition-all"
                    style={{ width: `${selectedDriver.acceleration_score}%` }}
                  />
                </div>
              </div>

              <div className="bg-gradient-to-br from-red-50 to-red-100 rounded-lg p-4 border border-red-200">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center space-x-2">
                    <AlertCircle className="h-5 w-5 text-red-600" />
                    <span className="text-sm font-medium text-gray-700">Braking</span>
                  </div>
                  <span className={`text-xl font-bold ${getScoreColor(selectedDriver.braking_score)}`}>
                    {selectedDriver.braking_score}%
                  </span>
                </div>
                <div className="w-full bg-white rounded-full h-2">
                  <div
                    className="bg-red-600 h-2 rounded-full transition-all"
                    style={{ width: `${selectedDriver.braking_score}%` }}
                  />
                </div>
              </div>

              <div className="bg-gradient-to-br from-teal-50 to-teal-100 rounded-lg p-4 border border-teal-200">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center space-x-2">
                    <Gauge className="h-5 w-5 text-teal-600" />
                    <span className="text-sm font-medium text-gray-700">Speed Compliance</span>
                  </div>
                  <span className={`text-xl font-bold ${getScoreColor(selectedDriver.speed_compliance)}`}>
                    {selectedDriver.speed_compliance}%
                  </span>
                </div>
                <div className="w-full bg-white rounded-full h-2">
                  <div
                    className="bg-teal-600 h-2 rounded-full transition-all"
                    style={{ width: `${selectedDriver.speed_compliance}%` }}
                  />
                </div>
              </div>

              <div className="bg-gradient-to-br from-orange-50 to-orange-100 rounded-lg p-4 border border-orange-200">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center space-x-2">
                    <Clock className="h-5 w-5 text-orange-600" />
                    <span className="text-sm font-medium text-gray-700">Idle Time</span>
                  </div>
                  <span className={`text-xl font-bold ${getScoreColor(selectedDriver.idle_time_score)}`}>
                    {selectedDriver.idle_time_score}%
                  </span>
                </div>
                <div className="w-full bg-white rounded-full h-2">
                  <div
                    className="bg-orange-600 h-2 rounded-full transition-all"
                    style={{ width: `${selectedDriver.idle_time_score}%` }}
                  />
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div className="flex items-center space-x-3 mb-4">
              <div className="p-2 bg-emerald-100 rounded-lg">
                <Brain className="h-5 w-5 text-emerald-600" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900">AI-Powered Coaching Recommendations</h3>
            </div>

            <div className="space-y-3">
              {selectedDriver.recommendations.map((recommendation, index) => {
                const isUrgent = recommendation.toUpperCase().includes('URGENT');
                const isExcellent = recommendation.toLowerCase().includes('excellent');

                return (
                  <div
                    key={index}
                    className={`flex items-start space-x-3 p-4 rounded-lg border ${
                      isUrgent
                        ? 'bg-red-50 border-red-200'
                        : isExcellent
                        ? 'bg-green-50 border-green-200'
                        : 'bg-blue-50 border-blue-200'
                    }`}
                  >
                    {isUrgent ? (
                      <AlertTriangle className="h-5 w-5 text-red-600 flex-shrink-0 mt-0.5" />
                    ) : isExcellent ? (
                      <CheckCircle className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
                    ) : (
                      <Target className="h-5 w-5 text-blue-600 flex-shrink-0 mt-0.5" />
                    )}
                    <p className="text-sm font-medium text-gray-900">{recommendation}</p>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="bg-gradient-to-r from-emerald-600 to-green-700 rounded-xl shadow-sm p-6 text-white">
            <div className="flex items-start justify-between">
              <div className="flex-1">
                <div className="flex items-center space-x-2 mb-3">
                  <Award className="h-5 w-5" />
                  <h3 className="text-lg font-semibold">Performance Summary</h3>
                </div>
                <p className="text-emerald-100 mb-4">
                  {selectedDriver.behavior_score >= 90
                    ? 'Outstanding performance! Continue these excellent driving habits.'
                    : selectedDriver.behavior_score >= 75
                    ? 'Good performance with room for improvement in key areas.'
                    : 'Requires immediate attention and training to improve safety and efficiency.'}
                </p>
                <div className="flex space-x-3">
                  <button className="px-4 py-2 bg-white text-emerald-600 rounded-lg font-medium hover:bg-emerald-50 transition-colors">
                    Schedule Training
                  </button>
                  <button className="px-4 py-2 bg-emerald-500 text-white rounded-lg font-medium hover:bg-emerald-400 transition-colors">
                    View Full Report
                  </button>
                </div>
              </div>
              <div className="text-right">
                <div className={`inline-flex items-center px-4 py-2 rounded-full text-sm font-medium border-2 ${
                  selectedDriver.risk_level === 'low'
                    ? 'bg-white/20 border-white/40'
                    : selectedDriver.risk_level === 'medium'
                    ? 'bg-yellow-500/20 border-yellow-400/40'
                    : 'bg-red-500/20 border-red-400/40'
                }`}>
                  {selectedDriver.risk_level.toUpperCase()} RISK
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default DriverBehaviorAI;
