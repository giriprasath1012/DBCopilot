import { useState } from 'react'
import ResultTable from './ResultTable'
import ResultChart from './ResultChart'
import { exportCsvUrl } from '../api/chatApi'

export default function ChatMessage({ message }) {
  const [showSql,   setShowSql]   = useState(false)
  const [showChart, setShowChart] = useState(false)

  const isUser     = message.type === 'user'
  const isError    = message.status === 'ERROR'
  const isRejected = message.status === 'REJECTED'
  const hasData    = !isUser && message.data && message.data.length > 0

  return (
    <div className={`message ${isUser ? 'user-message' : 'assistant-message'}`}>
      <div className="message-avatar">{isUser ? '👤' : '🤖'}</div>

      <div className="message-content">
        <div className={`message-bubble${isError ? ' error-bubble' : ''}${isRejected ? ' rejected-bubble' : ''}`}>
          {isRejected && <span className="rejected-icon">🚫 </span>}
          {message.content}
        </div>

        {!isUser && message.sql && (
          <div className="message-meta">
            <button className="meta-btn" onClick={() => setShowSql(v => !v)}>
              {showSql ? 'Hide SQL' : '</> View SQL'}
            </button>
            {hasData && (
              <button className="meta-btn" onClick={() => setShowChart(v => !v)}>
                {showChart ? 'Hide Chart' : '📊 Chart'}
              </button>
            )}
            {hasData && message.queryId && (
              <a className="meta-btn" href={exportCsvUrl(message.queryId)} download="results.csv">
                ⬇ Export CSV
              </a>
            )}
          </div>
        )}

        {showSql && message.sql && (
          <pre className="sql-block">{message.sql}</pre>
        )}

        {hasData && <ResultTable data={message.data} />}

        {showChart && hasData && <ResultChart data={message.data} />}
      </div>
    </div>
  )
}
