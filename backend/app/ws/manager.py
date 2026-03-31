from fastapi import WebSocket

class ConnectionManager:
    def __init__(self):
        self.connections = set()

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.connections.add(websocket)

    async def disconnect(self, websocket: WebSocket):
        self.connections.discard(websocket)
    

    async def broadcast(self, payload: dict):
        for connection in list(self.connections):
            try:
           
                await connection.send_json(payload)
            except Exception as e:
                print(f"Error occurred while sending message: {e}")
                self.connections.discard(connection)

manager = ConnectionManager()