import React, { useState } from 'react';
import { 
  Shield, 
  AlertTriangle, 
  CheckCircle, 
  Clock, 
  TrendingUp,
  TrendingDown,
  Award,
  AlertCircle
} from 'lucide-react';

const SafetyCompliance: React.FC = () => {
  const [activeTab, setActiveTab] = useState('overview');

  const safetyStats = [
    {
      name: 'Safety Score',
      value: '98.7%',
      change: '+0.5%',
      changeType: 'increase',
      icon: Shield,
      color: 'text-green-600',
      bgColor: 'bg-green-100',
    },
    {
      name: 'Incidents This Month',
      value: '3',
      change: '-2',
      changeType: 'decrease',
      icon: AlertTriangle,
      color: 'text-yellow-600',
      bgColor: 'bg-yellow-100',
    },
    {
      name: 'Compliance Rate',
      value: '96.2%',
      change: '+1.8%',
      changeType: 'increase',
      icon: CheckCircle,
      color: 'text-blue-600',
      bgColor: 'bg-blue-100',
    },
    {
      name: 'Overdue Items',
      value: '7',
      change: '-3',
      changeType: 'decrease',
      icon: Clock,
      color: 'text-red-600',
      bgColor: 'bg-red-100',
    },
  ];

  const complianceItems = [
    {
      id: 1,
      type: 'DOT Inspection',
      entity: 'Vehicle #1205',
      dueDate: '2024-01-15',
      status: 'overdue',
      priority: 'critical',
      daysOverdue: 5,
    },
    {
      id: 2,
      type: 'License Renewal',
      entity: 'Mike Johnson',
      dueDate: '2024-01-18',
      status: 'due-soon',
      priority: 'high',
      daysUntilDue: 3,
    },
    {
      id: 3,
      type: 'Medical Certificate',
      entity: 'Sarah Wilson',
      dueDate: '2024-01-25',
      status: 'pending',
      priority: 'medium',
      daysUntilDue: 10,
    },
    {
      id: 4,
      type: 'Safety Training',
      entity: 'John Smith',
      dueDate: '2024-01-20',
      status: 'due-soon',
      priority: 'medium',
      daysUntilDue: 5,
    },
  ];

  const recentIncidents = [
    {
      id: 1,
      type: 'Near Miss',
      driver: 'Tom Anderson',
      vehicle: 'Truck #1156',
      date: '2024-01-10',
      severity: 'low',
      description: 'Close call with pedestrian at intersection',
      status: 'resolved',
    },
    {
      id: 2,
      type: 'Traffic Violation',
      driver: 'Lisa Brown',
      vehicle: 'Truck #1089',
      date: '2024-01-08',
      severity: 'medium',
      description: 'Speeding ticket - 10 mph over limit',
      status: 'under-review',
    },
    {
      id: 3,
      type: 'Minor Accident',
      driver: 'David Lee',
      vehicle: 'Truck #1247',
      date: '2024-01-05',
      severity: 'medium',
      description: 'Backing incident in loading dock',
      status: 'resolved',
    },
  ];

  const safetyMetrics = [
    { name: 'Miles Driven', value: '2.4M', change: '+12%' },
    { name: 'Accident Rate', value: '0.02%', change: '-15%' },
    { name: 'Safety Training Hours', value: '1,247', change: '+23%' },
    { name: 'Violations', value: '12', change: '-8%' },
  ];

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Safety & Compliance</h1>
          <p className="text-gray-600">Monitor safety performance and regulatory compliance</p>
        </div>
        <div className="flex items-center space-x-3">
          <button 
            onClick={() => {
              // Simulate report generation
              const reportData = {
                timestamp: new Date().toISOString(),
                stats: safetyStats,
                incidents: recentIncidents,
                compliance: complianceItems
              };
              
              // In a real app, this would call an API
              console.log('Generating report with data:', reportData);
              
              // Create a dummy download
              const blob = new Blob([JSON.stringify(reportData, null, 2)], { type: 'application/json' });
              const url = URL.createObjectURL(blob);
              const a = document.createElement('a');
              a.href = url;
              a.download = `safety-report-${new Date().toISOString().split('T')[0]}.json`;
              document.body.appendChild(a);
              a.click();
              document.body.removeChild(a);
              URL.revokeObjectURL(url);
              
              alert('Report generated and downloaded successfully!');
            }}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            Generate Report
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200">
        <nav className="-mb-px flex space-x-8">
          {[
            { id: 'overview', name: 'Overview' },
            { id: 'compliance', name: 'Compliance' },
            { id: 'incidents', name: 'Incidents' },
            { id: 'training', name: 'Training' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === tab.id
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              {tab.name}
            </button>
          ))}
        </nav>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {safetyStats.map((stat) => {
          const Icon = stat.icon;
          return (
            <div key={stat.name} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">{stat.name}</p>
                  <p className="text-2xl font-semibold text-gray-900">{stat.value}</p>
                </div>
                <div className={`p-3 rounded-full ${stat.bgColor}`}>
                  <Icon className={`h-6 w-6 ${stat.color}`} />
                </div>
              </div>
              <div className="mt-4 flex items-center">
                {stat.changeType === 'increase' ? (
                  <TrendingUp className="h-4 w-4 text-green-500 mr-1" />
                ) : (
                  <TrendingDown className="h-4 w-4 text-green-500 mr-1" />
                )}
                <span className="text-sm font-medium text-green-600">
                  {stat.change}
                </span>
                <span className="text-sm text-gray-500 ml-1">from last month</span>
              </div>
            </div>
          );
        })}
      </div>

      {activeTab === 'overview' && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Safety Metrics */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="p-6 border-b border-gray-200">
              <h3 className="text-lg font-medium text-gray-900">Safety Metrics</h3>
            </div>
            <div className="p-6 space-y-4">
              {safetyMetrics.map((metric, index) => (
                <div key={index} className="flex items-center justify-between">
                  <span className="text-sm text-gray-600">{metric.name}</span>
                  <div className="flex items-center space-x-2">
                    <span className="text-sm font-medium text-gray-900">{metric.value}</span>
                    <span className="text-xs text-green-600">{metric.change}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Top Safety Performers */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="p-6 border-b border-gray-200">
              <h3 className="text-lg font-medium text-gray-900">Top Safety Performers</h3>
            </div>
            <div className="p-6 space-y-4">
              {[
                { name: 'Sarah Wilson', score: '99.8%', streak: '245 days' },
                { name: 'John Smith', score: '99.2%', streak: '189 days' },
                { name: 'Mike Johnson', score: '98.7%', streak: '156 days' },
              ].map((driver, index) => (
                <div key={index} className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                      <Award className="h-4 w-4 text-green-600" />
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-900">{driver.name}</p>
                      <p className="text-xs text-gray-500">Safety streak: {driver.streak}</p>
                    </div>
                  </div>
                  <span className="text-sm font-medium text-green-600">{driver.score}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {activeTab === 'compliance' && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="p-6 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-medium text-gray-900">Compliance Items</h3>
              <button className="text-sm text-blue-600 hover:text-blue-700 font-medium">
                Add New Item
              </button>
            </div>
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Type
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Entity
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Due Date
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Priority
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {complianceItems.map((item) => (
                  <tr key={item.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {item.type}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {item.entity}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {new Date(item.dueDate).toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        item.status === 'overdue' ? 'bg-red-100 text-red-800' :
                        item.status === 'due-soon' ? 'bg-yellow-100 text-yellow-800' :
                        'bg-green-100 text-green-800'
                      }`}>
                        {item.status === 'overdue' ? `${item.daysOverdue} days overdue` :
                         item.status === 'due-soon' ? `Due in ${item.daysUntilDue} days` :
                         `Due in ${item.daysUntilDue} days`}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        item.priority === 'critical' ? 'bg-red-100 text-red-800' :
                        item.priority === 'high' ? 'bg-orange-100 text-orange-800' :
                        'bg-yellow-100 text-yellow-800'
                      }`}>
                        {item.priority}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <button className="text-blue-600 hover:text-blue-900 mr-3">
                        Complete
                      </button>
                      <button className="text-gray-600 hover:text-gray-900">
                        View
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {activeTab === 'incidents' && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="p-6 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-medium text-gray-900">Recent Incidents</h3>
              <button className="text-sm text-blue-600 hover:text-blue-700 font-medium">
                Report Incident
              </button>
            </div>
          </div>
          <div className="p-6 space-y-4">
            {recentIncidents.map((incident) => (
              <div key={incident.id} className="border border-gray-200 rounded-lg p-4">
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center space-x-3">
                    <div className={`p-2 rounded-full ${
                      incident.severity === 'high' ? 'bg-red-100' :
                      incident.severity === 'medium' ? 'bg-yellow-100' :
                      'bg-blue-100'
                    }`}>
                      <AlertCircle className={`h-4 w-4 ${
                        incident.severity === 'high' ? 'text-red-600' :
                        incident.severity === 'medium' ? 'text-yellow-600' :
                        'text-blue-600'
                      }`} />
                    </div>
                    <div>
                      <h4 className="font-medium text-gray-900">{incident.type}</h4>
                      <p className="text-sm text-gray-500">{incident.driver} • {incident.vehicle}</p>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                      incident.status === 'resolved' ? 'bg-green-100 text-green-800' :
                      'bg-yellow-100 text-yellow-800'
                    }`}>
                      {incident.status}
                    </span>
                    <span className="text-sm text-gray-500">{incident.date}</span>
                  </div>
                </div>
                <p className="text-sm text-gray-700">{incident.description}</p>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default SafetyCompliance;