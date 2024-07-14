{# using view for staging #}

WITH source_data AS (

    SELECT
        "StockID"::INTEGER AS "StockID",
        "StockCode"::VARCHAR(12) AS "StockCode",
        "StockDescription"::VARCHAR(50) AS "StockDescription",
        row_number()
            OVER (PARTITION BY "StockCode" ORDER BY "StockID" DESC)
        ::INTEGER AS "StockGroupID"
    FROM {{ ref('02_ref_stock') }}

)

SELECT
    "StockID",
    "StockCode",
    "StockDescription"
FROM source_data
WHERE "StockGroupID" = 1
ORDER BY "StockDescription", "StockCode"
