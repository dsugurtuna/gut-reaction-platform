import { useQuery } from '@tanstack/react-query';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';

// Mock data for dashboard
const processingData = [
  { date: 'Mon', notes: 120 },
  { date: 'Tue', notes: 180 },
  { date: 'Wed', notes: 250 },
  { date: 'Thu', notes: 190 },
  { date: 'Fri', notes: 220 },
  { date: 'Sat', notes: 80 },
  { date: 'Sun', notes: 45 },
];

const cohortData = [
  { name: 'IBD Cases', value: 1250, color: '#3B82F6' },
  { name: 'Controls', value: 2500, color: '#10B981' },
  { name: 'Pending', value: 320, color: '#F59E0B' },
];

const stats = [
  { name: 'Total Patients', value: '4,070', change: '+12%', icon: '👥' },
  { name: 'Notes Processed', value: '23,456', change: '+8%', icon: '📝' },
  { name: 'VTE Detected', value: '342', change: '+3%', icon: '🔬' },
  { name: 'Audit Reviews', value: '156', change: '-2%', icon: '✅' },
];

export default function Dashboard() {
  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-2xl font-bold text-gray-900">Dashboard</h2>
        <p className="text-gray-500">Overview of platform activity and metrics</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => (
          <div key={stat.name} className="bg-white rounded-xl shadow-sm p-6 border border-gray-200">
            <div className="flex items-center justify-between">
              <span className="text-2xl">{stat.icon}</span>
              <span className={`text-sm font-medium ${stat.change.startsWith('+') ? 'text-green-600' : 'text-red-600'}`}>
                {stat.change}
              </span>
            </div>
            <p className="mt-4 text-3xl font-bold text-gray-900">{stat.value}</p>
            <p className="text-sm text-gray-500">{stat.name}</p>
          </div>
        ))}
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Processing Chart */}
        <div className="bg-white rounded-xl shadow-sm p-6 border border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Weekly Processing Volume</h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={processingData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
                <XAxis dataKey="date" stroke="#6B7280" />
                <YAxis stroke="#6B7280" />
                <Tooltip />
                <Line 
                  type="monotone" 
                  dataKey="notes" 
                  stroke="#3B82F6" 
                  strokeWidth={2}
                  dot={{ fill: '#3B82F6' }}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Cohort Distribution */}
        <div className="bg-white rounded-xl shadow-sm p-6 border border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Cohort Distribution</h3>
          <div className="h-64 flex items-center justify-center">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={cohortData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={80}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {cohortData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="mt-4 flex justify-center gap-6">
            {cohortData.map((item) => (
              <div key={item.name} className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full" style={{ backgroundColor: item.color }} />
                <span className="text-sm text-gray-600">{item.name}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Recent Activity</h3>
        </div>
        <ul className="divide-y divide-gray-200">
          {[
            { action: 'VTE extraction completed', target: 'Batch #1234', time: '2 min ago', icon: '✅' },
            { action: 'Document audit flagged', target: 'report_2024.pdf', time: '15 min ago', icon: '⚠️' },
            { action: 'New cohort created', target: 'IBD-VTE-2024', time: '1 hour ago', icon: '📁' },
            { action: 'Genomic linkage completed', target: '423 patients', time: '2 hours ago', icon: '🔗' },
          ].map((activity, idx) => (
            <li key={idx} className="px-6 py-4 flex items-center justify-between">
              <div className="flex items-center gap-4">
                <span className="text-xl">{activity.icon}</span>
                <div>
                  <p className="text-sm font-medium text-gray-900">{activity.action}</p>
                  <p className="text-sm text-gray-500">{activity.target}</p>
                </div>
              </div>
              <span className="text-sm text-gray-400">{activity.time}</span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
