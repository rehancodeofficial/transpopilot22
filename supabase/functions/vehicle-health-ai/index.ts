import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.57.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const url = new URL(req.url);
    const action = url.searchParams.get("action") || "analyze";

    if (action === "analyze") {
      const vehicleId = url.searchParams.get("vehicle_id");
      if (vehicleId) {
        const result = await analyzeVehicleHealth(supabase, vehicleId);
        return new Response(JSON.stringify(result), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      } else {
        const result = await analyzeAllVehicles(supabase);
        return new Response(JSON.stringify(result), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    } else if (action === "simulate") {
      const result = await simulateDiagnostics(supabase);
      return new Response(JSON.stringify(result), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    } else if (action === "generate-alerts") {
      const result = await generateHealthAlerts(supabase);
      return new Response(JSON.stringify(result), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: "Invalid action" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Error in vehicle health AI:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

async function analyzeVehicleHealth(supabase: any, vehicleId: string) {
  const { data: vehicle } = await supabase
    .from("vehicles")
    .select("*")
    .eq("id", vehicleId)
    .maybeSingle();

  if (!vehicle) {
    return { success: false, message: "Vehicle not found" };
  }

  const { data: latestDiagnostic } = await supabase
    .from("vehicle_diagnostics")
    .select("*")
    .eq("vehicle_id", vehicleId)
    .order("recorded_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  const healthScore = calculateHealthScore(vehicle, latestDiagnostic);
  const predictedIssues = predictIssues(vehicle, latestDiagnostic);
  const maintenanceRecommendations = generateMaintenanceRecommendations(
    vehicle,
    healthScore,
    predictedIssues
  );

  return {
    success: true,
    vehicle_id: vehicleId,
    vehicle_number: vehicle.vehicle_number,
    health_score: healthScore.overall,
    component_scores: healthScore.components,
    overall_status: getHealthStatus(healthScore.overall),
    predicted_issues: predictedIssues,
    maintenance_recommendations: maintenanceRecommendations,
    next_maintenance_due: calculateNextMaintenance(vehicle),
    cost_savings_potential: calculateCostSavings(predictedIssues.length, healthScore.overall),
  };
}

async function analyzeAllVehicles(supabase: any) {
  const { data: vehicles } = await supabase
    .from("vehicles")
    .select("*")
    .order("vehicle_number");

  if (!vehicles || vehicles.length === 0) {
    return { success: true, message: "No vehicles found", analyses: [] };
  }

  const analyses = [];
  for (const vehicle of vehicles) {
    const analysis = await analyzeVehicleHealth(supabase, vehicle.id);
    analyses.push(analysis);
  }

  const summary = {
    total_vehicles: vehicles.length,
    excellent_count: analyses.filter((a) => a.health_score >= 90).length,
    good_count: analyses.filter((a) => a.health_score >= 75 && a.health_score < 90).length,
    fair_count: analyses.filter((a) => a.health_score >= 60 && a.health_score < 75).length,
    poor_count: analyses.filter((a) => a.health_score < 60).length,
    avg_health_score: Math.round(
      analyses.reduce((sum, a) => sum + a.health_score, 0) / analyses.length
    ),
  };

  return {
    success: true,
    summary,
    analyses,
  };
}

async function simulateDiagnostics(supabase: any) {
  const { data: vehicles } = await supabase
    .from("vehicles")
    .select("id")
    .eq("status", "active");

  if (!vehicles || vehicles.length === 0) {
    return { success: true, message: "No active vehicles to simulate", inserted: 0 };
  }

  const diagnostics = vehicles.map((vehicle) => ({
    vehicle_id: vehicle.id,
    engine_temperature: 180 + Math.random() * 40,
    oil_pressure: 30 + Math.random() * 30,
    brake_wear_percentage: Math.random() * 100,
    tire_pressure_fl: 100 + Math.random() * 15,
    tire_pressure_fr: 100 + Math.random() * 15,
    tire_pressure_rl: 100 + Math.random() * 15,
    tire_pressure_rr: 100 + Math.random() * 15,
    transmission_temp: 160 + Math.random() * 40,
    diagnostic_codes: generateRandomDTC(),
    health_score: 60 + Math.random() * 40,
    recorded_at: new Date().toISOString(),
  }));

  const { error } = await supabase
    .from("vehicle_diagnostics")
    .insert(diagnostics);

  if (error) {
    return { success: false, message: error.message };
  }

  return {
    success: true,
    message: "Diagnostics simulated successfully",
    inserted: diagnostics.length,
  };
}

async function generateHealthAlerts(supabase: any) {
  const { data: vehicles } = await supabase
    .from("vehicles")
    .select("*, vehicle_diagnostics!inner(*)");

  const alerts = [];

  for (const vehicle of vehicles || []) {
    const latestDiag = vehicle.vehicle_diagnostics?.[0];
    if (!latestDiag) continue;

    if (latestDiag.engine_temperature > 210) {
      alerts.push({
        vehicle_id: vehicle.id,
        alert_type: "critical",
        component: "engine",
        message: `High engine temperature detected: ${latestDiag.engine_temperature}°F`,
        severity: "high",
      });
    }

    if (latestDiag.brake_wear_percentage > 80) {
      alerts.push({
        vehicle_id: vehicle.id,
        alert_type: "maintenance",
        component: "brakes",
        message: `Brake wear at ${Math.round(latestDiag.brake_wear_percentage)}% - replacement recommended`,
        severity: "medium",
      });
    }

    const avgTirePressure = (
      latestDiag.tire_pressure_fl +
      latestDiag.tire_pressure_fr +
      latestDiag.tire_pressure_rl +
      latestDiag.tire_pressure_rr
    ) / 4;

    if (avgTirePressure < 95) {
      alerts.push({
        vehicle_id: vehicle.id,
        alert_type: "maintenance",
        component: "tires",
        message: `Low tire pressure detected: ${Math.round(avgTirePressure)} PSI`,
        severity: "medium",
      });
    }

    if (latestDiag.diagnostic_codes && latestDiag.diagnostic_codes.length > 0) {
      alerts.push({
        vehicle_id: vehicle.id,
        alert_type: "diagnostic",
        component: "system",
        message: `Active diagnostic codes: ${latestDiag.diagnostic_codes.join(", ")}`,
        severity: "high",
      });
    }
  }

  return {
    success: true,
    alerts_generated: alerts.length,
    alerts,
  };
}

function calculateHealthScore(vehicle: any, diagnostic: any) {
  const mileage = vehicle.current_mileage || 0;
  const year = vehicle.year || new Date().getFullYear();
  const age = new Date().getFullYear() - year;

  let engineScore = 100;
  let brakeScore = 100;
  let transmissionScore = 100;
  let tireScore = 100;

  engineScore -= Math.min((mileage / 10000) * 0.5, 30);
  engineScore -= age * 2;

  if (diagnostic) {
    if (diagnostic.engine_temperature > 210) engineScore -= 15;
    if (diagnostic.oil_pressure < 20) engineScore -= 20;
    if (diagnostic.transmission_temp > 190) transmissionScore -= 15;
    if (diagnostic.brake_wear_percentage > 70) brakeScore -= (diagnostic.brake_wear_percentage - 70) * 0.5;

    const avgTirePressure = (
      diagnostic.tire_pressure_fl +
      diagnostic.tire_pressure_fr +
      diagnostic.tire_pressure_rl +
      diagnostic.tire_pressure_rr
    ) / 4;

    if (avgTirePressure < 95) tireScore -= (95 - avgTirePressure) * 2;
    if (diagnostic.diagnostic_codes?.length > 0) {
      engineScore -= diagnostic.diagnostic_codes.length * 5;
    }
  }

  engineScore = Math.max(Math.min(engineScore, 100), 0);
  brakeScore = Math.max(Math.min(brakeScore, 100), 0);
  transmissionScore = Math.max(Math.min(transmissionScore, 100), 0);
  tireScore = Math.max(Math.min(tireScore, 100), 0);

  const overall = Math.round((engineScore + brakeScore + transmissionScore + tireScore) / 4);

  return {
    overall,
    components: {
      engine: Math.round(engineScore),
      brakes: Math.round(brakeScore),
      transmission: Math.round(transmissionScore),
      tires: Math.round(tireScore),
    },
  };
}

function predictIssues(vehicle: any, diagnostic: any): string[] {
  const issues: string[] = [];
  const mileage = vehicle.current_mileage || 0;

  if (mileage > 100000) {
    issues.push("High mileage vehicle - increased monitoring recommended");
  }

  if (diagnostic) {
    if (diagnostic.engine_temperature > 200) {
      issues.push("Engine running hot - cooling system inspection needed");
    }

    if (diagnostic.oil_pressure < 25) {
      issues.push("Low oil pressure - immediate inspection required");
    }

    if (diagnostic.brake_wear_percentage > 75) {
      issues.push("Brake pads nearing end of life - schedule replacement");
    }

    if (diagnostic.transmission_temp > 180) {
      issues.push("Transmission temperature elevated - check fluid levels");
    }

    const minTirePressure = Math.min(
      diagnostic.tire_pressure_fl,
      diagnostic.tire_pressure_fr,
      diagnostic.tire_pressure_rl,
      diagnostic.tire_pressure_rr
    );

    if (minTirePressure < 90) {
      issues.push("One or more tires significantly underinflated");
    }
  }

  if (mileage % 15000 < 500 && mileage > 0) {
    issues.push("Scheduled maintenance due within 500 miles");
  }

  return issues;
}

function generateMaintenanceRecommendations(vehicle: any, healthScore: any, issues: string[]) {
  const recommendations: string[] = [];

  if (healthScore.overall < 70) {
    recommendations.push("Comprehensive vehicle inspection recommended");
  }

  if (healthScore.components.engine < 75) {
    recommendations.push("Engine diagnostics and tune-up recommended");
  }

  if (healthScore.components.brakes < 75) {
    recommendations.push("Brake system inspection and service needed");
  }

  if (healthScore.components.transmission < 75) {
    recommendations.push("Transmission service recommended");
  }

  if (healthScore.components.tires < 80) {
    recommendations.push("Tire rotation and alignment check needed");
  }

  if (issues.length > 3) {
    recommendations.push("PRIORITY: Multiple issues detected - schedule immediate service");
  }

  if (recommendations.length === 0) {
    recommendations.push("Vehicle in good condition - continue routine maintenance");
  }

  return recommendations;
}

function getHealthStatus(score: number): string {
  if (score >= 90) return "excellent";
  if (score >= 75) return "good";
  if (score >= 60) return "fair";
  return "poor";
}

function calculateNextMaintenance(vehicle: any): number {
  const mileage = vehicle.current_mileage || 0;
  const nextService = Math.ceil(mileage / 5000) * 5000;
  return Math.max(nextService - mileage, 0);
}

function calculateCostSavings(issueCount: number, healthScore: number): number {
  let savings = 500;

  if (issueCount > 2) {
    savings += issueCount * 800;
  } else if (issueCount > 0) {
    savings += issueCount * 400;
  }

  if (healthScore < 70) {
    savings += 1500;
  }

  return savings;
}

function generateRandomDTC(): string[] {
  const dtcCodes = [
    "P0300", "P0420", "P0171", "P0174", "P0128",
    "P0442", "P0455", "P0507", "P1404", "P2002"
  ];

  const shouldHaveDTC = Math.random() > 0.7;
  if (!shouldHaveDTC) return [];

  const numCodes = Math.floor(Math.random() * 3) + 1;
  const selectedCodes = [];
  for (let i = 0; i < numCodes; i++) {
    selectedCodes.push(dtcCodes[Math.floor(Math.random() * dtcCodes.length)]);
  }

  return [...new Set(selectedCodes)];
}