{{ config(
    materialized='table',
    location_root='s3://finance-lake-clean-vk1911eu/dbt/'
) }}

WITH base AS (
  SELECT
    realtime_start,
    realtime_end,
    observation_start,
    observation_end,
    obs
  FROM {{ source('raw', 'fred_raw') }}
  CROSS JOIN UNNEST(observations) AS t(obs)
)
SELECT
  TRY_CAST(obs.date AS DATE) AS obs_date,
  TRY_CAST(obs.value AS DOUBLE) AS value,
  'DGS10' AS series   -- static placeholder; adjust if you union multiple series
FROM base
WHERE obs.value IS NOT NULL;
