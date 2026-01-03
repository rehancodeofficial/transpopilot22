import React from 'react';
import { CheckCircle, Circle, Truck, Users, MapPin, BarChart3, X, Plug } from 'lucide-react';

interface OnboardingChecklistProps {
  completedSteps: string[];
  onStepClick: (step: string) => void;
  onDismiss: () => void;
  isVisible: boolean;
}

interface ChecklistStep {
  id: string;
  title: string;
  description: string;
  icon: React.ComponentType<{ className?: string }>;
  route: string;
}

const OnboardingChecklist: React.FC<OnboardingChecklistProps> = ({
  completedSteps,
  onStepClick,
  onDismiss,
  isVisible,
}) => {
  if (!isVisible) return null;

  const steps: ChecklistStep[] = [
    {
      id: 'connect_integration',
      title: 'Connect Your Telematics',
      description: 'Link Geotab, Samsara, Motive, or custom system to sync your fleet data',
      icon: Plug,
      route: 'integrations',
    },
    {
      id: 'view_tracking',
      title: 'Explore Live Tracking',
      description: 'See how real-time GPS tracking works',
      icon: MapPin,
      route: 'live-tracking',
    },
    {
      id: 'add_vehicle',
      title: 'Add Your First Vehicle',
      description: 'Set up your first truck to start tracking',
      icon: Truck,
      route: 'vehicles',
    },
    {
      id: 'add_driver',
      title: 'Add a Driver',
      description: 'Onboard your first driver to the system',
      icon: Users,
      route: 'drivers-management',
    },
    {
      id: 'check_analytics',
      title: 'View Your Dashboard',
      description: 'Explore AI-powered insights and reports',
      icon: BarChart3,
      route: 'dashboard',
    },
  ];

  const completedCount = completedSteps.length;
  const totalSteps = steps.length;
  const progress = (completedCount / totalSteps) * 100;

  return (
    <div className="bg-white rounded-xl shadow-lg border border-gray-200 p-6 mb-6 relative">
      <button
        onClick={onDismiss}
        className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 transition-colors"
        title="Dismiss checklist"
      >
        <X className="h-5 w-5" />
      </button>

      <div className="mb-6">
        <h3 className="text-lg font-bold text-gray-900 mb-2">Get Started with TranspoPilot</h3>
        <p className="text-sm text-gray-600 mb-4">
          Complete these steps to get the most out of your trial
        </p>

        <div className="flex items-center gap-3 mb-2">
          <div className="flex-1 bg-gray-200 rounded-full h-2">
            <div
              className="bg-gradient-to-r from-blue-600 to-blue-700 h-2 rounded-full transition-all duration-500"
              style={{ width: `${progress}%` }}
            />
          </div>
          <span className="text-sm font-semibold text-gray-700">
            {completedCount}/{totalSteps}
          </span>
        </div>

        {completedCount === totalSteps && (
          <div className="bg-green-50 border border-green-200 rounded-lg p-3 mt-3">
            <p className="text-sm text-green-800 font-medium flex items-center">
              <CheckCircle className="h-4 w-4 mr-2" />
              Great job! You've completed the onboarding checklist.
            </p>
          </div>
        )}
      </div>

      <div className="space-y-3">
        {steps.map((step) => {
          const isCompleted = completedSteps.includes(step.id);
          const Icon = step.icon;

          return (
            <button
              key={step.id}
              onClick={() => onStepClick(step.route)}
              className={`w-full flex items-start p-4 rounded-lg border-2 transition-all duration-200 ${
                isCompleted
                  ? 'bg-green-50 border-green-200 hover:bg-green-100'
                  : 'bg-gray-50 border-gray-200 hover:bg-gray-100 hover:border-blue-300'
              }`}
            >
              <div
                className={`flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center mr-4 ${
                  isCompleted
                    ? 'bg-green-600 text-white'
                    : 'bg-white border-2 border-gray-300 text-gray-400'
                }`}
              >
                {isCompleted ? (
                  <CheckCircle className="h-5 w-5" />
                ) : (
                  <Icon className="h-5 w-5" />
                )}
              </div>

              <div className="flex-1 text-left">
                <h4
                  className={`font-semibold mb-1 ${
                    isCompleted ? 'text-green-900' : 'text-gray-900'
                  }`}
                >
                  {step.title}
                </h4>
                <p
                  className={`text-sm ${
                    isCompleted ? 'text-green-700' : 'text-gray-600'
                  }`}
                >
                  {step.description}
                </p>
              </div>

              {!isCompleted && (
                <Circle className="h-5 w-5 text-gray-400 flex-shrink-0 ml-2" />
              )}
            </button>
          );
        })}
      </div>

      {completedCount < totalSteps && (
        <div className="mt-4 pt-4 border-t border-gray-200">
          <p className="text-xs text-gray-500 text-center">
            Click any step to navigate there directly
          </p>
        </div>
      )}
    </div>
  );
};

export default OnboardingChecklist;
