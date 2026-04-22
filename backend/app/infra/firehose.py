import json
import logging
import os

import boto3

logger = logging.getLogger(__name__)

FIREHOSE_NAME = os.environ.get("FIREHOSE_NAME", "portfolio5-chat-logs")
_client = None


def _get_client():
    global _client
    if _client is None:
        _client = boto3.client("firehose", region_name="ap-northeast-1")
    return _client


async def firehose_put(payload: dict):
    try:
        _get_client().put_record(
            DeliveryStreamName=FIREHOSE_NAME,
            Record={"Data": json.dumps(payload, ensure_ascii=False) + "\n"},
        )
    except Exception:
        logger.exception("Firehose put_record failed (non-fatal)")
