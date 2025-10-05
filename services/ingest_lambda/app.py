import json, os, hashlib, time, logging, boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sqs = boto3.client("sqs")
QUEUE_URL = os.environ["QUEUE_URL"]

def _parse_event(event):
    """Accept Lambda Function URL events and direct invokes."""
    if isinstance(event, dict) and "body" in event:
        body = event.get("body")
        
        if event.get("isBase64Encoded"):
            import base64
            try:
                body = base64.b64decode(body).decode("utf-8")
            except Exception:
                body = ""
        try:
            return json.loads(body) if isinstance(body, str) else {}
        except Exception:
            return {}
    return event if isinstance(event, dict) else {}

def handler(event, context):
    data = _parse_event(event)
    payload = data.get("payload", {})

    idem = data.get("idempotency_key") or hashlib.sha256(
        json.dumps(payload, sort_keys=True).encode("utf-8")
    ).hexdigest()

    msg = {"payload": payload, "key": idem, "ts": int(time.time() * 1000)}

    logger.info(json.dumps({"event": "enqueue", "key": idem}))

    sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=json.dumps(msg))

    return {
        "statusCode": 202,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",   # handy for demos
            "Access-Control-Allow-Headers": "*",
            "Access-Control-Allow-Methods": "OPTIONS,POST"
        },
        "body": json.dumps({"status": "queued", "key": idem})
    }
