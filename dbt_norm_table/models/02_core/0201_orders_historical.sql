{{
    config(
        unique_key=['"OrdersHashID"'],
        indexes=[{'columns': ['"OrdersHashID"'], 'type': 'hash'},]
    )
}}

WITH 
get_ids AS (

    SELECT DISTINCT "HashID"
    FROM {{ ref("0101_hashed_data") }}
    WHERE "HashInvoiceNo" NOT LIKE 'C%'
    {% if is_incremental() %}
        AND "HashInvoiceDate"
        > (
            SELECT
                max("OrdersInvoiceDate")
                - INTERVAL '{{ var("overlap_interval") }}'
            FROM {{ this }}
        )
    {% else %}
        AND TRUE
    {% endif %}

),

source_data AS (

    SELECT *
    FROM {{ ref("0101_hashed_data") }}
    WHERE "HashID" IN (SELECT "HashID" FROM get_ids)
        AND "HashRowCount" = 1

),

set_validity AS (

    SELECT
        *,
        "HashInvoiceDate"::DATE AS "HashValidFrom",
        '{{ dbt_date.date(9999, 12, 31) }}'::DATE AS "HashValidTo"
        FROM source_data

),

get_customers AS (

    SELECT * 
    FROM {{ ref('0211_customers_historical') }}

),

get_stock AS (

    SELECT * 
    FROM {{ ref('0212_stock_historical') }}

),

denormalize_dims AS (

    SELECT
        m.*,
        j1."CustomersID",
        --j1."CustomersCountry",
        --j2."StockDescription",
        j2."StockID"
    FROM set_validity m
    LEFT JOIN get_customers j1
    ON m."HashCustomerID" = j1."CustomersID"
        AND j1."CustomersValidFrom" <= m."HashValidFrom"
        AND m."HashValidFrom"::DATE < j1."CustomersValidTo"
    LEFT JOIN get_stock j2
    ON m."HashStockCode" = j2."StockCode"
        AND j2."StockValidFrom" <= m."HashValidFrom"
        AND m."HashValidFrom" < j2."StockValidTo"

)

SELECT
    "HashID" AS "OrdersHashID",
    "HashLoadDate" AS "OrdersLoadDate",
    "HashInvoiceNo" AS "OrdersInvoiceNo",
    "HashInvoiceDate" AS "OrdersInvoiceDate",
    "HashQuantity" AS "OrdersQuantity",
    "HashUnitPrice" AS "OrdersUnitPrice",
    "StockID" AS "OrdersStockID",
    "CustomersID" AS "OrdersCustomersID",
    "HashValidFrom" AS "OrdersValidFrom",
    "HashValidTo" AS "OrdersValidTo"
FROM denormalize_dims
--WHERE "CustomersCountry" IS NULL
ORDER BY "HashInvoiceNo", "HashValidFrom"
