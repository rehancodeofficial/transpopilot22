import React from 'react';
import { X, Truck, Sparkles, ArrowRight, CheckCircle, Plug } from 'lucide-react';

interface WelcomeModalProps {
  isOpen: boolean;
  onClose: () => void;
  onGetStarted: () => void;
  onConnectIntegration?: () => void;
  userName?: string;
}

const WelcomeModal: React.FC<WelcomeModalProps> = ({ isOpen, onClose, onGetStarted, onConnectIntegration, userName }) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 animate-fadeIn">
      <div
        className="absolute inset-0 bg-black bg-opacity-60 backdrop-blur-sm"
        onClick={onClose}
      />

      <div className="relative bg-white rounded-2xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto animate-slideUp">
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 transition-colors z-10"
        >
          <X className="h-6 w-6" />
        </button>

        <div className="p-8 md:p-12">
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center bg-gradient-to-br from-blue-500 to-blue-700 p-4 rounded-2xl shadow-2xl shadow-blue-500/30 mb-6">
              <Truck className="h-16 w-16 text-white" />
            </div>

            <div className="inline-flex items-center bg-blue-50 px-4 py-2 rounded-full mb-4">
              <Sparkles className="h-4 w-4 text-blue-600 mr-2" />
              <span className="text-blue-700 font-semibold text-sm">Welcome to TranspoPilot AI</span>
            </div>

            <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-3">
              {userName ? `Welcome, ${userName}!` : 'Welcome!'}
            </h2>
            <p className="text-lg text-gray-600 leading-relaxed">
              You're all set to transform your fleet operations with AI-powered insights
            </p>
          </div>

          <div className="space-y-4 mb-8">
            <div className="flex items-start p-4 bg-gradient-to-r from-blue-50 to-blue-100 rounded-xl border border-blue-200">
              <div className="flex-shrink-0 w-10 h-10 bg-blue-600 rounded-full flex items-center justify-center mr-4">
                <CheckCircle className="h-5 w-5 text-white" />
              </div>
              <div>
                <h3 className="font-bold text-gray-900 mb-1">Live Fleet Tracking</h3>
                <p className="text-sm text-gray-600">Monitor all your vehicles in real-time with GPS precision</p>
              </div>
            </div>

            <div className="flex items-start p-4 bg-gradient-to-r from-blue-50 to-blue-100 rounded-xl border border-blue-200">
              <div className="flex-shrink-0 w-10 h-10 bg-blue-600 rounded-full flex items-center justify-center mr-4">
                <CheckCircle className="h-5 w-5 text-white" />
              </div>
              <div>
                <h3 className="font-bold text-gray-900 mb-1">AI Route Optimization</h3>
                <p className="text-sm text-gray-600">Save up to 12% on fuel costs with intelligent routing</p>
              </div>
            </div>

            <div className="flex items-start p-4 bg-gradient-to-r from-blue-50 to-blue-100 rounded-xl border border-blue-200">
              <div className="flex-shrink-0 w-10 h-10 bg-blue-600 rounded-full flex items-center justify-center mr-4">
                <CheckCircle className="h-5 w-5 text-white" />
              </div>
              <div>
                <h3 className="font-bold text-gray-900 mb-1">Predictive Maintenance</h3>
                <p className="text-sm text-gray-600">Get ahead of vehicle issues before they become problems</p>
              </div>
            </div>

            <div className="flex items-start p-4 bg-gradient-to-r from-blue-50 to-blue-100 rounded-xl border border-blue-200">
              <div className="flex-shrink-0 w-10 h-10 bg-blue-600 rounded-full flex items-center justify-center mr-4">
                <CheckCircle className="h-5 w-5 text-white" />
              </div>
              <div>
                <h3 className="font-bold text-gray-900 mb-1">Compliance Automation</h3>
                <p className="text-sm text-gray-600">Never miss DOT inspections or renewals again</p>
              </div>
            </div>
          </div>

          <div className="bg-gradient-to-br from-blue-50 to-cyan-50 rounded-xl p-6 border-2 border-blue-200 mb-8">
            <div className="flex items-start gap-3 mb-3">
              <div className="flex-shrink-0 w-10 h-10 bg-gradient-to-br from-blue-600 to-cyan-600 rounded-full flex items-center justify-center">
                <Plug className="h-5 w-5 text-white" />
              </div>
              <div>
                <h3 className="font-bold text-gray-900 mb-1">Ready to connect your fleet?</h3>
                <p className="text-sm text-gray-700 leading-relaxed">
                  Connect Geotab, Samsara, Motive, or any telematics system to sync your real fleet data automatically. Or explore with demo data first.
                </p>
              </div>
            </div>
            <div className="bg-white rounded-lg p-3 border border-blue-200">
              <p className="text-xs text-gray-600 text-center">
                <span className="font-semibold text-gray-900">30-day free trial</span> • No credit card required • Demo data pre-loaded
              </p>
            </div>
          </div>

          <div className="flex flex-col gap-3">
            {onConnectIntegration && (
              <button
                onClick={onConnectIntegration}
                className="w-full bg-gradient-to-r from-blue-600 to-cyan-600 text-white px-6 py-4 rounded-xl font-bold text-lg hover:from-blue-700 hover:to-cyan-700 transition-all duration-200 shadow-lg hover:shadow-xl flex items-center justify-center group"
              >
                <Plug className="mr-2 h-5 w-5" />
                Connect Your Telematics
                <ArrowRight className="ml-2 h-5 w-5 group-hover:translate-x-1 transition-transform" />
              </button>
            )}
            <div className="flex flex-col sm:flex-row gap-3">
              <button
                onClick={onGetStarted}
                className="flex-1 bg-white text-gray-700 px-6 py-3 rounded-xl font-semibold hover:bg-gray-50 transition-all duration-200 border-2 border-gray-300"
              >
                Explore Demo First
              </button>
              <button
                onClick={onClose}
                className="sm:w-32 bg-white text-gray-600 px-6 py-3 rounded-xl font-medium hover:bg-gray-50 transition-all duration-200 border border-gray-300"
              >
                Skip
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default WelcomeModal;
