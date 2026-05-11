import api from './axios'

export const login = async (username, password) => {
  const { data } = await api.post('/auth/login', { username, password })
  return data
}

export const register = async (username, email, password) => {
  const { data } = await api.post('/auth/register', { username, email, password })
  return data
}
