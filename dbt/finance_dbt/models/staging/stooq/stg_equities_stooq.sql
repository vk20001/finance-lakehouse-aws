with raw as (

    select
        symbol,
        date        as raw_date,
        open,
        high,
        low,
        close,
        volume
    from {{ source('finance_lake_raw', 'equities_stooq_raw') }}
)

, normalized as (

    select
        symbol,

        -- normalize to canonical date
        try_cast(raw_date as date) as market_date,

        -- normalize prices + volume
        try_cast(open  as double) as open_price,
        try_cast(high  as double) as high_price,
        try_cast(low   as double) as low_price,
        try_cast(close as double) as close_price,
        try_cast(volume as double) as volume,

        raw_date
    from raw
)

-- =============================
-- DEDUPING STEP
-- =============================

, ranked as (

    select
        *,
        row_number() over (
            partition by symbol, market_date
            order by
                volume desc nulls last,
                raw_date desc nulls last
        ) as dedupe_rank
    from normalized
)

, deduped as (

    select *
    from ranked
    where dedupe_rank = 1
)

select
    symbol,
    market_date,

    open_price,
    high_price,
    low_price,
    close_price,
    volume,

    year(market_date)  as trade_year,
    month(market_date) as trade_month,
    day(market_date)   as trade_day,

    case
        when market_date < date '1985-01-01' then true
        else false
    end as is_suspicious_date,

    case
        when market_date > current_date then true
        else false
    end as is_future_date

from deduped
