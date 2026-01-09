select
    symbol,
    market_date,
    count(*) as record_count
from {{ ref('stg_equities_stooq') }}
group by 1, 2
having count(*) > 1
