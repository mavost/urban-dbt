{# using view for staging #}

WITH source_data AS (

    SELECT
        "StockID"::INTEGER AS "StockID",
        "StockCode"::VARCHAR(12) AS "StockCode",
        "StockDescription"::VARCHAR(50) AS "StockDescription"
    FROM {{ ref('02_ref_stock') }}

)

SELECT
    *
FROM source_data
ORDER BY "StockDescription", "StockCode"
