-- HARD FAIL — this indicates upstream ingestion or typing failure

{{ config(enabled=false) }}


select *
from {{ ref('equities_market_overview') }}
where is_broken_price = true
