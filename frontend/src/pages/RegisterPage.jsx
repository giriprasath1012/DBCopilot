import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { register } from '../api/authApi'

const DBIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
    <ellipse cx="12" cy="6" rx="8" ry="3" fill="currentColor"/>
    <path d="M4 6v4c0 1.657 3.582 3 8 3s8-1.343 8-3V6" fill="currentColor" opacity=".75"/>
    <path d="M4 10v4c0 1.657 3.582 3 8 3s8-1.343 8-3v-4" fill="currentColor" opacity=".5"/>
    <path d="M4 14v4c0 1.657 3.582 3 8 3s8-1.343 8-3v-4" fill="currentColor" opacity=".3"/>
  </svg>
)

export default function RegisterPage() {
  const [form, setForm]       = useState({ username: '', email: '', password: '' })
  const [error, setError]     = useState('')
  const [loading, setLoading] = useState(false)
  const { login: authLogin }  = useAuth()
  const navigate              = useNavigate()

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    if (form.password.length < 6) { setError('Password must be at least 6 characters.'); return }
    setLoading(true)
    try {
      const data = await register(form.username, form.email, form.password)
      authLogin({ username: data.username, email: data.email }, data.token)
      navigate('/chat')
    } catch (err) {
      setError(err.response?.data?.error || 'Registration failed. Try a different username or email.')
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
          <h2>Start querying smarter,<br />not harder</h2>
          <p>Join teams using natural language to explore their databases</p>

          <ul className="auth-features">
            <li>
              <div className="auth-feature-icon">🚀</div>
              <div>
                <strong>Zero SQL Knowledge Needed</strong>
                <span>Ask questions the way you think</span>
              </div>
            </li>
            <li>
              <div className="auth-feature-icon">🤖</div>
              <div>
                <strong>Powered by Local AI</strong>
                <span>Your data stays on your infrastructure</span>
              </div>
            </li>
            <li>
              <div className="auth-feature-icon">📈</div>
              <div>
                <strong>Instant Insights</strong>
                <span>Charts, tables and exports out of the box</span>
              </div>
            </li>
            <li>
              <div className="auth-feature-icon">🗄️</div>
              <div>
                <strong>Multi-Database Support</strong>
                <span>PostgreSQL, MySQL, Oracle, SQL Server, H2</span>
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
            <h1>Create your account</h1>
            <p>Free to use · No credit card required</p>
          </div>

          {error && <div className="alert error">⚠ {error}</div>}

          <form onSubmit={handleSubmit} className="auth-form">
            <div className="form-group">
              <label>Username</label>
              <input
                type="text"
                value={form.username}
                onChange={e => setForm({ ...form, username: e.target.value })}
                placeholder="Choose a username"
                required
                autoFocus
              />
            </div>
            <div className="form-group">
              <label>Email</label>
              <input
                type="email"
                value={form.email}
                onChange={e => setForm({ ...form, email: e.target.value })}
                placeholder="your@email.com"
                required
              />
            </div>
            <div className="form-group">
              <label>Password</label>
              <input
                type="password"
                value={form.password}
                onChange={e => setForm({ ...form, password: e.target.value })}
                placeholder="At least 6 characters"
                required
              />
            </div>
            <button type="submit" className="auth-submit-btn" disabled={loading}>
              {loading ? 'Creating account…' : 'Create Account →'}
            </button>
          </form>

          <p className="auth-footer">
            Already have an account? <Link to="/login">Sign in</Link>
          </p>
        </div>
      </div>
    </div>
  )
}
