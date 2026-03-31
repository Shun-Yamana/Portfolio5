from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .ws.chat import router as chat_router

app = FastAPI()

allow_origins = ["http://localhost:5174", "http://127.0.0.1:5174"]
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
