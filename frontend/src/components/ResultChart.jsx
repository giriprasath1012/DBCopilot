import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid,
  Tooltip, Legend, ResponsiveContainer,
} from 'recharts'

const COLORS = ['#6366f1', '#10b981', '#f59e0b', '#ef4444', '#3b82f6']

const isNumeric = (v) => v !== null && v !== undefined && !isNaN(Number(v)) && v !== ''

export default function ResultChart({ data }) {
  if (!data || data.length === 0) return null

  const keys        = Object.keys(data[0])
  const numericKeys = keys.filter(k => data.every(row => isNumeric(row[k])))
  const labelKey    = keys.find(k => !numericKeys.includes(k))

  if (numericKeys.length === 0) return null

  const chartData = data.slice(0, 20).map(row => ({
    name: labelKey ? String(row[labelKey] ?? '') : '—',
    ...Object.fromEntries(numericKeys.map(k => [k, Number(row[k]) || 0])),
  }))

  return (
    <div className="chart-container">
      <ResponsiveContainer width="100%" height={280}>
        <BarChart data={chartData} margin={{ top: 5, right: 20, left: 0, bottom: 60 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
          <XAxis
            dataKey="name"
            stroke="#94a3b8"
            tick={{ fontSize: 11 }}
            angle={-35}
            textAnchor="end"
            interval={0}
          />
          <YAxis stroke="#94a3b8" tick={{ fontSize: 11 }} />
          <Tooltip
            contentStyle={{ background: '#1e293b', border: '1px solid #334155', color: '#e2e8f0', borderRadius: 8 }}
            labelStyle={{ color: '#94a3b8' }}
          />
          <Legend wrapperStyle={{ color: '#94a3b8', fontSize: 12 }} />
          {numericKeys.slice(0, 5).map((key, i) => (
            <Bar key={key} dataKey={key} fill={COLORS[i % COLORS.length]} radius={[4, 4, 0, 0]} />
          ))}
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}
