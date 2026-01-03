import React, { useState, useRef, useEffect } from 'react';
import { User, LogOut, Settings, Shield, Building2, ChevronDown } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

interface UserDropdownProps {
  onNavigate: (page: string) => void;
}

const UserDropdown: React.FC<UserDropdownProps> = ({ onNavigate }) => {
  const { user, profile, signOut, isAdmin, isSuperAdmin, refreshProfile } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen]);

  const getInitials = (name: string) => {
    return name
      .split(' ')
      .map((n) => n[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  };

  const getRoleBadge = () => {
    if (!profile) return null;

    if (profile.role === 'super_admin') {
      return (
        <span className="px-2 py-0.5 text-xs font-bold bg-gradient-to-r from-red-500 to-orange-600 text-white rounded-full">
          Super Admin
        </span>
      );
    }

    if (profile.role === 'admin') {
      return (
        <span className="px-2 py-0.5 text-xs font-bold bg-gradient-to-r from-blue-500 to-blue-600 text-white rounded-full">
          Admin
        </span>
      );
    }

    return null;
  };

  const handleLogout = async () => {
    try {
      setIsOpen(false);
      await signOut();
      onNavigate('landing');
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  const handleMenuClick = (page: string) => {
    setIsOpen(false);
    onNavigate(page);
  };

  if (!user || !profile) return null;

  const avatarColor = profile.avatar_url
    ? 'bg-gray-200'
    : 'bg-gradient-to-br from-blue-500 to-blue-600';

  const handleToggleDropdown = async () => {
    if (!isOpen) {
      await refreshProfile();
    }
    setIsOpen(!isOpen);
  };

  return (
    <div className="relative" ref={dropdownRef} key={user.id}>
      <button
        onClick={handleToggleDropdown}
        className="flex items-center space-x-3 px-3 py-2 rounded-xl hover:bg-gray-100 transition-all duration-200"
      >
        <div className={`h-10 w-10 rounded-xl ${avatarColor} flex items-center justify-center text-white font-bold text-sm shadow-lg hover:scale-105 transition-transform`}>
          {profile.avatar_url ? (
            <img src={profile.avatar_url} alt={profile.full_name} className="h-full w-full rounded-xl object-cover" />
          ) : (
            getInitials(profile.full_name)
          )}
        </div>
        <div className="hidden md:block text-left">
          <div className="text-sm font-semibold text-gray-900">{profile.full_name}</div>
          <div className="text-xs text-gray-500">{user?.email || 'No email'}</div>
        </div>
        <ChevronDown className={`h-4 w-4 text-gray-500 transition-transform duration-200 ${isOpen ? 'rotate-180' : ''}`} />
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-2 w-72 bg-white rounded-xl shadow-2xl border border-gray-200 py-2 z-50 animate-slideDown">
          <div className="px-4 py-3 border-b border-gray-100">
            <div className="flex items-center space-x-3">
              <div className={`h-12 w-12 rounded-xl ${avatarColor} flex items-center justify-center text-white font-bold shadow-lg`}>
                {profile.avatar_url ? (
                  <img src={profile.avatar_url} alt={profile.full_name} className="h-full w-full rounded-xl object-cover" />
                ) : (
                  getInitials(profile.full_name)
                )}
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-sm font-semibold text-gray-900 truncate">{profile.full_name}</div>
                <div className="text-xs text-gray-500 truncate">{user?.email || 'No email'}</div>
                {getRoleBadge() && <div className="mt-1">{getRoleBadge()}</div>}
              </div>
            </div>
          </div>

          <div className="py-2">
            <button
              onClick={() => handleMenuClick('profile')}
              className="w-full px-4 py-2.5 text-left flex items-center space-x-3 hover:bg-gray-50 transition-colors group"
            >
              <div className="p-1.5 rounded-lg bg-gray-100 group-hover:bg-gray-200 transition-colors">
                <User className="h-4 w-4 text-gray-600" />
              </div>
              <span className="text-sm font-medium text-gray-700">My Profile</span>
            </button>
          </div>

          {isAdmin() && (
            <>
              <div className="border-t border-gray-200 my-2"></div>
              <div className="px-4 py-2">
                <div className="text-xs font-bold uppercase tracking-wider text-gray-500 flex items-center">
                  <Shield className="h-3 w-3 mr-1.5" />
                  Administration
                </div>
              </div>
              <div className="pb-2">
                <button
                  onClick={() => handleMenuClick('admin-dashboard')}
                  className="w-full px-4 py-2.5 text-left flex items-center space-x-3 hover:bg-blue-50 transition-colors group"
                >
                  <div className="p-1.5 rounded-lg bg-blue-100 group-hover:bg-blue-200 transition-colors">
                    <Shield className="h-4 w-4 text-blue-600" />
                  </div>
                  <div className="flex-1">
                    <span className="text-sm font-medium text-blue-700">Admin Dashboard</span>
                    <p className="text-xs text-blue-600">Manage organization</p>
                  </div>
                </button>

                {isSuperAdmin() && (
                  <button
                    onClick={() => handleMenuClick('super-admin-panel')}
                    className="w-full px-4 py-2.5 text-left flex items-center space-x-3 hover:bg-orange-50 transition-colors group"
                  >
                    <div className="p-1.5 rounded-lg bg-gradient-to-br from-orange-100 to-red-100 group-hover:from-orange-200 group-hover:to-red-200 transition-colors">
                      <Building2 className="h-4 w-4 text-orange-600" />
                    </div>
                    <div className="flex-1">
                      <span className="text-sm font-medium text-orange-700">Super Admin Panel</span>
                      <p className="text-xs text-orange-600">Platform control</p>
                    </div>
                  </button>
                )}
              </div>
            </>
          )}

          <div className="border-t border-gray-100 pt-2">
            <button
              onClick={handleLogout}
              className="w-full px-4 py-2.5 text-left flex items-center space-x-3 hover:bg-red-50 transition-colors"
            >
              <LogOut className="h-5 w-5 text-red-600" />
              <span className="text-sm font-medium text-red-700">Logout</span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default UserDropdown;
