import json, os, logging, boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ddb = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])
s3  = boto3.client("s3")
BUCKET = os.environ.get("BUCKET")

def handler(event, context):
    for r in event.get("Records", []):
        msg = json.loads(r["body"])
        key = msg["key"]
        payload = msg.get("payload", {})

        # Idempotency guard
        try:
            ddb.put_item(
                Item={"pk": f"event#{key}", "status": "processed", "payload": payload},
                ConditionExpression="attribute_not_exists(pk)"
            )
            logger.info(json.dumps({"event": "ddb_put", "key": key}))
        except ClientError as e:
            if e.response.get("Error", {}).get("Code") == "ConditionalCheckFailedException":
                logger.info(json.dumps({"event": "duplicate", "key": key}))
                continue
            raise

        if BUCKET:
            s3.put_object(
                Bucket=BUCKET,
                Key=f"events/{key}.json",
                Body=json.dumps(payload).encode("utf-8"),
                ContentType="application/json"
            )
            logger.info(json.dumps({"event": "s3_put", "key": key}))

    return {"ok": True}
