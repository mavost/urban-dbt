WITH source_data AS (

    SELECT count(*) AS my_rows
    FROM {{ source('ingest', 'ingest_retail_data') }}

)

SELECT *
FROM source_data
