import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, Session, AuthError } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
import { DEMO_USER, DEMO_ORGANIZATION, enableDemoMode, disableDemoMode } from '../lib/demoData';
import { markUserAuthenticated } from '../api/monitoring';
import { logDebug, logError, logInfo } from '../lib/logger';

interface Organization {
  id: string;
  name: string;
  subscription_tier: 'trial' | 'starter' | 'pro' | 'enterprise';
}

interface UserProfile {
  id: string;
  organization_id: string | null;
  role: 'user' | 'admin' | 'super_admin' | 'fleet_manager';
  full_name: string;
  avatar_url: string | null;
  phone: string | null;
  last_login_at: string | null;
  created_at: string;
  updated_at: string;
  organization?: Organization;
}

interface AuthContextType {
  user: User | null;
  profile: UserProfile | null;
  session: Session | null;
  loading: boolean;
  isGuestMode: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string, fullName?: string, role?: string, companyName?: string, onProgress?: (message: string) => void) => Promise<void>;
  signOut: () => Promise<void>;
  resendConfirmationEmail: (email: string) => Promise<void>;
  exitGuestMode: () => void;
  isAdmin: () => boolean;
  isSuperAdmin: () => boolean;
  isFleetManager: () => boolean;
  isEnterprise: () => boolean;
  refreshProfile: () => Promise<void>;
  seedDemoData: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const [isGuestMode, setIsGuestMode] = useState(false);

  const fetchProfile = async (userId: string) => {
    try {
      const { data, error } = await supabase
        .from('user_profiles')
        .select(`
          *,
          organization:organizations(
            id,
            name,
            subscription_tier
          )
        `)
        .eq('id', userId)
        .maybeSingle();

      if (error) {
        logError('Error fetching user profile', error);
        return null;
      }

      if (data) {
        // If user doesn't have an organization, create one
        if (!data.organization_id) {
          logDebug('User missing organization_id, creating one...');
          try {
            const { data: orgId, error: orgError } = await supabase
              .rpc('create_organization_for_user', { target_user_id: userId });

            if (orgError) {
              logError('Error creating organization', orgError);
            } else {
              logInfo('Successfully created organization', { orgId });
              // Refetch profile to get the new organization
              return fetchProfile(userId);
            }
          } catch (orgError) {
            logError('Exception creating organization', orgError);
          }
        }

        await supabase
          .from('user_profiles')
          .update({ last_login_at: new Date().toISOString() })
          .eq('id', userId);
      }

      return data;
    } catch (error) {
      logError('Error in fetchProfile', error);
      return null;
    }
  };

  const refreshProfile = async () => {
    if (user) {
      const profileData = await fetchProfile(user.id);
      setProfile(profileData);
    }
  };

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user) {
        fetchProfile(session.user.id).then((profileData) => {
          setProfile(profileData);
          // Mark user as authenticated for API monitoring
          markUserAuthenticated();
          setLoading(false);
        });
      } else {
        // No authenticated user - enable guest mode automatically
        enableDemoMode();
        setIsGuestMode(true);
        setProfile({
          id: DEMO_USER.id,
          organization_id: DEMO_USER.organization_id,
          role: DEMO_USER.role,
          full_name: DEMO_USER.full_name,
          avatar_url: null,
          phone: DEMO_USER.phone,
          last_login_at: null,
          created_at: DEMO_USER.created_at,
          updated_at: DEMO_USER.created_at,
          organization: DEMO_ORGANIZATION,
        });
        setLoading(false);
      }
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user) {
        // User logged in - disable guest mode
        setIsGuestMode(false);
        disableDemoMode();
        fetchProfile(session.user.id).then((profileData) => {
          setProfile(profileData);
          // Mark user as authenticated for API monitoring
          markUserAuthenticated();
        });
      } else {
        // User logged out - re-enable guest mode
        enableDemoMode();
        setIsGuestMode(true);
        setProfile({
          id: DEMO_USER.id,
          organization_id: DEMO_USER.organization_id,
          role: DEMO_USER.role,
          full_name: DEMO_USER.full_name,
          avatar_url: null,
          phone: DEMO_USER.phone,
          last_login_at: null,
          created_at: DEMO_USER.created_at,
          updated_at: DEMO_USER.created_at,
          organization: DEMO_ORGANIZATION,
        });
      }
      setLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  const seedDemoData = async () => {
    if (!user) {
      throw new Error('User must be authenticated to seed demo data');
    }

    try {
      const { error } = await supabase.rpc('seed_user_demo_data', {
        target_user_id: user.id,
      });

      if (error) {
        throw error;
      }
    } catch (error) {
      logError('Error seeding demo data', error);
      throw error;
    }
  };

  const signIn = async (email: string, password: string) => {
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        if (error.message.includes('Invalid login credentials')) {
          throw new Error('Invalid email or password. Please check your credentials and try again.');
        }
        if (error.message.includes('Email not confirmed')) {
          throw new Error('EMAIL_NOT_CONFIRMED: Please verify your email address before signing in. Check your inbox for a confirmation link.');
        }
        if (error.message.includes('Email link is invalid or has expired')) {
          throw new Error('EMAIL_LINK_EXPIRED: Your confirmation link has expired. Please request a new one.');
        }
        if (error.message.includes('fetch') || error.message.includes('Failed to fetch') || error.message.includes('NetworkError')) {
          throw new Error('Network error: Unable to reach the authentication server. Please check your internet connection and try again.');
        }
        throw error;
      }

      if (data.user) {
        const profileData = await fetchProfile(data.user.id);
        setProfile(profileData);
        // Mark user as authenticated for API monitoring
        markUserAuthenticated();
      }
    } catch (error) {
      if (error instanceof TypeError && error.message.includes('fetch')) {
        throw new Error('Network error: Unable to reach the authentication server. Please check your internet connection and try again.');
      }
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('Failed to sign in. Please try again.');
    }
  };

  const signUp = async (
    email: string,
    password: string,
    fullName?: string,
    role: string = 'user',
    companyName?: string,
    onProgress?: (message: string) => void
  ) => {
    try {
      onProgress?.('Creating your account...');
      logDebug('Starting signup process', { email });

      // Auto-generate fullName if not provided
      const generatedFullName = fullName || (() => {
        const username = email.split('@')[0];
        return username
          .split(/[._-]/)
          .map(part => part.charAt(0).toUpperCase() + part.slice(1))
          .join(' ');
      })();

      // Auto-generate companyName if not provided
      const generatedCompanyName = companyName || (() => {
        const domain = email.split('@')[1];
        if (!domain) return 'My Organization';
        const orgName = domain.split('.')[0];
        return orgName.charAt(0).toUpperCase() + orgName.slice(1) + ' Organization';
      })();

      const signupPromise = supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            full_name: generatedFullName,
            role: role,
            organization_name: generatedCompanyName,
          },
          emailRedirectTo: undefined,
        },
      });

      const timeoutPromise = new Promise<never>((_, reject) => {
        setTimeout(() => reject(new Error('TIMEOUT: Signup request timed out after 30 seconds. This may indicate a database trigger issue or slow network.')), 30000);
      });

      const { data, error } = await Promise.race([signupPromise, timeoutPromise]);

      if (error) {
        logError('Signup error details', {
          message: error.message,
          status: error.status,
          name: error.name,
        });

        if (error.message.includes('already registered')) {
          throw new Error('This email is already registered. Please sign in instead.');
        }
        if (error.message.includes('Password')) {
          throw new Error('Password must be at least 6 characters long.');
        }
        if (error.message.includes('Email rate limit exceeded')) {
          throw new Error('Too many signup attempts. Please wait a moment and try again.');
        }
        if (error.message.includes('fetch') || error.message.includes('network')) {
          throw new Error('Network error: Unable to reach the server. Please check your connection and try again.');
        }

        throw new Error(`Signup failed: ${error.message}`);
      }

      if (!data.user) {
        throw new Error('Account creation failed. Please try again.');
      }

      logInfo('User created successfully', { userId: data.user.id });

      if (data.user && !data.session) {
        logDebug('Email confirmation required', { email });
        throw new Error('EMAIL_CONFIRMATION_REQUIRED: Account created successfully! Please check your email and click the confirmation link to activate your account.');
      }

      if (!data.session) {
        throw new Error('Session creation failed. Please try signing in.');
      }

      onProgress?.('Loading your profile...');

      let retries = 0;
      const maxRetries = 5;
      let profileData = null;

      while (retries < maxRetries && !profileData) {
        await new Promise(resolve => setTimeout(resolve, 1000 * (retries + 1)));
        profileData = await fetchProfile(data.user.id);
        if (!profileData) {
          logDebug(`Profile not found, retry ${retries + 1}/${maxRetries}`);
          retries++;
        }
      }

      if (!profileData) {
        throw new Error('Profile creation timed out. Please try signing in.');
      }

      setProfile(profileData);

      onProgress?.('Setting up demo data...');
      try {
        await supabase.rpc('seed_user_demo_data', {
          target_user_id: data.user.id,
        });
      } catch (demoError) {
        logError('Demo data seeding failed (non-critical)', demoError);
      }

      // Mark user as authenticated for API monitoring
      markUserAuthenticated();

      onProgress?.('Account setup complete!');
    } catch (error) {
      logError('SignUp exception', error);
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('Failed to create account. Please try again.');
    }
  };

  const signOut = async () => {
    try {
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
      setProfile(null);
      // Guest mode will be re-enabled by the auth state change listener
    } catch (error) {
      if (error instanceof Error) {
        throw new Error(error.message);
      }
      throw new Error('Failed to sign out');
    }
  };

  const resendConfirmationEmail = async (email: string) => {
    try {
      const { error } = await supabase.auth.resend({
        type: 'signup',
        email: email,
      });

      if (error) {
        if (error.message.includes('rate limit')) {
          throw new Error('Too many requests. Please wait a few minutes before trying again.');
        }
        throw error;
      }
    } catch (error) {
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('Failed to resend confirmation email. Please try again.');
    }
  };

  const exitGuestMode = () => {
    // This just clears the guest mode flag, useful for prompting user to sign in
    setIsGuestMode(false);
    disableDemoMode();
  };

  const isAdmin = () => {
    return profile?.role === 'admin' || profile?.role === 'super_admin';
  };

  const isSuperAdmin = () => {
    return profile?.role === 'super_admin';
  };

  const isFleetManager = () => {
    return profile?.role === 'fleet_manager';
  };

  const isEnterprise = () => {
    return profile?.organization?.subscription_tier === 'enterprise';
  };

  const value = {
    user,
    profile,
    session,
    loading,
    isGuestMode,
    signIn,
    signUp,
    signOut,
    resendConfirmationEmail,
    exitGuestMode,
    isAdmin,
    isSuperAdmin,
    isFleetManager,
    isEnterprise,
    refreshProfile,
    seedDemoData,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
