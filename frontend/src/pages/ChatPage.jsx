import { useState, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { postQuery, getHistory, deleteHistory } from '../api/chatApi'
import ChatMessage from '../components/ChatMessage'
import Sidebar from '../components/Sidebar'

const SUGGESTIONS = [
  { icon: '👥', label: 'Customers',  text: 'Show all active customers from Bangalore' },
  { icon: '👔', label: 'Employees',  text: 'List employees in Engineering department' },
  { icon: '📦', label: 'Products',   text: 'Get top 5 products by price' },
  { icon: '🛒', label: 'Orders',     text: 'Show all pending orders' },
  { icon: '🧾', label: 'Invoices',   text: 'Show all overdue invoices' },
  { icon: '🏖',  label: 'Leaves',    text: 'List pending leave requests' },
]

export default function ChatPage() {
  const { user, logout }                = useAuth()
  const navigate                        = useNavigate()
  const [messages, setMessages]         = useState([])
  const [input, setInput]               = useState('')
  const [loading, setLoading]           = useState(false)
  const [history, setHistory]           = useState([])
  const messagesEndRef                  = useRef(null)

  useEffect(() => { loadHistory() }, [])

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, loading])

  const loadHistory = async () => {
    try { setHistory(await getHistory()) } catch { /* silent */ }
  }

  const buildConversationHistory = (msgs) => {
    const history = []
    for (let i = 0; i < msgs.length - 1; i++) {
      if (msgs[i].type === 'user' && msgs[i + 1]?.type === 'assistant' && msgs[i + 1].sql) {
        history.push({
          userQuery: msgs[i].content,
          generatedSql: msgs[i + 1].sql,
          resultSummary: msgs[i + 1].content || null,
        })
        i++
      }
    }
    return history.slice(-5)
  }

  const sendQuery = async (query) => {
    if (!query.trim() || loading) return
    const conversationHistory = buildConversationHistory(messages)
    setMessages(prev => [...prev, { id: Date.now(), type: 'user', content: query.trim() }])
    setInput('')
    setLoading(true)

    try {
      const res = await postQuery(query, conversationHistory)
      setMessages(prev => [...prev, {
        id: Date.now() + 1, type: 'assistant',
        content: res.summary, sql: res.sql, data: res.data,
        rowCount: res.rowCount, queryId: res.queryId,
        status: res.status, errorMessage: res.errorMessage,
      }])
      if (res.status !== 'REJECTED') loadHistory()
    } catch (err) {
      setMessages(prev => [...prev, {
        id: Date.now() + 1, type: 'assistant',
        content: err.response?.data?.errorMessage || 'Something went wrong.',
        status: 'ERROR',
      }])
    } finally {
      setLoading(false)
    }
  }

  const handleDeleteHistory = async (id) => {
    try {
      await deleteHistory(id)
      setHistory(prev => prev.filter(h => h.id !== id))
    } catch { /* silent */ }
  }

  return (
    <div className="chat-layout">
      <Sidebar
        history={history}
        onNewChat={() => setMessages([])}
        onSelectHistory={item => setMessages([
          { id: Date.now(),     type: 'user',      content: item.naturalQuery },
          { id: Date.now() + 1, type: 'assistant', content: item.resultSummary || 'Query from history',
            sql: item.generatedSql, status: item.status },
        ])}
        onDeleteHistory={handleDeleteHistory}
        username={user?.username}
        onLogout={() => { logout(); navigate('/login') }}
      />

      <div className="chat-main">
        {/* Top bar */}
        <div className="chat-topbar">
          <div className="chat-topbar-left">
            <span className="topbar-title">AI Query Console</span>
          </div>
          <div style={{ fontSize: '.75rem', color: 'var(--text-3)' }}>
            Powered by Ollama · llama3
          </div>
        </div>

        {/* Messages */}
        <div className="chat-messages">
          {messages.length === 0 && (
            <div className="empty-state">
              <div className="empty-icon">🗄️</div>
              <h2>Ask anything about your data</h2>
              <p>Type a question in plain English and DBCopilot will generate and run the SQL for you</p>
              <div className="suggestion-grid">
                {SUGGESTIONS.map(s => (
                  <button key={s.text} className="suggestion-card" onClick={() => sendQuery(s.text)}>
                    <div className="suggestion-card-icon">{s.icon}</div>
                    <div className="suggestion-card-label">{s.label}</div>
                    <div className="suggestion-card-text">{s.text}</div>
                  </button>
                ))}
              </div>
            </div>
          )}

          {messages.map(msg => (
            <ChatMessage key={msg.id} message={msg} username={user?.username} />
          ))}

          {loading && (
            <div className="msg msg--ai">
              <div className="msg-avatar msg-avatar--ai">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                  <ellipse cx="12" cy="6" rx="8" ry="3"/>
                  <path d="M4 6v4c0 1.657 3.582 3 8 3s8-1.343 8-3V6" opacity=".75"/>
                  <path d="M4 10v4c0 1.657 3.582 3 8 3s8-1.343 8-3v-4" opacity=".5"/>
                </svg>
              </div>
              <div className="msg-body">
                <div className="msg-thinking">
                  <span /><span /><span />
                </div>
              </div>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>

        {/* Input */}
        <div className="chat-input-area">
          <form onSubmit={e => { e.preventDefault(); sendQuery(input) }} className="chat-form">
            <input
              className="chat-input"
              type="text"
              value={input}
              onChange={e => setInput(e.target.value)}
              placeholder="Ask anything about your database…"
              disabled={loading}
              autoFocus
            />
            <button type="submit" className="send-btn" disabled={loading || !input.trim()}>
              {loading ? '…' : <>Send <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg></>}
            </button>
          </form>
          <p className="chat-hint">DBCopilot only runs SELECT queries · results are read-only</p>
        </div>
      </div>
    </div>
  )
}
