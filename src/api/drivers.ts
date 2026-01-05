import { supabase } from '../lib/supabase';
import { getUserOrganizationId, checkDriverLimit, getOrganizationTierLimits } from './organization';
import { isDemoMode, DEMO_DRIVERS } from '../lib/demoData';

export interface Driver {
  id: string;
  organization_id: string;
  first_name: string;
  last_name: string;
  email: string;
  phone: string | null;
  license_number: string;
  license_expiry: string;
  hire_date: string;
  status: 'active' | 'training' | 'inactive';
  safety_score: number;
  created_at: string;
  updated_at: string;
}

export interface CreateDriverInput {
  first_name: string;
  last_name: string;
  email: string;
  phone?: string;
  license_number: string;
  license_expiry: string;
  hire_date?: string;
  status?: 'active' | 'training' | 'inactive';
  safety_score?: number;
}

export interface UpdateDriverInput {
  first_name?: string;
  last_name?: string;
  email?: string;
  phone?: string;
  license_number?: string;
  license_expiry?: string;
  hire_date?: string;
  status?: 'active' | 'training' | 'inactive';
  safety_score?: number;
}

export const driverAPI = {
  async getAll(): Promise<Driver[]> {
    if (isDemoMode()) {
      await new Promise(resolve => setTimeout(resolve, 100));
      return DEMO_DRIVERS.map(d => {
        const [firstName, ...lastNameParts] = d.name.split(' ');
        return {
          id: d.id,
          organization_id: 'demo-org-12345',
          first_name: firstName,
          last_name: lastNameParts.join(' '),
          email: d.email,
          phone: d.phone,
          license_number: d.license_number,
          license_expiry: d.license_expiry,
          hire_date: d.hire_date,
          status: d.status as 'active' | 'training' | 'inactive',
          safety_score: d.safety_score,
          created_at: d.created_at,
          updated_at: d.created_at,
        };
      }) as Driver[];
    }

    const { data, error } = await supabase
      .from('drivers')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  async getById(id: string): Promise<Driver | null> {
    const { data, error } = await supabase
      .from('drivers')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async create(input: CreateDriverInput): Promise<Driver> {
    const orgId = await getUserOrganizationId();
    if (!orgId) {
      throw new Error('Action failed: No organization is associated with your profile. Please refresh the page or contact support.');
    }

    const canAddDriver = await checkDriverLimit();
    if (!canAddDriver) {
      const limits = await getOrganizationTierLimits();
      throw new Error(`Driver limit reached (${limits.max_drivers}). Please upgrade your plan to add more drivers.`);
    }

    const { data, error } = await supabase
      .from('drivers')
      .insert([{
        ...input,
        organization_id: orgId,
        status: input.status || 'active',
        safety_score: input.safety_score || 100.0,
        hire_date: input.hire_date || new Date().toISOString().split('T')[0],
      }])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async update(id: string, input: UpdateDriverInput): Promise<Driver> {
    const { data, error } = await supabase
      .from('drivers')
      .update({
        ...input,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async delete(id: string): Promise<void> {
    const { error } = await supabase
      .from('drivers')
      .delete()
      .eq('id', id);

    if (error) throw error;
  },

  async search(query: string): Promise<Driver[]> {
    const { data, error } = await supabase
      .from('drivers')
      .select('*')
      .or(`first_name.ilike.%${query}%,last_name.ilike.%${query}%,email.ilike.%${query}%,license_number.ilike.%${query}%`)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  async filterByStatus(status: string): Promise<Driver[]> {
    const { data, error } = await supabase
      .from('drivers')
      .select('*')
      .eq('status', status)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  async getExpiringLicenses(daysAhead: number = 30): Promise<Driver[]> {
    const today = new Date();
    const futureDate = new Date();
    futureDate.setDate(today.getDate() + daysAhead);

    const { data, error } = await supabase
      .from('drivers')
      .select('*')
      .gte('license_expiry', today.toISOString().split('T')[0])
      .lte('license_expiry', futureDate.toISOString().split('T')[0])
      .order('license_expiry', { ascending: true });

    if (error) throw error;
    return data || [];
  },
};
