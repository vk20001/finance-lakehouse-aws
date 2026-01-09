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

ranked as (

    select
        series_id,
        observation_date,
        realtime_start_ts,
        realtime_end_ts,
        cpi_value,
        drift_amount,
        issue_type,
        severity,

        row_number() over (
            partition by series_id, observation_date
            order by realtime_end_ts asc
        ) as revision_order

    from base
)

select
    series_id,
    observation_date,
    revision_order,

    realtime_start_ts,
    realtime_end_ts,

    drift_amount,
    issue_type,
    severity,

    -- revision duration in days (EXPLICIT CAST FIX)
    date_diff(
        'day',
        cast(realtime_start_ts as timestamp),
        cast(realtime_end_ts   as timestamp)
    ) as revision_lag_days

from ranked;
