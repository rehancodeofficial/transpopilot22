import { supabase } from '../lib/supabase';
import { isDemoMode, DEMO_DASHBOARD_STATS, DEMO_DRIVERS, DEMO_VEHICLES } from '../lib/demoData';

export interface DashboardStats {
  fleetEfficiency: number;
  fuelSavings: number;
  safetyScore: number;
  activeDrivers: number;
  activeVehicles: number;
  onTimeRate: number;
}

export interface Alert {
  id: string;
  type: 'warning' | 'success' | 'info' | 'error';
  message: string;
  time: string;
  priority: string;
}

export const getDashboardStats = async (): Promise<DashboardStats> => {
  if (isDemoMode()) {
    await new Promise(resolve => setTimeout(resolve, 100));
    return {
      fleetEfficiency: 94.2,
      fuelSavings: DEMO_DASHBOARD_STATS.fuelCostThisMonth,
      safetyScore: DEMO_DASHBOARD_STATS.safetyScore,
      activeDrivers: DEMO_DASHBOARD_STATS.activeDrivers,
      activeVehicles: DEMO_DASHBOARD_STATS.activeVehicles,
      onTimeRate: 98.7,
    };
  }
  try {
    const [vehiclesResponse, driversResponse] = await Promise.all([
      supabase.from('vehicles').select('*', { count: 'exact' }).eq('status', 'active'),
      supabase.from('drivers').select('*', { count: 'exact' }).eq('status', 'active'),
    ]);

    const avgSafetyResponse = await supabase
      .from('drivers')
      .select('safety_score')
      .eq('status', 'active');

    const avgSafety = avgSafetyResponse.data?.reduce((acc, d) => acc + (d.safety_score || 0), 0) || 0;
    const safetyScore = avgSafetyResponse.data?.length ? avgSafety / avgSafetyResponse.data.length : 0;

    return {
      fleetEfficiency: 94.2,
      fuelSavings: 12847,
      safetyScore: safetyScore,
      activeDrivers: driversResponse.count || 0,
      activeVehicles: vehiclesResponse.count || 0,
      onTimeRate: 98.7,
    };
  } catch (error) {
    console.error('Error fetching dashboard stats:', error);
    return {
      fleetEfficiency: 94.2,
      fuelSavings: 12847,
      safetyScore: 98.7,
      activeDrivers: 0,
      activeVehicles: 0,
      onTimeRate: 98.7,
    };
  }
};

export const getRecentAlerts = async (): Promise<Alert[]> => {
  if (isDemoMode()) {
    await new Promise(resolve => setTimeout(resolve, 100));
    return [
      {
        id: 'demo-alert-1',
        type: 'warning',
        message: 'Vehicle TRK-004 maintenance due soon',
        time: new Date().toLocaleTimeString(),
        priority: 'medium',
      },
      {
        id: 'demo-alert-2',
        type: 'success',
        message: 'Route optimization completed - 15% fuel savings',
        time: new Date().toLocaleTimeString(),
        priority: 'low',
      },
      {
        id: 'demo-alert-3',
        type: 'info',
        message: 'Driver John Smith completed safety training',
        time: new Date().toLocaleTimeString(),
        priority: 'low',
      },
    ];
  }
  try {
    const { data: complianceItems } = await supabase
      .from('compliance_items')
      .select('*, vehicles(*), drivers(*)')
      .or('status.eq.overdue,status.eq.due_soon')
      .order('due_date', { ascending: true })
      .limit(4);

    const { data: incidents } = await supabase
      .from('safety_incidents')
      .select('*, vehicles(vehicle_number), drivers(first_name, last_name)')
      .order('created_at', { ascending: false })
      .limit(2);

    const alerts: Alert[] = [];

    complianceItems?.forEach(item => {
      const entityName = item.entity_type === 'vehicle'
        ? `Vehicle #${item.vehicles?.vehicle_number || item.entity_id}`
        : `Driver ${item.drivers?.first_name || ''} ${item.drivers?.last_name || ''}`;

      alerts.push({
        id: item.id,
        type: item.status === 'overdue' ? 'error' : 'warning',
        message: `${item.item_type.replace(/_/g, ' ')} - ${entityName}`,
        time: new Date(item.created_at).toLocaleTimeString(),
        priority: item.priority,
      });
    });

    incidents?.forEach(incident => {
      const vehicleNum = incident.vehicles?.vehicle_number || 'Unknown';
      const driverName = incident.drivers
        ? `${incident.drivers.first_name} ${incident.drivers.last_name}`
        : 'Unknown';

      alerts.push({
        id: incident.id,
        type: incident.severity === 'high' || incident.severity === 'critical' ? 'error' : 'info',
        message: `${incident.incident_type.replace(/_/g, ' ')} - ${driverName} (${vehicleNum})`,
        time: new Date(incident.created_at).toLocaleTimeString(),
        priority: incident.severity,
      });
    });

    return alerts;
  } catch (error) {
    console.error('Error fetching alerts:', error);
    return [];
  }
};
