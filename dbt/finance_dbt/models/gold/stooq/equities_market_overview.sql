{{ config(
    materialized='table'
) }}

-- Base clean equity prices
with base as (

    select
        symbol,
        market_date,
        close_price,
        volume
    from {{ ref('equities_clean') }}
)

-- Previous close
, ordered as (

    select
        symbol,
        market_date,
        close_price,
        volume,

        lag(close_price) over (
            partition by symbol
            order by market_date
        ) as prev_close
    from base
)

-- Daily return
, returns as (

    select
        symbol,
        market_date,
        close_price,
        volume,

        case
            when prev_close is null then null
            when prev_close = 0 then null
            else (close_price - prev_close) / prev_close
        end as daily_return
    from ordered
)

-- Rolling price anchors
, rolling_price_refs as (

    select
        symbol,
        market_date,
        close_price,
        volume,
        daily_return,

        lag(close_price, 7) over (
            partition by symbol
            order by market_date
        ) as close_7d_ago,

        lag(close_price, 30) over (
            partition by symbol
            order by market_date
        ) as close_30d_ago
    from returns
)

-- Rolling returns
, rolling_perf as (

    select
        symbol,
        market_date,
        close_price,
        volume,
        daily_return,

        case
            when volume = 0 then null
            when close_7d_ago is null then null
            when close_7d_ago = 0 then null
            else (close_price / close_7d_ago) - 1
        end as rolling_return_7d,

        case
            when volume = 0 then null
            when close_30d_ago is null then null
            when close_30d_ago = 0 then null
            else (close_price / close_30d_ago) - 1
        end as rolling_return_30d
    from rolling_price_refs
)

-- Rolling volatility
, rolling_vol as (

    select
        symbol,
        market_date,
        close_price,
        volume,
        daily_return,
        rolling_return_7d,
        rolling_return_30d,

        stddev_samp(
            case
                when volume = 0 then null
                else daily_return
            end
        ) over (
            partition by symbol
            order by market_date
            rows between 29 preceding and current row
        ) as rolling_volatility_30d
    from rolling_perf
)

-- Drawdown
, drawdown as (

    select
        symbol,
        market_date,
        close_price,
        volume,
        daily_return,
        rolling_return_7d,
        rolling_return_30d,
        rolling_volatility_30d,

        max(close_price) over (
            partition by symbol
            order by market_date
            rows between 179 preceding and current row
        ) as rolling_peak_180d
    from rolling_vol
)

, drawdown_calc as (

    select
        symbol,
        market_date,
        close_price,
        volume,
        daily_return,
        rolling_return_7d,
        rolling_return_30d,
        rolling_volatility_30d,
        rolling_peak_180d,

        case
            when rolling_peak_180d = 0 then null
            else (close_price - rolling_peak_180d) / rolling_peak_180d
        end as drawdown_from_peak_180d

    from drawdown
)

-- Liquidity context (separate CTE)
, liquidity as (

    select
        symbol as liq_symbol,
        market_date as liq_market_date,

        avg(volume) over (
            partition by symbol
            rows between 60 preceding and 1 preceding
        ) as avg_volume_60d
    from base
)

-- Join explicitly & compute anomalies
, anomalies as (

    select
        d.symbol,
        d.market_date,
        d.close_price,
        d.volume,

        d.daily_return,
        d.rolling_return_7d,
        d.rolling_return_30d,
        d.rolling_volatility_30d,
        d.drawdown_from_peak_180d,

        l.avg_volume_60d,

        -- anomaly flags
        case when d.volume = 0 then true else false end as is_zero_volume,

        case
            when abs(d.daily_return) > 0.10 then true
            else false
        end as is_abnormal_return_day,

        case
            when d.rolling_volatility_30d >
                 3 * avg(d.rolling_volatility_30d)
                     over (partition by d.symbol)
            then true
            else false
        end as is_volatility_spike,

        case
            when d.drawdown_from_peak_180d < -0.25 then true
            else false
        end as is_deep_drawdown,

        case
            when d.volume = 0 and l.avg_volume_60d < 1000
                then 'LOW_LIQUIDITY_SYMBOL'
            when d.volume = 0
                then 'MARKET_CLOSED_OR_NO_TRADE'
            else 'NORMAL_TRADING_DAY'
        end as anomaly_reason

    from drawdown_calc d
    left join liquidity l
      on d.symbol = l.liq_symbol
     and d.market_date = l.liq_market_date
)

select *
from anomalies
