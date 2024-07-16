{# {{
    config(
        unique_key=['"SpineID"', '"StockDimStockID"']
    )
}} #}

WITH 
get_minmax AS 
(

    SELECT 
        min("MinDate") AS "MinDate",
        max("MaxDate") AS "MaxDate"
    FROM {{ ref('0503_date_statistics') }}

),
get_spine AS (
    SELECT
        "SpineID",
        "SpineValidFrom",
        "SpineValidTo",
        "SpineReportingDays"
    FROM {{ ref('0205_date_spine_months') }}
    WHERE TRUE
        AND "SpineValidTo" >= (SELECT "MinDate" FROM get_minmax)
        AND "SpineValidFrom" <= (SELECT "MaxDate" FROM get_minmax)
        
),
get_stock AS (

    SELECT
        j."SpineID",
        j."SpineValidFrom",
        j."SpineValidTo",
        j."SpineReportingDays",
        m."StockID" AS "StockDimStockID",
        m."StockCode" AS "StockDimCode",
        m."StockDescription" AS "StockDimDescription"
    FROM {{ ref('0212_stock_historical') }} m
    INNER JOIN get_spine j
    ON TRUE
        AND m."StockValidFrom" <= j."SpineValidTo"
        AND m."StockValidTo" >= j."SpineValidFrom"

)

SELECT 
    *
FROM get_stock
ORDER BY "SpineValidFrom", "StockDimStockID"
