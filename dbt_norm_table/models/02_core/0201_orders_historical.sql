WITH source_data AS (

    SELECT
        *,
        -- connect to historic purchases (sometimes, same invoice # is used)
        CASE
            WHEN "HashInvoiceNo" LIKE 'C%' THEN TRUE
            ELSE FALSE
        END::BOOLEAN AS "HashCancellation",
        CASE
            WHEN "HashInvoiceNo" LIKE 'C%' THEN replace("HashInvoiceNo", 'C', '')
            ELSE "HashInvoiceNo"
        END::INTEGER AS "HashNewInvoiceNo",
        /*CASE
            WHEN "HashInvoiceNo" LIKE 'C%' THEN "HashDescription"
            ELSE ''
        END::VARCHAR(60) AS "HashCancelDescription",*/
        '{{ dbt_date.date(2000, 1, 1) }}'::DATE AS "HashValidFrom",
        '{{ dbt_date.date(9999, 12, 31) }}'::DATE AS "HashValidTo"
    FROM {{ ref("0101_hashed_data") }}
    WHERE "HashRowCount" = 1

),

get_customers AS (

    SELECT * 
    FROM {{ ref('0211_customers_historical') }}

),

get_stock AS (

    SELECT * 
    FROM {{ ref('0212_stock_historical') }}
    WHERE "StockValidFrom" <= CURRENT_DATE
        AND CURRENT_DATE < "StockValidTo"

),

denormalize_dims AS (

    SELECT
        m.*,
        j1."CustomersID",
        --j1."CustomersCountry",
        --j2."StockDescription",
        j2."StockID"
    FROM source_data m
    LEFT JOIN get_customers j1
    ON m."HashCustomerID" = j1."CustomersID"
        AND j1."CustomersValidFrom" <= m."HashInvoiceDate"::DATE
        AND m."HashInvoiceDate"::DATE < j1."CustomersValidTo"
    LEFT JOIN get_stock j2
    ON m."HashStockCode" = j2."StockCode"

)

SELECT
    "HashID" AS "OrdersHashID",
    "HashLoadDate" AS "OrdersLoadDate",
    "HashNewInvoiceNo" AS "OrdersInvoiceNo",
    "HashInvoiceDate" AS "OrdersInvoiceDate",
    "HashQuantity" AS "OrdersQuantity",
    "HashUnitPrice" AS "OrdersUnitPrice",
    "StockID" AS "OrdersStockID",
    "CustomersID" AS "OrdersCustomersID",
    "HashCancellation" AS "OrdersCancellation"
FROM denormalize_dims
--WHERE "StockDescription" IS NULL
--WHERE "CustomersCountry" IS NULL
--WHERE "HashCancellation" = TRUE
ORDER BY "HashNewInvoiceNo"
