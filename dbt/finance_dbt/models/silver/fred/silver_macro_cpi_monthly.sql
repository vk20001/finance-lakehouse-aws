with base as (
    select
        series_id,
        cast(observation_date as date)           as observation_date,

        case
            when observation_value is null then null
            else observation_value
        end as cpi_value,

        case
            when observation_value is null then true
            else false
        end as is_missing,

        realtime_start,
        realtime_end,

        year,
        month,
        day,

        concat(
            cast(year as varchar),
            '-',
            lpad(cast(month as varchar), 2, '0'),
            '-',
            lpad(cast(day as varchar), 2, '0')
        ) as ingestion_partition_id

    from {{ ref('stg_fred_cpi') }}
),

ranked as (
    select
        *,
        row_number() over (
            partition by series_id, observation_date
            order by realtime_end desc, realtime_start desc
        ) as revision_rank
    from base
)

select
    series_id,
    observation_date,
    cpi_value,
    is_missing,

    realtime_start,
    realtime_end,

    ingestion_partition_id,

    {{ dbt_utils.generate_surrogate_key([
        'series_id',
        'observation_date'
    ]) }} as macro_record_id

from ranked
where revision_rank = 1
and (cpi_value is not null or is_missing = true)
