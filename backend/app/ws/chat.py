import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, WebSocket
from starlette.websockets import WebSocketDisconnect

from ..infra.firehose import firehose_put
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

            message_id = str(uuid.uuid4())
            created_at = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

            payload = {
                "type": "message",
                "room_id": "global",
                "text": text,
                "message_id": message_id,
                "created_at": created_at,
            }
            await publish("chat:global", payload)
            await firehose_put({"message_id": message_id, "content": text, "created_at": created_at})

    except WebSocketDisconnect:
        manager.disconnect(websocket)
