WITH source_data AS (

    SELECT count(*) AS my_rows
    FROM {{ source('ingest', 'ingest_retail_days_0') }}

)

SELECT *
FROM source_data
