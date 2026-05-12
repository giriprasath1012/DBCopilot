import { useState } from 'react'

const PAGE_SIZE = 10

const SUCCESS_VALS = new Set(['ACTIVE','COMPLETED','PAID','APPROVED','YES'])
const DANGER_VALS  = new Set(['INACTIVE','CANCELLED','OVERDUE','REJECTED','NO'])
const WARNING_VALS = new Set(['PENDING','UNPAID','ON_HOLD'])

function StatusBadge({ value }) {
  const v = String(value).toUpperCase()
  const cls = SUCCESS_VALS.has(v) ? 'badge badge--success'
            : DANGER_VALS.has(v)  ? 'badge badge--danger'
            : WARNING_VALS.has(v) ? 'badge badge--warning'
            :                       'badge badge--neutral'
  return <span className={cls}>{value}</span>
}

const isStatusCol = (h) => /status|state/i.test(h)
const isNumericCol = (h, data) => data.every(r => r[h] === null || r[h] === undefined || !isNaN(Number(r[h])))

const fmt = (h, v) => {
  if (v === null || v === undefined) return <span style={{ color: 'var(--text-3)' }}>—</span>
  if (typeof v === 'object') return JSON.stringify(v)
  return String(v)
}

export default function ResultTable({ data }) {
  const [page, setPage] = useState(0)

  if (!data || data.length === 0) return null

  const headers    = Object.keys(data[0])
  const totalPages = Math.ceil(data.length / PAGE_SIZE)
  const pageData   = data.slice(page * PAGE_SIZE, (page + 1) * PAGE_SIZE)
  const numCols    = new Set(headers.filter(h => !isStatusCol(h) && isNumericCol(h, data)))

  return (
    <div className="result-table-wrap">
      <div className="table-meta">
        <span className="table-meta-count">{data.length} row{data.length !== 1 ? 's' : ''}</span>
        {totalPages > 1 && (
          <span style={{ fontSize: '.72rem', color: 'var(--text-3)' }}>
            Page {page + 1} of {totalPages}
          </span>
        )}
      </div>

      <div className="table-scroll">
        <table className="result-table">
          <thead>
            <tr>
              {headers.map(h => (
                <th key={h} style={numCols.has(h) ? { textAlign: 'right' } : {}}>
                  {h.replace(/_/g, ' ')}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {pageData.map((row, i) => (
              <tr key={i}>
                {headers.map(h => (
                  <td
                    key={h}
                    className={numCols.has(h) ? 'td-numeric' : ''}
                    title={row[h] !== null && row[h] !== undefined ? String(row[h]) : ''}
                  >
                    {isStatusCol(h) && row[h]
                      ? <StatusBadge value={row[h]} />
                      : fmt(h, row[h])
                    }
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {totalPages > 1 && (
        <div className="table-pagination">
          <span className="pagination-info">
            Showing {page * PAGE_SIZE + 1}–{Math.min((page + 1) * PAGE_SIZE, data.length)} of {data.length}
          </span>
          <div className="pagination-btns">
            <button onClick={() => setPage(p => p - 1)} disabled={page === 0}>← Prev</button>
            <button onClick={() => setPage(p => p + 1)} disabled={page >= totalPages - 1}>Next →</button>
          </div>
        </div>
      )}
    </div>
  )
}
