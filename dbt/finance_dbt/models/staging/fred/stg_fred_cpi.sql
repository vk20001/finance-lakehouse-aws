with source as (

    select *
    from {{ source('fred', 'fred_raw') }}

),

exploded as (

    select
        -- CANONICAL COLUMN NAMES (THIS IS THE FIX)
        s.series       as series_id,
        o.date         as observation_date,

        case
            when o.value in ('.', '') then null
            else try_cast(o.value as double)
        end             as observation_value,

        s.realtime_start,
        s.realtime_end,
        s.observation_start,
        s.observation_end,
        s.year,
        s.month,
        s.day

    from source s
    cross join unnest(s.observations) as t(o)

)

select *
from exploded
where observation_value is not null
