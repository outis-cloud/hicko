import axios from 'axios'

const api = axios.create({ baseURL: process.env.VITE_API_BASE || 'http://localhost:8080' })

api.setToken = (token) => {
  if (token) api.defaults.headers.common['Authorization'] = `Bearer ${token}`
  else delete api.defaults.headers.common['Authorization']
}

export default api
