with base as (

    select
        series_id,
        cast(observation_date as date)              as observation_date,
        cast(realtime_start as timestamp)           as realtime_start_ts,
        cast(realtime_end   as timestamp)           as realtime_end_ts,
        cpi_value,
        drift_amount,
        issue_type,
        severity
    from {{ ref('macro_cpi_diagnostics') }}

),

lifecycles as (

    select
        series_id,
        observation_date,

        min(realtime_start_ts)                      as first_seen_at,
        max(realtime_end_ts)                        as last_seen_at,

        count(*)                                    as revision_events,
        max(abs(drift_amount))                      as max_drift_seen,

        sum(case when severity = 'critical' then 1 else 0 end) as critical_events,
        sum(case when severity = 'warn'     then 1 else 0 end) as warn_events

    from base
    group by 1,2
),

scored as (

    select
        series_id,
        observation_date,
        revision_events,
        max_drift_seen,
        critical_events,
        warn_events,

        -- lifecycle duration in days (EXPLICIT CAST FIX)
        date_diff(
            'day',
            cast(first_seen_at as timestamp),
            cast(last_seen_at  as timestamp)
        ) as lifecycle_days,

        case
            when critical_events > 0 then 0.95
            when warn_events > 2     then 0.75
            when warn_events > 0     then 0.50
            else 0.25
        end as revision_risk_score,

        case
            when max_drift_seen >= 2.0 then 'low'
            when max_drift_seen >= 1.0 then 'medium'
            else 'high'
        end as reliability_band

    from lifecycles
)

select *
from scored;
