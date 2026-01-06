import React, { useState, useEffect, useCallback } from 'react';
import {
  Route as RouteIcon,
  MapPin,
  Plus,
  Trash2,
  Navigation,
  TrendingUp,
  Clock,
  Fuel,
  Save,
  Play,
  CheckCircle,
  AlertCircle,
  RefreshCw,
  Pause,
} from 'lucide-react';
import { getRoutes, createRoute, getRouteWaypoints, createWaypoint, optimizeRoute } from '../api/routes';
import { Route, RouteWaypoint } from '../types/tracking';
import { useAuth } from '../contexts/AuthContext';

const RouteOptimization: React.FC = () => {
  const { profile, loading: authLoading } = useAuth();
  const [routes, setRoutes] = useState<Route[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [newRouteName, setNewRouteName] = useState('');
  const [newRouteDescription, setNewRouteDescription] = useState('');
  const [waypoints, setWaypoints] = useState<Array<{ name: string; address: string; lat: number; lng: number }>>([
    { name: '', address: '', lat: 0, lng: 0 },
  ]);
  const [optimizing, setOptimizing] = useState(false);
  const [optimizationResult, setOptimizationResult] = useState<any>(null);
  const [simulationActive, setSimulationActive] = useState(false);
  const [simulationInterval, setSimulationInterval] = useState<number | null>(null);

  useEffect(() => {
    loadRoutes();
  }, []);

  useEffect(() => {
    return () => {
      if (simulationInterval) {
        clearInterval(simulationInterval);
      }
    };
  }, [simulationInterval]);

  const loadRoutes = useCallback(async () => {
    try {
      setLoading(true);
      const data = await getRoutes();
      setRoutes(data);
    } catch (error) {
      console.error('Failed to load routes:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  const toggleSimulation = async () => {
    if (simulationActive) {
      if (simulationInterval) {
        clearInterval(simulationInterval);
        setSimulationInterval(null);
      }
      setSimulationActive(false);
    } else {
      await generateSampleRoutes();
      const interval = window.setInterval(async () => {
        await generateSampleRoutes();
      }, 30000);
      setSimulationInterval(interval);
      setSimulationActive(true);
    }
  };

  const generateSampleRoutes = async () => {
    try {
      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/route-optimization?action=generate-sample`,
        {
          headers: {
            Authorization: `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
            'Content-Type': 'application/json',
          },
        }
      );
      if (response.ok) {
        await loadRoutes();
      }
    } catch (error) {
      console.error('Failed to generate sample routes:', error);
    }
  };

  const addWaypoint = () => {
    setWaypoints([...waypoints, { name: '', address: '', lat: 0, lng: 0 }]);
  };

  const removeWaypoint = (index: number) => {
    if (waypoints.length > 1) {
      setWaypoints(waypoints.filter((_, i) => i !== index));
    }
  };

  const updateWaypoint = (index: number, field: string, value: string | number) => {
    const updated = [...waypoints];
    updated[index] = { ...updated[index], [field]: value };
    setWaypoints(updated);
  };

  const handleOptimizeRoute = async () => {
    const validWaypoints = waypoints.filter((wp) => wp.name && wp.lat && wp.lng);
    if (validWaypoints.length < 2) {
      alert('Please add at least 2 valid waypoints to optimize');
      return;
    }

    try {
      setOptimizing(true);
      const result = await optimizeRoute(validWaypoints);
      setOptimizationResult(result);
    } catch (error) {
      console.error('Optimization failed:', error);
      alert('Failed to optimize route');
    } finally {
      setOptimizing(false);
    }
  };

  const handleSaveRoute = async () => {
    if (!newRouteName.trim()) {
      alert('Please enter a route name');
      return;
    }

    if (authLoading) {
      alert('Please wait for authentication to complete');
      return;
    }

    if (!profile?.organization_id) {
      alert('Organization ID is missing. Please contact support or try refreshing the page.');
      return;
    }

    if (!optimizationResult) {
      alert('Please optimize the route first');
      return;
    }

    try {
      const route = await createRoute({
        name: newRouteName,
        description: newRouteDescription,
        status: 'planned',
        organization_id: profile?.organization_id,
        optimization_score: optimizationResult.optimizationScore,
        estimated_distance: optimizationResult.totalDistance,
        estimated_duration: optimizationResult.estimatedDuration,
      });

      for (const wp of optimizationResult.optimizedWaypoints) {
        await createWaypoint({
          route_id: route.id,
          sequence_number: wp.sequence,
          name: wp.name,
          address: '',
          latitude: wp.lat,
          longitude: wp.lng,
          status: 'pending',
        });
      }

      alert('Route created successfully!');
      setShowCreateModal(false);
      resetForm();
      loadRoutes();
    } catch (error) {
      console.error('Failed to save route:', error);
      alert('Failed to save route');
    }
  };

  const resetForm = () => {
    setNewRouteName('');
    setNewRouteDescription('');
    setWaypoints([{ name: '', address: '', lat: 0, lng: 0 }]);
    setOptimizationResult(null);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'in_progress':
        return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'cancelled':
        return 'bg-red-100 text-red-800 border-red-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Route Optimization</h1>
          <p className="text-gray-600">Create and optimize efficient delivery routes</p>
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
            onClick={loadRoutes}
            className="flex items-center space-x-2 px-4 py-2 bg-blue-100 text-blue-600 rounded-lg hover:bg-blue-200 transition-colors"
          >
            <RefreshCw className="h-4 w-4" />
            <span>Refresh</span>
          </button>
          <button
            onClick={() => setShowCreateModal(true)}
            className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <Plus className="h-4 w-4" />
            <span>Create Route</span>
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg p-6 text-white shadow-lg">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-blue-100 text-sm font-medium">Total Routes</p>
              <p className="text-3xl font-bold mt-1">{routes.length}</p>
            </div>
            <div className="p-3 bg-white/20 rounded-lg">
              <RouteIcon className="h-8 w-8" />
            </div>
          </div>
        </div>

        <div className="bg-gradient-to-br from-green-500 to-emerald-600 rounded-lg p-6 text-white shadow-lg">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-green-100 text-sm font-medium">Active Routes</p>
              <p className="text-3xl font-bold mt-1">
                {routes.filter((r) => r.status === 'in_progress').length}
              </p>
            </div>
            <div className="p-3 bg-white/20 rounded-lg">
              <Navigation className="h-8 w-8" />
            </div>
          </div>
        </div>

        <div className="bg-gradient-to-br from-amber-500 to-orange-600 rounded-lg p-6 text-white shadow-lg">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-amber-100 text-sm font-medium">Avg Optimization</p>
              <p className="text-3xl font-bold mt-1">
                {routes.length > 0
                  ? Math.round(
                      routes.reduce((acc, r) => acc + (r.optimization_score || 0), 0) / routes.length
                    )
                  : 0}
                %
              </p>
            </div>
            <div className="p-3 bg-white/20 rounded-lg">
              <TrendingUp className="h-8 w-8" />
            </div>
          </div>
        </div>

        <div className="bg-gradient-to-br from-red-500 to-rose-600 rounded-lg p-6 text-white shadow-lg">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-red-100 text-sm font-medium">Completed</p>
              <p className="text-3xl font-bold mt-1">
                {routes.filter((r) => r.status === 'completed').length}
              </p>
            </div>
            <div className="p-3 bg-white/20 rounded-lg">
              <CheckCircle className="h-8 w-8" />
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Recent Routes</h3>
        </div>
        <div className="p-6">
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
            </div>
          ) : routes.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-gray-500">
              <AlertCircle className="h-12 w-12 mb-2" />
              <p>No routes created yet</p>
              <button
                onClick={() => setShowCreateModal(true)}
                className="mt-4 text-blue-600 hover:text-blue-700 font-medium"
              >
                Create your first route
              </button>
            </div>
          ) : (
            <div className="space-y-4">
              {routes.map((route) => (
                <div
                  key={route.id}
                  className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center space-x-3">
                        <h4 className="text-lg font-semibold text-gray-900">{route.name}</h4>
                        <span
                          className={`inline-flex items-center px-2.5 py-0.5 rounded-lg text-xs font-medium border ${getStatusColor(
                            route.status
                          )}`}
                        >
                          {route.status.replace('_', ' ')}
                        </span>
                      </div>
                      {route.description && (
                        <p className="text-sm text-gray-600 mt-1">{route.description}</p>
                      )}
                      <div className="flex items-center space-x-6 mt-3 text-sm text-gray-700">
                        {route.estimated_distance && (
                          <div className="flex items-center space-x-1">
                            <MapPin className="h-4 w-4 text-blue-600" />
                            <span>{route.estimated_distance.toFixed(1)} mi</span>
                          </div>
                        )}
                        {route.estimated_duration && (
                          <div className="flex items-center space-x-1">
                            <Clock className="h-4 w-4 text-gray-600" />
                            <span>{Math.round(route.estimated_duration)} min</span>
                          </div>
                        )}
                        {route.optimization_score && (
                          <div className="flex items-center space-x-1">
                            <TrendingUp className="h-4 w-4 text-green-600" />
                            <span>{route.optimization_score.toFixed(1)}% optimized</span>
                          </div>
                        )}
                        {route.fuel_estimate && (
                          <div className="flex items-center space-x-1">
                            <Fuel className="h-4 w-4 text-amber-600" />
                            <span>{route.fuel_estimate.toFixed(1)} gal</span>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {showCreateModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-gray-200">
              <h2 className="text-xl font-bold text-gray-900">Create Optimized Route</h2>
            </div>

            <div className="p-6 space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Route Name
                  </label>
                  <input
                    type="text"
                    value={newRouteName}
                    onChange={(e) => setNewRouteName(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                    placeholder="Morning Deliveries"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Description
                  </label>
                  <input
                    type="text"
                    value={newRouteDescription}
                    onChange={(e) => setNewRouteDescription(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                    placeholder="Downtown area deliveries"
                  />
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between mb-3">
                  <label className="block text-sm font-medium text-gray-700">Waypoints</label>
                  <button
                    onClick={addWaypoint}
                    className="flex items-center space-x-1 text-sm text-blue-600 hover:text-blue-700"
                  >
                    <Plus className="h-4 w-4" />
                    <span>Add Waypoint</span>
                  </button>
                </div>

                <div className="space-y-3">
                  {waypoints.map((waypoint, index) => (
                    <div
                      key={index}
                      className="grid grid-cols-1 md:grid-cols-5 gap-3 p-3 border border-gray-200 rounded-lg"
                    >
                      <input
                        type="text"
                        value={waypoint.name}
                        onChange={(e) => updateWaypoint(index, 'name', e.target.value)}
                        className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
                        placeholder="Stop name"
                      />
                      <input
                        type="text"
                        value={waypoint.address}
                        onChange={(e) => updateWaypoint(index, 'address', e.target.value)}
                        className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
                        placeholder="Address"
                      />
                      <input
                        type="number"
                        step="0.000001"
                        value={waypoint.lat}
                        onChange={(e) => updateWaypoint(index, 'lat', parseFloat(e.target.value) || 0)}
                        className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
                        placeholder="Latitude"
                      />
                      <input
                        type="number"
                        step="0.000001"
                        value={waypoint.lng}
                        onChange={(e) => updateWaypoint(index, 'lng', parseFloat(e.target.value) || 0)}
                        className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
                        placeholder="Longitude"
                      />
                      <button
                        onClick={() => removeWaypoint(index)}
                        className="flex items-center justify-center p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                  ))}
                </div>
              </div>

              {optimizationResult && (
                <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                  <h3 className="font-semibold text-green-900 mb-2">Optimization Results</h3>
                  <div className="grid grid-cols-3 gap-4 text-sm">
                    <div>
                      <p className="text-green-700">Total Distance</p>
                      <p className="font-bold text-green-900">
                        {optimizationResult.totalDistance.toFixed(1)} miles
                      </p>
                    </div>
                    <div>
                      <p className="text-green-700">Estimated Time</p>
                      <p className="font-bold text-green-900">
                        {Math.round(optimizationResult.estimatedDuration)} min
                      </p>
                    </div>
                    <div>
                      <p className="text-green-700">Optimization Score</p>
                      <p className="font-bold text-green-900">
                        {optimizationResult.optimizationScore.toFixed(1)}%
                      </p>
                    </div>
                  </div>
                </div>
              )}
            </div>

            <div className="p-6 border-t border-gray-200 flex justify-end space-x-3">
              <button
                onClick={() => {
                  setShowCreateModal(false);
                  resetForm();
                }}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleOptimizeRoute}
                disabled={optimizing}
                className="flex items-center space-x-2 px-4 py-2 bg-amber-600 text-white rounded-lg hover:bg-amber-700 transition-colors disabled:opacity-50"
              >
                <Play className="h-4 w-4" />
                <span>{optimizing ? 'Optimizing...' : 'Optimize Route'}</span>
              </button>
              <button
                onClick={handleSaveRoute}
                disabled={!optimizationResult || authLoading || !profile?.organization_id}
                className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50"
              >
                <Save className="h-4 w-4" />
                <span>Save Route</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default RouteOptimization;
