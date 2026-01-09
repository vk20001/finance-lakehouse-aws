select *
from {{ ref('equities_anomaly_audit') }}
where symbol is null
   or market_date is null
   or anomaly_reason is null
