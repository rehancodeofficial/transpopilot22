import { supabase } from '../lib/supabase';
import { VehicleLocation, DriverLocation, VehicleWithLocation, DriverWithLocation } from '../types/tracking';
import { isDemoMode, DEMO_GPS_TRACKING } from '../lib/demoData';

export async function getVehicleLocations(): Promise<VehicleLocation[]> {
  if (isDemoMode()) {
    await new Promise(resolve => setTimeout(resolve, 100));
    return DEMO_GPS_TRACKING.map(gps => ({
      id: gps.id,
      vehicle_id: gps.vehicle_id,
      latitude: gps.latitude,
      longitude: gps.longitude,
      speed: gps.speed,
      heading: gps.heading,
      timestamp: gps.timestamp,
      created_at: gps.timestamp,
    })) as VehicleLocation[];
  }

  const { data, error } = await supabase
    .from('vehicle_locations')
    .select('*')
    .order('timestamp', { ascending: false });

  if (error) throw error;
  return data || [];
}

export async function getLatestVehicleLocation(vehicleId: string): Promise<VehicleLocation | null> {
  const { data, error } = await supabase
    .from('vehicle_locations')
    .select('*')
    .eq('vehicle_id', vehicleId)
    .order('timestamp', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) throw error;
  return data;
}

export async function getVehiclesWithLocations(): Promise<VehicleWithLocation[]> {
  if (isDemoMode()) {
    await new Promise(resolve => setTimeout(resolve, 100));
    const { DEMO_VEHICLES, DEMO_DRIVERS, DEMO_GPS_TRACKING } = await import('../lib/demoData');

    return DEMO_VEHICLES.map(vehicle => {
      const gps = DEMO_GPS_TRACKING.find(g => g.vehicle_id === vehicle.id);
      const driver = DEMO_DRIVERS.find(d => d.vehicle_id === vehicle.id);

      return {
        id: vehicle.id,
        organization_id: 'demo-org-12345',
        vehicle_number: vehicle.vehicle_number,
        make: vehicle.make,
        model: vehicle.model,
        year: vehicle.year,
        vin: vehicle.vin,
        status: vehicle.status,
        current_mileage: vehicle.mileage,
        fuel_capacity: 200,
        created_at: vehicle.created_at,
        updated_at: vehicle.created_at,
        location: gps ? {
          id: gps.id,
          vehicle_id: gps.vehicle_id,
          latitude: gps.latitude,
          longitude: gps.longitude,
          speed: gps.speed,
          heading: gps.heading,
          timestamp: gps.timestamp,
          created_at: gps.timestamp,
        } : null,
        driver_name: driver?.name,
      } as VehicleWithLocation;
    });
  }

  const { data: vehicles, error: vehiclesError } = await supabase
    .from('vehicles')
    .select('*');

  if (vehiclesError) throw vehiclesError;

  const vehiclesWithLocations = await Promise.all(
    (vehicles || []).map(async (vehicle) => {
      const location = await getLatestVehicleLocation(vehicle.id);

      let driverName = undefined;
      if (vehicle.driver_id) {
        const { data: driver } = await supabase
          .from('drivers')
          .select('first_name, last_name')
          .eq('id', vehicle.driver_id)
          .maybeSingle();

        if (driver) {
          driverName = `${driver.first_name} ${driver.last_name}`;
        }
      }

      return {
        ...vehicle,
        location,
        driver_name: driverName,
      };
    })
  );

  return vehiclesWithLocations;
}

export async function insertVehicleLocation(location: Omit<VehicleLocation, 'id' | 'created_at'>): Promise<VehicleLocation> {
  const { data, error } = await supabase
    .from('vehicle_locations')
    .insert(location)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function getDriverLocations(): Promise<DriverLocation[]> {
  const { data, error } = await supabase
    .from('driver_locations')
    .select('*')
    .order('timestamp', { ascending: false });

  if (error) throw error;
  return data || [];
}

export async function getLatestDriverLocation(driverId: string): Promise<DriverLocation | null> {
  const { data, error } = await supabase
    .from('driver_locations')
    .select('*')
    .eq('driver_id', driverId)
    .order('timestamp', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) throw error;
  return data;
}

export async function getDriversWithLocations(): Promise<DriverWithLocation[]> {
  const { data: drivers, error: driversError } = await supabase
    .from('drivers')
    .select('*');

  if (driversError) throw driversError;

  const driversWithLocations = await Promise.all(
    (drivers || []).map(async (driver) => {
      const location = await getLatestDriverLocation(driver.id);

      let vehicleName = undefined;
      const { data: vehicles } = await supabase
        .from('vehicles')
        .select('id, name')
        .eq('driver_id', driver.id)
        .maybeSingle();

      if (vehicles) {
        vehicleName = vehicles.name;
      }

      return {
        ...driver,
        location,
        vehicle_id: vehicles?.id,
        vehicle_name: vehicleName,
      };
    })
  );

  return driversWithLocations;
}

export async function insertDriverLocation(location: Omit<DriverLocation, 'id' | 'created_at'>): Promise<DriverLocation> {
  const { data, error } = await supabase
    .from('driver_locations')
    .insert(location)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function subscribeToVehicleLocations(
  callback: (location: VehicleLocation) => void
) {
  return supabase
    .channel('vehicle_locations_channel')
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'vehicle_locations',
      },
      (payload) => {
        callback(payload.new as VehicleLocation);
      }
    )
    .subscribe();
}

export async function subscribeToDriverLocations(
  callback: (location: DriverLocation) => void
) {
  return supabase
    .channel('driver_locations_channel')
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'driver_locations',
      },
      (payload) => {
        callback(payload.new as DriverLocation);
      }
    )
    .subscribe();
}
