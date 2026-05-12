import api from './axios'

export const postQuery = async (message) => {
  const { data } = await api.post('/chat/query', { message })
  return data
}

export const getHistory = async () => {
  const { data } = await api.get('/history')
  return data
}

export const deleteHistory = async (id) => {
  await api.delete(`/history/${id}`)
}

export const downloadCsv = async (queryId) => {
  const response = await api.get(`/export/csv/${queryId}`, { responseType: 'blob' })
  const url = window.URL.createObjectURL(new Blob([response.data], { type: 'text/csv' }))
  const link = document.createElement('a')
  link.href = url
  link.setAttribute('download', 'results.csv')
  document.body.appendChild(link)
  link.click()
  link.remove()
  window.URL.revokeObjectURL(url)
}
