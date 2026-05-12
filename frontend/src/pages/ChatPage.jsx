import { useState, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { postQuery, getHistory, deleteHistory } from '../api/chatApi'
import ChatMessage from '../components/ChatMessage'
import Sidebar from '../components/Sidebar'

const SUGGESTED_PROMPTS = [
  'Show all active customers from Bangalore',
  'How many employees joined this month?',
  'Get top 5 products by price',
  'Show all completed orders with amounts',
  'List employees in Engineering department',
  'Show total order amount by customer',
]

export default function ChatPage() {
  const { user, logout }   = useAuth()
  const navigate           = useNavigate()
  const [messages, setMessages]   = useState([])
  const [input, setInput]         = useState('')
  const [loading, setLoading]     = useState(false)
  const [history, setHistory]     = useState([])
  const messagesEndRef            = useRef(null)

  useEffect(() => { loadHistory() }, [])

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, loading])

  const loadHistory = async () => {
    try {
      const data = await getHistory()
      setHistory(data)
    } catch { /* silent */ }
  }

  const sendQuery = async (query) => {
    if (!query.trim() || loading) return

    const userMsg = { id: Date.now(), type: 'user', content: query.trim() }
    setMessages(prev => [...prev, userMsg])
    setInput('')
    setLoading(true)

    try {
      const res = await postQuery(query)
      const assistantMsg = {
        id:           Date.now() + 1,
        type:         'assistant',
        content:      res.summary,
        sql:          res.sql,
        data:         res.data,
        rowCount:     res.rowCount,
        queryId:      res.queryId,
        status:       res.status,
        errorMessage: res.errorMessage,
      }
      setMessages(prev => [...prev, assistantMsg])
      if (res.status !== 'REJECTED') loadHistory()
    } catch (err) {
      const errMsg = err.response?.data?.errorMessage || err.message || 'Something went wrong.'
      setMessages(prev => [...prev, {
        id: Date.now() + 1, type: 'assistant',
        content: 'Sorry, I could not process that request.',
        status: 'ERROR', errorMessage: errMsg,
      }])
    } finally {
      setLoading(false)
    }
  }

  const handleSubmit = (e) => {
    e.preventDefault()
    sendQuery(input)
  }

  const handleSelectHistory = (item) => {
    setMessages([
      { id: Date.now(),     type: 'user',      content: item.naturalQuery },
      { id: Date.now() + 1, type: 'assistant', content: item.resultSummary || 'Query from history',
        sql: item.generatedSql, status: item.status },
    ])
  }

  const handleDeleteHistory = async (id) => {
    try {
      await deleteHistory(id)
      setHistory(prev => prev.filter(h => h.id !== id))
    } catch { /* silent */ }
  }

  const handleLogout = () => { logout(); navigate('/login') }

  return (
    <div className="chat-layout">
      <Sidebar
        history={history}
        onNewChat={() => setMessages([])}
        onSelectHistory={handleSelectHistory}
        onDeleteHistory={handleDeleteHistory}
        username={user?.username}
        onLogout={handleLogout}
      />

      <div className="chat-main">
        <div className="chat-messages">
          {messages.length === 0 && (
            <div className="empty-state">
              <h2>Welcome to DBCopilot 🗄️</h2>
              <p>Ask questions about your database in plain English</p>
              <div className="suggestions">
                {SUGGESTED_PROMPTS.map(p => (
                  <button key={p} className="suggestion-btn" onClick={() => sendQuery(p)}>
                    {p}
                  </button>
                ))}
              </div>
            </div>
          )}

          {messages.map(msg => (
            <ChatMessage key={msg.id} message={msg} />
          ))}

          {loading && (
            <div className="message assistant-message">
              <div className="message-avatar">🤖</div>
              <div className="message-content">
                <div className="thinking">
                  <span /><span /><span />
                </div>
              </div>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>

        <div className="chat-input-area">
          <form onSubmit={handleSubmit} className="chat-form">
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
              {loading ? '…' : 'Send ↑'}
            </button>
          </form>
        </div>
      </div>
    </div>
  )
}
