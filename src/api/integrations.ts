import { supabase } from '../lib/supabase';
import {
  IntegrationProvider,
  IntegrationCredentials,
  IntegrationSyncLog,
  IntegrationMapping,
} from '../types/tracking';

export async function getIntegrationProviders(): Promise<IntegrationProvider[]> {
  const { data, error } = await supabase
    .from('integration_providers')
    .select('*')
    .order('display_name');

  if (error) throw error;
  return data || [];
}

export async function getIntegrationProvider(name: string): Promise<IntegrationProvider | null> {
  const { data, error } = await supabase
    .from('integration_providers')
    .select('*')
    .eq('name', name)
    .maybeSingle();

  if (error) throw error;
  return data;
}

export async function updateIntegrationProvider(
  id: string,
  updates: Partial<IntegrationProvider>
): Promise<IntegrationProvider> {
  const { data, error } = await supabase
    .from('integration_providers')
    .update({ ...updates, updated_at: new Date().toISOString() })
    .eq('id', id)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function getIntegrationCredentials(providerId: string): Promise<IntegrationCredentials | null> {
  const { data, error } = await supabase
    .from('integration_credentials')
    .select('*')
    .eq('provider_id', providerId)
    .maybeSingle();

  if (error) throw error;
  return data;
}

export async function upsertIntegrationCredentials(
  credentials: Omit<IntegrationCredentials, 'id' | 'created_at' | 'updated_at'>
): Promise<IntegrationCredentials> {
  const { data, error } = await supabase
    .from('integration_credentials')
    .upsert(
      { ...credentials, updated_at: new Date().toISOString() },
      { onConflict: 'provider_id' }
    )
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function deleteIntegrationCredentials(providerId: string): Promise<void> {
  const { error } = await supabase
    .from('integration_credentials')
    .delete()
    .eq('provider_id', providerId);

  if (error) throw error;
}

export async function getIntegrationSyncLogs(providerId?: string, limit = 50): Promise<IntegrationSyncLog[]> {
  let query = supabase
    .from('integration_sync_logs')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(limit);

  if (providerId) {
    query = query.eq('provider_id', providerId);
  }

  const { data, error } = await query;

  if (error) throw error;
  return data || [];
}

export async function createSyncLog(
  log: Omit<IntegrationSyncLog, 'id' | 'created_at'>
): Promise<IntegrationSyncLog> {
  const { data, error } = await supabase
    .from('integration_sync_logs')
    .insert(log)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function updateSyncLog(
  id: string,
  updates: Partial<IntegrationSyncLog>
): Promise<IntegrationSyncLog> {
  const { data, error } = await supabase
    .from('integration_sync_logs')
    .update(updates)
    .eq('id', id)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function getIntegrationMappings(
  providerId: string,
  entityType?: 'vehicle' | 'driver' | 'route'
): Promise<IntegrationMapping[]> {
  let query = supabase
    .from('integration_mappings')
    .select('*')
    .eq('provider_id', providerId);

  if (entityType) {
    query = query.eq('entity_type', entityType);
  }

  const { data, error } = await query;

  if (error) throw error;
  return data || [];
}

export async function createMapping(
  mapping: Omit<IntegrationMapping, 'id' | 'created_at'>
): Promise<IntegrationMapping> {
  const { data, error } = await supabase
    .from('integration_mappings')
    .insert(mapping)
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function testIntegrationConnection(
  provider: string,
  credentials: Partial<IntegrationCredentials>
): Promise<{ success: boolean; message: string }> {
  try {
    const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
    const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

    const functionMap: Record<string, string> = {
      geotab: 'geotab-sync',
      samsara: 'samsara-sync',
      motive: 'motive-sync',
      custom: 'custom-fleet-sync',
    };

    const functionName = functionMap[provider];
    if (!functionName) {
      return { success: false, message: 'Unknown provider' };
    }

    const hasCredentials = credentials && Object.keys(credentials).length > 0;
    
    const response = await fetch(
      `${supabaseUrl}/functions/v1/${functionName}?action=test`,
      {
        method: hasCredentials ? 'POST' : 'GET',
        headers: {
          'Authorization': `Bearer ${supabaseKey}`,
          'Content-Type': 'application/json',
        },
        body: hasCredentials ? JSON.stringify({ credentials }) : undefined,
      }
    );

    if (!response.ok) {
      const errorData = await response.json();
      return { success: false, message: errorData.error || 'Connection test failed' };
    }

    const result = await response.json();
    return result;
  } catch (error) {
    return { success: false, message: error instanceof Error ? error.message : 'Connection failed' };
  }
}

export async function activateMonitoring(providerId: string): Promise<void> {
  try {
    const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
    const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

    const response = await fetch(
      `${supabaseUrl}/functions/v1/system-health-monitor?action=monitor-integrations`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${supabaseKey}`,
          'Content-Type': 'application/json',
        },
      }
    );

    if (!response.ok) {
      console.error('Failed to activate monitoring:', await response.text());
    }
  } catch (error) {
    console.error('Error activating monitoring:', error);
  }
}

export async function triggerSync(
  providerId: string,
  syncType: IntegrationSyncLog['sync_type']
): Promise<IntegrationSyncLog> {
  const log = await createSyncLog({
    provider_id: providerId,
    sync_type: syncType,
    status: 'running',
    records_processed: 0,
    records_success: 0,
    records_failed: 0,
    started_at: new Date().toISOString(),
  });

  const provider = await getIntegrationProviderById(providerId);
  if (!provider) {
    return log;
  }

  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

  const functionMap: Record<string, string> = {
    geotab: 'geotab-sync',
    samsara: 'samsara-sync',
    motive: 'motive-sync',
    custom: 'custom-fleet-sync',
  };

  const functionName = functionMap[provider.name];
  if (functionName) {
    const actionMap: Record<string, string> = {
      vehicles: 'sync-vehicles',
      drivers: 'sync-drivers',
      locations: 'sync-locations',
      fuel: 'sync-fuel',
      safety: 'sync-safety',
    };

    const action = actionMap[syncType] || syncType;

    fetch(`${supabaseUrl}/functions/v1/${functionName}?action=${action}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${supabaseKey}`,
        'Content-Type': 'application/json',
      },
    }).catch((error) => {
      console.error('Sync trigger failed:', error);
    });
  }

  return log;
}

async function getIntegrationProviderById(id: string) {
  const { data } = await supabase
    .from('integration_providers')
    .select('*')
    .eq('id', id)
    .maybeSingle();
  return data;
}
