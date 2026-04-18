import asyncio
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.infra.redis_pubsub import subscribe_loop
from app.ws.manager import manager
from .ws.chat import router as chat_router

app = FastAPI()
@app.on_event("startup")
async def on_startup():
    async def on_message(payload: dict):
        await manager.broadcast(payload)

    app.state.redis_task = asyncio.create_task(
        subscribe_loop("chat:global", on_message)
    )

@app.on_event("shutdown")
async def on_shutdown():
    task = getattr(app.state, "redis_task", None)
    if not task:
        return
    task.cancel()
    try:
        await task
    except asyncio.CancelledError:
        pass



allow_origins = ["http://localhost:5173", "http://127.0.0.1:5173", "http://localhost:5174", "http://127.0.0.1:5174"]
allow_methods = ["*"]
allow_headers = ["*"]
allow_credentials = False

app.add_middleware(
    CORSMiddleware,
    allow_origins=allow_origins,
    allow_credentials=allow_credentials,
    allow_methods=allow_methods,
    allow_headers=allow_headers,
)

app.include_router(chat_router)


@app.get("/health")
def healthcheck():
    return {"status": "OK"}

