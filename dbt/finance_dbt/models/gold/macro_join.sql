{{ config(materialized='table') }}

with fred as (
  select
    series,
    obs_date as date,
    cast(value as double) as value
  from {{ ref('fred_clean') }}
  where series in ('DGS10','CPIAUCSL','UNRATE','TB3MS')
),
fred_pivot as (
  select
    date,
    max(case when series='DGS10'    then value end) as dgs10,
    max(case when series='CPIAUCSL' then value end) as cpiaucsl,
    max(case when series='UNRATE'   then value end) as unrate,
    max(case when series='TB3MS'    then value end) as tb3ms
  from fred
  group by date
),
r as (
  select symbol, date, daily_return
  from {{ ref('returns') }}
)
select
  r.symbol,
  r.date,
  r.daily_return,
  p.dgs10,
  p.cpiaucsl,
  p.unrate,
  p.tb3ms
from r r
left join fred_pivot p
  on p.date = r.date
