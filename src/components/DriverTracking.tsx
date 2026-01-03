import React, { useState, useEffect, useCallback } from 'react';
import {
  User,
  MapPin,
  Clock,
  Activity,
  Phone,
  Mail,
  Truck,
  AlertCircle,
  Search,
  Filter,
  RefreshCw,
  Play,
  Pause,
  Navigation,
} from 'lucide-react';
import { getDriversWithLocations, subscribeToDriverLocations } from '../api/tracking';
import { simulateGPSUpdates, startAutoSimulation } from '../api/gpsSimulator';
import { DriverWithLocation } from '../types/tracking';
import Map, { createDriverIcon } from './Map';

const DriverTracking: React.FC = () => {
  const [drivers, setDrivers] = useState<DriverWithLocation[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [selectedDriver, setSelectedDriver] = useState<DriverWithLocation | null>(null);
  const [mapCenter, setMapCenter] = useState<[number, number]>([40.7128, -74.006]);
  const [simulationActive, setSimulationActive] = useState(false);
  const [simulationInterval, setSimulationInterval] = useState<(() => void) | null>(null);
  const [showMap, setShowMap] = useState(false);

  useEffect(() => {
    loadDrivers();

    const subscription = subscribeToDriverLocations((newLocation) => {
      setDrivers((prev) =>
        prev.map((d) => {
          if (d.id === newLocation.driver_id) {
            return { ...d, location: newLocation };
          }
          return d;
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
      await loadDrivers();
    } catch (error) {
      console.error('Failed to simulate GPS data:', error);
    }
  };

  const handleDriverClick = (driver: DriverWithLocation) => {
    setSelectedDriver(driver);
    if (driver.location) {
      setMapCenter([
        Number(driver.location.latitude),
        Number(driver.location.longitude),
      ]);
      setShowMap(true);
    }
  };

  const loadDrivers = useCallback(async () => {
    try {
      setLoading(true);
      const data = await getDriversWithLocations();
      setDrivers(data);
    } catch (error) {
      console.error('Failed to load drivers:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  const filteredDrivers = drivers.filter((driver) => {
    const fullName = `${driver.first_name} ${driver.last_name}`.toLowerCase();
    const matchesSearch =
      fullName.includes(searchTerm.toLowerCase()) ||
      driver.license_number.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesFilter =
      filterStatus === 'all' ||
      (driver.location && driver.location.status === filterStatus);

    return matchesSearch && matchesFilter;
  });

  const activeDrivers = drivers.filter((d) => d.location && d.location.status === 'driving');
  const onBreakDrivers = drivers.filter((d) => d.location && d.location.status === 'break');
  const offDutyDrivers = drivers.filter((d) => !d.location || d.location.status === 'off_duty');

  const getStatusColor = (status?: string) => {
    switch (status) {
      case 'driving':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'active':
        return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'break':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'off_duty':
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getStatusIcon = (status?: string) => {
    switch (status) {
      case 'driving':
        return <Activity className="h-4 w-4" />;
      case 'break':
        return <Clock className="h-4 w-4" />;
      default:
        return <User className="h-4 w-4" />;
    }
  };

  const formatStatus = (status?: string) => {
    if (!status) return 'Off Duty';
    return status
      .split('_')
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  };

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Driver Tracking</h1>
          <p className="text-gray-600">Monitor driver locations and status in real-time</p>
        </div>
        <div className="flex items-center space-x-3">
          <button
            onClick={() => setShowMap(!showMap)}
            className="flex items-center space-x-2 px-4 py-2 bg-teal-600 text-white rounded-lg hover:bg-teal-700 transition-colors"
          >
            <MapPin className="h-4 w-4" />
            <span>{showMap ? 'Hide' : 'Show'} Map</span>
          </button>
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
            onClick={loadDrivers}
            className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <RefreshCw className="h-4 w-4" />
            <span>Refresh</span>
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-gradient-to-br from-green-500 to-emerald-600 rounded-lg p-6 text-white shadow-lg">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-green-100 text-sm font-medium">Driving</p>
              <p className="text-3xl font-bold mt-1">{activeDrivers.length}</p>
            </div>
            <div className="p-3 bg-white/20 rounded-lg">
              <Activity className="h-8 w-8" />
            </div>
          </div>
        </div>

        <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg p-6 text-white shadow-lg">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-blue-100 text-sm font-medium">Total Drivers</p>
              <p className="text-3xl font-bold mt-1">{drivers.length}</p>
            </div>
            <div className="p-3 bg-white/20 rounded-lg">
              <User className="h-8 w-8" />
            </div>
          </div>
        </div>

        <div className="bg-gradient-to-br from-amber-500 to-orange-600 rounded-lg p-6 text-white shadow-lg">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-amber-100 text-sm font-medium">On Break</p>
              <p className="text-3xl font-bold mt-1">{onBreakDrivers.length}</p>
            </div>
            <div className="p-3 bg-white/20 rounded-lg">
              <Clock className="h-8 w-8" />
            </div>
          </div>
        </div>

        <div className="bg-gradient-to-br from-gray-500 to-slate-600 rounded-lg p-6 text-white shadow-lg">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-100 text-sm font-medium">Off Duty</p>
              <p className="text-3xl font-bold mt-1">{offDutyDrivers.length}</p>
            </div>
            <div className="p-3 bg-white/20 rounded-lg">
              <User className="h-8 w-8" />
            </div>
          </div>
        </div>
      </div>

      {showMap && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          <div className="p-4 border-b border-gray-200 bg-gray-50">
            <h3 className="text-lg font-semibold text-gray-900">Driver Locations Map</h3>
          </div>
          <div className="relative h-[500px]">
            <Map
              center={mapCenter}
              zoom={12}
              markers={filteredDrivers
                .filter((d) => d.location)
                .map((driver) => {
                  const color =
                    driver.location?.status === 'driving'
                      ? '#10b981'
                      : driver.location?.status === 'break'
                      ? '#f59e0b'
                      : '#6b7280';

                  return {
                    id: driver.id,
                    position: [
                      Number(driver.location!.latitude),
                      Number(driver.location!.longitude),
                    ] as [number, number],
                    icon: createDriverIcon(color),
                    popup: (
                      <div className="p-2">
                        <p className="font-semibold text-gray-900">
                          {driver.first_name} {driver.last_name}
                        </p>
                        <p className="text-xs text-gray-600">{driver.license_number}</p>
                        {driver.vehicle_name && (
                          <p className="text-xs text-gray-500 mt-1">
                            Vehicle: {driver.vehicle_name}
                          </p>
                        )}
                        <div className="mt-2">
                          <span
                            className={`inline-block text-xs px-2 py-1 rounded ${
                              driver.location?.status === 'driving'
                                ? 'bg-green-100 text-green-700'
                                : driver.location?.status === 'break'
                                ? 'bg-yellow-100 text-yellow-700'
                                : 'bg-gray-100 text-gray-700'
                            }`}
                          >
                            {driver.location?.status?.replace('_', ' ') || 'Off Duty'}
                          </span>
                        </div>
                        <div className="mt-1 text-xs text-gray-500">
                          Last update: {new Date(driver.location!.timestamp).toLocaleTimeString()}
                        </div>
                      </div>
                    ),
                  };
                })}
            />
          </div>
        </div>
      )}

      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="p-4 border-b border-gray-200 space-y-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search drivers by name or license..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>

          <div className="flex items-center space-x-2">
            <Filter className="h-4 w-4 text-gray-400" />
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="all">All Status</option>
              <option value="driving">Driving</option>
              <option value="active">Active</option>
              <option value="break">On Break</option>
              <option value="off_duty">Off Duty</option>
            </select>
          </div>
        </div>

        <div className="p-6">
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
            </div>
          ) : filteredDrivers.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-gray-500">
              <AlertCircle className="h-12 w-12 mb-2" />
              <p>No drivers found</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {filteredDrivers.map((driver) => (
                <div
                  key={driver.id}
                  onClick={() => handleDriverClick(driver)}
                  className={`p-6 rounded-lg border transition-all cursor-pointer ${
                    selectedDriver?.id === driver.id
                      ? 'bg-blue-50 border-blue-300 shadow-md'
                      : 'bg-white border-gray-200 hover:bg-gray-50 hover:border-gray-300 hover:shadow-sm'
                  }`}
                >
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex items-center space-x-3">
                      <div className="w-12 h-12 rounded-full bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center text-white font-bold text-lg shadow-md">
                        {driver.first_name.charAt(0)}
                        {driver.last_name.charAt(0)}
                      </div>
                      <div>
                        <h3 className="font-semibold text-gray-900">
                          {driver.first_name} {driver.last_name}
                        </h3>
                        <p className="text-xs text-gray-600">{driver.license_number}</p>
                      </div>
                    </div>
                  </div>

                  <div
                    className={`inline-flex items-center space-x-2 px-3 py-1.5 rounded-lg border font-medium text-sm mb-4 ${getStatusColor(
                      driver.location?.status
                    )}`}
                  >
                    {getStatusIcon(driver.location?.status)}
                    <span>{formatStatus(driver.location?.status)}</span>
                  </div>

                  <div className="space-y-2 text-sm">
                    {driver.vehicle_name && (
                      <div className="flex items-center space-x-2 text-gray-700">
                        <Truck className="h-4 w-4 text-blue-600" />
                        <span className="truncate">{driver.vehicle_name}</span>
                      </div>
                    )}

                    {driver.location && (
                      <>
                        <div className="flex items-center space-x-2 text-gray-700">
                          <MapPin className="h-4 w-4 text-green-600" />
                          <span>
                            {driver.location.latitude.toFixed(4)}, {driver.location.longitude.toFixed(4)}
                          </span>
                        </div>
                        <div className="flex items-center space-x-2 text-gray-700">
                          <Clock className="h-4 w-4 text-gray-600" />
                          <span>{new Date(driver.location.timestamp).toLocaleString()}</span>
                        </div>
                      </>
                    )}

                    {driver.email && (
                      <div className="flex items-center space-x-2 text-gray-700">
                        <Mail className="h-4 w-4 text-gray-600" />
                        <span className="truncate">{driver.email}</span>
                      </div>
                    )}

                    {driver.phone && (
                      <div className="flex items-center space-x-2 text-gray-700">
                        <Phone className="h-4 w-4 text-gray-600" />
                        <span>{driver.phone}</span>
                      </div>
                    )}
                  </div>

                  {driver.status && (
                    <div className="mt-4 pt-4 border-t border-gray-200">
                      <div className="flex items-center justify-between text-xs">
                        <span className="text-gray-600">Driver Status</span>
                        <span
                          className={`px-2 py-1 rounded ${
                            driver.status === 'active'
                              ? 'bg-green-100 text-green-700'
                              : 'bg-gray-100 text-gray-700'
                          }`}
                        >
                          {driver.status}
                        </span>
                      </div>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default DriverTracking;
