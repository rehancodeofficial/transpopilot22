import React, { useEffect, useState } from 'react';
import { Users, Truck, TrendingUp, Activity, UserPlus, Shield, Settings, BarChart3, ShieldCheck, X, Mail } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { supabase } from '../lib/supabase';

const AdminDashboardPage: React.FC = () => {
  const { isAdmin } = useAuth();
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalVehicles: 0,
    totalDrivers: 0,
    activeRoutes: 0,
  });
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showInviteModal, setShowInviteModal] = useState(false);
  const [inviteForm, setInviteForm] = useState({
    email: '',
    fullName: '',
    role: 'user'
  });
  const [inviteLoading, setInviteLoading] = useState(false);
  const [inviteMessage, setInviteMessage] = useState<{ type: 'success' | 'error', text: string } | null>(null);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);

      const { data: allUsers } = await supabase
        .from('user_profiles')
        .select('*')
        .order('created_at', { ascending: false });

      setUsers(allUsers || []);

      const { count: vehicleCount } = await supabase
        .from('vehicles')
        .select('*', { count: 'exact', head: true });

      const { count: driverCount } = await supabase
        .from('drivers')
        .select('*', { count: 'exact', head: true });

      const { count: routeCount } = await supabase
        .from('routes')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'active');

      setStats({
        totalUsers: allUsers?.length || 0,
        totalVehicles: vehicleCount || 0,
        totalDrivers: driverCount || 0,
        activeRoutes: routeCount || 0,
      });
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  if (!isAdmin()) {
    return (
      <div className="p-6">
        <div className="bg-red-50 border border-red-200 rounded-lg p-6">
          <h2 className="text-xl font-bold text-red-900 mb-2">Access Denied</h2>
          <p className="text-red-700">You do not have admin permissions to view this page.</p>
        </div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  const handleInviteUser = async (e: React.FormEvent) => {
    e.preventDefault();
    setInviteLoading(true);
    setInviteMessage(null);

    try {
      const temporaryPassword = Math.random().toString(36).slice(-12) + 'Aa1!';

      const { data, error } = await supabase.auth.signUp({
        email: inviteForm.email,
        password: temporaryPassword,
        options: {
          data: {
            full_name: inviteForm.fullName,
            role: inviteForm.role,
          },
        },
      });

      if (error) throw error;

      setInviteMessage({
        type: 'success',
        text: `User ${inviteForm.fullName} has been invited successfully! They will receive an email with login instructions.`
      });

      setInviteForm({ email: '', fullName: '', role: 'user' });

      setTimeout(() => {
        setShowInviteModal(false);
        setInviteMessage(null);
        fetchDashboardData();
      }, 2000);

    } catch (error: any) {
      setInviteMessage({
        type: 'error',
        text: error.message || 'Failed to invite user. Please try again.'
      });
    } finally {
      setInviteLoading(false);
    }
  };

  const getRoleBadge = (role: string) => {
    if (role === 'admin') {
      return <span className="px-2 py-0.5 text-xs font-bold bg-blue-100 text-blue-700 rounded-full">Admin</span>;
    }
    if (role === 'super_admin') {
      return <span className="px-2 py-0.5 text-xs font-bold bg-red-100 text-red-700 rounded-full">Super Admin</span>;
    }
    return <span className="px-2 py-0.5 text-xs font-bold bg-gray-100 text-gray-700 rounded-full">User</span>;
  };

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 flex items-center">
            <Shield className="h-8 w-8 mr-3 text-blue-600" />
            Admin Dashboard
          </h1>
          <p className="text-gray-600 mt-1">Manage your organization and users</p>
        </div>
        <button
          onClick={() => setShowInviteModal(true)}
          className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-lg"
        >
          <UserPlus className="h-5 w-5" />
          <span>Invite User</span>
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white rounded-xl shadow-lg p-6 border border-gray-200">
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 bg-blue-100 rounded-lg">
              <Users className="h-6 w-6 text-blue-600" />
            </div>
            <TrendingUp className="h-5 w-5 text-green-600" />
          </div>
          <div className="text-3xl font-bold text-gray-900">{stats.totalUsers}</div>
          <div className="text-sm text-gray-600">Total Users</div>
        </div>

        <div className="bg-white rounded-xl shadow-lg p-6 border border-gray-200">
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 bg-emerald-100 rounded-lg">
              <Truck className="h-6 w-6 text-emerald-600" />
            </div>
            <TrendingUp className="h-5 w-5 text-green-600" />
          </div>
          <div className="text-3xl font-bold text-gray-900">{stats.totalVehicles}</div>
          <div className="text-sm text-gray-600">Total Vehicles</div>
        </div>

        <div className="bg-white rounded-xl shadow-lg p-6 border border-gray-200">
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 bg-orange-100 rounded-lg">
              <Users className="h-6 w-6 text-orange-600" />
            </div>
            <TrendingUp className="h-5 w-5 text-green-600" />
          </div>
          <div className="text-3xl font-bold text-gray-900">{stats.totalDrivers}</div>
          <div className="text-sm text-gray-600">Total Drivers</div>
        </div>

        <div className="bg-white rounded-xl shadow-lg p-6 border border-gray-200">
          <div className="flex items-center justify-between mb-4">
            <div className="p-3 bg-red-100 rounded-lg">
              <Activity className="h-6 w-6 text-red-600" />
            </div>
            <TrendingUp className="h-5 w-5 text-green-600" />
          </div>
          <div className="text-3xl font-bold text-gray-900">{stats.activeRoutes}</div>
          <div className="text-sm text-gray-600">Active Routes</div>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-lg border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h2 className="text-xl font-bold text-gray-900 flex items-center">
            <BarChart3 className="h-6 w-6 mr-2 text-blue-600" />
            All Users
          </h2>
          <p className="text-sm text-gray-600 mt-1">View all users in your organization</p>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Name
                </th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Role
                </th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Last Login
                </th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Joined
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {users.map((user) => (
                <tr key={user.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{user.full_name}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">{getRoleBadge(user.role)}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                    {user.last_login_at ? new Date(user.last_login_at).toLocaleDateString() : 'Never'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                    {new Date(user.created_at).toLocaleDateString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="bg-gradient-to-br from-blue-50 to-cyan-50 rounded-xl shadow-lg border border-blue-200 p-6">
        <div className="flex items-start space-x-4">
          <div className="p-3 bg-blue-600 rounded-lg">
            <ShieldCheck className="h-8 w-8 text-white" />
          </div>
          <div className="flex-1">
            <h3 className="text-lg font-bold text-gray-900 mb-2">Need to Grant Admin Access?</h3>
            <p className="text-gray-700 mb-4">
              Only Super Admins can promote users to Admin or grant Super Admin access. If you need to assign administrative privileges to other users, please contact a Super Admin.
            </p>
            <div className="bg-white rounded-lg p-4 border border-blue-200">
              <p className="text-sm text-gray-600">
                <span className="font-semibold text-gray-900">Current Permissions:</span> As an Admin, you can view all users and manage fleet operations, but cannot modify user roles. Super Admins have exclusive control over role assignments.
              </p>
            </div>
          </div>
        </div>
      </div>

      {showInviteModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-2xl max-w-md w-full p-6 relative animate-slideDown">
            <button
              onClick={() => setShowInviteModal(false)}
              className="absolute top-4 right-4 p-2 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <X className="h-5 w-5 text-gray-500" />
            </button>

            <div className="flex items-center space-x-3 mb-6">
              <div className="p-3 bg-blue-100 rounded-xl">
                <Mail className="h-6 w-6 text-blue-600" />
              </div>
              <div>
                <h2 className="text-2xl font-bold text-gray-900">Invite New User</h2>
                <p className="text-sm text-gray-600">Add a new member to your organization</p>
              </div>
            </div>

            {inviteMessage && (
              <div className={`mb-4 p-4 rounded-lg border ${
                inviteMessage.type === 'success'
                  ? 'bg-green-50 border-green-200 text-green-800'
                  : 'bg-red-50 border-red-200 text-red-800'
              }`}>
                <p className="text-sm font-medium">{inviteMessage.text}</p>
              </div>
            )}

            <form onSubmit={handleInviteUser} className="space-y-4">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Full Name
                </label>
                <input
                  type="text"
                  required
                  value={inviteForm.fullName}
                  onChange={(e) => setInviteForm({ ...inviteForm, fullName: e.target.value })}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                  placeholder="John Doe"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Email Address
                </label>
                <input
                  type="email"
                  required
                  value={inviteForm.email}
                  onChange={(e) => setInviteForm({ ...inviteForm, email: e.target.value })}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                  placeholder="john@example.com"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Role
                </label>
                <select
                  value={inviteForm.role}
                  onChange={(e) => setInviteForm({ ...inviteForm, role: e.target.value })}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                >
                  <option value="user">User</option>
                  <option value="admin">Admin</option>
                </select>
                <p className="text-xs text-gray-500 mt-2">
                  Note: Only Super Admins can grant Super Admin access
                </p>
              </div>

              <div className="flex space-x-3 pt-4">
                <button
                  type="button"
                  onClick={() => setShowInviteModal(false)}
                  className="flex-1 px-4 py-2.5 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 font-medium transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={inviteLoading}
                  className="flex-1 px-4 py-2.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center space-x-2"
                >
                  {inviteLoading ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                      <span>Sending...</span>
                    </>
                  ) : (
                    <>
                      <UserPlus className="h-4 w-4" />
                      <span>Send Invite</span>
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default AdminDashboardPage;
