import { useTheme } from '../context/ThemeContext'

export default function Sidebar({ history, onNewChat, onSelectHistory, onDeleteHistory, username, onLogout }) {
  const { theme, toggleTheme } = useTheme()

  return (
    <div className="sidebar">
      <div className="sidebar-header">
        <div className="brand-row">
          <div className="brand">
            <span className="brand-icon">🗄️</span>
            <span>DBCopilot</span>
          </div>
          <button className="theme-toggle" onClick={toggleTheme} title="Toggle theme">
            {theme === 'dark' ? '☀️ Light' : '🌙 Dark'}
          </button>
        </div>
        <button className="new-chat-btn" onClick={onNewChat}>+ New Chat</button>
      </div>

      <div className="sidebar-history">
        <p className="history-title">Recent Queries</p>

        {history.length === 0
          ? <p className="no-history">No queries yet</p>
          : history.map(item => (
              <div
                key={item.id}
                className={`history-item${item.status === 'ERROR' ? ' error-item' : ''}`}
                onClick={() => onSelectHistory(item)}
                title={item.naturalQuery}
              >
                <span className="history-icon">{item.status === 'ERROR' ? '❌' : '✅'}</span>
                <span className="history-text">{item.naturalQuery}</span>
                <button
                  className="history-delete-btn"
                  title="Delete"
                  onClick={e => { e.stopPropagation(); onDeleteHistory(item.id) }}
                >×</button>
              </div>
            ))
        }
      </div>

      <div className="sidebar-footer">
        <div className="user-info">👤 {username}</div>
        <button className="logout-btn" onClick={onLogout}>Logout</button>
      </div>
    </div>
  )
}
