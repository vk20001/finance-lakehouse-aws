{{ config(materialized='table') }}

with base as (
  select
    symbol,
    date,
    close
  from {{ ref('equities_clean') }}
),
calc as (
  select
    symbol,
    date,
    close,
    lag(close) over (partition by symbol order by date)        as prev_close
  from base
)
select
  symbol,
  date,
  close,
  case
    when prev_close is null or prev_close = 0 then null
    else (close - prev_close) / prev_close
  end as daily_return
from calc
