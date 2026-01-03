import React, { useState, useEffect } from 'react';
import { CheckCircle, Clock, Upload, FileText, PlayCircle, BookOpen, AlertCircle } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import {
  getDriverIdForUser,
  getOrCreateOnboardingProgress,
  getTrainingModulesWithCompletion,
  getDocumentRequirementsWithUploads,
  completeTrainingModule,
  uploadDriverDocument,
  OnboardingProgress
} from '../api/driverOnboarding';
import LoadingSpinner from './LoadingSpinner';
import ErrorMessage from './ErrorMessage';

const DriverSelfOnboarding: React.FC = () => {
  const { user, profile } = useAuth();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [progress, setProgress] = useState<OnboardingProgress | null>(null);
  const [modules, setModules] = useState<any[]>([]);
  const [documents, setDocuments] = useState<any[]>([]);
  const [driverId, setDriverId] = useState<string | null>(null);
  const [uploading, setUploading] = useState<string | null>(null);

  useEffect(() => {
    loadData();
  }, [user?.id]);

  const loadData = async () => {
    if (!user?.id || !profile?.organization_id) return;

    try {
      setLoading(true);
      setError('');

      const id = await getDriverIdForUser(user.id);
      if (!id) {
        setError('You are not registered as a driver');
        return;
      }

      setDriverId(id);

      const [prog, mods, docs] = await Promise.all([
        getOrCreateOnboardingProgress(user.id, id, profile.organization_id),
        getTrainingModulesWithCompletion(user.id, id, profile.organization_id),
        getDocumentRequirementsWithUploads(user.id, id, profile.organization_id),
      ]);

      setProgress(prog);
      setModules(mods);
      setDocuments(docs);
    } catch (err: any) {
      setError(err.message || 'Failed to load onboarding data');
    } finally {
      setLoading(false);
    }
  };

  const handleCompleteModule = async (moduleId: string) => {
    if (!user?.id || !driverId || !profile?.organization_id) return;

    try {
      await completeTrainingModule(user.id, driverId, moduleId, profile.organization_id, 30);
      await loadData();
    } catch (err: any) {
      setError(err.message || 'Failed to complete module');
    }
  };

  const handleFileUpload = async (requirementId: string, file: File) => {
    if (!user?.id || !driverId || !profile?.organization_id) return;

    try {
      setUploading(requirementId);
      await uploadDriverDocument(file, user.id, driverId, requirementId, profile.organization_id);
      await loadData();
    } catch (err: any) {
      setError(err.message || 'Failed to upload document');
    } finally {
      setUploading(null);
    }
  };

  if (loading) return <LoadingSpinner />;
  if (!driverId) return <ErrorMessage message="You are not registered as a driver" />;

  const completedModules = modules.filter(m => m.completion).length;
  const totalModules = modules.filter(m => m.is_required).length;
  const uploadedDocs = documents.filter(d => d.document?.approval_status === 'approved').length;
  const totalDocs = documents.filter(d => d.is_required).length;

  return (
    <div className="p-4 md:p-6 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">My Onboarding</h1>
        <p className="text-gray-600">Complete your training and upload required documents</p>
      </div>

      {error && <ErrorMessage message={error} onDismiss={() => setError('')} />}

      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-medium text-gray-900">Overall Progress</h2>
          <span className="text-2xl font-bold text-blue-600">{progress?.completion_percentage || 0}%</span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-4 mb-4">
          <div
            className="bg-blue-600 h-4 rounded-full transition-all duration-300"
            style={{ width: `${progress?.completion_percentage || 0}%` }}
          />
        </div>
        <div className="grid grid-cols-2 gap-4 text-sm">
          <div>
            <p className="text-gray-500">Training Modules</p>
            <p className="font-medium">{completedModules} / {totalModules} completed</p>
          </div>
          <div>
            <p className="text-gray-500">Documents</p>
            <p className="font-medium">{uploadedDocs} / {totalDocs} approved</p>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h2 className="text-lg font-medium text-gray-900">Training Modules</h2>
        </div>
        <div className="divide-y divide-gray-200">
          {modules.map((module) => (
            <div key={module.id} className="p-6">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center space-x-3 mb-2">
                    {module.completion ? (
                      <CheckCircle className="h-5 w-5 text-green-600" />
                    ) : (
                      <PlayCircle className="h-5 w-5 text-gray-400" />
                    )}
                    <div>
                      <h3 className="font-medium text-gray-900">{module.title}</h3>
                      {module.is_required && (
                        <span className="inline-block mt-1 px-2 py-0.5 text-xs font-medium bg-red-100 text-red-800 rounded">
                          Required
                        </span>
                      )}
                    </div>
                  </div>
                  <p className="text-sm text-gray-600 ml-8">{module.description}</p>
                  <div className="ml-8 mt-2 flex items-center space-x-4 text-sm text-gray-500">
                    <span>{module.duration_minutes} minutes</span>
                    <span>{module.content_type}</span>
                  </div>
                </div>
                {!module.completion && (
                  <button
                    onClick={() => handleCompleteModule(module.id)}
                    className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                  >
                    Start Module
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h2 className="text-lg font-medium text-gray-900">Required Documents</h2>
        </div>
        <div className="divide-y divide-gray-200">
          {documents.map((req) => (
            <div key={req.id} className="p-6">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center space-x-3 mb-2">
                    <FileText className="h-5 w-5 text-gray-400" />
                    <div>
                      <h3 className="font-medium text-gray-900">{req.title}</h3>
                      {req.is_required && (
                        <span className="inline-block mt-1 px-2 py-0.5 text-xs font-medium bg-red-100 text-red-800 rounded">
                          Required
                        </span>
                      )}
                    </div>
                  </div>
                  <p className="text-sm text-gray-600 ml-8 mb-2">{req.description}</p>
                  {req.document && (
                    <div className="ml-8 flex items-center space-x-2 text-sm">
                      <span className="text-gray-600">{req.document.file_name}</span>
                      <span className={`px-2 py-0.5 rounded text-xs font-medium ${
                        req.document.approval_status === 'approved' ? 'bg-green-100 text-green-800' :
                        req.document.approval_status === 'rejected' ? 'bg-red-100 text-red-800' :
                        'bg-yellow-100 text-yellow-800'
                      }`}>
                        {req.document.approval_status}
                      </span>
                    </div>
                  )}
                  {req.document?.rejection_reason && (
                    <div className="ml-8 mt-2 p-3 bg-red-50 border border-red-200 rounded">
                      <p className="text-sm text-red-800">
                        <AlertCircle className="inline h-4 w-4 mr-1" />
                        {req.document.rejection_reason}
                      </p>
                    </div>
                  )}
                </div>
                {(!req.document || req.document.approval_status === 'rejected') && (
                  <div>
                    <input
                      type="file"
                      id={`upload-${req.id}`}
                      className="hidden"
                      accept={req.accepted_file_types.map((t: string) => `.${t}`).join(',')}
                      onChange={(e) => {
                        const file = e.target.files?.[0];
                        if (file) handleFileUpload(req.id, file);
                      }}
                      disabled={uploading === req.id}
                    />
                    <label
                      htmlFor={`upload-${req.id}`}
                      className={`inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white ${
                        uploading === req.id ? 'bg-gray-400' : 'bg-blue-600 hover:bg-blue-700 cursor-pointer'
                      }`}
                    >
                      <Upload className="h-4 w-4 mr-2" />
                      {uploading === req.id ? 'Uploading...' : req.document ? 'Reupload' : 'Upload'}
                    </label>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>

      {progress?.completion_percentage === 100 && (
        <div className="bg-green-50 border border-green-200 rounded-lg p-6">
          <div className="flex items-start">
            <CheckCircle className="h-6 w-6 text-green-600 mt-0.5" />
            <div className="ml-3">
              <h3 className="text-lg font-medium text-green-900">Onboarding Complete!</h3>
              <p className="mt-1 text-sm text-green-700">
                Congratulations! You have completed all required training modules and uploaded all necessary documents.
                Your account is now active and you can begin your duties.
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default DriverSelfOnboarding;
