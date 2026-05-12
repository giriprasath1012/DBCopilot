import { useState } from 'react'
import ResultTable from './ResultTable'
import ResultChart from './ResultChart'
import { downloadCsv } from '../api/chatApi'

const AIAvatar = () => (
  <div className="msg-avatar msg-avatar--ai">
    <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
      <ellipse cx="12" cy="6" rx="8" ry="3"/>
      <path d="M4 6v4c0 1.657 3.582 3 8 3s8-1.343 8-3V6" opacity=".75"/>
      <path d="M4 10v4c0 1.657 3.582 3 8 3s8-1.343 8-3v-4" opacity=".5"/>
    </svg>
  </div>
)

export default function ChatMessage({ message, username }) {
  const [showSql,   setShowSql]   = useState(false)
  const [showChart, setShowChart] = useState(false)
  const [copied,    setCopied]    = useState(false)

  const isUser     = message.type === 'user'
  const isError    = message.status === 'ERROR'
  const isRejected = message.status === 'REJECTED'
  const hasData    = !isUser && message.data?.length > 0

  const copySQL = () => {
    navigator.clipboard.writeText(message.sql)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  const bubbleClass = isError    ? 'msg-bubble msg-bubble--ai msg-bubble--error'
                    : isRejected ? 'msg-bubble msg-bubble--ai msg-bubble--rejected'
                    : isUser     ? 'msg-bubble msg-bubble--user'
                    :              'msg-bubble msg-bubble--ai'

  return (
    <div className={`msg ${isUser ? 'msg--user' : 'msg--ai'}`}>

      {isUser ? (
        <div className="msg-avatar msg-avatar--user">
          {username ? username[0].toUpperCase() : 'U'}
        </div>
      ) : (
        <AIAvatar />
      )}

      <div className="msg-body">
        <div className={bubbleClass}>
          {isRejected && '⛔ '}
          {isError    && '⚠ '}
          {message.content}
        </div>

        {!isUser && message.sql && (
          <div className="msg-actions">
            <button className="action-chip" onClick={() => setShowSql(v => !v)}>
              <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>
              {showSql ? 'Hide SQL' : 'View SQL'}
            </button>
            {hasData && (
              <button className="action-chip" onClick={() => setShowChart(v => !v)}>
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="18" y="3" width="4" height="18"/><rect x="10" y="8" width="4" height="13"/><rect x="2" y="13" width="4" height="8"/></svg>
                {showChart ? 'Hide Chart' : 'Chart'}
              </button>
            )}
            {hasData && message.queryId && (
              <button className="action-chip" onClick={() => downloadCsv(message.queryId)}>
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                Export CSV
              </button>
            )}
          </div>
        )}

        {showSql && message.sql && (
          <div className="sql-block-wrapper">
            <div className="sql-block-header">
              <span className="sql-block-lang">SQL</span>
              <button className={`copy-btn ${copied ? 'copied' : ''}`} onClick={copySQL}>
                {copied
                  ? <><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="20 6 9 17 4 12"/></svg> Copied</>
                  : <><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg> Copy</>
                }
              </button>
            </div>
            <pre className="sql-block">{message.sql}</pre>
          </div>
        )}

        {hasData && <ResultTable data={message.data} />}
        {showChart && hasData && <ResultChart data={message.data} />}
      </div>
    </div>
  )
}
