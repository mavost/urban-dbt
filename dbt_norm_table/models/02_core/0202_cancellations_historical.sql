{{
    config(
        unique_key=['"CancellationsHashID"'],
        indexes=[{'columns': ['"CancellationsHashID"'], 'type': 'hash'},]
    )
}}

WITH get_ids AS (

    SELECT DISTINCT "TransactHashID"
    FROM {{ ref("0101_transactional_data") }}
    WHERE "TransactInvoiceNo" LIKE 'C%'
    {% if is_incremental() %}
        AND "TransactInvoiceDate"
        > (
            SELECT
                max("CancellationsInvoiceDate")
                - INTERVAL '{{ var("overlap_interval") }}'
            FROM {{ this }}
        )
    {% else %}
        AND TRUE
    {% endif %}

),

source_data AS (

    SELECT *,
        -- connect cancellations to historic purchases (sometimes, same invoice # is used)
        CASE
            WHEN "TransactInvoiceNo" LIKE 'C%' THEN replace("TransactInvoiceNo", 'C', '')
            ELSE "TransactInvoiceNo"
        END::INTEGER AS "NewHashInvoiceNo"
        /*CASE
            WHEN "TransactInvoiceNo" LIKE 'C%' THEN "TransactDescription"
            ELSE ''
        END::VARCHAR(60) AS "TransactCancelDescription",*/
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
        --j2."StockDescription",
        j2."StockID"
    FROM set_validity m
    LEFT JOIN get_customers j1
    ON m."TransactCustomerID" = j1."CustomersID"
        AND j1."CustomersValidFrom" <= m."TransactValidFrom"
        AND m."TransactValidFrom" < j1."CustomersValidTo"
    LEFT JOIN get_stock j2
    ON m."TransactStockCode" = j2."StockCode"
        AND j2."StockValidFrom" <= m."TransactValidFrom"
        AND m."TransactValidFrom" < j2."StockValidTo"

)

SELECT
    "TransactHashID" AS "CancellationsHashID",
    "TransactLoadDate" AS "CancellationsLoadDate",
    "NewHashInvoiceNo" AS "CancellationsInvoiceNo",
    "TransactInvoiceDate" AS "CancellationsInvoiceDate",
    "TransactQuantity" AS "CancellationsQuantity",
    "TransactUnitPrice" AS "CancellationsUnitPrice",
    ("TransactUnitPrice" * "TransactQuantity")::NUMERIC AS "CancellationsRefunds",
    "StockID" AS "CancellationsStockID",
    "CustomersID" AS "CancellationsCustomersID",
    "TransactValidFrom" AS "CancellationsValidFrom",
    "TransactValidTo" AS "CancellationsValidTo"
FROM denormalize_dims
--WHERE "CustomersCountry" IS NULL
ORDER BY "NewHashInvoiceNo", "TransactValidFrom"
