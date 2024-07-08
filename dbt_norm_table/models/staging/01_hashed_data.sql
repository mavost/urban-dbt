{{ config(materialized='table') }}

WITH source_data AS (

    SELECT COUNT(*) AS rows
    FROM {{ source('ingest', 'ingest_retail_data') }}

)

select *
from source_data

