import React, { useState } from 'react';
import { createContactSubmission } from '../api/contactSubmissions';
import { 
  Mail, 
  Phone, 
  MapPin, 
  Clock,
  CheckCircle,
  MessageSquare,
  Calendar,
  Users
} from 'lucide-react';

const ContactPage: React.FC = () => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    company: '',
    fleetSize: '',
    phone: '',
    message: '',
    inquiryType: 'demo'
  });
  const [isSubmitted, setIsSubmitted] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const result = await createContactSubmission(formData);
    if (result.success) {
      setIsSubmitted(true);
    } else {
      alert('Error submitting form. Please try again.');
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const contactInfo = [
    {
      icon: Phone,
      title: "Phone",
      details: "+1 (555) 123-4567",
      description: "Mon-Fri 8AM-6PM EST"
    },
    {
      icon: Mail,
      title: "Email",
      details: "hello@transpopilot.ai",
      description: "We respond within 2 hours"
    },
    {
      icon: MapPin,
      title: "Address",
      details: "123 Innovation Drive, Austin, TX 78701",
      description: "Visit our headquarters"
    },
    {
      icon: Clock,
      title: "Support Hours",
      details: "24/7 Emergency Support",
      description: "For critical fleet issues"
    }
  ];

  const faqs = [
    {
      question: "How quickly can we get started?",
      answer: "Most customers are up and running within 24-48 hours. Our team handles all the setup and integration work for you."
    },
    {
      question: "Do you integrate with existing fleet management systems?",
      answer: "Yes! We have pre-built integrations with most major fleet management platforms, and our API can connect to custom systems."
    },
    {
      question: "What's included in the free trial?",
      answer: "Full access to all features for 30 days, including AI optimization, compliance tracking, and dedicated support. No credit card required."
    },
    {
      question: "How much can we expect to save?",
      answer: "Our customers typically save 8-15% on fuel costs and avoid thousands in compliance fines. The average ROI is 300-500% in the first year."
    }
  ];

  return (
    <div className="min-h-screen bg-white">
      {/* Hero Section */}
      <div className="bg-gradient-to-r from-blue-600 to-blue-700 py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h1 className="text-4xl font-bold text-white mb-6">
            Get Started with TranspoPilot AI
          </h1>
          <p className="text-xl text-blue-100 max-w-3xl mx-auto">
            Ready to transform your fleet operations? Our team is here to help you get started 
            and answer any questions about our AI-powered transportation management platform.
          </p>
        </div>
      </div>

      <div className="py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
            {/* Contact Form */}
            <div>
              <h2 className="text-2xl font-bold text-gray-900 mb-6">
                Schedule Your Personalized Demo
              </h2>
              
              {!isSubmitted ? (
                <form onSubmit={handleSubmit} className="space-y-6">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Full Name *
                      </label>
                      <input
                        type="text"
                        name="name"
                        value={formData.name}
                        onChange={handleChange}
                        className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                        required
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Business Email *
                      </label>
                      <input
                        type="email"
                        name="email"
                        value={formData.email}
                        onChange={handleChange}
                        className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                        required
                      />
                    </div>
                  </div>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Company Name *
                      </label>
                      <input
                        type="text"
                        name="company"
                        value={formData.company}
                        onChange={handleChange}
                        className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                        required
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Fleet Size
                      </label>
                      <select
                        name="fleetSize"
                        value={formData.fleetSize}
                        onChange={handleChange}
                        className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                      >
                        <option value="">Select fleet size</option>
                        <option value="1-10">1-10 vehicles</option>
                        <option value="11-50">11-50 vehicles</option>
                        <option value="51-200">51-200 vehicles</option>
                        <option value="201-500">201-500 vehicles</option>
                        <option value="500+">500+ vehicles</option>
                      </select>
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Phone Number
                    </label>
                    <input
                      type="tel"
                      name="phone"
                      value={formData.phone}
                      onChange={handleChange}
                      className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      What are you interested in?
                    </label>
                    <select
                      name="inquiryType"
                      value={formData.inquiryType}
                      onChange={handleChange}
                      className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="demo">Schedule a demo</option>
                      <option value="trial">Start free trial</option>
                      <option value="pricing">Pricing information</option>
                      <option value="integration">API integration</option>
                      <option value="support">Technical support</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Tell us about your current challenges
                    </label>
                    <textarea
                      name="message"
                      value={formData.message}
                      onChange={handleChange}
                      rows={4}
                      className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="What are your biggest pain points with fleet management? What would you like to see in a demo?"
                    />
                  </div>

                  <button
                    type="submit"
                    className="w-full bg-blue-600 text-white py-3 px-4 rounded-lg font-semibold hover:bg-blue-700 transition-colors"
                  >
                    Schedule Demo
                  </button>
                  
                  <p className="text-sm text-gray-600 text-center">
                    We'll contact you within 2 hours to schedule your personalized demo
                  </p>
                </form>
              ) : (
                <div className="bg-green-50 border border-green-200 rounded-lg p-6 text-center">
                  <CheckCircle className="h-12 w-12 text-green-500 mx-auto mb-4" />
                  <h3 className="text-lg font-semibold text-green-800 mb-2">Thank You!</h3>
                  <p className="text-green-700">
                    We've received your request and will contact you within 2 hours to schedule 
                    your personalized demo. In the meantime, feel free to explore our documentation 
                    or call us directly at +1 (555) 123-4567.
                  </p>
                </div>
              )}
            </div>

            {/* Contact Information */}
            <div>
              <h2 className="text-2xl font-bold text-gray-900 mb-6">
                Get in Touch
              </h2>
              
              <div className="space-y-6 mb-8">
                {contactInfo.map((info, index) => {
                  const Icon = info.icon;
                  return (
                    <div key={index} className="flex items-start space-x-4">
                      <div className="bg-blue-100 rounded-lg p-3">
                        <Icon className="h-6 w-6 text-blue-600" />
                      </div>
                      <div>
                        <h3 className="font-semibold text-gray-900">{info.title}</h3>
                        <p className="text-gray-700">{info.details}</p>
                        <p className="text-sm text-gray-500">{info.description}</p>
                      </div>
                    </div>
                  );
                })}
              </div>

              {/* Quick Actions */}
              <div className="bg-gray-50 rounded-lg p-6">
                <h3 className="font-semibold text-gray-900 mb-4">Quick Actions</h3>
                <div className="space-y-3">
                  <button className="w-full flex items-center justify-center space-x-2 bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 transition-colors">
                    <Calendar className="h-4 w-4" />
                    <span>Book a 15-min Call</span>
                  </button>
                  <button className="w-full flex items-center justify-center space-x-2 border border-gray-300 text-gray-700 py-2 px-4 rounded-lg hover:bg-gray-50 transition-colors">
                    <MessageSquare className="h-4 w-4" />
                    <span>Start Live Chat</span>
                  </button>
                  <button className="w-full flex items-center justify-center space-x-2 border border-gray-300 text-gray-700 py-2 px-4 rounded-lg hover:bg-gray-50 transition-colors">
                    <Users className="h-4 w-4" />
                    <span>Join Webinar</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* FAQ Section */}
      <div className="py-16 bg-gray-50">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">Frequently Asked Questions</h2>
            <p className="text-gray-600">Quick answers to common questions</p>
          </div>
          <div className="space-y-6">
            {faqs.map((faq, index) => (
              <div key={index} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
                <h3 className="font-semibold text-gray-900 mb-2">{faq.question}</h3>
                <p className="text-gray-700">{faq.answer}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default ContactPage;