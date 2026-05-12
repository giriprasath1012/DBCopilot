import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { login } from '../api/authApi'

const DBIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
    <ellipse cx="12" cy="6" rx="8" ry="3" fill="currentColor"/>
    <path d="M4 6v4c0 1.657 3.582 3 8 3s8-1.343 8-3V6" fill="currentColor" opacity=".75"/>
    <path d="M4 10v4c0 1.657 3.582 3 8 3s8-1.343 8-3v-4" fill="currentColor" opacity=".5"/>
    <path d="M4 14v4c0 1.657 3.582 3 8 3s8-1.343 8-3v-4" fill="currentColor" opacity=".3"/>
  </svg>
)

export default function LoginPage() {
  const [form, setForm]       = useState({ username: '', password: '' })
  const [error, setError]     = useState('')
  const [loading, setLoading] = useState(false)
  const { login: authLogin }  = useAuth()
  const navigate              = useNavigate()

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const data = await login(form.username, form.password)
      authLogin({ username: data.username, email: data.email }, data.token)
      navigate('/chat')
    } catch (err) {
      setError(err.response?.data?.error || 'Login failed. Check your credentials.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="auth-layout">

      {/* ── Brand panel ──────────────────────────────── */}
      <div className="auth-left">
        <div className="auth-brand">
          <div className="auth-brand-icon"><DBIcon /></div>
          <span className="auth-brand-name">DBCopilot</span>
        </div>

        <div className="auth-left-body">
          <h2>Query your database<br />in plain English</h2>
          <p>AI-powered SQL generation for modern data teams</p>

          <ul className="auth-features">
            <li>
              <div className="auth-feature-icon">⚡</div>
              <div>
                <strong>Natural Language to SQL</strong>
                <span>Type your question, get instant SQL queries</span>
              </div>
            </li>
            <li>
              <div className="auth-feature-icon">🔍</div>
              <div>
                <strong>Live Schema Introspection</strong>
                <span>Always up-to-date with your database structure</span>
              </div>
            </li>
            <li>
              <div className="auth-feature-icon">📊</div>
              <div>
                <strong>Charts & CSV Export</strong>
                <span>Visualise results and export with one click</span>
              </div>
            </li>
            <li>
              <div className="auth-feature-icon">🔒</div>
              <div>
                <strong>Secure by Design</strong>
                <span>Read-only queries, JWT authentication</span>
              </div>
            </li>
          </ul>
        </div>

        <div className="auth-left-footer">
          <div className="auth-db-badges">
            {['PostgreSQL', 'MySQL', 'Oracle', 'SQL Server', 'H2'].map(db => (
              <span key={db} className="auth-db-badge">{db}</span>
            ))}
          </div>
        </div>
      </div>

      {/* ── Form panel ───────────────────────────────── */}
      <div className="auth-right">
        <div className="auth-form-wrapper">
          <div className="auth-form-header">
            <h1>Welcome back</h1>
            <p>Sign in to your DBCopilot account</p>
          </div>

          {error && <div className="alert error">⚠ {error}</div>}

          <form onSubmit={handleSubmit} className="auth-form">
            <div className="form-group">
              <label>Username</label>
              <input
                type="text"
                value={form.username}
                onChange={e => setForm({ ...form, username: e.target.value })}
                placeholder="Enter your username"
                required
                autoFocus
              />
            </div>
            <div className="form-group">
              <label>Password</label>
              <input
                type="password"
                value={form.password}
                onChange={e => setForm({ ...form, password: e.target.value })}
                placeholder="Enter your password"
                required
              />
            </div>
            <button type="submit" className="auth-submit-btn" disabled={loading}>
              {loading ? 'Signing in…' : 'Sign In →'}
            </button>
          </form>

          <p className="auth-footer">
            Don&apos;t have an account? <Link to="/register">Create one free</Link>
          </p>
        </div>
      </div>
    </div>
  )
}
