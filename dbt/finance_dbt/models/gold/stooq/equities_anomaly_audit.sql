{{ config(
    materialized='table'
) }}

with src as (
    select
        symbol,
        market_date,
        volume,
        anomaly_reason,
        is_zero_volume,
        is_abnormal_return_day,
        is_volatility_spike,
        is_deep_drawdown
    from {{ ref('equities_market_overview') }}
)

-- explode anomaly flags into standardized audit rows
, flattened as (

    select symbol, market_date, anomaly_reason
    from src

    union all
    select symbol, market_date, 'ZERO_VOLUME'
    from src
    where is_zero_volume = true

    union all
    select symbol, market_date, 'ABNORMAL_RETURN_DAY'
    from src
    where is_abnormal_return_day = true

    union all
    select symbol, market_date, 'VOLATILITY_SPIKE'
    from src
    where is_volatility_spike = true

    union all
    select symbol, market_date, 'DEEP_DRAWDOWN'
    from src
    where is_deep_drawdown = true
)

select
    symbol,
    market_date,
    anomaly_reason,

    date_trunc('month', market_date) as anomaly_month,

    -- normalize to 1 record per anomaly event
    1 as anomaly_event_count
from flattened
