

with r as (
  select symbol, date, daily_return
  from "AwsDataCatalog"."finance-lake_db"."returns"
),
roll as (
  select
    symbol,
    date,
    -- 21-trading-day rolling window (approx 1 month)
    stddev_pop(daily_return) over (
      partition by symbol
      order by date
      rows between 20 preceding and current row
    ) as vol_21d,
    avg(daily_return) over (
      partition by symbol
      order by date
      rows between 20 preceding and current row
    ) as mean_21d
  from r
)
select symbol, date, vol_21d, mean_21d
from roll