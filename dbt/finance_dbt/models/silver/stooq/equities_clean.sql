with base as (

    select
        symbol,
        market_date,
        open_price,
        high_price,
        low_price,
        close_price,
        volume,
        trade_year,
        trade_month,
        trade_day,
        is_suspicious_date,
        is_future_date
    from {{ ref('stg_equities_stooq') }}
)

, filtered as (

    select *
    from base

    where is_suspicious_date = false
      and is_future_date = false

      -- numeric sanity
      and open_price  is not null
      and high_price  is not null
      and low_price   is not null
      and close_price is not null

      -- allow null volumes but not negative ones
      and (volume is null or volume >= 0)
)

select
    symbol,
    market_date,

    open_price,
    high_price,
    low_price,
    close_price,
    volume,

    trade_year,
    trade_month,
    trade_day

from filtered

