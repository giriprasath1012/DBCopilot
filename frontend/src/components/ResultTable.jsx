import { useState } from 'react'

const PAGE_SIZE = 10

export default function ResultTable({ data }) {
  const [page, setPage] = useState(0)

  if (!data || data.length === 0) return null

  const headers    = Object.keys(data[0])
  const totalPages = Math.ceil(data.length / PAGE_SIZE)
  const pageData   = data.slice(page * PAGE_SIZE, (page + 1) * PAGE_SIZE)

  const cellValue = (v) => {
    if (v === null || v === undefined) return '—'
    if (typeof v === 'object') return JSON.stringify(v)
    return String(v)
  }

  return (
    <div className="result-table-container">
      <div className="table-info">{data.length} row{data.length !== 1 ? 's' : ''}</div>
      <div className="table-scroll">
        <table className="result-table">
          <thead>
            <tr>{headers.map(h => <th key={h}>{h}</th>)}</tr>
          </thead>
          <tbody>
            {pageData.map((row, i) => (
              <tr key={i}>
                {headers.map(h => <td key={h} title={cellValue(row[h])}>{cellValue(row[h])}</td>)}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {totalPages > 1 && (
        <div className="pagination">
          <button onClick={() => setPage(p => p - 1)} disabled={page === 0}>← Prev</button>
          <span>{page + 1} / {totalPages}</span>
          <button onClick={() => setPage(p => p + 1)} disabled={page >= totalPages - 1}>Next →</button>
        </div>
      )}
    </div>
  )
}
