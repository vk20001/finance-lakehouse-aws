import os, time, urllib.parse, urllib.request, ssl, datetime as dt
import boto3

s3 = boto3.client("s3")
BUCKET = os.environ["RAW_BUCKET"]
PREFIX = os.environ.get("RAW_PREFIX", "equities_stooq/")

# Map human tickers -> Stooq symbols
# (Stooq format: aapl.us, msft.us, spy.us, jpm.us)
DEFAULT_MAP = "AAPL:aapl.us,MSFT:msft.us,SPY:spy.us,JPM:jpm.us"
MAPPING = dict(pair.split(":") for pair in os.environ.get("SYMBOL_MAP", DEFAULT_MAP).split(",") if ":" in pair)

INTERVAL = os.environ.get("INTERVAL","d")  # d=1day, w=week, m=month
BASE = "https://stooq.com/q/d/l/"

def fetch_csv(stooq_symbol, interval):
    params = {"s": stooq_symbol, "i": interval}
    url = BASE + "?" + urllib.parse.urlencode(params)
    ctx = ssl.create_default_context()
    with urllib.request.urlopen(url, context=ctx, timeout=20) as r:
        return r.read()  # bytes (CSV)

def put_bytes(body: bytes, key: str, content_type="text/csv"):
    s3.put_object(Bucket=BUCKET, Key=key, Body=body, ContentType=content_type)

def lambda_handler(event, context):
    today = dt.date.today()
    y, m, d = today.year, f"{today.month:02d}", f"{today.day:02d}"
    ts = int(time.time())
    wrote = []

    for human, stooq in MAPPING.items():
        csv_bytes = fetch_csv(stooq, INTERVAL)
        # raw CSV, partitioned by date and human symbol
        key = f"{PREFIX}symbol={urllib.parse.quote(human, safe='')}/year={y}/month={m}/day={d}/part-{ts}.csv"
        put_bytes(csv_bytes, key)
        wrote.append({"symbol": human, "key": key, "bytes": len(csv_bytes)})

    return {"ok": True, "bucket": BUCKET, "wrote": wrote}
