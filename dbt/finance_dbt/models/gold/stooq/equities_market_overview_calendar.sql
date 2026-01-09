{{ config(
    materialized='table',
    location_root='s3://finance-lake-gold-vk1911eu/dbt/'
) }}

select *
from {{ ref('equities_market_overview') }}
