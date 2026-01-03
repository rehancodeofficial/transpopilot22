// TranspoPilot AI Integration API
export interface IntegrationConfig {
  apiKey: string;
  companyId: string;
  environment: 'sandbox' | 'production';
  webhookUrl?: string;
}

export interface TruckingCompanyData {
  vehicles: Vehicle[];
  drivers: Driver[];
  routes: Route[];
  fuelRecords: FuelRecord[];
}

export interface Vehicle {
  id: string;
  vin: string;
  make: string;
  model: string;
  year: number;
  licensePlate: string;
  currentLocation: {
    lat: number;
    lng: number;
    timestamp: string;
  };
  fuelLevel: number;
  mileage: number;
  status: 'active' | 'maintenance' | 'inactive';
}

export interface Driver {
  id: string;
  employeeId: string;
  firstName: string;
  lastName: string;
  licenseNumber: string;
  licenseExpiry: string;
  phone: string;
  email: string;
  status: 'active' | 'inactive' | 'on-duty' | 'off-duty';
  currentVehicleId?: string;
  hoursOfService: {
    driving: number;
    onDuty: number;
    remaining: number;
  };
}

export interface Route {
  id: string;
  name: string;
  startLocation: string;
  endLocation: string;
  waypoints: Array<{
    lat: number;
    lng: number;
    address: string;
    estimatedArrival: string;
  }>;
  assignedVehicleId: string;
  assignedDriverId: string;
  status: 'planned' | 'in-progress' | 'completed' | 'delayed';
}

export interface FuelRecord {
  id: string;
  vehicleId: string;
  driverId: string;
  location: string;
  gallons: number;
  costPerGallon: number;
  totalCost: number;
  timestamp: string;
  odometer: number;
}

export class TranspoPilotAPI {
  private config: IntegrationConfig;
  private baseUrl: string;

  constructor(config: IntegrationConfig) {
    this.config = config;
    this.baseUrl = config.environment === 'production' 
      ? 'https://api.transpopilot.ai/v1' 
      : 'https://sandbox-api.transpopilot.ai/v1';
  }

  private async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      ...options,
      headers: {
        'Authorization': `Bearer ${this.config.apiKey}`,
        'Content-Type': 'application/json',
        'X-Company-ID': this.config.companyId,
        ...options.headers,
      },
    });

    if (!response.ok) {
      throw new Error(`API Error: ${response.status} ${response.statusText}`);
    }

    return response.json();
  }

  // Vehicle Management
  async syncVehicles(vehicles: Vehicle[]): Promise<{ success: boolean; synced: number }> {
    return this.request('/vehicles/sync', {
      method: 'POST',
      body: JSON.stringify({ vehicles }),
    });
  }

  async updateVehicleLocation(vehicleId: string, location: { lat: number; lng: number }): Promise<void> {
    await this.request(`/vehicles/${vehicleId}/location`, {
      method: 'PUT',
      body: JSON.stringify(location),
    });
  }

  async getVehicleInsights(vehicleId: string): Promise<{
    fuelEfficiency: number;
    maintenanceAlerts: string[];
    routeOptimizations: string[];
  }> {
    return this.request(`/vehicles/${vehicleId}/insights`);
  }

  // Driver Management
  async syncDrivers(drivers: Driver[]): Promise<{ success: boolean; synced: number }> {
    return this.request('/drivers/sync', {
      method: 'POST',
      body: JSON.stringify({ drivers }),
    });
  }

  async updateDriverStatus(driverId: string, status: Driver['status']): Promise<void> {
    await this.request(`/drivers/${driverId}/status`, {
      method: 'PUT',
      body: JSON.stringify({ status }),
    });
  }

  async getDriverSafetyScore(driverId: string): Promise<{
    score: number;
    incidents: number;
    trainingStatus: string;
    recommendations: string[];
  }> {
    return this.request(`/drivers/${driverId}/safety`);
  }

  // Route Optimization
  async optimizeRoute(route: Omit<Route, 'id'>): Promise<{
    optimizedRoute: Route;
    fuelSavings: number;
    timeSavings: number;
    distanceReduction: number;
  }> {
    return this.request('/routes/optimize', {
      method: 'POST',
      body: JSON.stringify(route),
    });
  }

  async trackRoute(routeId: string): Promise<{
    currentLocation: { lat: number; lng: number };
    eta: string;
    delayMinutes: number;
    fuelConsumed: number;
  }> {
    return this.request(`/routes/${routeId}/track`);
  }

  // Fuel Management
  async recordFuelPurchase(fuelRecord: Omit<FuelRecord, 'id'>): Promise<FuelRecord> {
    return this.request('/fuel/record', {
      method: 'POST',
      body: JSON.stringify(fuelRecord),
    });
  }

  async getFuelAnalytics(timeframe: 'week' | 'month' | 'quarter'): Promise<{
    totalCost: number;
    averageMPG: number;
    topPerformers: Array<{ driverId: string; mpg: number }>;
    recommendations: string[];
  }> {
    return this.request(`/fuel/analytics?timeframe=${timeframe}`);
  }

  // Compliance & Safety
  async getComplianceAlerts(): Promise<Array<{
    type: string;
    entityId: string;
    description: string;
    dueDate: string;
    priority: 'low' | 'medium' | 'high' | 'critical';
  }>> {
    return this.request('/compliance/alerts');
  }

  async reportIncident(incident: {
    driverId: string;
    vehicleId: string;
    type: string;
    description: string;
    location: string;
    severity: 'low' | 'medium' | 'high';
  }): Promise<{ incidentId: string }> {
    return this.request('/safety/incidents', {
      method: 'POST',
      body: JSON.stringify(incident),
    });
  }

  // Webhooks for real-time updates
  async setupWebhook(events: string[]): Promise<{ webhookId: string }> {
    return this.request('/webhooks', {
      method: 'POST',
      body: JSON.stringify({
        url: this.config.webhookUrl,
        events,
      }),
    });
  }
}

// Usage Example
export const initializeTranspoPilot = (config: IntegrationConfig) => {
  return new TranspoPilotAPI(config);
};