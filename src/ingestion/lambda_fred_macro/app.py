import os, json, time, urllib.parse, urllib.request, ssl
import datetime as dt
import boto3

s3 = boto3.client("s3")
BUCKET = os.environ["RAW_BUCKET"]
PREFIX = os.environ.get("RAW_PREFIX", "fred/")
API_KEY = os.environ["FRED_API_KEY"]
SERIES = [s.strip() for s in os.environ.get("FRED_SERIES","DGS10,TB3MS,CPIAUCSL,UNRATE").split(",") if s.strip()]
BASE_URL = os.environ.get("FRED_BASE_URL","https://api.stlouisfed.org/fred/series/observations")

# Fetch observations for one series (simple, robust; no external libs)
def fetch_series(series_id, start_date="2015-01-01"):
    params = {
        "series_id": series_id,
        "file_type": "json",
        "api_key": API_KEY,
        "observation_start": start_date
    }
    url = BASE_URL + "?" + urllib.parse.urlencode(params)
    # Create a permissive SSL context (default is fine, but explicit here)
    ctx = ssl.create_default_context()
    with urllib.request.urlopen(url, context=ctx, timeout=20) as r:
        body = r.read().decode("utf-8")
    data = json.loads(body)
    return data

def put_json(obj: dict, key: str):
    s3.put_object(
        Bucket=BUCKET,
        Key=key,
        Body=json.dumps(obj).encode("utf-8"),
        ContentType="application/json"
    )

def lambda_handler(event, context):
    # Partition path: fred/series=<ID>/year=YYYY/month=MM/day=DD/part-<ts>.json
    today = dt.date.today()
    y, m, d = today.year, f"{today.month:02d}", f"{today.day:02d}"
    ts = int(time.time())
    results = []

    for sid in SERIES:
        data = fetch_series(sid)
        key = f"{PREFIX}series={sid}/year={y}/month={m}/day={d}/part-{ts}.json"
        put_json(data, key)
        results.append({"series": sid, "key": key, "count": len(data.get("observations", []))})

    return {"ok": True, "wrote": results, "bucket": BUCKET}
