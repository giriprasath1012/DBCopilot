import { useTheme } from '../context/ThemeContext'

const DBIcon = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
    <ellipse cx="12" cy="6" rx="8" ry="3" fill="currentColor"/>
    <path d="M4 6v4c0 1.657 3.582 3 8 3s8-1.343 8-3V6" fill="currentColor" opacity=".75"/>
    <path d="M4 10v4c0 1.657 3.582 3 8 3s8-1.343 8-3v-4" fill="currentColor" opacity=".5"/>
    <path d="M4 14v4c0 1.657 3.582 3 8 3s8-1.343 8-3v-4" fill="currentColor" opacity=".3"/>
  </svg>
)

export default function Sidebar({ history, onNewChat, onSelectHistory, onDeleteHistory, username, onLogout }) {
  const { theme, toggleTheme } = useTheme()

  return (
    <div className="sidebar">

      {/* Header */}
      <div className="sidebar-header">
        <div className="sidebar-brand-row">
          <div className="sidebar-brand">
            <div className="sidebar-brand-icon"><DBIcon /></div>
            <span className="sidebar-brand-name">DBCopilot</span>
          </div>
          <button className="theme-btn" onClick={toggleTheme} title="Toggle theme">
            {theme === 'dark' ? '☀ Light' : '☾ Dark'}
          </button>
        </div>

        <div>
          <span className="db-connection-badge">
            <span className="db-dot" />
            PostgreSQL · Connected
          </span>
        </div>

        <button className="new-chat-btn" onClick={onNewChat}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
            <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
          </svg>
          New Chat
        </button>
      </div>

      {/* History */}
      <div className="sidebar-history">
        <p className="history-section-label">Recent Queries</p>

        {history.length === 0 ? (
          <p className="no-history">No queries yet.<br />Start a conversation above.</p>
        ) : (
          history.map(item => (
            <div
              key={item.id}
              className="history-item"
              onClick={() => onSelectHistory(item)}
              title={item.naturalQuery}
            >
              <span className={`history-status-dot ${item.status === 'ERROR' ? 'err' : 'ok'}`} />
              <span className="history-text">{item.naturalQuery}</span>
              <button
                className="history-del-btn"
                title="Delete"
                onClick={e => { e.stopPropagation(); onDeleteHistory(item.id) }}
              >✕</button>
            </div>
          ))
        )}
      </div>

      {/* Footer */}
      <div className="sidebar-footer">
        <div className="user-row">
          <div className="user-avatar">
            {username ? username[0].toUpperCase() : '?'}
          </div>
          <span className="user-name">{username}</span>
          <button className="logout-btn" onClick={onLogout}>Sign out</button>
        </div>
      </div>
    </div>
  )
}
