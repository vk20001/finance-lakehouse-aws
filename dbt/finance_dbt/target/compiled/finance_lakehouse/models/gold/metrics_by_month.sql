

with base as (
  select
    symbol,
    date_trunc('month', date) as month,
    avg(daily_return) as avg_return,
    stddev_pop(daily_return) as vol_month,
    count(*) as trading_days
  from "AwsDataCatalog"."finance-lake_db"."returns"
  group by symbol, date_trunc('month', date)
)
select
  symbol,
  month,
  avg_return,
  vol_month,
  trading_days,
  avg_return / nullif(vol_month, 0) as sharpe_ratio
from base