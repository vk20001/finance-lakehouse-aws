select
    symbol,
    market_date,
    count(*) as record_count
from {{ ref('equities_clean') }}
group by 1, 2
having count(*) > 1
