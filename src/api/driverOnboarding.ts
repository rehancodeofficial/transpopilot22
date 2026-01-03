import { supabase } from '../lib/supabase';

export interface OnboardingProgress {
  id: string;
  driver_id: string;
  user_id: string;
  organization_id: string;
  current_step: string;
  completion_percentage: number;
  status: 'not_started' | 'in_progress' | 'completed';
  started_at: string | null;
  completed_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface TrainingModule {
  id: string;
  organization_id: string | null;
  title: string;
  description: string | null;
  content_type: 'video' | 'document' | 'quiz' | 'interactive';
  content_url: string | null;
  duration_minutes: number;
  is_required: boolean;
  display_order: number;
  passing_score: number | null;
  created_at: string;
  updated_at: string;
}

export interface TrainingCompletion {
  id: string;
  driver_id: string;
  user_id: string;
  training_module_id: string;
  organization_id: string;
  completed_at: string;
  time_spent_minutes: number;
  quiz_score: number | null;
  status: 'completed' | 'in_progress' | 'failed';
  created_at: string;
}

export interface DocumentRequirement {
  id: string;
  organization_id: string | null;
  document_type: string;
  title: string;
  description: string | null;
  is_required: boolean;
  display_order: number;
  accepted_file_types: string[];
  max_file_size_mb: number;
  created_at: string;
  updated_at: string;
}

export interface DriverDocument {
  id: string;
  driver_id: string;
  user_id: string;
  document_requirement_id: string | null;
  organization_id: string;
  file_name: string;
  file_path: string;
  file_size_bytes: number;
  file_type: string;
  approval_status: 'pending' | 'approved' | 'rejected';
  reviewed_by: string | null;
  reviewed_at: string | null;
  rejection_reason: string | null;
  uploaded_at: string;
  created_at: string;
  updated_at: string;
}

export interface ModuleWithCompletion extends TrainingModule {
  completion?: TrainingCompletion;
}

export interface RequirementWithDocument extends DocumentRequirement {
  document?: DriverDocument;
}

// Get driver onboarding progress by user ID
export async function getDriverOnboardingProgress(userId: string): Promise<OnboardingProgress | null> {
  const { data, error } = await supabase
    .from('driver_onboarding_progress')
    .select('*')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) throw error;
  return data;
}

// Get or create driver onboarding progress
export async function getOrCreateOnboardingProgress(
  userId: string,
  driverId: string,
  organizationId: string
): Promise<OnboardingProgress> {
  let progress = await getDriverOnboardingProgress(userId);

  if (!progress) {
    const { data, error } = await supabase
      .from('driver_onboarding_progress')
      .insert({
        driver_id: driverId,
        user_id: userId,
        organization_id: organizationId,
        status: 'in_progress',
        started_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (error) throw error;
    progress = data;
  }

  return progress;
}

// Update onboarding progress
export async function updateOnboardingProgress(
  userId: string,
  updates: Partial<OnboardingProgress>
): Promise<OnboardingProgress> {
  const { data, error } = await supabase
    .from('driver_onboarding_progress')
    .update(updates)
    .eq('user_id', userId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

// Get all training modules for organization
export async function getTrainingModules(organizationId: string | null): Promise<TrainingModule[]> {
  const { data, error } = await supabase
    .from('training_modules')
    .select('*')
    .or(`organization_id.is.null,organization_id.eq.${organizationId}`)
    .order('display_order', { ascending: true });

  if (error) throw error;
  return data || [];
}

// Get training modules with completion status for a driver
export async function getTrainingModulesWithCompletion(
  userId: string,
  driverId: string,
  organizationId: string | null
): Promise<ModuleWithCompletion[]> {
  const modules = await getTrainingModules(organizationId);

  const { data: completions, error } = await supabase
    .from('driver_training_completions')
    .select('*')
    .eq('user_id', userId)
    .eq('driver_id', driverId);

  if (error) throw error;

  const completionMap = new Map(
    (completions || []).map(c => [c.training_module_id, c])
  );

  return modules.map(module => ({
    ...module,
    completion: completionMap.get(module.id),
  }));
}

// Mark training module as complete
export async function completeTrainingModule(
  userId: string,
  driverId: string,
  trainingModuleId: string,
  organizationId: string,
  timeSpentMinutes: number,
  quizScore?: number
): Promise<TrainingCompletion> {
  const { data, error } = await supabase
    .from('driver_training_completions')
    .upsert({
      user_id: userId,
      driver_id: driverId,
      training_module_id: trainingModuleId,
      organization_id: organizationId,
      time_spent_minutes: timeSpentMinutes,
      quiz_score: quizScore,
      status: 'completed',
      completed_at: new Date().toISOString(),
    }, { onConflict: 'driver_id,training_module_id' })
    .select()
    .single();

  if (error) throw error;

  // Recalculate progress
  await calculateAndUpdateProgress(userId, driverId, organizationId);

  return data;
}

// Get all document requirements
export async function getDocumentRequirements(organizationId: string | null): Promise<DocumentRequirement[]> {
  const { data, error } = await supabase
    .from('document_requirements')
    .select('*')
    .or(`organization_id.is.null,organization_id.eq.${organizationId}`)
    .order('display_order', { ascending: true });

  if (error) throw error;
  return data || [];
}

// Get document requirements with uploaded documents for a driver
export async function getDocumentRequirementsWithUploads(
  userId: string,
  driverId: string,
  organizationId: string | null
): Promise<RequirementWithDocument[]> {
  const requirements = await getDocumentRequirements(organizationId);

  const { data: documents, error } = await supabase
    .from('driver_documents')
    .select('*')
    .eq('user_id', userId)
    .eq('driver_id', driverId);

  if (error) throw error;

  const documentMap = new Map(
    (documents || []).map(d => [d.document_requirement_id, d])
  );

  return requirements.map(req => ({
    ...req,
    document: documentMap.get(req.id),
  }));
}

// Upload driver document
export async function uploadDriverDocument(
  file: File,
  userId: string,
  driverId: string,
  requirementId: string,
  organizationId: string
): Promise<DriverDocument> {
  const fileExt = file.name.split('.').pop();
  const fileName = `${userId}/${requirementId}/${Date.now()}.${fileExt}`;

  const { data: uploadData, error: uploadError } = await supabase.storage
    .from('driver-documents')
    .upload(fileName, file);

  if (uploadError) throw uploadError;

  const { data, error } = await supabase
    .from('driver_documents')
    .insert({
      user_id: userId,
      driver_id: driverId,
      document_requirement_id: requirementId,
      organization_id: organizationId,
      file_name: file.name,
      file_path: uploadData.path,
      file_size_bytes: file.size,
      file_type: file.type,
      approval_status: 'pending',
      uploaded_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (error) throw error;

  // Recalculate progress
  await calculateAndUpdateProgress(userId, driverId, organizationId);

  return data;
}

// Get driver documents
export async function getDriverDocuments(
  userId: string,
  driverId: string
): Promise<DriverDocument[]> {
  const { data, error } = await supabase
    .from('driver_documents')
    .select('*')
    .eq('user_id', userId)
    .eq('driver_id', driverId)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data || [];
}

// Get document download URL
export async function getDocumentDownloadUrl(filePath: string): Promise<string> {
  const { data, error } = await supabase.storage
    .from('driver-documents')
    .createSignedUrl(filePath, 3600); // 1 hour expiry

  if (error) throw error;
  return data.signedUrl;
}

// Admin: Approve document
export async function approveDocument(documentId: string, reviewerId: string): Promise<DriverDocument> {
  const { data, error } = await supabase
    .from('driver_documents')
    .update({
      approval_status: 'approved',
      reviewed_by: reviewerId,
      reviewed_at: new Date().toISOString(),
      rejection_reason: null,
    })
    .eq('id', documentId)
    .select()
    .single();

  if (error) throw error;

  // Recalculate progress for this driver
  if (data) {
    await calculateAndUpdateProgress(data.user_id, data.driver_id, data.organization_id);
  }

  return data;
}

// Admin: Reject document
export async function rejectDocument(
  documentId: string,
  reviewerId: string,
  reason: string
): Promise<DriverDocument> {
  const { data, error } = await supabase
    .from('driver_documents')
    .update({
      approval_status: 'rejected',
      reviewed_by: reviewerId,
      reviewed_at: new Date().toISOString(),
      rejection_reason: reason,
    })
    .eq('id', documentId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

// Admin: Get all drivers in onboarding
export async function getAllDriversInOnboarding(organizationId: string) {
  const { data, error } = await supabase
    .from('driver_onboarding_progress')
    .select(`
      *,
      drivers:driver_id (
        id,
        first_name,
        last_name,
        email,
        status
      )
    `)
    .eq('organization_id', organizationId)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data || [];
}

// Admin: Get pending documents for review
export async function getPendingDocuments(organizationId: string) {
  const { data, error } = await supabase
    .from('driver_documents')
    .select(`
      *,
      drivers:driver_id (
        id,
        first_name,
        last_name,
        email
      ),
      document_requirements:document_requirement_id (
        title,
        document_type
      )
    `)
    .eq('organization_id', organizationId)
    .eq('approval_status', 'pending')
    .order('uploaded_at', { ascending: true });

  if (error) throw error;
  return data || [];
}

// Calculate and update onboarding progress
async function calculateAndUpdateProgress(
  userId: string,
  driverId: string,
  organizationId: string
): Promise<void> {
  // Get required modules count and completed count
  const modules = await getTrainingModules(organizationId);
  const requiredModules = modules.filter(m => m.is_required);

  const { data: completions } = await supabase
    .from('driver_training_completions')
    .select('*')
    .eq('user_id', userId)
    .eq('driver_id', driverId)
    .eq('status', 'completed');

  const completedRequiredModules = requiredModules.filter(m =>
    completions?.some(c => c.training_module_id === m.id)
  ).length;

  // Get required documents count and approved count
  const requirements = await getDocumentRequirements(organizationId);
  const requiredDocs = requirements.filter(r => r.is_required);

  const { data: documents } = await supabase
    .from('driver_documents')
    .select('*')
    .eq('user_id', userId)
    .eq('driver_id', driverId)
    .eq('approval_status', 'approved');

  const approvedRequiredDocs = requiredDocs.filter(r =>
    documents?.some(d => d.document_requirement_id === r.id)
  ).length;

  // Calculate overall completion percentage
  const totalRequired = requiredModules.length + requiredDocs.length;
  const totalCompleted = completedRequiredModules + approvedRequiredDocs;
  const completionPercentage = totalRequired > 0
    ? Math.round((totalCompleted / totalRequired) * 100)
    : 0;

  // Determine status
  let status: 'not_started' | 'in_progress' | 'completed' = 'in_progress';
  let completedAt: string | null = null;

  if (completionPercentage === 100) {
    status = 'completed';
    completedAt = new Date().toISOString();

    // Update driver status to active
    await supabase
      .from('drivers')
      .update({ status: 'active' })
      .eq('id', driverId);
  } else if (completionPercentage === 0) {
    status = 'not_started';
  }

  // Update progress
  await supabase
    .from('driver_onboarding_progress')
    .update({
      completion_percentage: completionPercentage,
      status,
      completed_at: completedAt,
    })
    .eq('user_id', userId)
    .eq('driver_id', driverId);
}

// Get driver ID for current user
export async function getDriverIdForUser(userId: string): Promise<string | null> {
  const { data, error } = await supabase
    .from('drivers')
    .select('id')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) throw error;
  return data?.id || null;
}
