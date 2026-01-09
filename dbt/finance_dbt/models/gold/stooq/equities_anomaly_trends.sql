{{ config(
    materialized='table'
) }}

with audit as (
    select *
    from {{ ref('equities_anomaly_audit') }}
)

select
    anomaly_month,
    anomaly_reason,
    count(*) as anomaly_count
from audit
group by
    anomaly_month,
    anomaly_reason
order by
    anomaly_month,
    anomaly_reason
