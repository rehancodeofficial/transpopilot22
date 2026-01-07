import React, { useState } from 'react';
import {
  Truck,
  BarChart3,
  Fuel,
  Shield,
  Users,
  Users,
  Menu,
  X,
  Bell,
  Brain,
  Plug,
  Home,
  Info,
  MessageSquare,
  MapPin,
  Navigation,
  Route as RouteIcon,
  DollarSign,
  LogIn,
  UserPlus,
  ShieldCheck,
  Building2,
  Activity,
  ThumbsUp
} from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { useIsMobile } from '../hooks/useIsMobile';
import UserDropdown from './UserDropdown';
import DemoModeBanner from './DemoModeBanner';
import SignupPreviewBanner from './SignupPreviewBanner';

interface LayoutProps {
  children: React.ReactNode;
  activeTab: string;
  onTabChange: (tab: string) => void;
}

const Layout: React.FC<LayoutProps> = ({ children, activeTab, onTabChange }) => {
  const { user, isAdmin, isSuperAdmin, isFleetManager, isEnterprise, profile, isGuestMode } = useAuth();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const isMobile = useIsMobile();

  const navigation = [
    { id: 'landing', name: 'Home', icon: Home, section: 'main', gradient: 'from-emerald-500 to-teal-600', hoverGradient: 'from-emerald-600 to-teal-700', shadowColor: 'shadow-emerald-500/50', requiresAuth: false, mobileVisible: true },
    { id: 'about', name: 'About Us', icon: Info, section: 'main', gradient: 'from-cyan-500 to-blue-600', hoverGradient: 'from-cyan-600 to-blue-700', shadowColor: 'shadow-cyan-500/50', requiresAuth: false, mobileVisible: true },
    { id: 'pricing', name: 'Pricing', icon: DollarSign, section: 'main', gradient: 'from-blue-500 to-cyan-600', hoverGradient: 'from-blue-600 to-cyan-700', shadowColor: 'shadow-blue-500/50', requiresAuth: false, mobileVisible: true },
    { id: 'contact', name: 'Contact', icon: MessageSquare, section: 'main', gradient: 'from-teal-500 to-emerald-600', hoverGradient: 'from-teal-600 to-emerald-700', shadowColor: 'shadow-teal-500/50', requiresAuth: false, mobileVisible: true },
    { id: 'login', name: 'Sign In', icon: LogIn, section: 'auth', gradient: 'from-blue-500 to-blue-600', hoverGradient: 'from-blue-600 to-blue-700', shadowColor: 'shadow-blue-500/50', requiresAuth: false, hideWhenAuth: true, mobileVisible: true },
    { id: 'signup', name: 'Sign Up', icon: UserPlus, section: 'auth', gradient: 'from-emerald-500 to-teal-600', hoverGradient: 'from-emerald-600 to-teal-700', shadowColor: 'shadow-emerald-500/50', requiresAuth: false, hideWhenAuth: true, mobileVisible: true },
    { id: 'dashboard', name: 'Dashboard', icon: BarChart3, section: 'operations', gradient: 'from-blue-500 to-blue-700', hoverGradient: 'from-blue-600 to-blue-800', shadowColor: 'shadow-blue-500/50', requiresAuth: true, mobileVisible: true },
    { id: 'vehicles', name: 'Vehicles', icon: Truck, section: 'operations', gradient: 'from-blue-500 to-blue-600', hoverGradient: 'from-blue-600 to-blue-700', shadowColor: 'shadow-blue-500/50', requiresAuth: true, mobileVisible: true },
    { id: 'vehicle-health-ai', name: 'Vehicle Health AI', icon: Brain, section: 'operations', gradient: 'from-teal-500 to-cyan-600', hoverGradient: 'from-teal-600 to-cyan-700', shadowColor: 'shadow-teal-500/50', requiresAuth: true, mobileVisible: false },
    { id: 'drivers-management', name: 'Drivers', icon: Users, section: 'operations', gradient: 'from-green-500 to-green-600', hoverGradient: 'from-green-600 to-green-700', shadowColor: 'shadow-green-500/50', requiresAuth: true, mobileVisible: true },
    { id: 'live-tracking', name: 'Live Tracking', icon: MapPin, section: 'operations', gradient: 'from-green-500 to-emerald-600', hoverGradient: 'from-green-600 to-emerald-700', shadowColor: 'shadow-green-500/50', requiresAuth: true, mobileVisible: true },
    { id: 'driver-tracking', name: 'Driver Tracking', icon: Navigation, section: 'operations', gradient: 'from-blue-500 to-cyan-600', hoverGradient: 'from-blue-600 to-cyan-700', shadowColor: 'shadow-blue-500/50', requiresAuth: true, mobileVisible: false },
    { id: 'driver-behavior-ai', name: 'Driver Behavior AI', icon: Brain, section: 'operations', gradient: 'from-emerald-500 to-green-600', hoverGradient: 'from-emerald-600 to-green-700', shadowColor: 'shadow-emerald-500/50', requiresAuth: true, mobileVisible: false },
    { id: 'route-optimization', name: 'Route Optimization', icon: RouteIcon, section: 'operations', gradient: 'from-orange-500 to-red-600', hoverGradient: 'from-orange-600 to-red-700', shadowColor: 'shadow-orange-500/50', requiresAuth: true, mobileVisible: false },
    { id: 'fuel', name: 'Fuel Optimization', icon: Fuel, section: 'operations', gradient: 'from-amber-500 to-orange-600', hoverGradient: 'from-amber-600 to-orange-700', shadowColor: 'shadow-amber-500/50', requiresAuth: true, mobileVisible: false },
    { id: 'safety', name: 'Safety & Compliance', icon: Shield, section: 'operations', gradient: 'from-red-500 to-rose-600', hoverGradient: 'from-red-600 to-rose-700', shadowColor: 'shadow-red-500/50', requiresAuth: true, mobileVisible: true },
    { id: 'drivers', name: 'Driver Onboarding', icon: Users, section: 'operations', gradient: 'from-green-500 to-emerald-600', hoverGradient: 'from-green-600 to-emerald-700', shadowColor: 'shadow-green-500/50', requiresAuth: true, mobileVisible: false },
    { id: 'integration', name: 'API Integration', icon: Plug, section: 'operations', gradient: 'from-violet-500 to-purple-600', hoverGradient: 'from-violet-600 to-purple-700', shadowColor: 'shadow-violet-500/50', requiresAuth: true, mobileVisible: false },
    { id: 'integrations', name: 'Fleet Integrations', icon: Plug, section: 'operations', gradient: 'from-red-500 to-orange-600', hoverGradient: 'from-red-600 to-orange-700', shadowColor: 'shadow-red-500/50', requiresAuth: true, mobileVisible: false },
    { id: 'fleet-manager-dashboard', name: 'Fleet Operations', icon: BarChart3, section: 'admin', gradient: 'from-blue-500 to-blue-700', hoverGradient: 'from-blue-600 to-blue-800', shadowColor: 'shadow-blue-500/50', requiresAuth: true, fleetManagerOnly: true, mobileVisible: false },
    { id: 'admin-dashboard', name: 'Admin Dashboard', icon: ShieldCheck, section: 'admin', gradient: 'from-indigo-500 to-purple-600', hoverGradient: 'from-indigo-600 to-purple-700', shadowColor: 'shadow-indigo-500/50', requiresAuth: true, adminOnly: true, mobileVisible: false },
    { id: 'super-admin-panel', name: 'Super Admin Panel', icon: ShieldCheck, section: 'admin', gradient: 'from-violet-500 to-purple-700', hoverGradient: 'from-violet-600 to-purple-800', shadowColor: 'shadow-violet-500/50', requiresAuth: true, superAdminOnly: true, mobileVisible: false },
    { id: 'operations-monitoring', name: 'Operations Monitoring', icon: Activity, section: 'admin', gradient: 'from-cyan-500 to-blue-600', hoverGradient: 'from-cyan-600 to-blue-700', shadowColor: 'shadow-cyan-500/50', requiresAuth: true, adminOnly: true, requiresEnterprise: true, mobileVisible: false },
    { id: 'production-monitoring', name: 'Production Monitoring', icon: Activity, section: 'admin', gradient: 'from-violet-500 to-purple-600', hoverGradient: 'from-violet-600 to-purple-700', shadowColor: 'shadow-violet-500/50', requiresAuth: true, adminOnly: true, mobileVisible: false },
    { id: 'feedback-management', name: 'Feedback Management', icon: MessageSquare, section: 'admin', gradient: 'from-pink-500 to-rose-600', hoverGradient: 'from-pink-600 to-rose-700', shadowColor: 'shadow-pink-500/50', requiresAuth: true, adminOnly: true, mobileVisible: false },
    { id: 'customer-success', name: 'Customer Success', icon: Building2, section: 'system', gradient: 'from-emerald-500 to-green-600', hoverGradient: 'from-emerald-600 to-green-700', shadowColor: 'shadow-emerald-500/50', requiresAuth: true, mobileVisible: false },
  ];

  const sections = [
    { id: 'main', title: 'Main', gradient: 'from-emerald-500 to-teal-600' },
    { id: 'auth', title: 'Authentication', gradient: 'from-blue-500 to-emerald-600' },
    { id: 'operations', title: 'Fleet Operations', gradient: 'from-blue-500 to-orange-600' },
    { id: 'admin', title: 'Admin & Management', gradient: 'from-indigo-500 to-purple-600' },
    { id: 'system', title: 'System', gradient: 'from-slate-500 to-gray-600' },
  ];

  const isSignupPreview = activeTab === 'signup' && !user;

  const filteredNavigation = navigation.filter(item => {
    // Signup preview mode: show all authenticated features as a preview
    if (isSignupPreview) {
      // Hide auth items (login, signup themselves)
      if (item.id === 'login' || item.id === 'signup') return false;
      // Show all authenticated features to preview
      if (item.requiresAuth) return true;
      // Show main navigation items
      if (item.section === 'main') return true;
      return false;
    }

    // In guest mode, show Sign In/Sign Up plus non-auth-required items
    if (isGuestMode) {
      // Show auth items (Sign In, Sign Up) in guest mode
      if (item.hideWhenAuth) return true;
      // Hide items that require authentication
      if (item.requiresAuth) return false;
      if (isMobile && (item as any).mobileVisible === false) return false;
      return true;
    }

    // Normal authentication flow
    if (item.hideWhenAuth && user) return false;
    if (item.requiresAuth && !user) return false;

    const itemSuperAdminOnly = (item as any).superAdminOnly;
    const itemAdminOnly = (item as any).adminOnly;
    const itemFleetManagerOnly = (item as any).fleetManagerOnly;
    const itemRequiresEnterprise = (item as any).requiresEnterprise;
    const itemMobileVisible = (item as any).mobileVisible;

    if (itemSuperAdminOnly && !isSuperAdmin()) return false;
    if (itemAdminOnly && !isAdmin() && !isSuperAdmin()) return false;
    if (itemFleetManagerOnly && !isFleetManager() && !isAdmin() && !isSuperAdmin()) return false;
    if (isFleetManager() && !isAdmin() && !isSuperAdmin() && item.section === 'system' && item.id !== 'settings' && item.id !== 'feedback') return false;

    if (itemRequiresEnterprise && !isSuperAdmin() && !isEnterprise()) return false;

    if (isMobile && itemMobileVisible === false) return false;

    return true;
  });

  const visibleSections = sections.filter(section =>
    filteredNavigation.some(item => item.section === section.id)
  );

  const totalFeatures = navigation.filter(item => item.requiresAuth).length;

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Mobile sidebar */}
      <div className={`fixed inset-0 z-50 lg:hidden ${sidebarOpen ? 'block' : 'hidden'}`}>
        <div className="fixed inset-0 bg-gray-900 bg-opacity-60 backdrop-blur-sm" onClick={() => setSidebarOpen(false)} />
        <div className="fixed inset-y-0 left-0 flex w-72 flex-col bg-gradient-to-br from-slate-50 via-white to-slate-50 shadow-2xl">
          <div className="flex h-10 items-center justify-between px-2 border-b border-gray-200 bg-gradient-to-r from-slate-900 via-slate-800 to-slate-900 shadow-lg">
            <div className="flex flex-col">
              <span className="text-sm font-bold bg-gradient-to-r from-emerald-400 to-teal-400 bg-clip-text text-transparent">TranspoPilot AI</span>
              {isMobile && user && (
                <span className="text-xs text-gray-400">Mobile View: {mobileFeatures} features</span>
              )}
            </div>
            <button onClick={() => setSidebarOpen(false)} className="p-1 rounded-lg hover:bg-white/10 transition-colors">
              <X className="h-4 w-4 text-white" />
            </button>
          </div>
          {isSignupPreview && <SignupPreviewBanner />}
          <nav className="flex-1 px-2 py-1 space-y-0.5 overflow-y-auto">
            {visibleSections.map((section) => (
              <div key={section.id}>
                <div className="px-2 py-0.5 mb-0.5">
                  <div className={`text-xs font-bold uppercase tracking-wider bg-gradient-to-r ${section.gradient} bg-clip-text text-transparent flex items-center`}>
                    <div className={`h-1 w-1 rounded-full bg-gradient-to-r ${section.gradient} mr-1.5`} />
                    {section.title}
                  </div>
                </div>
                <div className="space-y-0.5">
                  {filteredNavigation
                    .filter((item) => item.section === section.id)
                    .map((item) => {
                      const Icon = item.icon;
                      const isActive = activeTab === item.id;
                      return (
                        <button
                          key={item.id}
                          onClick={() => {
                            if (isSignupPreview) {
                              // In preview mode, do nothing or show a tooltip
                              return;
                            }
                            onTabChange(item.id);
                            setSidebarOpen(false);
                          }}
                          className={`nav-tab-3d w-full flex items-center justify-between px-1.5 py-1 text-xs font-semibold rounded-lg transition-all duration-300 ${
                            isActive
                              ? `bg-gradient-to-r ${item.gradient} text-white shadow-lg ${item.shadowColor} nav-tab-active`
                              : isSignupPreview
                              ? `text-gray-600 bg-gray-50 cursor-default opacity-75`
                              : `text-gray-700 hover:bg-gradient-to-r ${item.gradient} hover:text-white hover:shadow-md ${item.shadowColor}`
                          }`}
                          disabled={isSignupPreview}
                        >
                          <div className="flex items-center">
                            <div className={`mr-1.5 p-0.5 rounded-md ${isActive ? 'bg-white/20' : 'bg-gray-100'} transition-all duration-300`}>
                              <Icon className={`h-3 w-3 ${isActive ? 'text-white' : 'text-gray-600'}`} />
                            </div>
                            {item.name}
                          </div>
                          {isSignupPreview && (
                            <span className="text-[10px] bg-emerald-100 text-emerald-700 px-1.5 py-0.5 rounded font-bold">
                              INCLUDED
                            </span>
                          )}
                        </button>
                      );
                    })}
                </div>
              </div>
            ))}
          </nav>
          {isMobile && user && (
            <div className="px-4 py-3 border-t border-gray-200 bg-gradient-to-r from-blue-50 to-emerald-50">
              <p className="text-xs text-gray-600 text-center">
                📱 Mobile-optimized view showing essential features. For advanced tools like AI analytics and admin panels, use desktop.
              </p>
            </div>
          )}
          <div className="px-4 py-2 border-t border-gray-200 bg-gray-50">
            <p className="text-xs text-gray-500 text-center">v{__APP_VERSION__}</p>
          </div>
        </div>
      </div>

      {/* Desktop sidebar */}
      <div className="hidden lg:fixed lg:inset-y-0 lg:flex lg:w-72 lg:flex-col">
        <div className="flex flex-col flex-grow bg-gradient-to-br from-slate-50 via-white to-slate-50 border-r border-gray-200 shadow-xl">
          <div className="flex h-10 items-center px-2 border-b border-gray-200 bg-gradient-to-r from-slate-900 via-slate-800 to-slate-900 shadow-lg relative overflow-hidden">
            <div className="absolute inset-0 bg-gradient-to-r from-emerald-500/10 to-teal-500/10" />
            <div className="flex flex-col relative z-10">
              <span className="text-sm font-bold bg-gradient-to-r from-emerald-400 to-teal-400 bg-clip-text text-transparent">TranspoPilot AI</span>
            </div>
          </div>
          {isSignupPreview && <SignupPreviewBanner />}
          <nav className="flex-1 px-2 py-1 space-y-0.5 overflow-y-auto">
            {visibleSections.map((section) => (
              <div key={section.id}>
                <div className="px-2 py-0.5 mb-0.5">
                  <div className={`text-xs font-bold uppercase tracking-wider bg-gradient-to-r ${section.gradient} bg-clip-text text-transparent flex items-center`}>
                    <div className={`h-1 w-1 rounded-full bg-gradient-to-r ${section.gradient} mr-1.5 animate-pulse`} />
                    {section.title}
                  </div>
                </div>
                <div className="space-y-0.5">
                  {filteredNavigation
                    .filter((item) => item.section === section.id)
                    .map((item) => {
                      const Icon = item.icon;
                      const isActive = activeTab === item.id;
                      return (
                        <button
                          key={item.id}
                          onClick={() => {
                            if (isSignupPreview) {
                              return;
                            }
                            onTabChange(item.id);
                          }}
                          className={`nav-tab-3d w-full flex items-center justify-between px-1.5 py-1 text-xs font-semibold rounded-lg transition-all duration-300 ${
                            isActive
                              ? `bg-gradient-to-r ${item.gradient} text-white shadow-lg ${item.shadowColor} nav-tab-active`
                              : isSignupPreview
                              ? `text-gray-600 bg-gray-50 cursor-default opacity-75`
                              : `text-gray-700 hover:bg-gradient-to-r ${item.gradient} hover:text-white hover:shadow-md ${item.shadowColor}`
                          }`}
                          disabled={isSignupPreview}
                        >
                          <div className="flex items-center">
                            <div className={`mr-1.5 p-0.5 rounded-md ${isActive ? 'bg-white/20' : 'bg-gray-100'} transition-all duration-300`}>
                              <Icon className={`h-3 w-3 ${isActive ? 'text-white' : 'text-gray-600'}`} />
                            </div>
                            {item.name}
                          </div>
                          {isSignupPreview && (
                            <span className="text-[10px] bg-emerald-100 text-emerald-700 px-1.5 py-0.5 rounded font-bold">
                              INCLUDED
                            </span>
                          )}
                        </button>
                      );
                    })}
                </div>
              </div>
            ))}
          </nav>
          <div className="px-4 py-2 border-t border-gray-200 bg-gray-50">
            <p className="text-xs text-gray-500 text-center">v{__APP_VERSION__}</p>
          </div>
        </div>
      </div>

      {/* Main content */}
      <div className="lg:pl-72">
        {/* Demo Mode Banner */}
        {isGuestMode && (
          <div className="sticky top-0 z-50">
            <DemoModeBanner onNavigate={onTabChange} />
          </div>
        )}

        {/* Top bar */}
        <div className={`sticky ${isGuestMode ? 'top-[52px]' : 'top-0'} z-40 flex h-10 bg-white/80 backdrop-blur-md border-b border-gray-200 shadow-md`}>
          <button
            onClick={() => setSidebarOpen(true)}
            className="px-4 text-gray-600 hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-emerald-500 lg:hidden transition-colors"
          >
            <Menu className="h-6 w-6" />
          </button>
          <div className="flex flex-1 justify-between px-2 lg:px-3">
            <div className="flex flex-1 items-center">
              <h1 className="text-sm font-bold text-gray-900 capitalize">
                {navigation.find(item => item.id === activeTab)?.name || 'Dashboard'}
              </h1>
            </div>
            <div className="flex items-center space-x-1.5">
              <div className="flex items-center space-x-1 px-2 py-1 bg-gradient-to-r from-emerald-500 to-teal-600 text-white rounded-lg text-xs font-bold shadow-lg shadow-emerald-500/30 hover:shadow-xl hover:shadow-emerald-500/40 transition-all duration-300">
                <div className="w-1.5 h-1.5 bg-white rounded-full animate-pulse" />
                AI Active
              </div>

              {/* Debug: Show profile info */}
              {profile && (
                <div className="flex items-center space-x-1 px-2 py-1 bg-red-500 text-white rounded-lg text-xs font-bold">
                  Role: {profile.role}
                </div>
              )}

              {(profile?.role === 'admin' || profile?.role === 'super_admin') && (
                <button
                  onClick={() => onTabChange('admin-dashboard')}
                  className={`flex items-center space-x-1 px-2 py-1 rounded-lg text-xs font-semibold transition-all duration-200 ${
                    activeTab === 'admin-dashboard'
                      ? 'bg-gradient-to-r from-indigo-500 to-blue-600 text-white shadow-lg shadow-indigo-500/30'
                      : 'text-indigo-700 hover:bg-indigo-50'
                  }`}
                >
                  <ShieldCheck className="h-3.5 w-3.5" />
                  <span>Admin</span>
                </button>
              )}

              {profile?.role === 'super_admin' && (
                <button
                  onClick={() => onTabChange('super-admin-panel')}
                  className={`flex items-center space-x-1 px-2 py-1 rounded-lg text-xs font-semibold transition-all duration-200 ${
                    activeTab === 'super-admin-panel'
                      ? 'bg-gradient-to-r from-violet-500 to-purple-700 text-white shadow-lg shadow-violet-500/30'
                      : 'text-violet-700 hover:bg-violet-50'
                  }`}
                >
                  <ShieldCheck className="h-3.5 w-3.5" />
                  <span>Super Admin</span>
                </button>
              )}

              {profile?.role === 'super_admin' && (
                <button
                  onClick={() => onTabChange('operations-monitoring')}
                  className={`flex items-center space-x-1 px-2 py-1 rounded-lg text-xs font-semibold transition-all duration-200 ${
                    activeTab === 'operations-monitoring'
                      ? 'bg-gradient-to-r from-cyan-500 to-blue-600 text-white shadow-lg shadow-cyan-500/30'
                      : 'text-cyan-700 hover:bg-cyan-50'
                  }`}
                >
                  <Activity className="h-3.5 w-3.5" />
                  <span>Operations</span>
                </button>
              )}

              {user && (
                <button
                  onClick={() => onTabChange('feedback')}
                  className="flex items-center space-x-1 px-2 py-1 text-gray-700 hover:text-pink-600 hover:bg-pink-50 rounded-lg transition-all duration-200"
                >
                  <ThumbsUp className="h-3.5 w-3.5" />
                  <span className="text-xs font-semibold hidden sm:inline">Feedback</span>
                </button>
              )}
              <button className="relative p-1.5 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg transition-all duration-200">
                <Bell className="h-3.5 w-3.5" />
                <span className="absolute top-1 right-1 block h-2 w-2 rounded-full bg-gradient-to-r from-red-500 to-rose-600 ring-2 ring-white shadow-lg animate-pulse" />
              </button>
              <UserDropdown onNavigate={onTabChange} />
            </div>
          </div>
        </div>

        {/* Page content */}
        <main className="flex-1">
          {children}
        </main>
      </div>
    </div>
  );
};

export default Layout;