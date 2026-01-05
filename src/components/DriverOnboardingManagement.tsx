import React, { useState, useEffect } from 'react';
import {
  Users,
  CheckCircle,
  Clock,
  FileText,
  Download,
  X,
  Check
} from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { getAllDriversInOnboarding, getPendingDocuments, approveDocument, rejectDocument, getDocumentDownloadUrl } from '../api/driverOnboarding';
import LoadingSpinner from './LoadingSpinner';
import ErrorMessage from './ErrorMessage';

const DriverOnboardingManagement: React.FC = () => {
  const { profile } = useAuth();
  const [activeTab, setActiveTab] = useState('drivers');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [driversInOnboarding, setDriversInOnboarding] = useState<any[]>([]);
  const [pendingDocuments, setPendingDocuments] = useState<any[]>([]);
  const [rejectionModal, setRejectionModal] = useState<{ open: boolean; documentId: string | null }>({ open: false, documentId: null });
  const [rejectionReason, setRejectionReason] = useState('');

  useEffect(() => {
    if (profile) {
      if (profile.organization_id) {
        loadData();
      } else {
        setLoading(false);
      }
    }
  }, [profile?.id, profile?.organization_id]);

  const loadData = async () => {
    try {
      setLoading(true);
      setError('');

      if (!profile?.organization_id) {
        setLoading(false);
        return;
      }

      const [drivers, documents] = await Promise.all([
        getAllDriversInOnboarding(profile.organization_id),
        getPendingDocuments(profile.organization_id),
      ]);

      setDriversInOnboarding(drivers);
      setPendingDocuments(documents);
    } catch (err: any) {
      setError(err.message || 'Failed to load onboarding data');
    } finally {
      setLoading(false);
    }
  };

  const handleApproveDocument = async (documentId: string) => {
    if (!profile?.id) return;

    try {
      await approveDocument(documentId, profile.id);
      await loadData();
    } catch (err: any) {
      setError(err.message || 'Failed to approve document');
    }
  };

  const handleRejectDocument = async () => {
    if (!profile?.id || !rejectionModal.documentId) return;

    try {
      await rejectDocument(rejectionModal.documentId, profile.id, rejectionReason);
      setRejectionModal({ open: false, documentId: null });
      setRejectionReason('');
      await loadData();
    } catch (err: any) {
      setError(err.message || 'Failed to reject document');
    }
  };

  const handleDownloadDocument = async (filePath: string) => {
    try {
      const url = await getDocumentDownloadUrl(filePath);
      window.open(url, '_blank');
    } catch (err: any) {
      setError(err.message || 'Failed to download document');
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'bg-green-100 text-green-800';
      case 'in_progress':
        return 'bg-blue-100 text-blue-800';
      case 'not_started':
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  if (loading) return <LoadingSpinner />;

  const stats = [
    {
      name: 'In Progress',
      value: driversInOnboarding.filter(d => d.status === 'in_progress').length.toString(),
      icon: Clock,
      color: 'text-blue-600',
      bgColor: 'bg-blue-100',
    },
    {
      name: 'Completed',
      value: driversInOnboarding.filter(d => d.status === 'completed').length.toString(),
      icon: CheckCircle,
      color: 'text-green-600',
      bgColor: 'bg-green-100',
    },
    {
      name: 'Pending Documents',
      value: pendingDocuments.length.toString(),
      icon: FileText,
      color: 'text-yellow-600',
      bgColor: 'bg-yellow-100',
    },
    {
      name: 'Avg. Progress',
      value: driversInOnboarding.length > 0
        ? Math.round(driversInOnboarding.reduce((sum, d) => sum + d.completion_percentage, 0) / driversInOnboarding.length) + '%'
        : '0%',
      icon: Users,
      color: 'text-blue-700',
      bgColor: 'bg-blue-50',
    },
  ];

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Driver Onboarding Management</h1>
          <p className="text-gray-600">Monitor and manage driver onboarding progress</p>
        </div>
      </div>

      {error && <ErrorMessage message={error} onDismiss={() => setError('')} />}

      {!profile?.organization_id && (
        <div className="bg-yellow-50 border-l-4 border-yellow-400 p-4">
          <div className="flex">
            <div className="flex-shrink-0">
              <Clock className="h-5 w-5 text-yellow-400" aria-hidden="true" />
            </div>
            <div className="ml-3">
              <p className="text-sm text-yellow-700">
                No organization associated with your profile. Please refresh or contact support to have an organization assigned to your account.
              </p>
            </div>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => {
          const Icon = stat.icon;
          return (
            <div key={stat.name} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">{stat.name}</p>
                  <p className="text-2xl font-semibold text-gray-900">{stat.value}</p>
                </div>
                <div className={`p-3 rounded-full ${stat.bgColor}`}>
                  <Icon className={`h-6 w-6 ${stat.color}`} />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="border-b border-gray-200">
        <nav className="-mb-px flex space-x-8">
          {[
            { id: 'drivers', name: 'Drivers in Onboarding' },
            { id: 'documents', name: 'Pending Documents' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === tab.id
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              {tab.name}
            </button>
          ))}
        </nav>
      </div>

      {activeTab === 'drivers' && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-lg font-medium text-gray-900">Drivers Currently in Onboarding</h3>
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Driver
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Progress
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Started
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {driversInOnboarding.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                      No drivers currently in onboarding
                    </td>
                  </tr>
                ) : (
                  driversInOnboarding.map((driver) => (
                    <tr key={driver.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div>
                          <div className="text-sm font-medium text-gray-900">
                            {driver.drivers?.first_name} {driver.drivers?.last_name}
                          </div>
                          <div className="text-sm text-gray-500">{driver.drivers?.email}</div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          <div className="w-32 bg-gray-200 rounded-full h-2 mr-3">
                            <div
                              className="bg-blue-600 h-2 rounded-full"
                              style={{ width: `${driver.completion_percentage}%` }}
                            />
                          </div>
                          <span className="text-sm text-gray-600">{driver.completion_percentage}%</span>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(driver.status)}`}>
                          {driver.status.replace('_', ' ')}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {driver.started_at ? new Date(driver.started_at).toLocaleDateString() : 'Not started'}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {activeTab === 'documents' && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-lg font-medium text-gray-900">Documents Pending Review</h3>
          </div>
          <div className="divide-y divide-gray-200">
            {pendingDocuments.length === 0 ? (
              <div className="p-12 text-center text-gray-500">
                No documents pending review
              </div>
            ) : (
              pendingDocuments.map((doc) => (
                <div key={doc.id} className="p-6">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center space-x-3 mb-2">
                        <FileText className="h-5 w-5 text-gray-400" />
                        <div>
                          <p className="text-sm font-medium text-gray-900">
                            {doc.document_requirements?.title || 'Document'}
                          </p>
                          <p className="text-xs text-gray-500">
                            {doc.drivers?.first_name} {doc.drivers?.last_name} - {doc.drivers?.email}
                          </p>
                        </div>
                      </div>
                      <div className="ml-8">
                        <p className="text-sm text-gray-600">{doc.file_name}</p>
                        <p className="text-xs text-gray-500">
                          Uploaded {new Date(doc.uploaded_at).toLocaleString()}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-2">
                      <button
                        onClick={() => handleDownloadDocument(doc.file_path)}
                        className="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded"
                        title="Download"
                      >
                        <Download className="h-5 w-5" />
                      </button>
                      <button
                        onClick={() => handleApproveDocument(doc.id)}
                        className="p-2 text-green-600 hover:text-green-700 hover:bg-green-50 rounded"
                        title="Approve"
                      >
                        <Check className="h-5 w-5" />
                      </button>
                      <button
                        onClick={() => setRejectionModal({ open: true, documentId: doc.id })}
                        className="p-2 text-red-600 hover:text-red-700 hover:bg-red-50 rounded"
                        title="Reject"
                      >
                        <X className="h-5 w-5" />
                      </button>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      )}

      {rejectionModal.open && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-medium text-gray-900">Reject Document</h3>
              <button
                onClick={() => {
                  setRejectionModal({ open: false, documentId: null });
                  setRejectionReason('');
                }}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Reason for rejection
              </label>
              <textarea
                value={rejectionReason}
                onChange={(e) => setRejectionReason(e.target.value)}
                rows={4}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Please provide a reason for rejecting this document..."
              />
            </div>
            <div className="flex justify-end space-x-3">
              <button
                onClick={() => {
                  setRejectionModal({ open: false, documentId: null });
                  setRejectionReason('');
                }}
                className="px-4 py-2 text-gray-700 hover:text-gray-900"
              >
                Cancel
              </button>
              <button
                onClick={handleRejectDocument}
                disabled={!rejectionReason.trim()}
                className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Reject Document
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default DriverOnboardingManagement;
