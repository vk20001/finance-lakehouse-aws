{{ config(
    materialized='table',
    location_root='s3://finance-lake-clean-vk1911eu/dbt/'
) }}

with base as (

    select
        series_id,
        observation_date,
        observation_value as value,
        realtime_start,
        realtime_end,
        year,
        month,
        day
    from {{ ref('stg_fred_cpi') }}

),

deduped as (

    select
        *,
        row_number() over (
            partition by series_id, observation_date
            order by realtime_end desc
        ) as rn
    from base

)

select
    series_id,
    observation_date,
    value,
    realtime_start,
    realtime_end,
    year,
    month,
    day
from deduped
where rn = 1
