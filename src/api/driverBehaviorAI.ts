import { supabase } from '../lib/supabase';
import { isDemoMode, DEMO_DRIVER_BEHAVIOR } from '../lib/demoData';

export interface DriverBehaviorMetrics {
  id: string;
  driver_id: string;
  harsh_acceleration_count: number;
  harsh_braking_count: number;
  speed_violations_count: number;
  idle_time_minutes: number;
  total_distance_miles: number;
  total_drive_time_hours: number;
  recorded_date: string;
}

export interface DriverBehaviorSummary {
  driver_id: string;
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

export async function getDriverBehaviorData(): Promise<DriverBehaviorSummary[]> {
  if (isDemoMode()) {
    await new Promise(resolve => setTimeout(resolve, 100));
    const { DEMO_DRIVERS } = await import('../lib/demoData');

    return DEMO_DRIVER_BEHAVIOR.map((behavior, idx) => {
      const driver = DEMO_DRIVERS.find(d => d.id === behavior.driver_id) || DEMO_DRIVERS[idx];
      const riskLevel =
        behavior.safety_score >= 90 ? 'low' :
        behavior.safety_score >= 75 ? 'medium' : 'high';
      const trend = Math.random() > 0.7 ? 'declining' : Math.random() > 0.5 ? 'stable' : 'improving';

      return {
        driver_id: driver.id,
        name: driver.name,
        email: driver.email,
        behavior_score: behavior.safety_score,
        safety_rating: behavior.safety_score,
        fuel_efficiency_rating: Math.min(100, behavior.safety_score + Math.floor(Math.random() * 10)),
        acceleration_score: Math.max(0, 100 - behavior.rapid_acceleration_events * 5),
        braking_score: Math.max(0, 100 - behavior.hard_braking_events * 5),
        speed_compliance: Math.max(0, 100 - behavior.speeding_events * 3),
        idle_time_score: Math.max(0, 100 - behavior.idle_time_hours * 2),
        total_miles: driver.total_miles,
        incidents_count: behavior.hard_braking_events + behavior.rapid_acceleration_events + behavior.speeding_events,
        risk_level: riskLevel,
        recommendations: riskLevel === 'high' ? ['Attend defensive driving course', 'Reduce speeding incidents'] : ['Maintain good driving habits'],
        improvement_trend: trend,
      };
    }) as DriverBehaviorSummary[];
  }

  const { data: drivers, error } = await supabase
    .from('drivers')
    .select('*')
    .eq('status', 'active')
    .order('last_name');

  if (error) {
    console.error('Error fetching drivers:', error);
    return [];
  }

  const behaviorSummaries = await Promise.all(
    drivers.map(async (driver) => {
      const metrics = await getDriverMetrics(driver.id);
      const incidents = await getDriverIncidents(driver.id);
      const scores = calculateDriverScores(metrics, incidents);
      const recommendations = generateRecommendations(scores, incidents.length);

      return {
        driver_id: driver.id,
        name: `${driver.first_name} ${driver.last_name}`,
        email: driver.email,
        behavior_score: scores.overall,
        safety_rating: scores.safety,
        fuel_efficiency_rating: scores.fuel_efficiency,
        acceleration_score: scores.acceleration,
        braking_score: scores.braking,
        speed_compliance: scores.speed_compliance,
        idle_time_score: scores.idle_time,
        total_miles: metrics.total_miles,
        incidents_count: incidents.length,
        risk_level: getRiskLevel(scores.overall, incidents.length),
        recommendations,
        improvement_trend: await calculateTrend(driver.id)
      };
    })
  );

  return behaviorSummaries.sort((a, b) => b.behavior_score - a.behavior_score);
}

export async function getDriverMetrics(driverId: string): Promise<{
  harsh_acceleration: number;
  harsh_braking: number;
  speed_violations: number;
  idle_time: number;
  total_miles: number;
  total_hours: number;
}> {
  const { data: behaviorData } = await supabase
    .from('driver_behavior_analytics')
    .select('*')
    .eq('driver_id', driverId)
    .order('recorded_date', { ascending: false })
    .limit(30);

  if (!behaviorData || behaviorData.length === 0) {
    return {
      harsh_acceleration: 0,
      harsh_braking: 0,
      speed_violations: 0,
      idle_time: 0,
      total_miles: 0,
      total_hours: 0
    };
  }

  const totals = behaviorData.reduce(
    (acc, record) => ({
      harsh_acceleration: acc.harsh_acceleration + (record.harsh_acceleration_count || 0),
      harsh_braking: acc.harsh_braking + (record.harsh_braking_count || 0),
      speed_violations: acc.speed_violations + (record.speed_violations_count || 0),
      idle_time: acc.idle_time + (record.idle_time_minutes || 0),
      total_miles: acc.total_miles + (record.total_distance_miles || 0),
      total_hours: acc.total_hours + (record.total_drive_time_hours || 0)
    }),
    {
      harsh_acceleration: 0,
      harsh_braking: 0,
      speed_violations: 0,
      idle_time: 0,
      total_miles: 0,
      total_hours: 0
    }
  );

  return totals;
}

export async function getDriverIncidents(driverId: string) {
  const { data, error } = await supabase
    .from('safety_incidents')
    .select('*')
    .eq('driver_id', driverId)
    .order('incident_date', { ascending: false });

  if (error) {
    console.error('Error fetching driver incidents:', error);
    return [];
  }

  return data || [];
}

function calculateDriverScores(metrics: any, incidents: any[]) {
  const milesPerIncident = metrics.total_miles > 0 ? metrics.total_miles / Math.max(incidents.length, 1) : 10000;
  const safetyBase = Math.min((milesPerIncident / 100), 100);

  const accelerationScore = Math.max(
    100 - (metrics.harsh_acceleration / Math.max(metrics.total_miles / 100, 1)) * 10,
    40
  );

  const brakingScore = Math.max(
    100 - (metrics.harsh_braking / Math.max(metrics.total_miles / 100, 1)) * 10,
    40
  );

  const speedScore = Math.max(
    100 - (metrics.speed_violations / Math.max(metrics.total_miles / 100, 1)) * 15,
    40
  );

  const idleScore = Math.max(
    100 - (metrics.idle_time / Math.max(metrics.total_hours, 1)) * 2,
    40
  );

  const fuelEfficiency = Math.round((accelerationScore + brakingScore + idleScore) / 3);
  const safety = Math.round(Math.min(safetyBase, 100));
  const overall = Math.round(
    (accelerationScore + brakingScore + speedScore + idleScore + safety) / 5
  );

  return {
    overall: Math.min(overall, 100),
    safety: Math.min(safety, 100),
    fuel_efficiency: Math.min(fuelEfficiency, 100),
    acceleration: Math.min(Math.round(accelerationScore), 100),
    braking: Math.min(Math.round(brakingScore), 100),
    speed_compliance: Math.min(Math.round(speedScore), 100),
    idle_time: Math.min(Math.round(idleScore), 100)
  };
}

function generateRecommendations(scores: any, incidentCount: number): string[] {
  const recommendations: string[] = [];

  if (scores.overall >= 90) {
    recommendations.push('Excellent performance - maintain current standards');
    return recommendations;
  }

  if (incidentCount > 3) {
    recommendations.push('URGENT: Schedule immediate safety training');
    recommendations.push('Review company driving policies');
  }

  if (scores.acceleration < 75) {
    recommendations.push('Focus on smoother acceleration patterns');
    recommendations.push('Practice gradual acceleration techniques');
  }

  if (scores.braking < 75) {
    recommendations.push('Reduce harsh braking incidents');
    recommendations.push('Focus on anticipating stops to reduce harsh braking');
  }

  if (scores.speed_compliance < 80) {
    recommendations.push('Improve speed limit compliance');
    recommendations.push('Monitor speed compliance closely');
  }

  if (scores.idle_time < 80) {
    recommendations.push('Reduce idle time to improve fuel efficiency');
  }

  if (scores.safety < 75) {
    recommendations.push('Schedule defensive driving training');
  }

  if (recommendations.length === 0) {
    recommendations.push('Good overall performance');
    recommendations.push('Continue monitoring key metrics');
  }

  return recommendations;
}

function getRiskLevel(score: number, incidentCount: number): 'low' | 'medium' | 'high' {
  if (score < 65 || incidentCount > 4) return 'high';
  if (score < 80 || incidentCount > 2) return 'medium';
  return 'low';
}

async function calculateTrend(driverId: string): Promise<'improving' | 'stable' | 'declining'> {
  const { data: recentData } = await supabase
    .from('driver_behavior_analytics')
    .select('*')
    .eq('driver_id', driverId)
    .order('recorded_date', { ascending: false })
    .limit(10);

  if (!recentData || recentData.length < 5) {
    return 'stable';
  }

  const recent = recentData.slice(0, 5);
  const older = recentData.slice(5, 10);

  const recentAvg = recent.reduce((sum, r) =>
    sum + (r.harsh_acceleration_count || 0) + (r.harsh_braking_count || 0) + (r.speed_violations_count || 0), 0
  ) / recent.length;

  const olderAvg = older.reduce((sum, r) =>
    sum + (r.harsh_acceleration_count || 0) + (r.harsh_braking_count || 0) + (r.speed_violations_count || 0), 0
  ) / older.length;

  if (recentAvg < olderAvg * 0.8) return 'improving';
  if (recentAvg > olderAvg * 1.2) return 'declining';
  return 'stable';
}

export async function saveBehaviorMetrics(metrics: Omit<DriverBehaviorMetrics, 'id' | 'recorded_date'>) {
  const { data, error } = await supabase
    .from('driver_behavior_analytics')
    .insert([{
      ...metrics,
      recorded_date: new Date().toISOString()
    }])
    .select()
    .single();

  if (error) {
    console.error('Error saving behavior metrics:', error);
    throw error;
  }

  return data;
}

export async function getDriverPerformanceHistory(driverId: string, days: number = 30) {
  const fromDate = new Date();
  fromDate.setDate(fromDate.getDate() - days);

  const { data, error } = await supabase
    .from('driver_behavior_analytics')
    .select('*')
    .eq('driver_id', driverId)
    .gte('recorded_date', fromDate.toISOString())
    .order('recorded_date', { ascending: true });

  if (error) {
    console.error('Error fetching performance history:', error);
    return [];
  }

  return data || [];
}
