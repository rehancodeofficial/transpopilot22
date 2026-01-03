import React, { useState, useEffect, useCallback } from 'react';
import {
  MapPin,
  Navigation,
  Activity,
  Gauge,
  Clock,
  AlertCircle,
  Filter,
  Search,
  RefreshCw,
  Play,
  Pause,
} from 'lucide-react';
import { getVehiclesWithLocations, subscribeToVehicleLocations } from '../api/tracking';
import { simulateGPSUpdates, startAutoSimulation } from '../api/gpsSimulator';
import { VehicleWithLocation } from '../types/tracking';
import Map, { createVehicleIcon } from './Map';

const LiveTracking: React.FC = () => {
  const [vehicles, setVehicles] = useState<VehicleWithLocation[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [selectedVehicle, setSelectedVehicle] = useState<VehicleWithLocation | null>(null);
  const [mapCenter, setMapCenter] = useState<[number, number]>([40.7128, -74.006]);
  const [simulationActive, setSimulationActive] = useState(false);
  const [simulationInterval, setSimulationInterval] = useState<(() => void) | null>(null);

  useEffect(() => {
    loadVehicles();

    const subscription = subscribeToVehicleLocations((newLocation) => {
      setVehicles((prev) =>
        prev.map((v) => {
          if (v.id === newLocation.vehicle_id) {
            return { ...v, location: newLocation };
          }
          return v;
        })
      );
    });

    return () => {
      subscription.then((sub) => sub.unsubscribe());
    };
  }, []);

  useEffect(() => {
    return () => {
      if (simulationInterval) {
        simulationInterval();
      }
    };
  }, [simulationInterval]);

  const toggleSimulation = async () => {
    if (simulationActive) {
      if (simulationInterval) {
        simulationInterval();
        setSimulationInterval(null);
      }
      setSimulationActive(false);
    } else {
      const stopFn = await startAutoSimulation(5000);
      setSimulationInterval(() => stopFn);
      setSimulationActive(true);
      await simulateGPSUpdates();
    }
  };

  const handleManualSimulate = async () => {
    try {
      await simulateGPSUpdates();
      await loadVehicles();
    } catch (error) {
      console.error('Failed to simulate GPS data:', error);
    }
  };

  const loadVehicles = useCallback(async () => {
    try {
      setLoading(true);
      const data = await getVehiclesWithLocations();
      setVehicles(data);
    } catch (error) {
      console.error('Failed to load vehicles:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  const filteredVehicles = vehicles.filter((vehicle) => {
    const matchesSearch =
      vehicle.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      vehicle.license_plate.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesFilter =
      filterStatus === 'all' ||
      vehicle.status.toLowerCase() === filterStatus.toLowerCase();

    return matchesSearch && matchesFilter;
  });

  const activeVehicles = vehicles.filter((v) => v.status === 'active' && v.location);
  const idleVehicles = vehicles.filter((v) => v.location && (v.location.speed || 0) < 5);

  const handleVehicleClick = (vehicle: VehicleWithLocation) => {
    setSelectedVehicle(vehicle);
    if (vehicle.location) {
      setMapCenter([
        Number(vehicle.location.latitude),
        Number(vehicle.location.longitude),
      ]);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'active':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'maintenance':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'offline':
        return 'bg-gray-100 text-gray-800 border-gray-200';
      default:
        return 'bg-blue-100 text-blue-800 border-blue-200';
    }
  };

  const getSpeedColor = (speed: number) => {
    if (speed === 0) return 'text-gray-500';
    if (speed < 30) return 'text-green-600';
    if (speed < 60) return 'text-blue-600';
    return 'text-orange-600';
  };

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Live Fleet Tracking</h1>
          <p className="text-gray-600">Real-time vehicle locations and status monitoring</p>
        </div>
        <div className="flex items-center space-x-3">
          <button
            onClick={toggleSimulation}
            className={`flex items-center space-x-2 px-4 py-2 rounded-lg transition-colors ${
              simulationActive
                ? 'bg-red-600 hover:bg-red-700 text-white'
                : 'bg-green-600 hover:bg-green-700 text-white'
            }`}
          >
            {simulationActive ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4" />}
            <span>{simulationActive ? 'Stop' : 'Start'} Simulation</span>
          </button>
          <button
            onClick={handleManualSimulate}
            className="flex items-center space-x-2 px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors"
          >
            <Navigation className="h-4 w-4" />
            <span>Update Once</span>
          </button>
          <button
            onClick={loadVehicles}
            className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <RefreshCw className="h-4 w-4" />
            <span>Refresh</span>
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-gradient-to-br from-green-500 to-emerald-600 rounded-lg p-6 text-white shadow-lg">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-green-100 text-sm font-medium">Active Vehicles</p>
              <p className="text-3xl font-bold mt-1">{activeVehicles.length}</p>
            </div>
            <div className="p-3 bg-white/20 rounded-lg">
              <Activity className="h-8 w-8" />
            </div>
          </div>
        </div>

        <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg p-6 text-white shadow-lg">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-blue-100 text-sm font-medium">Total Fleet</p>
              <p className="text-3xl font-bold mt-1">{vehicles.length}</p>
            </div>
            <div className="p-3 bg-white/20 rounded-lg">
              <MapPin className="h-8 w-8" />
            </div>
          </div>
        </div>

        <div className="bg-gradient-to-br from-amber-500 to-orange-600 rounded-lg p-6 text-white shadow-lg">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-amber-100 text-sm font-medium">Idle Vehicles</p>
              <p className="text-3xl font-bold mt-1">{idleVehicles.length}</p>
            </div>
            <div className="p-3 bg-white/20 rounded-lg">
              <Clock className="h-8 w-8" />
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
            <div className="p-4 border-b border-gray-200 bg-gray-50">
              <h3 className="text-lg font-semibold text-gray-900">Fleet Map</h3>
            </div>
            <div className="relative h-[600px]">
              <Map
                center={mapCenter}
                zoom={12}
                markers={filteredVehicles
                  .filter((v) => v.location)
                  .map((vehicle) => {
                    const isActive = vehicle.status === 'active';
                    const color = isActive ? '#10b981' : '#9ca3af';

                    return {
                      id: vehicle.id,
                      position: [
                        Number(vehicle.location!.latitude),
                        Number(vehicle.location!.longitude),
                      ] as [number, number],
                      icon: createVehicleIcon(color, isActive),
                      popup: (
                        <div className="p-2">
                          <p className="font-semibold text-gray-900">{vehicle.name}</p>
                          <p className="text-xs text-gray-600">{vehicle.license_plate}</p>
                          {vehicle.driver_name && (
                            <p className="text-xs text-gray-500 mt-1">
                              Driver: {vehicle.driver_name}
                            </p>
                          )}
                          <div className="mt-2 flex items-center text-xs">
                            <Gauge className="h-3 w-3 mr-1 text-blue-600" />
                            <span className={getSpeedColor(vehicle.location!.speed || 0)}>
                              {Math.round(vehicle.location!.speed || 0)} mph
                            </span>
                          </div>
                          <div className="mt-1 text-xs text-gray-500">
                            Last update: {new Date(vehicle.location!.timestamp).toLocaleTimeString()}
                          </div>
                        </div>
                      ),
                    };
                  })}
              />
            </div>
          </div>
        </div>

        <div className="lg:col-span-1">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 h-[600px] flex flex-col">
            <div className="p-4 border-b border-gray-200 space-y-3">
              <h3 className="text-lg font-semibold text-gray-900">Vehicle List</h3>

              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search vehicles..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
                />
              </div>

              <div className="flex items-center space-x-2">
                <Filter className="h-4 w-4 text-gray-400" />
                <select
                  value={filterStatus}
                  onChange={(e) => setFilterStatus(e.target.value)}
                  className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
                >
                  <option value="all">All Status</option>
                  <option value="active">Active</option>
                  <option value="maintenance">Maintenance</option>
                  <option value="offline">Offline</option>
                </select>
              </div>
            </div>

            <div className="flex-1 overflow-y-auto p-4 space-y-2">
              {loading ? (
                <div className="flex items-center justify-center h-full">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
                </div>
              ) : filteredVehicles.length === 0 ? (
                <div className="flex flex-col items-center justify-center h-full text-gray-500">
                  <AlertCircle className="h-12 w-12 mb-2" />
                  <p className="text-sm">No vehicles found</p>
                </div>
              ) : (
                filteredVehicles.map((vehicle) => (
                  <div
                    key={vehicle.id}
                    onClick={() => handleVehicleClick(vehicle)}
                    className={`p-3 rounded-lg border cursor-pointer transition-all ${
                      selectedVehicle?.id === vehicle.id
                        ? 'bg-blue-50 border-blue-300 shadow-md'
                        : 'bg-white border-gray-200 hover:bg-gray-50 hover:border-gray-300'
                    }`}
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center space-x-2">
                          <p className="font-semibold text-sm text-gray-900 truncate">
                            {vehicle.name}
                          </p>
                          <span
                            className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium border ${getStatusColor(
                              vehicle.status
                            )}`}
                          >
                            {vehicle.status}
                          </span>
                        </div>
                        <p className="text-xs text-gray-600 mt-1">{vehicle.license_plate}</p>
                        {vehicle.driver_name && (
                          <p className="text-xs text-gray-500 mt-1">
                            Driver: {vehicle.driver_name}
                          </p>
                        )}
                      </div>
                    </div>
                    {vehicle.location && (
                      <div className="mt-2 grid grid-cols-2 gap-2 text-xs">
                        <div className="flex items-center space-x-1">
                          <Gauge className="h-3 w-3 text-blue-600" />
                          <span className={getSpeedColor(vehicle.location.speed || 0)}>
                            {Math.round(vehicle.location.speed || 0)} mph
                          </span>
                        </div>
                        <div className="flex items-center space-x-1">
                          <Clock className="h-3 w-3 text-gray-500" />
                          <span className="text-gray-600">
                            {new Date(vehicle.location.timestamp).toLocaleTimeString()}
                          </span>
                        </div>
                      </div>
                    )}
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LiveTracking;
