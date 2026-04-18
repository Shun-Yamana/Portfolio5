import { useEffect, useState } from 'react'
import Chat from './components/Chat'
import './App.css'

function App() {
  const [status, setStatus] = useState()

  useEffect(() => {
    fetch(`${import.meta.env.VITE_API_BASE_URL}/health`)
      .then((res) => res.json())
      .then((data) => setStatus(data.status))
      .catch(() => setStatus('ERROR'))
  }, [])

  return (
    <>
      <p>API: {status ?? 'Loading...'}</p>
      <Chat />
    </>
  )
}

export default App
