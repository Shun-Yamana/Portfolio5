from fastapi import APIRouter, WebSocket
from starlette.websockets import WebSocketDisconnect

from ..infra.redis_pubsub import publish
from .manager import manager

router = APIRouter()


@router.websocket("/ws/chat")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)

    try:
        await websocket.send_json({"type": "welcome", "message": "Welcome to the chat!"})

        while True:
            data = await websocket.receive_json()

            if data.get("type") != "send_message":
                continue

            text = (data.get("text") or "").strip()
            if not text:
                continue

            payload = {"type": "message", "room_id": "global", "text": text}
            await publish("chat:global", payload)

    except WebSocketDisconnect:
        manager.disconnect(websocket)
