import React, { useState, useEffect, useCallback } from 'react';
import {
  Fuel,
  TrendingUp,
  TrendingDown,
  MapPin,
  DollarSign,
  Route,
  Zap,
  RefreshCw,
  Play,
  Pause
} from 'lucide-react';
import {
  getFuelStats,
  getDriverFuelPerformance,
  getOptimizedRoutesFuelData,
  FuelStats,
  DriverFuelPerformance
} from '../api/fuel';

const FuelOptimization: React.FC = () => {
  const [selectedTimeframe, setSelectedTimeframe] = useState<'day' | 'week' | 'month' | 'quarter' | 'year'>('week');
  const [loading, setLoading] = useState(true);
  const [fuelStats, setFuelStats] = useState<FuelStats | null>(null);
  const [topPerformers, setTopPerformers] = useState<DriverFuelPerformance[]>([]);
  const [optimizedRoutes, setOptimizedRoutes] = useState<any[]>([]);
  const [simulationActive, setSimulationActive] = useState(false);
  const [simulationInterval, setSimulationInterval] = useState<number | null>(null);

  useEffect(() => {
    loadFuelData();
  }, [selectedTimeframe]);

  useEffect(() => {
    return () => {
      if (simulationInterval) {
        clearInterval(simulationInterval);
      }
    };
  }, [simulationInterval]);

  const loadFuelData = useCallback(async () => {
    try {
      setLoading(true);
      const [stats, performers, routes] = await Promise.all([
        getFuelStats(selectedTimeframe),
        getDriverFuelPerformance(5),
        getOptimizedRoutesFuelData()
      ]);

      setFuelStats(stats);
      setTopPerformers(performers);
      setOptimizedRoutes(routes);
    } catch (error) {
      console.error('Failed to load fuel data:', error);
    } finally {
      setLoading(false);
    }
  }, [selectedTimeframe]);

  const toggleSimulation = async () => {
    if (simulationActive) {
      if (simulationInterval) {
        clearInterval(simulationInterval);
        setSimulationInterval(null);
      }
      setSimulationActive(false);
    } else {
      await simulateFuelData();
      const interval = window.setInterval(async () => {
        await simulateFuelData();
      }, 20000);
      setSimulationInterval(interval);
      setSimulationActive(true);
    }
  };

  const simulateFuelData = async () => {
    try {
      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/fuel-optimization?action=simulate`,
        {
          headers: {
            Authorization: `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
            'Content-Type': 'application/json',
          },
        }
      );
      if (response.ok) {
        await loadFuelData();
      }
    } catch (error) {
      console.error('Failed to simulate fuel data:', error);
    }
  };

  const fuelStatsDisplay = [
    {
      name: 'Total Fuel Cost',
      value: fuelStats ? `$${fuelStats.totalCost.toLocaleString()}` : '$0',
      change: fuelStats ? `${fuelStats.costChange > 0 ? '+' : ''}${fuelStats.costChange}%` : '0%',
      changeType: (fuelStats?.costChange || 0) < 0 ? 'decrease' : 'increase',
      icon: DollarSign,
      color: (fuelStats?.costChange || 0) < 0 ? 'text-green-600' : 'text-red-600',
      bgColor: (fuelStats?.costChange || 0) < 0 ? 'bg-green-100' : 'bg-red-100',
    },
    {
      name: 'Average MPG',
      value: fuelStats ? fuelStats.averageMPG.toFixed(1) : '0.0',
      change: fuelStats ? `${fuelStats.mpgChange > 0 ? '+' : ''}${fuelStats.mpgChange.toFixed(1)}` : '0',
      changeType: 'increase',
      icon: Fuel,
      color: 'text-blue-600',
      bgColor: 'bg-blue-100',
    },
    {
      name: 'Fuel Efficiency',
      value: fuelStats ? `${fuelStats.fuelEfficiency.toFixed(1)}%` : '0%',
      change: fuelStats ? `${fuelStats.efficiencyChange > 0 ? '+' : ''}${fuelStats.efficiencyChange.toFixed(1)}%` : '0%',
      changeType: 'increase',
      icon: TrendingUp,
      color: 'text-blue-600',
      bgColor: 'bg-blue-100',
    },
    {
      name: 'CO2 Reduction',
      value: fuelStats ? `${fuelStats.co2Reduction.toFixed(1)}%` : '0%',
      change: '+3.2%',
      changeType: 'increase',
      icon: Zap,
      color: 'text-blue-700',
      bgColor: 'bg-blue-50',
    },
  ];

  const fuelStations = [
    {
      name: 'Shell Station',
      location: '123 Highway Blvd',
      price: '$3.45/gal',
      distance: '2.3 miles',
      discount: '5¢ fleet discount',
    },
    {
      name: 'BP Truck Stop',
      location: '456 Interstate Dr',
      price: '$3.42/gal',
      distance: '4.1 miles',
      discount: '3¢ fleet discount',
    },
    {
      name: 'Pilot Travel Center',
      location: '789 Route 95',
      price: '$3.48/gal',
      distance: '1.8 miles',
      discount: '7¢ fleet discount',
    },
  ];

  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-gray-600">Loading fuel optimization data...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Fuel Optimization</h1>
          <p className="text-gray-600">AI-powered fuel management and route optimization</p>
        </div>
        <div className="flex items-center space-x-3">
          <button
            onClick={toggleSimulation}
            className={`flex items-center space-x-2 px-4 py-2 rounded-lg transition-colors ${
              simulationActive
                ? 'bg-red-500 hover:bg-red-600 text-white'
                : 'bg-green-500 hover:bg-green-600 text-white'
            }`}
          >
            {simulationActive ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4" />}
            <span>{simulationActive ? 'Stop' : 'Start'} Simulation</span>
          </button>
          <button
            onClick={loadFuelData}
            className="flex items-center space-x-2 px-4 py-2 bg-blue-100 text-blue-600 rounded-lg hover:bg-blue-200 transition-colors"
          >
            <RefreshCw className="h-4 w-4" />
            <span>Refresh</span>
          </button>
          <select
            value={selectedTimeframe}
            onChange={(e) => setSelectedTimeframe(e.target.value as any)}
            className="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="day">Today</option>
            <option value="week">This Week</option>
            <option value="month">This Month</option>
            <option value="quarter">This Quarter</option>
            <option value="year">This Year</option>
          </select>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {fuelStatsDisplay.map((stat) => {
          const Icon = stat.icon;
          const isNegativeGood = stat.name === 'Total Fuel Cost';
          const showGreen = isNegativeGood
            ? stat.changeType === 'decrease'
            : stat.changeType === 'increase';

          return (
            <div key={stat.name} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">{stat.name}</p>
                  <p className="text-2xl font-semibold text-gray-900">{stat.value}</p>
                </div>
                <div className={`p-3 rounded-full ${stat.bgColor}`}>
                  <Icon className={`h-6 w-6 ${stat.color}`} />
                </div>
              </div>
              <div className="mt-4 flex items-center">
                {showGreen ? (
                  <TrendingUp className="h-4 w-4 text-green-500 mr-1" />
                ) : (
                  <TrendingDown className="h-4 w-4 text-green-500 mr-1" />
                )}
                <span className="text-sm font-medium text-green-600">
                  {stat.change}
                </span>
                <span className="text-sm text-gray-500 ml-1">vs last {selectedTimeframe}</span>
              </div>
            </div>
          );
        })}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="p-6 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-medium text-gray-900">Route Optimizations</h3>
            </div>
          </div>
          <div className="p-6 space-y-4">
            {optimizedRoutes.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                <p>No optimized routes yet</p>
                <p className="text-sm mt-2">Create routes to see fuel savings</p>
              </div>
            ) : (
              optimizedRoutes.slice(0, 3).map((route) => (
                <div key={route.id} className="border border-gray-200 rounded-lg p-4">
                  <div className="flex items-center justify-between mb-3">
                    <h4 className="font-medium text-gray-900">{route.name}</h4>
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                      route.status === 'active' || route.status === 'completed'
                        ? 'bg-green-100 text-green-800'
                        : 'bg-yellow-100 text-yellow-800'
                    }`}>
                      {route.status}
                    </span>
                  </div>
                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <p className="text-gray-500">Distance Saved</p>
                      <p className="font-medium">{route.originalDistance - route.optimizedDistance} miles</p>
                    </div>
                    <div>
                      <p className="text-gray-500">Fuel Savings</p>
                      <p className="font-medium text-green-600">${route.fuelSavings}</p>
                    </div>
                    <div>
                      <p className="text-gray-500">Time Saved</p>
                      <p className="font-medium">{route.timeSavings} min</p>
                    </div>
                    <div>
                      <p className="text-gray-500">New Distance</p>
                      <p className="font-medium">{route.optimizedDistance} miles</p>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-lg font-medium text-gray-900">Top Fuel Performers</h3>
          </div>
          <div className="p-6 space-y-4">
            {topPerformers.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                <p>No fuel data yet</p>
                <p className="text-sm mt-2">Start simulation to generate data</p>
              </div>
            ) : (
              topPerformers.map((performer, index) => (
                <div key={performer.driver_id} className="flex items-center justify-between p-3 rounded-lg hover:bg-gray-50">
                  <div className="flex items-center space-x-3">
                    <div className="flex-shrink-0">
                      <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                        <span className="text-sm font-medium text-blue-600">#{index + 1}</span>
                      </div>
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-900">{performer.driver_name}</p>
                      <p className="text-xs text-gray-500">{performer.vehicle_number || 'N/A'}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-medium text-gray-900">{performer.averageMPG} MPG</p>
                    <p className="text-xs text-green-600">${performer.fuelSavings} saved</p>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-medium text-gray-900">Fuel Station Network</h3>
            <span className="text-xs text-gray-500 bg-yellow-50 px-2 py-1 rounded">Sample Data</span>
          </div>
        </div>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {fuelStations.map((station, index) => (
              <div key={index} className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow">
                <div className="flex items-center justify-between mb-2">
                  <h4 className="font-medium text-gray-900">{station.name}</h4>
                  <span className="text-lg font-bold text-green-600">{station.price}</span>
                </div>
                <div className="space-y-1 text-sm text-gray-600">
                  <div className="flex items-center">
                    <MapPin className="h-4 w-4 mr-1" />
                    {station.location}
                  </div>
                  <div className="flex items-center">
                    <Route className="h-4 w-4 mr-1" />
                    {station.distance} away
                  </div>
                  <div className="flex items-center">
                    <DollarSign className="h-4 w-4 mr-1" />
                    {station.discount}
                  </div>
                </div>
                <button className="w-full mt-3 px-3 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 transition-colors">
                  View Details
                </button>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default FuelOptimization;
