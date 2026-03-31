import { useEffect, useState } from 'react'
import Chat from './components/Chat'
import './App.css'

function App() {
  const [status, setStatus] = useState()

  useEffect(() => {
    fetch('http://127.0.0.1:8000/health')
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
