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

export const exportCsvUrl = (queryId) => `/api/export/csv/${queryId}`
