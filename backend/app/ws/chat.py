from fastapi import APIRouter, WebSocket
from starlette.websockets import WebSocketDisconnect

from .manager import manager

router = APIRouter()


@router.websocket("/ws/chat")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)  # ここで accept() + 接続登録（あなたの設計）

    try:
        await websocket.send_json({"type": "welcome", "message": "Welcome to the chat!"})

        while True:
            data = await websocket.receive_json()  # dict が返る（receive_textだとstr）

            if data.get("type") != "send_message":
                continue

            text = (data.get("text") or "").strip()
            if not text:
                continue

            await manager.broadcast({"type": "message", "text": text})

    except WebSocketDisconnect:
        manager.disconnect(websocket)  # await不要（setから外すだけ）

    

