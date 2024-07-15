{{
    config(
        unique_key=['"StockCode"']
    )
}}

WITH source_data AS (

    SELECT
        *,
        '{{ dbt_date.date(2000, 1, 1) }}'::DATE AS "StockValidFrom",
        '{{ dbt_date.date(9999, 12, 31) }}'::DATE AS "StockValidTo"
    FROM {{ ref('0112_stock_load') }}
    {% if is_incremental() %}
        WHERE "StockCode" NOT IN (SELECT DISTINCT "StockCode" FROM {{ this }})
    {% else %}
        WHERE TRUE
    {% endif %}

)

SELECT
    "StockID",
    "StockCode",
    "StockDescription",
    "StockValidFrom",
    "StockValidTo"
FROM source_data
ORDER BY "StockDescription", "StockCode"
