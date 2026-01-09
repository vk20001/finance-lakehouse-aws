{{ config(
    materialized='table',
    location_root='s3://finance-lake-gold-vk1911eu/dbt/'
) }}

select *
from {{ ref('equities_market_overview') }}
where
    -- remove days that are not tradable
    not (
        is_zero_volume = true
        and anomaly_reason = 'MARKET_CLOSED_OR_NO_TRADE'
    )
