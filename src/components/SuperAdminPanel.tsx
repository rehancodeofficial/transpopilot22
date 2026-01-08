import React, { useEffect, useState } from 'react';
import { Users, Truck, TrendingUp, Crown, BarChart3, Shield, UserPlus, UserMinus, ShieldCheck } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { supabase } from '../lib/supabase';

const SuperAdminPanel: React.FC = () => {
  const { isSuperAdmin } = useAuth();
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalVehicles: 0,
    totalDrivers: 0,
    totalRoutes: 0,
  });
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [processingUserId, setProcessingUserId] = useState<string | null>(null);
  const [message, setMessage] = useState<{ type: 'success' | 'error', text: string } | null>(null);

  useEffect(() => {
    if (isSuperAdmin() || sessionStorage.getItem('super_admin_authenticated') === 'true') {
      fetchGlobalStats();
    }
  }, []);

  const fetchGlobalStats = async () => {
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
        .select('*', { count: 'exact', head: true });

      setStats({
        totalUsers: allUsers?.length || 0,
        totalVehicles: vehicleCount || 0,
        totalDrivers: driverCount || 0,
        totalRoutes: routeCount || 0,
      });
    } catch (error) {
      console.error('Error fetching global stats:', error);
    } finally {
      setLoading(false);
    }
  };

  if (!isSuperAdmin() && sessionStorage.getItem('super_admin_authenticated') !== 'true') {
    return (
      <div className="p-6">
        <div className="bg-red-50 border border-red-200 rounded-lg p-6">
          <h2 className="text-xl font-bold text-red-900 mb-2">Access Denied</h2>
          <p className="text-red-700">You do not have super admin permissions to view this page.</p>
        </div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-600"></div>
      </div>
    );
  }

  const promoteToAdmin = async (userId: string) => {
    setProcessingUserId(userId);
    setMessage(null);
    try {
      const { data, error } = await supabase.rpc('promote_user_to_admin', {
        target_user_id: userId
      });

      if (error) throw error;

      if (data.success) {
        setMessage({ type: 'success', text: data.message });
        await fetchGlobalStats();
      } else {
        setMessage({ type: 'error', text: data.message });
      }
    } catch (error: any) {
      setMessage({ type: 'error', text: error.message || 'Failed to promote user' });
    } finally {
      setProcessingUserId(null);
      setTimeout(() => setMessage(null), 5000);
    }
  };

  const demoteToUser = async (userId: string) => {
    setProcessingUserId(userId);
    setMessage(null);
    try {
      const { data, error } = await supabase.rpc('demote_admin_to_user', {
        target_user_id: userId
      });

      if (error) throw error;

      if (data.success) {
        setMessage({ type: 'success', text: data.message });
        await fetchGlobalStats();
      } else {
        setMessage({ type: 'error', text: data.message });
      }
    } catch (error: any) {
      setMessage({ type: 'error', text: error.message || 'Failed to demote user' });
    } finally {
      setProcessingUserId(null);
      setTimeout(() => setMessage(null), 5000);
    }
  };

  const grantSuperAdmin = async (userId: string) => {
    if (!confirm('Are you sure you want to grant Super Admin access? This gives full platform control.')) {
      return;
    }

    setProcessingUserId(userId);
    setMessage(null);
    try {
      const { data, error } = await supabase.rpc('grant_super_admin', {
        target_user_id: userId
      });

      if (error) throw error;

      if (data.success) {
        setMessage({ type: 'success', text: data.message });
        await fetchGlobalStats();
      } else {
        setMessage({ type: 'error', text: data.message });
      }
    } catch (error: any) {
      setMessage({ type: 'error', text: error.message || 'Failed to grant super admin' });
    } finally {
      setProcessingUserId(null);
      setTimeout(() => setMessage(null), 5000);
    }
  };

  const getRoleBadge = (role: string) => {
    if (role === 'super_admin') {
      return <span className="px-2 py-0.5 text-xs font-bold bg-orange-100 text-orange-700 rounded-full">Super Admin</span>;
    }
    if (role === 'admin') {
      return <span className="px-2 py-0.5 text-xs font-bold bg-blue-100 text-blue-700 rounded-full">Admin</span>;
    }
    return <span className="px-2 py-0.5 text-xs font-bold bg-gray-100 text-gray-700 rounded-full">User</span>;
  };

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 flex items-center">
            <Crown className="h-8 w-8 mr-3 text-orange-600" />
            Super Admin Panel
          </h1>
          <p className="text-gray-600 mt-1">Manage platform-wide settings and view global statistics</p>
        </div>
      </div>

      {message && (
        <div className={`p-4 rounded-lg border ${
          message.type === 'success'
            ? 'bg-green-50 border-green-200 text-green-800'
            : 'bg-red-50 border-red-200 text-red-800'
        }`}>
          <p className="font-medium">{message.text}</p>
        </div>
      )}

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
              <BarChart3 className="h-6 w-6 text-red-600" />
            </div>
            <TrendingUp className="h-5 w-5 text-green-600" />
          </div>
          <div className="text-3xl font-bold text-gray-900">{stats.totalRoutes}</div>
          <div className="text-sm text-gray-600">Total Routes</div>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-lg border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h2 className="text-xl font-bold text-gray-900 flex items-center">
            <Shield className="h-6 w-6 mr-2 text-orange-600" />
            User Management & Role Assignment
          </h2>
          <p className="text-sm text-gray-600 mt-1">Manage user roles and grant admin access</p>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Name</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Role</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Last Login</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Joined</th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-gray-600 uppercase">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {users.map((user) => (
                <tr key={user.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4">
                    <div className="text-sm font-medium text-gray-900">{user.full_name}</div>
                  </td>
                  <td className="px-6 py-4">{getRoleBadge(user.role)}</td>
                  <td className="px-6 py-4 text-sm text-gray-600">
                    {user.last_login_at ? new Date(user.last_login_at).toLocaleDateString() : 'Never'}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600">
                    {new Date(user.created_at).toLocaleDateString()}
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center space-x-2">
                      {user.role === 'user' && (
                        <button
                          onClick={() => promoteToAdmin(user.id)}
                          disabled={processingUserId === user.id}
                          className="flex items-center space-x-1 px-3 py-1.5 bg-blue-600 text-white text-xs font-medium rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                        >
                          <UserPlus className="h-3.5 w-3.5" />
                          <span>Make Admin</span>
                        </button>
                      )}
                      {user.role === 'admin' && (
                        <>
                          <button
                            onClick={() => demoteToUser(user.id)}
                            disabled={processingUserId === user.id}
                            className="flex items-center space-x-1 px-3 py-1.5 bg-gray-600 text-white text-xs font-medium rounded-lg hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                          >
                            <UserMinus className="h-3.5 w-3.5" />
                            <span>Remove Admin</span>
                          </button>
                          <button
                            onClick={() => grantSuperAdmin(user.id)}
                            disabled={processingUserId === user.id}
                            className="flex items-center space-x-1 px-3 py-1.5 bg-orange-600 text-white text-xs font-medium rounded-lg hover:bg-orange-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                          >
                            <ShieldCheck className="h-3.5 w-3.5" />
                            <span>Make Super Admin</span>
                          </button>
                        </>
                      )}
                      {user.role === 'super_admin' && (
                        <span className="text-xs text-gray-500 italic">Protected Role</span>
                      )}
                      {processingUserId === user.id && (
                        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-orange-600"></div>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default SuperAdminPanel;
