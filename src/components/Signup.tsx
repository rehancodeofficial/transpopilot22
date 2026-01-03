import React, { useState } from 'react';
import { Truck, Mail, Lock, User, AlertCircle, Loader2, Building2, Activity, Brain, MapPin, Route as RouteIcon, Fuel, Shield, Users, Plug, BarChart3 } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { supabase, isSupabaseConfigured } from '../lib/supabase';

interface SignupProps {
  onNavigate: (page: string) => void;
}

const Signup: React.FC<SignupProps> = ({ onNavigate }) => {
  const { signUp, resendConfirmationEmail } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [emailConfirmationRequired, setEmailConfirmationRequired] = useState(false);
  const [progressMessage, setProgressMessage] = useState<string>('');
  const [testingConnection, setTestingConnection] = useState(false);
  const [connectionStatus, setConnectionStatus] = useState<string | null>(null);
  const [resendingEmail, setResendingEmail] = useState(false);

  const testConnection = async () => {
    setTestingConnection(true);
    setConnectionStatus(null);
    setError(null);

    try {
      console.log('Testing Supabase connection...');

      if (!isSupabaseConfigured) {
        setConnectionStatus('Configuration error: Supabase credentials not found in environment variables');
        return;
      }

      console.log('Step 1: Testing basic database connection...');
      const { error: dbError } = await supabase.from('user_profiles').select('count').limit(1);

      if (dbError) {
        console.error('Database connection test error:', dbError);
        setConnectionStatus(`Database connection failed: ${dbError.message}. This could mean your Supabase project is paused or the table does not exist.`);
        return;
      }

      console.log('Step 2: Testing auth service...');
      const { error: authError } = await supabase.auth.getSession();

      if (authError) {
        console.error('Auth service test error:', authError);
        setConnectionStatus(`Auth service failed: ${authError.message}`);
        return;
      }

      console.log('Step 3: Checking organizations table...');
      const { error: orgError } = await supabase.from('organizations').select('count').limit(1);

      if (orgError) {
        console.error('Organizations table test error:', orgError);
        setConnectionStatus(`Organizations table access failed: ${orgError.message}. RLS policies may be too restrictive.`);
        return;
      }

      setConnectionStatus('All connection tests passed! The database and authentication service are working correctly. You can proceed with signup.');
    } catch (err) {
      console.error('Connection test exception:', err);
      if (err instanceof Error) {
        if (err.message.includes('fetch') || err.message.includes('NetworkError')) {
          setConnectionStatus('Network error: Cannot reach Supabase servers. Check your internet connection or verify your Supabase project is running.');
        } else {
          setConnectionStatus(`Connection test failed: ${err.message}`);
        }
      } else {
        setConnectionStatus('Connection failed: Unknown error occurred during testing');
      }
    } finally {
      setTestingConnection(false);
    }
  };

  const handleResendEmail = async () => {
    setResendingEmail(true);
    setError(null);

    try {
      await resendConfirmationEmail(email);
      setSuccessMessage('Confirmation email sent! Please check your inbox.');
    } catch (err) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError('Failed to resend confirmation email. Please try again.');
      }
    } finally {
      setResendingEmail(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccessMessage(null);
    setEmailConfirmationRequired(false);
    setProgressMessage('');

    if (password.length < 8) {
      setError('Password must be at least 8 characters long');
      return;
    }

    setLoading(true);

    try {
      console.log('Starting signup process...');
      await signUp(email, password, undefined, 'admin', undefined, setProgressMessage);
      console.log('Signup successful, navigating to dashboard...');
      onNavigate('dashboard');
    } catch (err) {
      console.error('Signup error caught in component:', err);

      let errorMessage = 'Failed to create account. Please try again.';

      if (err instanceof Error) {
        console.error('Error details:', {
          message: err.message,
          name: err.name,
          stack: err.stack,
        });

        // Check for email confirmation required
        if (err.message.includes('EMAIL_CONFIRMATION_REQUIRED:')) {
          const message = err.message.replace('EMAIL_CONFIRMATION_REQUIRED: ', '');
          setSuccessMessage(message);
          setEmailConfirmationRequired(true);
          setError(null);
          setProgressMessage('');
          setLoading(false);
          return;
        }

        if (err.message.includes('TIMEOUT')) {
          errorMessage = 'Signup request timed out after 30 seconds. This usually means the database trigger is taking too long. The issue has been logged. Please try again or use the "Test Connection" button below to diagnose.';
        } else if (err.message.includes('fetch') || err.message.includes('NetworkError') || err.message.includes('Failed to fetch')) {
          errorMessage = 'Network error: Unable to connect to the server. This could mean: 1) Your internet connection is down, 2) The Supabase project is paused or unavailable, 3) There is a CORS configuration issue. Use "Test Connection" below to diagnose.';
        } else if (err.message.includes('JWT') || err.message.includes('token')) {
          errorMessage = 'Authentication error: Please refresh the page and try again.';
        } else if (err.message.includes('already registered')) {
          errorMessage = 'This email is already registered. Please sign in instead.';
        } else if (err.message.includes('timeout') || err.message.includes('timed out')) {
          errorMessage = 'Request timed out. The database trigger may be slow or failing. Try using the "Test Connection" button to diagnose the issue.';
        } else if (err.message.includes('rate limit')) {
          errorMessage = 'Too many signup attempts. Please wait a few minutes before trying again.';
        } else if (err.message.includes('CORS')) {
          errorMessage = 'Configuration error: CORS issue detected. Please contact support.';
        } else {
          errorMessage = err.message;
        }
      } else {
        console.error('Unknown error type:', err);
        errorMessage = 'An unexpected error occurred. Please try again.';
      }

      setError(errorMessage);
      setProgressMessage('');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-slate-100 flex items-center justify-center p-4 lg:p-8">
      <div className="max-w-6xl w-full grid lg:grid-cols-2 gap-8 items-center">
        {/* Left side - Feature showcase */}
        <div className="hidden lg:block">
          <div className="text-center lg:text-left mb-8">
            <div className="inline-flex items-center justify-center bg-gradient-to-br from-blue-500 to-blue-700 p-4 rounded-2xl shadow-2xl shadow-blue-500/30 mb-6">
              <Truck className="h-16 w-16 text-white" />
            </div>
            <h1 className="text-5xl font-bold text-gray-900 mb-4">Welcome to TranspoPilot AI</h1>
            <p className="text-gray-600 text-xl mb-8">Instantly access all premium features</p>
          </div>

          <div className="bg-white/80 backdrop-blur-sm rounded-2xl shadow-xl p-8 border border-gray-200">
            <h2 className="text-2xl font-bold text-gray-900 mb-6 flex items-center">
              <Activity className="h-6 w-6 text-emerald-600 mr-2" />
              Get Instant Access To:
            </h2>
            <div className="space-y-4">
              {[
                { icon: Brain, text: 'AI-Powered Vehicle Health Analysis', color: 'text-teal-600' },
                { icon: MapPin, text: 'Real-Time GPS Fleet Tracking', color: 'text-green-600' },
                { icon: RouteIcon, text: 'Advanced Route Optimization', color: 'text-orange-600' },
                { icon: Fuel, text: 'Fuel Efficiency Insights', color: 'text-amber-600' },
                { icon: Shield, text: 'Safety & Compliance Monitoring', color: 'text-red-600' },
                { icon: Users, text: 'Driver Behavior Analytics', color: 'text-emerald-600' },
                { icon: Plug, text: 'Fleet Management Integrations', color: 'text-violet-600' },
                { icon: BarChart3, text: 'Comprehensive Dashboard Analytics', color: 'text-blue-600' },
              ].map((feature, index) => (
                <div key={index} className="flex items-center space-x-3 p-3 rounded-lg hover:bg-gray-50 transition-all">
                  <div className={`p-2 rounded-lg bg-gray-50 ${feature.color}`}>
                    <feature.icon className="h-5 w-5" />
                  </div>
                  <span className="text-gray-700 font-medium">{feature.text}</span>
                </div>
              ))}
            </div>
            <div className="mt-6 p-4 bg-emerald-50 border border-emerald-200 rounded-lg">
              <p className="text-sm text-emerald-800 font-semibold text-center">
                All features available immediately after signup
              </p>
            </div>
          </div>
        </div>

        {/* Right side - Signup form */}
        <div>
          <div className="text-center lg:hidden mb-8">
            <div className="inline-flex items-center justify-center bg-gradient-to-br from-blue-500 to-blue-700 p-4 rounded-2xl shadow-2xl shadow-blue-500/30 mb-6">
              <Truck className="h-12 w-12 text-white" />
            </div>
            <h1 className="text-4xl font-bold text-gray-900 mb-2">Create Account</h1>
            <p className="text-gray-600 text-lg">Start your 30-day free trial today</p>
          </div>

          <div className="bg-white rounded-2xl shadow-xl p-8 border border-gray-100">
            <div className="hidden lg:block text-center mb-6">
              <h2 className="text-3xl font-bold text-gray-900 mb-2">Create Account</h2>
              <p className="text-gray-600">Start your 30-day free trial</p>
            </div>

            <form onSubmit={handleSubmit} className="space-y-5">

            <div>
              <label htmlFor="email" className="block text-sm font-semibold text-gray-700 mb-2">
                Email Address
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Mail className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  type="email"
                  id="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                  placeholder="your@email.com"
                  disabled={loading}
                />
              </div>
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-semibold text-gray-700 mb-2">
                Password (minimum 8 characters)
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Lock className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  type="password"
                  id="password"
                  required
                  minLength={8}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                  placeholder="Create a password"
                  disabled={loading}
                />
              </div>
            </div>

            {error && (
              <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start">
                <AlertCircle className="h-5 w-5 text-red-600 mt-0.5 mr-3 flex-shrink-0" />
                <p className="text-sm text-red-800">{error}</p>
              </div>
            )}

            {successMessage && (
              <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                <div className="flex items-start mb-3">
                  <Mail className="h-5 w-5 text-green-600 mt-0.5 mr-3 flex-shrink-0" />
                  <p className="text-sm text-green-800">{successMessage}</p>
                </div>
                {emailConfirmationRequired && (
                  <div className="mt-3 flex gap-2">
                    <button
                      type="button"
                      onClick={handleResendEmail}
                      disabled={resendingEmail}
                      className="flex-1 bg-green-600 text-white py-2 px-4 rounded-lg font-medium hover:bg-green-700 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center text-sm"
                    >
                      {resendingEmail ? (
                        <>
                          <Loader2 className="animate-spin h-4 w-4 mr-2" />
                          Sending...
                        </>
                      ) : (
                        'Resend Email'
                      )}
                    </button>
                    <button
                      type="button"
                      onClick={() => onNavigate('login')}
                      className="flex-1 bg-gray-100 text-gray-700 py-2 px-4 rounded-lg font-medium hover:bg-gray-200 transition-all duration-200 text-sm"
                    >
                      Go to Sign In
                    </button>
                  </div>
                )}
              </div>
            )}

            {progressMessage && (
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 flex items-center">
                <Loader2 className="animate-spin h-5 w-5 text-blue-600 mr-3 flex-shrink-0" />
                <p className="text-sm text-blue-800">{progressMessage}</p>
              </div>
            )}

            {connectionStatus && (
              <div className={`border rounded-lg p-4 flex items-start ${
                connectionStatus.includes('successful')
                  ? 'bg-green-50 border-green-200'
                  : 'bg-yellow-50 border-yellow-200'
              }`}>
                <Activity className={`h-5 w-5 mt-0.5 mr-3 flex-shrink-0 ${
                  connectionStatus.includes('successful')
                    ? 'text-green-600'
                    : 'text-yellow-600'
                }`} />
                <p className={`text-sm ${
                  connectionStatus.includes('successful')
                    ? 'text-green-800'
                    : 'text-yellow-800'
                }`}>{connectionStatus}</p>
              </div>
            )}

            <div className="space-y-3">
              <button
                type="submit"
                disabled={loading}
                className="w-full bg-gradient-to-r from-blue-600 to-blue-700 text-white py-3 rounded-lg font-bold text-lg hover:from-blue-700 hover:to-blue-800 transition-all duration-200 shadow-lg hover:shadow-xl disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
              >
                {loading ? (
                  <>
                    <Loader2 className="animate-spin h-5 w-5 mr-2" />
                    Creating account...
                  </>
                ) : (
                  'Start Free Trial'
                )}
              </button>

              <button
                type="button"
                onClick={testConnection}
                disabled={testingConnection || loading}
                className="w-full bg-gray-100 text-gray-700 py-2 rounded-lg font-medium hover:bg-gray-200 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
              >
                {testingConnection ? (
                  <>
                    <Loader2 className="animate-spin h-4 w-4 mr-2" />
                    Testing connection...
                  </>
                ) : (
                  <>
                    <Activity className="h-4 w-4 mr-2" />
                    Test Connection
                  </>
                )}
              </button>
            </div>
          </form>

          <div className="mt-6 text-center">
            <p className="text-sm text-gray-600">
              Already have an account?{' '}
              <button
                onClick={() => onNavigate('login')}
                className="font-semibold text-blue-600 hover:text-blue-700 transition-colors"
              >
                Sign in
              </button>
            </p>
          </div>
        </div>

        <div className="mt-6 text-center">
          <button
            onClick={() => onNavigate('landing')}
            className="text-sm text-gray-600 hover:text-gray-900 transition-colors"
          >
            Back to home
          </button>
        </div>
      </div>
      </div>
    </div>
  );
};

export default Signup;
