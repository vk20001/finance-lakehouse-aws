select
    case
        when max(case when severity = 'critical' then 1 end) = 1
            then 'BLOCKING'

        when max(case when severity = 'warn' then 1 end) = 1
            then 'DEGRADED'

        else 'HEALTHY'
    end as system_state,

    -- Force naive timestamp (no timezone)
    cast(date_trunc('second', current_timestamp) as timestamp) as evaluated_at

from {{ ref('macro_cpi_diagnostics') }}
