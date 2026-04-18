import json
import os
import redis.asyncio as redis

REDIS_URL = os.environ.get("REDIS_URL", "redis://localhost:6379/0")

async def subscribe_loop(channel: str, on_message):
    redis_client = redis.from_url(REDIS_URL, decode_responses=True)
    pubsub = redis_client.pubsub()
    await pubsub.subscribe(channel)
    try:
        async for msg in pubsub.listen():
            if msg["type"] == "message":
                payload = json.loads(msg["data"])
                await on_message(payload)
    finally:
        await pubsub.close()
        await redis_client.close()

async def publish(channel: str, payload: dict): 
    redis_client = redis.from_url(REDIS_URL, decode_responses=True)
    await redis_client.publish(channel, json.dumps(payload))
    await redis_client.close()