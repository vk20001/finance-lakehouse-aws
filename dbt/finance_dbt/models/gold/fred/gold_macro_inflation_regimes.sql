with base as (

    select
        series_id,
        observation_date,
        cpi_value,
        is_missing,
        realtime_start,
        realtime_end

    from {{ ref('silver_macro_cpi_monthly') }}

    where is_missing = false
),

features as (

    select
        *,
        lag(cpi_value, 1) over (
            partition by series_id
            order by observation_date
        ) as prev_cpi_value,

        lag(cpi_value, 12) over (
            partition by series_id
            order by observation_date
        ) as prev_year_value,

        avg(cpi_value) over (
            partition by series_id
            order by observation_date
            rows between 2 preceding and current row
        ) as rolling_3m_avg,

        avg(cpi_value) over (
            partition by series_id
            order by observation_date
            rows between 5 preceding and current row
        ) as rolling_6m_avg

    from base
),

metrics as (

    select
        *,
        case
            when prev_cpi_value is null then null
            else cpi_value - prev_cpi_value
        end as cpi_mom_change,

        case
            when prev_year_value is null then null
            else cpi_value - prev_year_value
        end as cpi_yoy_change,

        rolling_3m_avg - prev_cpi_value as rolling_3m_trend,
        rolling_6m_avg - prev_cpi_value as rolling_6m_trend

    from features
),

regimes as (

    select
        *,
        case
            when cpi_mom_change is null
                then 'insufficient_history'

            when cpi_mom_change < -0.3
                then 'deflation_risk'

            when cpi_mom_change >= -0.3
                 and cpi_mom_change < 0.0
                then 'disinflation'

            when cpi_mom_change >= 0.0
                 and cpi_mom_change < 0.3
                then 'stable_low'

            when cpi_mom_change >= 0.3
                 and cpi_mom_change < 0.8
                then 'rising_inflation'

            when cpi_mom_change >= 0.8
                then 'overheating'

            else 'unclassified'
        end as inflation_regime_label

    from metrics
)

select
    series_id,
    observation_date,
    cpi_value,

    cpi_mom_change,
    cpi_yoy_change,

    rolling_3m_trend,
    rolling_6m_trend,

    inflation_regime_label,

    realtime_start,
    realtime_end

from regimes
order by series_id, observation_date
