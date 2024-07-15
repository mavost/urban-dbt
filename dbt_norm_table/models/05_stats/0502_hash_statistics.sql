WITH source_data AS (

    SELECT
        *
    FROM {{ ref("0101_hashed_data") }}

),

duplicates AS (

    SELECT
        "HashLoadDate",
        'Hash Duplicates'::VARCHAR(30) AS "StatsDescription",
        count(*)::INTEGER AS "StatsCount"
    FROM source_data
    WHERE "HashRowCount" > 1
    GROUP BY "HashLoadDate"

),

cancellations AS (

    SELECT
        "HashLoadDate",
        'Hash Cancellations'::VARCHAR(30) AS "StatsDescription",
        count(*)::INTEGER AS "StatsCount"
    FROM source_data
    WHERE "HashRowCount" = 1
        AND "HashInvoiceNo" LIKE 'C%'
    GROUP BY "HashLoadDate"

),

orders AS (

    SELECT
        "HashLoadDate",
        'Hash Orders'::VARCHAR(30) AS "StatsDescription",
        count(*)::INTEGER AS "StatsCount"
    FROM source_data
    WHERE "HashRowCount" = 1
        AND "HashInvoiceNo" NOT LIKE 'C%'
    GROUP BY "HashLoadDate"

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
