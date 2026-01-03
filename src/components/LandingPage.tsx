import React, { useState } from 'react';
import {
  Truck,
  DollarSign,
  Shield,
  TrendingUp,
  CheckCircle,
  Star,
  ArrowRight,
  Zap,
  Users,
  BarChart3,
  Target,
  Sparkles,
  MapPin,
  Clock
} from 'lucide-react';

interface LandingPageProps {
  onNavigate?: (tab: string) => void;
}

const LandingPage: React.FC<LandingPageProps> = ({ onNavigate }) => {
  const [email, setEmail] = useState('');
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [fleetSize, setFleetSize] = useState(25);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (onNavigate) {
      onNavigate('signup');
    }
  };

  const calculateSavings = (trucks: number) => {
    const fuelSavings = trucks * 2400;
    const compliance = Math.round(trucks * 340);
    const efficiency = Math.round(trucks * 480);
    return {
      fuel: fuelSavings.toLocaleString(),
      compliance: compliance.toLocaleString(),
      efficiency: efficiency.toLocaleString(),
      total: (fuelSavings + compliance + efficiency).toLocaleString()
    };
  };

  const savings = calculateSavings(fleetSize);

  const testimonials = [
    {
      name: "Mike Rodriguez",
      company: "Rodriguez Trucking",
      fleet: "45 trucks",
      quote: "TranspoPilot saved us $18,000 in the first month. The fuel optimization alone paid for itself in week one.",
      savings: "$18,000/month",
      avatar: "MR"
    },
    {
      name: "Sarah Chen",
      company: "Pacific Logistics",
      fleet: "120 trucks",
      quote: "We went from 3 DOT violations per month to zero. The compliance tracking is a game-changer.",
      savings: "Zero violations",
      avatar: "SC"
    },
    {
      name: "Tom Wilson",
      company: "Wilson Transport",
      fleet: "78 trucks",
      quote: "Driver onboarding time cut from 3 weeks to 8 days. Our drivers love the AI route suggestions.",
      savings: "65% faster onboarding",
      avatar: "TW"
    }
  ];

  const features = [
    {
      icon: Zap,
      title: "AI Route Optimization",
      description: "Smart routing algorithms that reduce miles driven by 8-15%, cutting fuel costs dramatically",
      metric: "12% fuel savings"
    },
    {
      icon: Shield,
      title: "Compliance Automation",
      description: "Never miss another inspection or renewal. Automated tracking for DOT, IFTA, and all state requirements",
      metric: "98.7% compliance"
    },
    {
      icon: BarChart3,
      title: "Predictive Analytics",
      description: "Machine learning forecasts maintenance needs, preventing breakdowns before they happen",
      metric: "35% less downtime"
    },
    {
      icon: MapPin,
      title: "Live Fleet Tracking",
      description: "Real-time GPS monitoring with geofencing, driver behavior alerts, and instant communication",
      metric: "100% visibility"
    },
    {
      icon: Clock,
      title: "Smart Dispatch",
      description: "Optimize load assignments based on driver hours, location, and historical performance data",
      metric: "20% more loads"
    },
    {
      icon: Users,
      title: "Driver Success Platform",
      description: "Digital onboarding, training modules, performance incentives, and two-way feedback systems",
      metric: "40% less turnover"
    }
  ];

  const stats = [
    { label: "Fleets Using TranspoPilot", value: "500+", icon: Truck },
    { label: "Total Trucks Managed", value: "45,000+", icon: Target },
    { label: "Average ROI", value: "670%", icon: TrendingUp },
    { label: "Customer Satisfaction", value: "4.9/5", icon: Star }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-50 to-white">

      {/* Hero Section */}
      <div className="relative overflow-hidden bg-gradient-to-br from-blue-600 via-blue-700 to-blue-800">
        <div className="absolute inset-0 bg-black opacity-10"></div>
        <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent"></div>

        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24 lg:py-32">
          <div className="text-center">
            <div className="inline-flex items-center bg-white/20 backdrop-blur-sm px-4 py-2 rounded-full mb-6 border border-white/30">
              <Sparkles className="h-4 w-4 text-yellow-300 mr-2" />
              <span className="text-white text-sm font-medium">Trusted by 500+ trucking companies</span>
            </div>

            <h1 className="text-5xl lg:text-7xl font-bold text-white mb-6 leading-tight">
              Stop Losing Money<br />
              <span className="text-blue-200">Start Saving Thousands</span>
            </h1>

            <p className="text-xl lg:text-2xl text-blue-50 mb-10 max-w-3xl mx-auto leading-relaxed">
              TranspoPilot AI saves trucking companies an average of <span className="font-bold text-white">$2,400 per truck monthly</span> through intelligent route optimization, compliance automation, and predictive maintenance.
            </p>

            <div className="flex flex-col sm:flex-row gap-4 justify-center mb-12">
              <button
                onClick={() => onNavigate && onNavigate('signup')}
                className="group bg-white text-blue-700 px-8 py-4 rounded-xl font-bold text-lg hover:bg-blue-50 transition-all duration-200 shadow-2xl hover:shadow-blue-500/50 hover:scale-105"
              >
                Start Free 30-Day Trial
                <ArrowRight className="inline-block ml-2 h-5 w-5 group-hover:translate-x-1 transition-transform" />
              </button>
              <a
                href="#calculator"
                className="border-2 border-white text-white px-8 py-4 rounded-xl font-bold text-lg hover:bg-white/10 backdrop-blur-sm transition-all duration-200 text-center"
              >
                Calculate Your Savings
              </a>
            </div>

            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 lg:gap-8 max-w-4xl mx-auto mt-16">
              {stats.map((stat, index) => {
                const Icon = stat.icon;
                return (
                  <div key={index} className="bg-white/10 backdrop-blur-md rounded-xl p-4 border border-white/20">
                    <Icon className="h-6 w-6 text-blue-200 mx-auto mb-2" />
                    <div className="text-3xl font-bold text-white mb-1">{stat.value}</div>
                    <div className="text-blue-100 text-sm">{stat.label}</div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>

      {/* ROI Calculator Section */}
      <div id="calculator" className="py-20 bg-white">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-4xl lg:text-5xl font-bold text-gray-900 mb-4">
              See Your ROI in <span className="text-blue-600">Real-Time</span>
            </h2>
            <p className="text-xl text-gray-600">Calculate exactly how much your fleet could save</p>
          </div>

          <div className="bg-gradient-to-br from-slate-50 to-white rounded-2xl shadow-2xl p-8 lg:p-12 border border-slate-200">
            <div className="mb-8">
              <label className="block text-lg font-semibold text-gray-900 mb-4">
                How many trucks do you operate?
              </label>
              <div className="flex items-center gap-4">
                <input
                  type="range"
                  min="5"
                  max="500"
                  value={fleetSize}
                  onChange={(e) => setFleetSize(Number(e.target.value))}
                  className="flex-1 h-3 bg-gradient-to-r from-emerald-200 to-emerald-600 rounded-lg appearance-none cursor-pointer"
                  style={{
                    background: `linear-gradient(to right, #2563eb 0%, #2563eb ${(fleetSize - 5) / 4.95}%, #dbeafe ${(fleetSize - 5) / 4.95}%, #dbeafe 100%)`
                  }}
                />
                <div className="text-4xl font-bold text-blue-600 min-w-[100px] text-right">
                  {fleetSize}
                </div>
              </div>
              <div className="flex justify-between text-sm text-gray-500 mt-2">
                <span>5 trucks</span>
                <span>500+ trucks</span>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-12">
              <div className="space-y-4">
                <h3 className="text-xl font-bold text-gray-900 mb-6 flex items-center">
                  <DollarSign className="h-6 w-6 text-blue-600 mr-2" />
                  Monthly Savings Breakdown
                </h3>
                <div className="bg-blue-50 rounded-xl p-4 border border-blue-200">
                  <div className="flex justify-between items-center mb-1">
                    <span className="text-gray-700 font-medium">Fuel Optimization</span>
                    <span className="text-2xl font-bold text-blue-700">${savings.fuel}</span>
                  </div>
                  <p className="text-sm text-gray-600">AI-powered routing reduces fuel costs by 12%</p>
                </div>

                <div className="bg-blue-50 rounded-xl p-4 border border-blue-300">
                  <div className="flex justify-between items-center mb-1">
                    <span className="text-gray-700 font-medium">Compliance Automation</span>
                    <span className="text-2xl font-bold text-blue-800">${savings.compliance}</span>
                  </div>
                  <p className="text-sm text-gray-600">Avoid violations and penalties</p>
                </div>

                <div className="bg-blue-100 rounded-xl p-4 border border-blue-400">
                  <div className="flex justify-between items-center mb-1">
                    <span className="text-gray-700 font-medium">Efficiency Gains</span>
                    <span className="text-2xl font-bold text-blue-900">${savings.efficiency}</span>
                  </div>
                  <p className="text-sm text-gray-600">Reduced idle time and faster dispatch</p>
                </div>
              </div>

              <div className="bg-gradient-to-br from-blue-600 to-blue-800 rounded-2xl p-8 text-white shadow-xl">
                <h3 className="text-xl font-bold mb-6">Your Annual Impact</h3>

                <div className="space-y-4">
                  <div>
                    <div className="text-sm opacity-90 mb-1">Total Monthly Savings</div>
                    <div className="text-4xl font-bold">${savings.total}</div>
                  </div>

                  <div className="border-t border-white/20 pt-4">
                    <div className="text-sm opacity-90 mb-1">Total Annual Savings</div>
                    <div className="text-5xl font-bold mb-2">
                      ${(parseInt(savings.total.replace(/,/g, '')) * 12).toLocaleString()}
                    </div>
                  </div>

                  <div className="bg-white/20 backdrop-blur-sm rounded-xl p-4 mt-6">
                    <div className="flex justify-between items-center mb-2">
                      <span className="text-sm">TranspoPilot Cost</span>
                      <span className="font-semibold">$997/mo</span>
                    </div>
                    <div className="flex justify-between items-center text-lg">
                      <span className="font-bold">ROI</span>
                      <span className="font-bold text-yellow-300">
                        {Math.round((parseInt(savings.total.replace(/,/g, '')) / 997) * 100)}%
                      </span>
                    </div>
                  </div>
                </div>

                <button
                  onClick={() => onNavigate && onNavigate('signup')}
                  className="w-full mt-8 bg-white text-blue-700 px-6 py-4 rounded-xl font-bold hover:bg-blue-50 transition-all duration-200 shadow-lg"
                >
                  Get Your Free Trial
                  <ArrowRight className="inline-block ml-2 h-5 w-5" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Features Section */}
      <div id="features" className="py-20 bg-slate-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-4xl lg:text-5xl font-bold text-gray-900 mb-4">
              Everything You Need to <span className="text-blue-600">Dominate</span>
            </h2>
            <p className="text-xl text-gray-600 max-w-3xl mx-auto">
              Powerful features designed specifically for modern trucking operations
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {features.map((feature, index) => {
              const Icon = feature.icon;
              return (
                <div
                  key={index}
                  className="group bg-white rounded-2xl p-8 shadow-lg hover:shadow-2xl transition-all duration-300 border border-slate-200 hover:border-blue-300 hover:-translate-y-1"
                >
                  <div className="bg-gradient-to-br from-blue-100 to-blue-200 rounded-xl w-14 h-14 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300">
                    <Icon className="h-7 w-7 text-blue-600" />
                  </div>
                  <h3 className="text-xl font-bold text-gray-900 mb-3">{feature.title}</h3>
                  <p className="text-gray-600 mb-4 leading-relaxed">{feature.description}</p>
                  <div className="inline-block bg-blue-50 text-blue-700 px-4 py-2 rounded-full text-sm font-semibold">
                    {feature.metric}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Testimonials */}
      <div id="testimonials" className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <div className="inline-flex items-center bg-blue-50 px-4 py-2 rounded-full mb-6">
              <span className="text-blue-700 font-semibold">Real Results from Real Fleets</span>
            </div>
            <h2 className="text-4xl lg:text-5xl font-bold text-gray-900 mb-4">
              Don't Take Our Word For It
            </h2>
            <div className="flex items-center justify-center mb-4">
              {[...Array(5)].map((_, i) => (
                <Star key={i} className="h-7 w-7 text-yellow-400 fill-current" />
              ))}
              <span className="ml-3 text-lg text-gray-600 font-medium">4.9/5 from 500+ companies</span>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {testimonials.map((testimonial, index) => (
              <div
                key={index}
                className="bg-gradient-to-br from-slate-50 to-white rounded-2xl shadow-xl p-8 border border-slate-200 hover:shadow-2xl transition-all duration-300 hover:-translate-y-1"
              >
                <div className="flex mb-4">
                  {[...Array(5)].map((_, i) => (
                    <Star key={i} className="h-5 w-5 text-yellow-400 fill-current" />
                  ))}
                </div>
                <p className="text-gray-700 text-lg mb-6 leading-relaxed italic">
                  "{testimonial.quote}"
                </p>
                <div className="flex items-center mb-4">
                  <div className="w-14 h-14 bg-gradient-to-br from-blue-100 to-blue-200 rounded-full flex items-center justify-center mr-4">
                    <span className="text-blue-700 font-bold text-lg">{testimonial.avatar}</span>
                  </div>
                  <div>
                    <h4 className="font-bold text-gray-900">{testimonial.name}</h4>
                    <p className="text-sm text-gray-600">{testimonial.company}</p>
                    <p className="text-xs text-gray-500">{testimonial.fleet}</p>
                  </div>
                </div>
                <div className="bg-blue-50 rounded-xl p-3 border-l-4 border-blue-500">
                  <div className="text-blue-800 font-bold text-lg">{testimonial.savings}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* CTA Section */}
      <div className="relative py-24 overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-blue-600 via-blue-700 to-blue-800"></div>
        <div className="absolute inset-0 bg-black opacity-10"></div>
        <div className="absolute inset-0">
          <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-blue-400 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-pulse"></div>
          <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-blue-500 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-pulse" style={{ animationDelay: '2s' }}></div>
        </div>

        <div className="relative max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-4xl lg:text-6xl font-bold text-white mb-6 leading-tight">
            Ready to Save Thousands<br />Every Single Month?
          </h2>
          <p className="text-xl lg:text-2xl text-blue-50 mb-12 max-w-3xl mx-auto">
            Join 500+ trucking companies already using TranspoPilot AI to maximize profits and streamline operations
          </p>

          {!isSubmitted ? (
            <div className="max-w-xl mx-auto">
              <form onSubmit={handleSubmit} className="mb-8">
                <div className="flex flex-col sm:flex-row gap-4">
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="Enter your business email"
                    className="flex-1 px-6 py-4 rounded-xl text-lg focus:outline-none focus:ring-4 focus:ring-blue-300 shadow-xl"
                    required
                  />
                  <button
                    type="submit"
                    className="bg-white text-blue-700 px-8 py-4 rounded-xl font-bold text-lg hover:bg-blue-50 transition-all duration-200 shadow-2xl hover:shadow-blue-500/50 hover:scale-105 flex items-center justify-center"
                  >
                    Get Started Free
                    <ArrowRight className="h-6 w-6 ml-2" />
                  </button>
                </div>
              </form>

              <div className="flex flex-col sm:flex-row items-center justify-center gap-6 text-blue-50">
                <div className="flex items-center">
                  <CheckCircle className="h-5 w-5 mr-2 text-blue-200" />
                  <span>30-day free trial</span>
                </div>
                <div className="flex items-center">
                  <CheckCircle className="h-5 w-5 mr-2 text-blue-200" />
                  <span>No credit card required</span>
                </div>
                <div className="flex items-center">
                  <CheckCircle className="h-5 w-5 mr-2 text-blue-200" />
                  <span>Instant access</span>
                </div>
              </div>
            </div>
          ) : (
            <div className="max-w-xl mx-auto bg-white/10 backdrop-blur-md rounded-2xl p-10 border border-white/20">
              <CheckCircle className="h-16 w-16 text-blue-300 mx-auto mb-6" />
              <h3 className="text-2xl font-bold text-white mb-4">Thank You!</h3>
              <p className="text-blue-50 text-lg leading-relaxed">
                We'll contact you within 24 hours to schedule your personalized demo and discuss your fleet's specific needs.
              </p>
            </div>
          )}
        </div>
      </div>


      {/* Footer */}
      <div className="bg-slate-900 py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-12 mb-12">
            <div>
              <div className="flex items-center mb-4">
                <div className="bg-gradient-to-br from-blue-400 to-blue-600 p-2 rounded-lg mr-3">
                  <Truck className="h-6 w-6 text-white" />
                </div>
                <span className="text-white font-bold text-xl">TranspoPilot AI</span>
              </div>
              <p className="text-gray-400 leading-relaxed mb-4">
                The leading AI-powered transportation management platform for modern trucking companies.
              </p>
              <div className="flex items-center space-x-1">
                {[...Array(5)].map((_, i) => (
                  <Star key={i} className="h-5 w-5 text-yellow-400 fill-current" />
                ))}
                <span className="text-gray-400 ml-2 text-sm">4.9/5 rating</span>
              </div>
            </div>

            <div>
              <h4 className="text-white font-bold mb-4 text-lg">Product</h4>
              <ul className="space-y-3 text-gray-400">
                <li onClick={() => scrollToSection('features')} className="hover:text-blue-400 transition-colors cursor-pointer">Features</li>
                <li onClick={() => onNavigate('pricing')} className="hover:text-blue-400 transition-colors cursor-pointer">Pricing</li>
                <li onClick={() => onNavigate('integrations')} className="hover:text-blue-400 transition-colors cursor-pointer">Integrations</li>
                <li className="hover:text-blue-400 transition-colors cursor-pointer opacity-50">Mobile App</li>
                <li onClick={() => onNavigate('integration')} className="hover:text-blue-400 transition-colors cursor-pointer">API Docs</li>
              </ul>
            </div>

            <div>
              <h4 className="text-white font-bold mb-4 text-lg">Company</h4>
              <ul className="space-y-3 text-gray-400">
                <li onClick={() => onNavigate('about')} className="hover:text-blue-400 transition-colors cursor-pointer">About Us</li>
                <li className="hover:text-blue-400 transition-colors cursor-pointer opacity-50">Careers</li>
                <li onClick={() => onNavigate('contact')} className="hover:text-blue-400 transition-colors cursor-pointer">Contact</li>
                <li className="hover:text-blue-400 transition-colors cursor-pointer opacity-50">Blog</li>
                <li className="hover:text-blue-400 transition-colors cursor-pointer opacity-50">Press Kit</li>
              </ul>
            </div>

            <div>
              <h4 className="text-white font-bold mb-4 text-lg">Resources</h4>
              <ul className="space-y-3 text-gray-400">
                <li className="hover:text-blue-400 transition-colors cursor-pointer opacity-50">Help Center</li>
                <li onClick={() => onNavigate('drivers')} className="hover:text-blue-400 transition-colors cursor-pointer">Training</li>
                <li onClick={() => scrollToSection('testimonials')} className="hover:text-blue-400 transition-colors cursor-pointer">Case Studies</li>
                <li className="hover:text-blue-400 transition-colors cursor-pointer opacity-50">Webinars</li>
                <li onClick={() => onNavigate('operations-monitoring')} className="hover:text-blue-400 transition-colors cursor-pointer">Status</li>
              </ul>
            </div>
          </div>

          <div className="border-t border-gray-800 pt-8">
            <div className="flex flex-col md:flex-row justify-between items-center">
              <div className="text-gray-400 text-sm mb-4 md:mb-0">
                <p>&copy; 2025 TranspoPilot AI. All rights reserved.</p>
                <p className="text-xs text-gray-500 mt-1">Version {__APP_VERSION__}</p>
              </div>
              <div className="flex space-x-6 text-gray-400 text-sm">
                <span className="hover:text-blue-400 transition-colors cursor-pointer opacity-50">Privacy Policy</span>
                <span className="hover:text-blue-400 transition-colors cursor-pointer opacity-50">Terms of Service</span>
                <span onClick={() => onNavigate('safety')} className="hover:text-blue-400 transition-colors cursor-pointer">Security</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LandingPage;