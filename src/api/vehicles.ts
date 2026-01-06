import { supabase } from '../lib/supabase';
import { getUserOrganizationId, checkVehicleLimit, getOrganizationTierLimits } from './organization';
import { handleSupabaseError } from '../lib/errorHandler';
import { isDemoMode, DEMO_VEHICLES } from '../lib/demoData';

export interface Vehicle {
  id: string;
  organization_id: string;
  vehicle_number: string;
  make: string;
  model: string;
  year: number;
  vin: string;
  status: 'active' | 'maintenance' | 'inactive';
  current_mileage: number;
  fuel_capacity: number;
  created_at: string;
  updated_at: string;
}

export interface CreateVehicleInput {
  vehicle_number: string;
  make: string;
  model: string;
  year: number;
  vin: string;
  status?: 'active' | 'maintenance' | 'inactive';
  current_mileage?: number;
  fuel_capacity?: number;
}

export interface UpdateVehicleInput {
  vehicle_number?: string;
  make?: string;
  model?: string;
  year?: number;
  vin?: string;
  status?: 'active' | 'maintenance' | 'inactive';
  current_mileage?: number;
  fuel_capacity?: number;
}

export const vehicleAPI = {
  async getAll(): Promise<Vehicle[]> {
    if (isDemoMode()) {
      await new Promise(resolve => setTimeout(resolve, 100));
      return DEMO_VEHICLES.map(v => ({
        ...v,
        organization_id: 'demo-org-12345',
        fuel_capacity: 200,
        current_mileage: v.mileage,
        updated_at: v.created_at,
      })) as Vehicle[];
    }

    const { data, error } = await supabase
      .from('vehicles')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) handleSupabaseError(error, 'load vehicles');
    return data || [];
  },

  async getById(id: string): Promise<Vehicle | null> {
    const { data, error } = await supabase
      .from('vehicles')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) handleSupabaseError(error, 'load vehicle');
    return data;
  },

  async create(input: CreateVehicleInput): Promise<Vehicle> {
    const orgId = await getUserOrganizationId();
    if (!orgId) {
      throw new Error('Action failed: No organization is associated with your profile. Please refresh the page or contact support.');
    }

    const canAddVehicle = await checkVehicleLimit();
    if (!canAddVehicle) {
      const limits = await getOrganizationTierLimits();
      throw new Error(`Vehicle limit reached (${limits.max_vehicles}). Please upgrade your plan to add more vehicles.`);
    }

    const { data, error } = await supabase
      .from('vehicles')
      .insert([{
        ...input,
        organization_id: orgId,
        status: input.status || 'active',
        current_mileage: input.current_mileage || 0,
      }])
      .select()
      .single();

    if (error) {
      console.error('Error creating vehicle:', error);
      handleSupabaseError(error, 'create vehicle');
    }
    return data;
  },

  async update(id: string, input: UpdateVehicleInput): Promise<Vehicle> {
    const { data, error } = await supabase
      .from('vehicles')
      .update({
        ...input,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single();

    if (error) handleSupabaseError(error, 'update vehicle');
    return data;
  },

  async delete(id: string): Promise<void> {
    const { error } = await supabase
      .from('vehicles')
      .delete()
      .eq('id', id);

    if (error) handleSupabaseError(error, 'delete vehicle');
  },

  async search(query: string): Promise<Vehicle[]> {
    const { data, error } = await supabase
      .from('vehicles')
      .select('*')
      .or(`vehicle_number.ilike.%${query}%,make.ilike.%${query}%,model.ilike.%${query}%,vin.ilike.%${query}%`)
      .order('created_at', { ascending: false });

    if (error) handleSupabaseError(error, 'search vehicles');
    return data || [];
  },

  async filterByStatus(status: string): Promise<Vehicle[]> {
    const { data, error } = await supabase
      .from('vehicles')
      .select('*')
      .eq('status', status)
      .order('created_at', { ascending: false });

    if (error) handleSupabaseError(error, 'filter vehicles');
    return data || [];
  },
};
