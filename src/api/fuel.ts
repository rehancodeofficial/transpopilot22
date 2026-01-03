import { supabase } from '../lib/supabase';
import { isDemoMode, DEMO_FUEL_RECORDS } from '../lib/demoData';

export interface FuelRecord {
  id: string;
  vehicle_id: string;
  driver_id?: string;
  gallons: number;
  cost_per_gallon: number;
  total_cost: number;
  station_name?: string;
  location?: string;
  odometer_reading?: number;
  mpg?: number;
  transaction_date: string;
  created_at: string;
}

export interface FuelStats {
  totalCost: number;
  totalGallons: number;
  averageMPG: number;
  averageCostPerGallon: number;
  totalMilesDriven: number;
  fuelEfficiency: number;
  co2Reduction: number;
  costChange: number;
  mpgChange: number;
  efficiencyChange: number;
}

export interface VehicleFuelPerformance {
  vehicle_id: string;
  vehicle_number: string;
  make: string;
  model: string;
  totalGallons: number;
  totalCost: number;
  averageMPG: number;
  totalMiles: number;
  efficiency: number;
}

export interface DriverFuelPerformance {
  driver_id: string;
  driver_name: string;
  vehicle_number?: string;
  averageMPG: number;
  totalCost: number;
  totalMiles: number;
  fuelSavings: number;
  efficiency: number;
}

export async function getFuelRecords(
  startDate?: string,
  endDate?: string,
  vehicleId?: string
): Promise<FuelRecord[]> {
  if (isDemoMode()) {
    await new Promise(resolve => setTimeout(resolve, 100));
    return DEMO_FUEL_RECORDS.map(record => ({
      id: record.id,
      vehicle_id: record.vehicle_id,
      driver_id: record.driver_id,
      gallons: record.gallons,
      cost_per_gallon: record.cost / record.gallons,
      total_cost: record.cost,
      station_name: record.location,
      location: record.location,
      odometer_reading: record.odometer,
      mpg: record.mpg,
      transaction_date: record.date,
      created_at: record.created_at,
    })).filter(record => {
      if (vehicleId && record.vehicle_id !== vehicleId) return false;
      if (startDate && record.transaction_date < startDate) return false;
      if (endDate && record.transaction_date > endDate) return false;
      return true;
    }) as FuelRecord[];
  }

  let query = supabase
    .from('fuel_records')
    .select('*')
    .order('transaction_date', { ascending: false });

  if (startDate) {
    query = query.gte('transaction_date', startDate);
  }
  if (endDate) {
    query = query.lte('transaction_date', endDate);
  }
  if (vehicleId) {
    query = query.eq('vehicle_id', vehicleId);
  }

  const { data, error } = await query;
  if (error) throw error;
  return data || [];
}

export async function getFuelStats(timeframe: 'day' | 'week' | 'month' | 'quarter' | 'year'): Promise<FuelStats> {
  const now = new Date();
  const startDate = new Date(now);

  switch (timeframe) {
    case 'day':
      startDate.setDate(now.getDate() - 1);
      break;
    case 'week':
      startDate.setDate(now.getDate() - 7);
      break;
    case 'month':
      startDate.setMonth(now.getMonth() - 1);
      break;
    case 'quarter':
      startDate.setMonth(now.getMonth() - 3);
      break;
    case 'year':
      startDate.setFullYear(now.getFullYear() - 1);
      break;
  }

  const { data: currentPeriod } = await supabase
    .from('fuel_records')
    .select('*')
    .gte('transaction_date', startDate.toISOString());

  const previousStartDate = new Date(startDate);
  const timeDiff = now.getTime() - startDate.getTime();
  previousStartDate.setTime(startDate.getTime() - timeDiff);

  const { data: previousPeriod } = await supabase
    .from('fuel_records')
    .select('*')
    .gte('transaction_date', previousStartDate.toISOString())
    .lt('transaction_date', startDate.toISOString());

  const calculateStats = (records: any[]) => {
    if (!records || records.length === 0) {
      return { cost: 0, gallons: 0, mpg: 0, miles: 0, costPerGallon: 0 };
    }

    const totalCost = records.reduce((sum, r) => sum + (r.total_cost || 0), 0);
    const totalGallons = records.reduce((sum, r) => sum + (r.gallons || 0), 0);
    const validMPGs = records.filter(r => r.mpg && r.mpg > 0);
    const averageMPG = validMPGs.length > 0
      ? validMPGs.reduce((sum, r) => sum + r.mpg, 0) / validMPGs.length
      : 0;
    const totalMiles = totalGallons > 0 ? totalGallons * averageMPG : 0;
    const costPerGallon = totalGallons > 0 ? totalCost / totalGallons : 0;

    return { cost: totalCost, gallons: totalGallons, mpg: averageMPG, miles: totalMiles, costPerGallon };
  };

  const current = calculateStats(currentPeriod || []);
  const previous = calculateStats(previousPeriod || []);

  const costChange = previous.cost > 0 ? ((current.cost - previous.cost) / previous.cost) * 100 : 0;
  const mpgChange = previous.mpg > 0 ? current.mpg - previous.mpg : 0;

  const baselineEfficiency = 85;
  const efficiency = current.mpg > 0 ? Math.min(100, (current.mpg / 7.5) * 100) : baselineEfficiency;
  const previousEfficiency = previous.mpg > 0 ? Math.min(100, (previous.mpg / 7.5) * 100) : baselineEfficiency;
  const efficiencyChange = previousEfficiency > 0 ? efficiency - previousEfficiency : 0;

  const co2PerGallon = 22.4;
  const baselineCO2 = current.gallons * co2PerGallon;
  const optimizedCO2 = baselineCO2 * 0.875;
  const co2Reduction = baselineCO2 > 0 ? ((baselineCO2 - optimizedCO2) / baselineCO2) * 100 : 0;

  return {
    totalCost: Math.round(current.cost * 100) / 100,
    totalGallons: Math.round(current.gallons * 100) / 100,
    averageMPG: Math.round(current.mpg * 10) / 10,
    averageCostPerGallon: Math.round(current.costPerGallon * 100) / 100,
    totalMilesDriven: Math.round(current.miles),
    fuelEfficiency: Math.round(efficiency * 10) / 10,
    co2Reduction: Math.round(co2Reduction * 10) / 10,
    costChange: Math.round(costChange * 10) / 10,
    mpgChange: Math.round(mpgChange * 10) / 10,
    efficiencyChange: Math.round(efficiencyChange * 10) / 10,
  };
}

export async function getVehicleFuelPerformance(limit: number = 10): Promise<VehicleFuelPerformance[]> {
  const { data: vehicles } = await supabase
    .from('vehicles')
    .select('id, vehicle_number, make, model')
    .eq('status', 'active');

  if (!vehicles) return [];

  const performance = await Promise.all(
    vehicles.map(async (vehicle) => {
      const { data: fuelRecords } = await supabase
        .from('fuel_records')
        .select('*')
        .eq('vehicle_id', vehicle.id)
        .order('transaction_date', { ascending: false })
        .limit(30);

      const totalGallons = fuelRecords?.reduce((sum, r) => sum + (r.gallons || 0), 0) || 0;
      const totalCost = fuelRecords?.reduce((sum, r) => sum + (r.total_cost || 0), 0) || 0;
      const validMPGs = fuelRecords?.filter(r => r.mpg && r.mpg > 0) || [];
      const averageMPG = validMPGs.length > 0
        ? validMPGs.reduce((sum, r) => sum + r.mpg, 0) / validMPGs.length
        : 0;
      const totalMiles = totalGallons * averageMPG;
      const efficiency = averageMPG > 0 ? Math.min(100, (averageMPG / 7.5) * 100) : 0;

      return {
        vehicle_id: vehicle.id,
        vehicle_number: vehicle.vehicle_number,
        make: vehicle.make,
        model: vehicle.model,
        totalGallons: Math.round(totalGallons * 100) / 100,
        totalCost: Math.round(totalCost * 100) / 100,
        averageMPG: Math.round(averageMPG * 10) / 10,
        totalMiles: Math.round(totalMiles),
        efficiency: Math.round(efficiency),
      };
    })
  );

  return performance
    .filter(p => p.averageMPG > 0)
    .sort((a, b) => b.averageMPG - a.averageMPG)
    .slice(0, limit);
}

export async function getDriverFuelPerformance(limit: number = 10): Promise<DriverFuelPerformance[]> {
  const { data: drivers } = await supabase
    .from('drivers')
    .select('id, first_name, last_name')
    .eq('status', 'active');

  if (!drivers) return [];

  const performance = await Promise.all(
    drivers.map(async (driver) => {
      const { data: fuelRecords } = await supabase
        .from('fuel_records')
        .select('*, vehicles(vehicle_number)')
        .eq('driver_id', driver.id)
        .order('transaction_date', { ascending: false })
        .limit(30);

      const totalCost = fuelRecords?.reduce((sum, r) => sum + (r.total_cost || 0), 0) || 0;
      const validMPGs = fuelRecords?.filter(r => r.mpg && r.mpg > 0) || [];
      const averageMPG = validMPGs.length > 0
        ? validMPGs.reduce((sum, r) => sum + r.mpg, 0) / validMPGs.length
        : 0;
      const totalGallons = fuelRecords?.reduce((sum, r) => sum + (r.gallons || 0), 0) || 0;
      const totalMiles = totalGallons * averageMPG;

      const baselineMPG = 7.0;
      const fuelSavings = averageMPG > baselineMPG
        ? ((averageMPG - baselineMPG) / baselineMPG) * totalCost
        : 0;

      const efficiency = averageMPG > 0 ? Math.min(100, (averageMPG / 7.5) * 100) : 0;
      const vehicle = fuelRecords?.[0]?.vehicles as any;

      return {
        driver_id: driver.id,
        driver_name: `${driver.first_name} ${driver.last_name}`,
        vehicle_number: vehicle?.vehicle_number,
        averageMPG: Math.round(averageMPG * 10) / 10,
        totalCost: Math.round(totalCost * 100) / 100,
        totalMiles: Math.round(totalMiles),
        fuelSavings: Math.round(fuelSavings * 100) / 100,
        efficiency: Math.round(efficiency),
      };
    })
  );

  return performance
    .filter(p => p.averageMPG > 0)
    .sort((a, b) => b.averageMPG - a.averageMPG)
    .slice(0, limit);
}

export async function getOptimizedRoutesFuelData(): Promise<any[]> {
  const { data: routes } = await supabase
    .from('routes')
    .select(`
      *,
      route_analytics(*)
    `)
    .in('status', ['completed', 'active'])
    .order('created_at', { ascending: false })
    .limit(10);

  if (!routes) return [];

  return routes.map(route => {
    const analytics = (route.route_analytics as any[]) || [];
    const fuelSavingsAnalytic = analytics.find(a => a.metric_type === 'fuel_efficiency');
    const distanceSavingsAnalytic = analytics.find(a => a.metric_type === 'distance_optimization');
    const timeSavingsAnalytic = analytics.find(a => a.metric_type === 'time_savings');

    const baselineDistance = route.estimated_distance || 0;
    const optimizedDistance = distanceSavingsAnalytic?.optimized_value || baselineDistance;
    const distanceSaved = baselineDistance - optimizedDistance;

    const avgMPG = 7.0;
    const costPerGallon = 3.45;
    const fuelSavings = (distanceSaved / avgMPG) * costPerGallon;
    const timeSaved = timeSavingsAnalytic?.improvement_percentage || 10;

    return {
      id: route.id,
      name: route.name || `Route ${route.id.slice(0, 8)}`,
      originalDistance: Math.round(baselineDistance),
      optimizedDistance: Math.round(optimizedDistance),
      fuelSavings: Math.round(fuelSavings * 100) / 100,
      timeSavings: Math.round(timeSaved),
      status: route.status,
    };
  });
}

export async function createFuelRecord(record: Omit<FuelRecord, 'id' | 'created_at'>): Promise<FuelRecord> {
  const { data, error } = await supabase
    .from('fuel_records')
    .insert(record)
    .select()
    .single();

  if (error) throw error;
  return data;
}
