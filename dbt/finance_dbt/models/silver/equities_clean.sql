{{ config(
    materialized='table',
    location_root='s3://finance-lake-clean-vk1911eu/dbt/'
) }}

SELECT
  symbol,
  CAST(year  AS INTEGER) AS year,
  CAST(month AS INTEGER) AS month,
  CAST(day   AS INTEGER) AS day,
  TRY_CAST(date  AS DATE)    AS date,
  TRY_CAST(open   AS DOUBLE) AS open,
  TRY_CAST(high   AS DOUBLE) AS high,
  TRY_CAST(low    AS DOUBLE) AS low,
  TRY_CAST(close  AS DOUBLE) AS close,
  TRY_CAST(volume AS DOUBLE) AS volume
FROM {{ source('raw', 'equities_stooq_raw') }};
