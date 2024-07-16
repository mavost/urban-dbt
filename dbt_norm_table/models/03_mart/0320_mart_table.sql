{{
    config(
        materialized='incremental',
        unique_key=['"SpineID"', '"OrdRetInvoiceNo"', '"OrdRetInvoiceDate"', '"StockDimCode"', '"OrdRetCancellation"']
    )
}}

-- rerun/materialize only 1 months of pre-existing data to cover the jump of 50 days of new data

WITH
get_max AS 
(

    SELECT DISTINCT
        max(s."SpineValidTo") AS "MaxDate"
    FROM ( SELECT DISTINCT "SpineValidTo" FROM {{ this }} ) s

)

SELECT 
    m."SpineID",
    m."SpineValidFrom",
    m."SpineValidTo",
    m."SpineReportingDays",
    m."OrdRetInvoiceNo",
    m."OrdRetInvoiceDate",
    m."OrdRetQuantity",
    m."OrdRetUnitPrice",
    m."OrdRetSales",
    --m."OrdRetStockID",
    --m."OrdRetCustomersID",
    m."OrdRetCancellation",
    j1."CustDimCustomerID",
    --j1."CustDimValidFrom",
    --j1."CustDimValidTo",
    j1."CustDimCountryName",
    j1."CustDimContinent",
    j1."CustDimBusinessRegion",
    --j2."StockDimStockID",
    j2."StockDimCode",
    j2."StockDimDescription"
FROM {{ ref('0301_orders_returns_facts') }} m

INNER JOIN {{ ref('0311_customers_dim') }} j1
ON j1."SpineID" = m."SpineID"
    AND j1."CustDimCustomerID" = m."OrdRetCustomersID"
    -- date ranges are not inclusive in ValidTo apart from the reporting spine's range
    AND j1."CustDimValidFrom" <= m."OrdRetInvoiceDate"::DATE
    AND m."OrdRetInvoiceDate"::DATE < j1."CustDimValidTo"

INNER JOIN {{ ref('0312_stock_dim') }} j2
ON j2."SpineID" = m."SpineID"
    AND j2."StockDimStockID" = m."OrdRetStockID"
{% if is_incremental() %}

WHERE m."SpineValidFrom"
    >= (
        SELECT
            "MaxDate"
            - INTERVAL '{{ var("overlap_interval") }}'
        FROM get_max
    )
{% endif %}
