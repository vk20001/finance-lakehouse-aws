-- SOFT ANOMALY — valid in edge cases, but should be reviewed
{{ config(enabled=false) }}

select *
from {{ ref('equities_market_overview') }}
where is_suspicious_zero_volume = true
