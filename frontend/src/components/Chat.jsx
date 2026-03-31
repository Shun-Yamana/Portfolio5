import { useEffect, useRef, useState } from 'react'

function Chat() {
  const wsRef = useRef(null)

  const [connectionState, setConnectionState] = useState('connecting')
  const [messages, setMessages] = useState([])
  const [input, setInput] = useState('')

  useEffect(() => {
    const ws = new WebSocket('ws://127.0.0.1:8000/ws/chat')
    wsRef.current = ws

    ws.onopen = () => setConnectionState('open')

    ws.onmessage = (event) => {
      let data
      try {
        data = JSON.parse(event.data)
      } catch {
        return
      }

      if (data?.type === 'message') {
        setMessages((prev) => [...prev, data])
      }
    }

    ws.onerror = () => setConnectionState('error')
    ws.onclose = () => setConnectionState('closed')

    return () => {
      wsRef.current = null
      ws.close()
    }
  }, [])

  const onSubmit = (e) => {
    e.preventDefault()

    const text = input.trim()
    if (!text) return

    const ws = wsRef.current
    if (!ws || ws.readyState !== WebSocket.OPEN) return

    ws.send(JSON.stringify({ type: 'send_message', room_id: 'global', text }))
    setInput('')
  }

  return (
    <>
      <p>WS: {connectionState}</p>
      <div className="chat">
        <div className="messages">
          {messages.map((message, index) => (
            <div key={message.message_id ?? index}>{message.text}</div>
          ))}
        </div>
        <form onSubmit={onSubmit}>
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Type a message"
          />
          <button type="submit" disabled={connectionState !== 'open' || !input.trim()}>
            Send
          </button>
        </form>
      </div>
    </>
  )
}

export default Chat
