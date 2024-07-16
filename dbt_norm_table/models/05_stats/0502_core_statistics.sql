WITH source_data AS (

    SELECT
        *
    FROM {{ ref("0101_transactional_data") }}

),

duplicates AS (

    SELECT
        "TransactLoadDate",
        'Hash Duplicates'::VARCHAR(30) AS "StatsDescription",
        count(*)::INTEGER AS "StatsCount"
    FROM source_data
    WHERE "TransactRowCount" > 1
    GROUP BY "TransactLoadDate"

),

cancellations AS (

    SELECT
        "TransactLoadDate",
        'Hash Cancellations'::VARCHAR(30) AS "StatsDescription",
        count(*)::INTEGER AS "StatsCount"
    FROM source_data
    WHERE "TransactRowCount" = 1
        AND "TransactInvoiceNo" LIKE 'C%'
    GROUP BY "TransactLoadDate"

),

orders AS (

    SELECT
        "TransactLoadDate",
        'Hash Orders'::VARCHAR(30) AS "StatsDescription",
        count(*)::INTEGER AS "StatsCount"
    FROM source_data
    WHERE "TransactRowCount" = 1
        AND "TransactInvoiceNo" NOT LIKE 'C%'
    GROUP BY "TransactLoadDate"

)

SELECT
    *
FROM duplicates
UNION ALL
SELECT
    *
FROM cancellations
UNION ALL
SELECT
    *
FROM orders
