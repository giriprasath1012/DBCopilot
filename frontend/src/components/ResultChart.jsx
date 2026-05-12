import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'
import { useTheme } from '../context/ThemeContext'

const PALETTE = ['#6366f1', '#10b981', '#f59e0b', '#0ea5e9', '#a855f7']

const isNumeric = (v) => v !== null && v !== undefined && !isNaN(Number(v)) && v !== ''

export default function ResultChart({ data }) {
  const { theme } = useTheme()

  if (!data || data.length === 0) return null

  const keys        = Object.keys(data[0])
  const numericKeys = keys.filter(k => data.every(row => isNumeric(row[k])))
  const labelKey    = keys.find(k => !numericKeys.includes(k))

  if (numericKeys.length === 0) return null

  const chartData = data.slice(0, 20).map(row => ({
    name: labelKey ? String(row[labelKey] ?? '—') : '—',
    ...Object.fromEntries(numericKeys.map(k => [k, Number(row[k]) || 0])),
  }))

  const dark  = theme === 'dark'
  const grid  = dark ? '#192d47' : '#dde4ef'
  const axis  = dark ? '#3d5a78' : '#8ba4c0'
  const ttBg  = dark ? '#0d1626' : '#ffffff'
  const ttBdr = dark ? '#192d47' : '#d8e3f0'
  const ttTxt = dark ? '#e8f0fe' : '#0c1831'

  return (
    <div className="chart-wrap">
      <p className="chart-title">Data Visualisation</p>
      <ResponsiveContainer width="100%" height={260}>
        <BarChart data={chartData} margin={{ top: 4, right: 12, left: 0, bottom: 55 }}>
          <CartesianGrid strokeDasharray="3 3" stroke={grid} vertical={false} />
          <XAxis
            dataKey="name"
            stroke={axis}
            tick={{ fontSize: 11, fill: axis }}
            angle={-35}
            textAnchor="end"
            interval={0}
          />
          <YAxis stroke={axis} tick={{ fontSize: 11, fill: axis }} width={50} />
          <Tooltip
            contentStyle={{ background: ttBg, border: `1px solid ${ttBdr}`, color: ttTxt, borderRadius: 10, fontSize: 12 }}
            labelStyle={{ color: axis, fontWeight: 600 }}
            cursor={{ fill: dark ? 'rgba(99,102,241,.06)' : 'rgba(99,102,241,.04)' }}
          />
          <Legend wrapperStyle={{ color: axis, fontSize: 12, paddingTop: 8 }} />
          {numericKeys.slice(0, 5).map((key, i) => (
            <Bar key={key} dataKey={key} fill={PALETTE[i % PALETTE.length]} radius={[4, 4, 0, 0]} maxBarSize={48} />
          ))}
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}
