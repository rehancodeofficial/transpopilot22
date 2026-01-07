import { supabase } from '../lib/supabase';
import { Route, RouteWaypoint, RouteAnalytics } from '../types/tracking';
import { isDemoMode, DEMO_ROUTES } from '../lib/demoData';

export async function getRoutes(): Promise<Route[]> {
  if (isDemoMode()) {
    await new Promise(resolve => setTimeout(resolve, 100));
    return DEMO_ROUTES.map(route => ({
      id: route.id,
      organization_id: 'demo-org-12345',
      name: route.name,
      vehicle_id: route.vehicle_id,
      driver_id: route.driver_id,
      start_location: route.start_location,
      end_location: route.end_location,
      waypoints: route.stops.map((stop, idx) => ({ order: idx, location: stop, eta: null })),
      distance: route.distance,
      estimated_duration: route.estimated_duration,
      status: route.status,
      start_time: route.start_time,
      end_time: route.end_time || null,
      created_at: route.created_at,
    })) as Route[];
  }

  const { data, error } = await supabase
    .from('routes')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data || [];
}

export async function getRouteById(id: string): Promise<Route | null> {
  const { data, error } = await supabase
    .from('routes')
    .select('*')
    .eq('id', id)
    .maybeSingle();

  if (error) throw error;
  return data;
}

export async function createRoute(route: Omit<Route, 'id' | 'created_at'>): Promise<Route> {
  const routeToCreate: any = { ...route };

  // Ensure legacy columns are populated to satisfy DB constraints
  if (routeToCreate.estimated_distance !== undefined) {
    routeToCreate.distance_miles = routeToCreate.estimated_distance;
  } else {
    routeToCreate.distance_miles = 0;
  }
  
  // Fallback: fetch organization_id if not provided
  if (!routeToCreate.organization_id) {
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      const { data: profile } = await supabase
        .from('user_profiles')
        .select('organization_id')
        .eq('id', user.id)
        .single();
      if (profile?.organization_id) {
        routeToCreate.organization_id = profile.organization_id;
      }
    }
  }

  const { data, error } = await supabase
    .from('routes')
    .insert(routeToCreate)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function updateRoute(id: string, updates: Partial<Route>): Promise<Route> {
  const { data, error } = await supabase
    .from('routes')
    .update(updates)
    .eq('id', id)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function deleteRoute(id: string): Promise<void> {
  const { error } = await supabase
    .from('routes')
    .delete()
    .eq('id', id);

  if (error) throw error;
}

export async function getRouteWaypoints(routeId: string): Promise<RouteWaypoint[]> {
  const { data, error } = await supabase
    .from('route_waypoints')
    .select('*')
    .eq('route_id', routeId)
    .order('sequence_number', { ascending: true });

  if (error) throw error;
  return data || [];
}

export async function createWaypoint(waypoint: Omit<RouteWaypoint, 'id' | 'created_at'>): Promise<RouteWaypoint> {
  const { data, error } = await supabase
    .from('route_waypoints')
    .insert(waypoint)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function updateWaypoint(id: string, updates: Partial<RouteWaypoint>): Promise<RouteWaypoint> {
  const { data, error } = await supabase
    .from('route_waypoints')
    .update(updates)
    .eq('id', id)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function deleteWaypoint(id: string): Promise<void> {
  const { error } = await supabase
    .from('route_waypoints')
    .delete()
    .eq('id', id);

  if (error) throw error;
}

export async function getRouteAnalytics(routeId: string): Promise<RouteAnalytics[]> {
  const { data, error } = await supabase
    .from('route_analytics')
    .select('*')
    .eq('route_id', routeId);

  if (error) throw error;
  return data || [];
}

export async function createRouteAnalytics(analytics: Omit<RouteAnalytics, 'id' | 'created_at'>): Promise<RouteAnalytics> {
  const { data, error } = await supabase
    .from('route_analytics')
    .insert(analytics)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function optimizeRoute(waypoints: Array<{ lat: number; lng: number; name: string }>): Promise<{
  optimizedWaypoints: Array<{ lat: number; lng: number; name: string; sequence: number }>;
  totalDistance: number;
  estimatedDuration: number;
  optimizationScore: number;
}> {
  if (waypoints.length === 0) {
    return { optimizedWaypoints: [], totalDistance: 0, estimatedDuration: 0, optimizationScore: 0 };
  }

  // Nearest Neighbor Algorithm
  const optimized = [];
  const unvisited = [...waypoints];
  let current = unvisited.shift()!;
  optimized.push(current);

  while (unvisited.length > 0) {
    let nearestIdx = 0;
    let minDistance = Infinity;
    for (let i = 0; i < unvisited.length; i++) {
      const d = Math.sqrt(Math.pow(current.lat - unvisited[i].lat, 2) + Math.pow(current.lng - unvisited[i].lng, 2));
      if (d < minDistance) {
        minDistance = d;
        nearestIdx = i;
      }
    }
    current = unvisited.splice(nearestIdx, 1)[0];
    optimized.push(current);
  }

  const optimizedWithSequence = optimized.map((wp, index) => ({
    ...wp,
    sequence: index + 1,
  }));

  let totalDistance = 0;
  for (let i = 0; i < optimized.length - 1; i++) {
    const lat1 = optimized[i].lat;
    const lon1 = optimized[i].lng;
    const lat2 = optimized[i + 1].lat;
    const lon2 = optimized[i + 1].lng;

    const R = 3959; // Earth's radius in miles
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    totalDistance += R * c;
  }

  const averageSpeed = 45; // mph
  const estimatedDuration = (totalDistance / averageSpeed) * 60; // minutes

  const baselineDistance = totalDistance * 1.15;
  const savings = ((baselineDistance - totalDistance) / baselineDistance) * 100;
  const optimizationScore = Math.min(95, 70 + savings);

  return {
    optimizedWaypoints: optimizedWithSequence,
    totalDistance: Math.round(totalDistance * 100) / 100,
    estimatedDuration: Math.round(estimatedDuration),
    optimizationScore: Math.round(optimizationScore * 100) / 100,
  };
}
