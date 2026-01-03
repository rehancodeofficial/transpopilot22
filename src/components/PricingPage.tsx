import React from 'react';
import { Check, Truck, Zap, Building2, ArrowRight } from 'lucide-react';

interface PricingPageProps {
  onNavigate: (page: string) => void;
}

const PricingPage: React.FC<PricingPageProps> = ({ onNavigate }) => {
  const plans = [
    {
      name: 'Starter',
      price: 997,
      period: 'month',
      description: 'Perfect for small fleets getting started with AI-powered management',
      gradient: 'from-blue-500 to-blue-600',
      shadowColor: 'shadow-blue-500/30',
      icon: Truck,
      features: [
        'Up to 10 vehicles',
        'Up to 10 drivers',
        'Real-time GPS tracking',
        'Basic route optimization',
        'Fuel consumption monitoring',
        'Driver performance metrics',
        'Email support',
        'Mobile app access',
        'Basic reporting',
      ],
      recommended: false,
    },
    {
      name: 'Pro',
      price: 1997,
      period: 'month',
      description: 'Advanced features for growing fleets that demand more control',
      gradient: 'from-emerald-500 to-teal-600',
      shadowColor: 'shadow-emerald-500/30',
      icon: Zap,
      features: [
        'Up to 50 vehicles',
        'Up to 50 drivers',
        'Everything in Starter, plus:',
        'AI-powered route optimization',
        'Predictive vehicle maintenance',
        'Advanced driver behavior analytics',
        'Safety & compliance automation',
        'Priority support (24/7)',
        'Custom integrations',
        'Advanced reporting & analytics',
        'API access',
      ],
      recommended: true,
    },
    {
      name: 'Enterprise',
      price: 3997,
      priceRange: '3997-4997',
      period: 'month',
      description: 'Unlimited scale with dedicated support for large operations',
      gradient: 'from-orange-500 to-red-600',
      shadowColor: 'shadow-orange-500/30',
      icon: Building2,
      features: [
        'Unlimited vehicles',
        'Unlimited drivers',
        'Everything in Pro, plus:',
        'Custom AI model training',
        'Dedicated account manager',
        'White-label solution',
        'On-premise deployment option',
        'Custom SLA',
        'Training & onboarding',
        'Multi-organization support',
        'Advanced security features',
        'Custom feature development',
      ],
      recommended: false,
    },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-slate-100">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
        <div className="text-center mb-16">
          <h1 className="text-5xl font-bold text-gray-900 mb-4">
            Simple, Transparent Pricing
          </h1>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Choose the perfect plan for your fleet. All plans include a 30-day free trial with no credit card required.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-8 mb-16">
          {plans.map((plan) => {
            const Icon = plan.icon;
            return (
              <div
                key={plan.name}
                className={`bg-white rounded-2xl shadow-xl border-2 ${
                  plan.recommended ? 'border-emerald-500 scale-105' : 'border-gray-200'
                } hover:shadow-2xl transition-all duration-300 relative overflow-hidden`}
              >
                {plan.recommended && (
                  <div className="absolute top-0 right-0 bg-gradient-to-r from-emerald-500 to-teal-600 text-white px-6 py-2 text-xs font-bold rounded-bl-lg shadow-lg">
                    MOST POPULAR
                  </div>
                )}

                <div className="p-8">
                  <div className={`inline-flex items-center justify-center bg-gradient-to-r ${plan.gradient} p-4 rounded-xl shadow-lg ${plan.shadowColor} mb-6`}>
                    <Icon className="h-8 w-8 text-white" />
                  </div>

                  <h3 className="text-2xl font-bold text-gray-900 mb-2">{plan.name}</h3>
                  <p className="text-gray-600 text-sm mb-6 h-12">{plan.description}</p>

                  <div className="mb-6">
                    <div className="flex items-baseline">
                      <span className="text-5xl font-bold text-gray-900">
                        ${plan.priceRange ? plan.priceRange.split('-')[0] : plan.price}
                      </span>
                      {plan.priceRange && (
                        <span className="text-2xl font-bold text-gray-600 ml-1">
                          - ${plan.priceRange.split('-')[1]}
                        </span>
                      )}
                      <span className="text-gray-600 ml-2">/ {plan.period}</span>
                    </div>
                    {plan.priceRange && (
                      <p className="text-sm text-gray-500 mt-1">Based on fleet size</p>
                    )}
                  </div>

                  <button
                    onClick={() => onNavigate('signup')}
                    className={`w-full py-4 rounded-lg font-bold text-lg transition-all duration-200 shadow-lg hover:shadow-xl flex items-center justify-center group ${
                      plan.recommended
                        ? 'bg-gradient-to-r from-emerald-500 to-teal-600 text-white hover:from-emerald-600 hover:to-teal-700'
                        : 'bg-gray-900 text-white hover:bg-gray-800'
                    }`}
                  >
                    Start Free Trial
                    <ArrowRight className="h-5 w-5 ml-2 group-hover:translate-x-1 transition-transform" />
                  </button>

                  <div className="mt-8 space-y-4">
                    {plan.features.map((feature, index) => (
                      <div key={index} className="flex items-start">
                        {feature.startsWith('Everything in') ? (
                          <div className="w-full">
                            <div className="h-px bg-gray-200 my-2" />
                            <p className="text-sm font-semibold text-gray-700">{feature}</p>
                            <div className="h-px bg-gray-200 my-2" />
                          </div>
                        ) : (
                          <>
                            <Check className={`h-5 w-5 flex-shrink-0 mr-3 bg-gradient-to-r ${plan.gradient} text-white rounded-full p-0.5`} />
                            <span className="text-gray-700 text-sm">{feature}</span>
                          </>
                        )}
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        <div className="bg-gradient-to-r from-blue-600 to-blue-700 rounded-2xl shadow-2xl p-12 text-center text-white">
          <h2 className="text-3xl font-bold mb-4">Need a custom solution?</h2>
          <p className="text-xl mb-8 opacity-90">
            Contact our sales team to discuss custom pricing for your specific needs.
          </p>
          <button
            onClick={() => onNavigate('contact')}
            className="bg-white text-blue-600 px-8 py-4 rounded-lg font-bold text-lg hover:bg-gray-100 transition-all duration-200 shadow-lg hover:shadow-xl"
          >
            Contact Sales
          </button>
        </div>

        <div className="mt-16 text-center">
          <h3 className="text-2xl font-bold text-gray-900 mb-8">Frequently Asked Questions</h3>
          <div className="grid md:grid-cols-2 gap-8 text-left max-w-4xl mx-auto">
            <div>
              <h4 className="font-semibold text-gray-900 mb-2">Can I switch plans later?</h4>
              <p className="text-gray-600 text-sm">
                Yes, you can upgrade or downgrade your plan at any time. Changes will be reflected in your next billing cycle.
              </p>
            </div>
            <div>
              <h4 className="font-semibold text-gray-900 mb-2">What happens after the trial ends?</h4>
              <p className="text-gray-600 text-sm">
                After your 30-day trial, you'll be prompted to select a plan. Your data will be retained for 90 days if you choose not to continue.
              </p>
            </div>
            <div>
              <h4 className="font-semibold text-gray-900 mb-2">Do you offer annual billing?</h4>
              <p className="text-gray-600 text-sm">
                Yes, annual billing is available with a 20% discount. Contact our sales team for details.
              </p>
            </div>
            <div>
              <h4 className="font-semibold text-gray-900 mb-2">Is there a setup fee?</h4>
              <p className="text-gray-600 text-sm">
                No setup fees for Starter and Pro plans. Enterprise plans include complimentary onboarding and training.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PricingPage;
