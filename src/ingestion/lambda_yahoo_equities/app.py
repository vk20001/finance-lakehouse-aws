import os, json, time, urllib.parse, urllib.request, ssl, datetime as dt
import boto3

s3 = boto3.client("s3")
BUCKET = os.environ["RAW_BUCKET"]
PREFIX = os.environ.get("RAW_PREFIX", "yahoo_equities/")
TICKERS = [t.strip() for t in os.environ.get("TICKERS","AAPL,SPY,JPM,^GSPC").split(",") if t.strip()]
RANGE = os.environ.get("RANGE","5y")        # e.g., 1y, 5y, max
INTERVAL = os.environ.get("INTERVAL","1d")  # 1d, 1wk, etc.

BASE = "https://query2.finance.yahoo.com/v8/finance/chart/"

def fetch_chart(ticker, rng, interval):
    params = {
        "range": rng,
        "interval": interval,
        "includePrePost": "false",
        "events": "div,splits"
    }
    url = BASE + urllib.parse.quote(ticker) + "?" + urllib.parse.urlencode(params)
    ctx = ssl.create_default_context()
    with urllib.request.urlopen(url, context=ctx, timeout=20) as r:
        body = r.read().decode("utf-8")
    return json.loads(body)

def put_json(obj: dict, key: str):
    s3.put_object(
        Bucket=BUCKET, Key=key,
        Body=json.dumps(obj).encode("utf-8"),
        ContentType="application/json"
    )

def lambda_handler(event, context):
    today = dt.date.today()
    y, m, d = today.year, f"{today.month:02d}", f"{today.day:02d}"
    ts = int(time.time())
    wrote = []

    for t in TICKERS:
        data = fetch_chart(t, RANGE, INTERVAL)
        key = f"{PREFIX}symbol={urllib.parse.quote(t, safe='')}/year={y}/month={m}/day={d}/part-{ts}.json"
        put_json(data, key)
        pts = len(data.get("chart",{}).get("result",[{}])[0].get("timestamp",[]) )
        wrote.append({"symbol": t, "key": key, "points": pts})

    return {"ok": True, "bucket": BUCKET, "wrote": wrote}
