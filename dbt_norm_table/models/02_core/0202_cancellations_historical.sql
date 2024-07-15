{{
    config(
        unique_key=['"CancellationsHashID"'],
        indexes=[{'columns': ['"CancellationsHashID"'], 'type': 'hash'},]
    )
}}

WITH get_ids AS (

    SELECT DISTINCT "HashID"
    FROM {{ ref("0101_hashed_data") }}
    WHERE "HashInvoiceNo" LIKE 'C%'
    {% if is_incremental() %}
        AND "HashInvoiceDate"
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
            WHEN "HashInvoiceNo" LIKE 'C%' THEN replace("HashInvoiceNo", 'C', '')
            ELSE "HashInvoiceNo"
        END::INTEGER AS "NewHashInvoiceNo"
        /*CASE
            WHEN "HashInvoiceNo" LIKE 'C%' THEN "HashDescription"
            ELSE ''
        END::VARCHAR(60) AS "HashCancelDescription",*/
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
        AND m."HashValidFrom" < j1."CustomersValidTo"
    LEFT JOIN get_stock j2
    ON m."HashStockCode" = j2."StockCode"
        AND j2."StockValidFrom" <= m."HashValidFrom"
        AND m."HashValidFrom" < j2."StockValidTo"

)

SELECT
    "HashID" AS "CancellationsHashID",
    "HashLoadDate" AS "CancellationsLoadDate",
    "NewHashInvoiceNo" AS "CancellationsInvoiceNo",
    "HashInvoiceDate" AS "CancellationsInvoiceDate",
    "HashQuantity" AS "CancellationsQuantity",
    "HashUnitPrice" AS "CancellationsUnitPrice",
    "StockID" AS "CancellationsStockID",
    "CustomersID" AS "CancellationsCustomersID",
    "HashValidFrom" AS "CancellationsValidFrom",
    "HashValidTo" AS "CancellationsValidTo"
FROM denormalize_dims
--WHERE "CustomersCountry" IS NULL
ORDER BY "NewHashInvoiceNo", "HashValidFrom"
