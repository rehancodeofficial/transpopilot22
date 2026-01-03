import React, { useState } from 'react';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import Layout from './components/Layout';
import ErrorBoundary from './components/ErrorBoundary';
import Dashboard from './components/Dashboard';
import LandingPage from './components/LandingPage';
import AboutPage from './components/AboutPage';
import ContactPage from './components/ContactPage';
import FuelOptimization from './components/FuelOptimization';
import SafetyCompliance from './components/SafetyCompliance';
import DriverOnboardingManagement from './components/DriverOnboardingManagement';
import DriverSelfOnboarding from './components/DriverSelfOnboarding';
import IntegrationDashboard from './components/IntegrationDashboard';
import LiveTracking from './components/LiveTracking';
import DriverTracking from './components/DriverTracking';
import RouteOptimization from './components/RouteOptimization';
import IntegrationsPage from './components/IntegrationsPage';
import VehiclesManagement from './components/VehiclesManagement';
import DriversManagement from './components/DriversManagement';
import VehicleHealthAI from './components/VehicleHealthAI';
import DriverBehaviorAI from './components/DriverBehaviorAI';
import Login from './components/Login';
import Signup from './components/Signup';
import PricingPage from './components/PricingPage';
import AdminDashboardPage from './components/AdminDashboardPage';
import SuperAdminPanel from './components/SuperAdminPanel';
import UserProfilePage from './components/UserProfilePage';
import OperationsMonitoringDashboard from './components/OperationsMonitoringDashboard';
import CustomerSuccessDashboard from './components/CustomerSuccessDashboard';
import FleetManagerDashboard from './components/FleetManagerDashboard';
import FeedbackPage from './components/FeedbackPage';
import FeedbackManagementDashboard from './components/FeedbackManagementDashboard';
import ProductionMonitoringDashboard from './components/ProductionMonitoringDashboard';
import DiagnosticsPage from './components/DiagnosticsPage';
import SetupWizard from './components/SetupWizard';
import { isSupabaseConfigured } from './lib/supabase';

const AppContent: React.FC = () => {
  const [activeTab, setActiveTab] = useState('dashboard');
  const { isAdmin, isSuperAdmin, user, isGuestMode } = useAuth();

  const integrationConfig = {
    apiKey: 'demo-api-key-12345',
    companyId: 'demo-trucking-company',
    environment: 'sandbox' as const,
    webhookUrl: 'https://your-company.com/webhooks/transpopilot',
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'landing':
        return <LandingPage onNavigate={setActiveTab} />;
      case 'login':
        return <Login onNavigate={setActiveTab} />;
      case 'signup':
        return <Signup onNavigate={setActiveTab} />;
      case 'pricing':
        return <PricingPage onNavigate={setActiveTab} />;
      case 'about':
        return <AboutPage />;
      case 'contact':
        return <ContactPage />;
      case 'dashboard':
        return <Dashboard onNavigate={setActiveTab} />;
      case 'vehicles':
        return <VehiclesManagement />;
      case 'vehicle-health-ai':
        return <VehicleHealthAI />;
      case 'drivers-management':
        return <DriversManagement />;
      case 'live-tracking':
        return <LiveTracking />;
      case 'driver-tracking':
        return <DriverTracking />;
      case 'driver-behavior-ai':
        return <DriverBehaviorAI />;
      case 'route-optimization':
        return <RouteOptimization />;
      case 'fuel':
        return <FuelOptimization />;
      case 'safety':
        return <SafetyCompliance />;
      case 'drivers':
        return <DriverOnboardingManagement />;
      case 'my-onboarding':
        return <DriverSelfOnboarding />;
      case 'integration':
        return <IntegrationDashboard config={integrationConfig} />;
      case 'integrations':
        return <IntegrationsPage />;
      case 'profile':
        return <UserProfilePage />;
      case 'admin-dashboard':
        if (!user || !isAdmin()) {
          return (
            <div className="p-6">
              <div className="bg-red-50 border border-red-200 rounded-lg p-6">
                <h2 className="text-xl font-bold text-red-900 mb-2">Access Denied</h2>
                <p className="text-red-700">You need admin permissions to access this page.</p>
                <button
                  onClick={() => setActiveTab('dashboard')}
                  className="mt-4 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Go to Dashboard
                </button>
              </div>
            </div>
          );
        }
        return <AdminDashboardPage />;
      case 'super-admin-panel':
        if (!user || !isSuperAdmin()) {
          return (
            <div className="p-6">
              <div className="bg-red-50 border border-red-200 rounded-lg p-6">
                <h2 className="text-xl font-bold text-red-900 mb-2">Access Denied</h2>
                <p className="text-red-700">You need super admin permissions to access this page.</p>
                <button
                  onClick={() => setActiveTab('dashboard')}
                  className="mt-4 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Go to Dashboard
                </button>
              </div>
            </div>
          );
        }
        return <SuperAdminPanel />;
      case 'operations-monitoring':
        return <OperationsMonitoringDashboard />;
      case 'customer-success':
        return <CustomerSuccessDashboard />;
      case 'fleet-manager-dashboard':
        return <FleetManagerDashboard />;
      case 'feedback':
        return <FeedbackPage />;
      case 'feedback-management':
        return <FeedbackManagementDashboard />;
      case 'production-monitoring':
        if (!user || !isSuperAdmin()) {
          return (
            <div className="p-6">
              <div className="bg-red-50 border border-red-200 rounded-lg p-6">
                <h2 className="text-xl font-bold text-red-900 mb-2">Access Denied</h2>
                <p className="text-red-700">You need super admin permissions to access this page.</p>
                <button
                  onClick={() => setActiveTab('dashboard')}
                  className="mt-4 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Go to Dashboard
                </button>
              </div>
            </div>
          );
        }
        return <ProductionMonitoringDashboard />;
      case 'diagnostics':
        return <DiagnosticsPage />;
      case 'settings':
        return <div className="p-6"><h1 className="text-2xl font-bold">Settings</h1><p className="text-gray-600 mt-2">Settings page coming soon...</p></div>;
      default:
        return <LandingPage onNavigate={setActiveTab} />;
    }
  };

  return (
    <Layout activeTab={activeTab} onTabChange={setActiveTab}>
      {renderContent()}
    </Layout>
  );
};

function App() {
  if (!isSupabaseConfigured) {
    return <SetupWizard />;
  }

  return (
    <ErrorBoundary>
      <AuthProvider>
        <AppContent />
      </AuthProvider>
    </ErrorBoundary>
  );
}

export default App;