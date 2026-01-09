with base as (

    select
        series_id,
        observation_date,
        cpi_value,
        is_missing,
        realtime_start,
        realtime_end,

        lag(cpi_value) over (
            partition by series_id
            order by observation_date
        ) as prev_value

    from {{ ref('silver_macro_cpi_monthly') }}

),

drift as (

    select
        series_id,
        observation_date,
        cpi_value,
        is_missing,
        realtime_start,
        realtime_end,

        case
            when prev_value is null then null
            else cpi_value - prev_value
        end as drift_amount

    from base
),

classified as (

    select
        series_id,
        observation_date,
        cpi_value,
        is_missing,
        realtime_start,
        realtime_end,
        drift_amount,

        case
            when is_missing = true then 'missing_value'

            when observation_date >= date_add('month', -3, current_date)
             and abs(drift_amount) >= 0.8
                then 'revision_critical'

            when observation_date >= date_add('year', -1, current_date)
             and abs(drift_amount) >= 0.3
                then 'revision_moderate'

            when abs(drift_amount) < 0.1
                then 'revision_minor'

            else 'revision_moderate'
        end as issue_type

    from drift
),

final as (

    select
        series_id,
        observation_date,
        cpi_value,
        is_missing,
        realtime_start,
        realtime_end,
        drift_amount,
        issue_type,

        case
            when is_missing = true then 'warn'
            when issue_type = 'revision_critical' then 'critical'
            when issue_type = 'revision_moderate' then 'warn'
            when issue_type = 'revision_minor' then 'info'
            else 'info'
        end as severity

    from classified
)

select * from final
