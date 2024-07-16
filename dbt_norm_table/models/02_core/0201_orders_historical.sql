{{
    config(
        unique_key=['"OrdersHashID"'],
        indexes=[{'columns': ['"OrdersHashID"'], 'type': 'hash'},]
    )
}}

WITH 
get_ids AS (

    SELECT DISTINCT "TransactHashID"
    FROM {{ ref("0101_transactional_data") }}
    WHERE "TransactInvoiceNo" NOT LIKE 'C%'
    {% if is_incremental() %}
        AND "TransactInvoiceDate"
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
    FROM {{ ref("0101_transactional_data") }}
    WHERE "TransactHashID" IN (SELECT "TransactHashID" FROM get_ids)
        AND "TransactRowCount" = 1

),

set_validity AS (

    SELECT
        *,
        "TransactInvoiceDate"::DATE AS "TransactValidFrom",
        '{{ dbt_date.date(9999, 12, 31) }}'::DATE AS "TransactValidTo"
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
        --m."TransactDescription" AS debug1,
        --m."TransactStockCode" AS debug2,
        j2."StockID"
    FROM set_validity m
    LEFT JOIN get_customers j1
    ON m."TransactCustomerID" = j1."CustomersID"
        AND j1."CustomersValidFrom" <= m."TransactValidFrom"
        AND m."TransactValidFrom"::DATE < j1."CustomersValidTo"
    LEFT JOIN get_stock j2
    ON m."TransactStockCode" = j2."StockCode"
        AND j2."StockValidFrom" <= m."TransactValidFrom"
        AND m."TransactValidFrom" < j2."StockValidTo"

)

SELECT
    "TransactHashID" AS "OrdersHashID",
    "TransactLoadDate" AS "OrdersLoadDate",
    "TransactInvoiceNo"::INTEGER AS "OrdersInvoiceNo",
    "TransactInvoiceDate" AS "OrdersInvoiceDate",
    "TransactQuantity" AS "OrdersQuantity",
    "TransactUnitPrice" AS "OrdersUnitPrice",
    ("TransactUnitPrice" * "TransactQuantity")::NUMERIC AS "OrdersSales",
    "StockID" AS "OrdersStockID",
    "CustomersID" AS "OrdersCustomersID",
    "TransactValidFrom" AS "OrdersValidFrom",
    "TransactValidTo" AS "OrdersValidTo"
    --,debug1
    --,debug2
FROM denormalize_dims
--WHERE "CustomersCountry" IS NULL
--WHERE "StockID" IS NULL
ORDER BY "TransactInvoiceNo", "TransactValidFrom"
