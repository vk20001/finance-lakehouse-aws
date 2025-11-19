import os, json, time, boto3

s3 = boto3.client("s3")
BUCKET = os.environ["RAW_BUCKET"]
PREFIX = os.environ.get("RAW_PREFIX", "smoke_tests/")

def lambda_handler(event, context):
    now = int(time.time())
    key = f"{PREFIX}hello_{now}.json"
    body = {
        "msg": "hello from lambda",
        "ts": now,
        "event": event
    }
    s3.put_object(
        Bucket=BUCKET,
        Key=key,
        Body=json.dumps(body).encode("utf-8"),
        ContentType="application/json"
    )
    return {"ok": True, "bucket": BUCKET, "key": key}
