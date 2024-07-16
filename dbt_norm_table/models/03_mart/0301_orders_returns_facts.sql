{# {{
    config(
        unique_key=['"SpineID"', '"OrdRetInvoiceNo"', '"OrdRetInvoiceDate"', '"OrdRetStockID"', '"OrdRetCancellation"']
    )
}} #}

WITH 
get_minmax AS 
(

    SELECT 
        min("MinDate") AS "MinDate",
        max("MaxDate") AS "MaxDate"
    FROM {{ ref('0230_date_statistics') }}

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
get_orders_cancellations AS (

    SELECT
        "OrdersInvoiceNo" AS "OrdRetInvoiceNo",
        "OrdersInvoiceDate" AS "OrdRetInvoiceDate",
        "OrdersQuantity" AS "OrdRetQuantity",
        "OrdersUnitPrice" AS "OrdRetUnitPrice",
        "OrdersSales" AS "OrdRetSales",
        "OrdersStockID" AS "OrdRetStockID",
        "OrdersCustomersID" AS "OrdRetCustomersID",
        "OrdersValidFrom" AS "OrdRetValidFrom",
        "OrdersValidTo" AS "OrdRetValidTo",
        FALSE::BOOLEAN AS "OrdRetCancellation"
    FROM {{ ref('0201_orders_historical') }}
    UNION
    SELECT
        "CancellationsInvoiceNo" AS "OrdRetInvoiceNo",
        "CancellationsInvoiceDate" AS "OrdRetInvoiceDate",
        "CancellationsQuantity" AS "OrdRetQuantity",
        "CancellationsUnitPrice" AS "OrdRetUnitPrice",
        "CancellationsRefunds" AS "OrdRetSales",
        "CancellationsStockID" AS "OrdRetStockID",
        "CancellationsCustomersID" AS "OrdRetCustomersID",
        "CancellationsValidFrom" AS "OrdRetValidFrom",
        "CancellationsValidTo" AS "OrdRetValidTo",
        TRUE::BOOLEAN AS "OrdRetCancellation"
    FROM {{ ref('0202_cancellations_historical') }}

)
SELECT
    m."SpineID",
    m."SpineValidFrom",
    m."SpineValidTo",
    m."SpineReportingDays",
    j."OrdRetInvoiceNo",
    j."OrdRetInvoiceDate",
    j."OrdRetQuantity",
    j."OrdRetUnitPrice",
    j."OrdRetSales",
    j."OrdRetStockID",
    j."OrdRetCustomersID",
    j."OrdRetCancellation"
FROM get_spine m
JOIN get_orders_cancellations j
ON m."SpineValidFrom" <= j."OrdRetInvoiceDate"::DATE
    AND j."OrdRetInvoiceDate"::DATE <= m."SpineValidTo"
ORDER BY m."SpineValidFrom", j."OrdRetInvoiceNo"





