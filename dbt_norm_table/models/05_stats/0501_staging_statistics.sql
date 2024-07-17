WITH 

transactional_data AS (

    SELECT
        *
    FROM {{ ref("0101_transactional_data") }}

),

transactional_nulls AS (


    SELECT
        *
    FROM {{ ref("0102_transactional_nulls") }}

),

data_uniques AS (

    SELECT
        "TransactSourceTable",
        "TransactLoadDate",
        'Hash: Uniques'::VARCHAR(30) AS "StatsDescription",
        count(*)::INTEGER AS "StatsCount"
    FROM transactional_data
    WHERE "TransactRowCount" = 1
    GROUP BY "TransactSourceTable", "TransactLoadDate"

),

data_duplicates AS (

    SELECT
        "TransactSourceTable",
        "TransactLoadDate",
        'Hash: Duplicates'::VARCHAR(30) AS "StatsDescription",
        count(*)::INTEGER AS "StatsCount"
    FROM transactional_data
    WHERE "TransactRowCount" > 1
    GROUP BY "TransactSourceTable", "TransactLoadDate"

),

null_types AS (

    SELECT
        "NullSourceTable",
        "NullLoadDate",
        ('Null: ' || "NullErrorType")::VARCHAR(30) AS "StatsDescription",
        count(*)::INTEGER AS "StatsCount"
    FROM transactional_nulls
    GROUP BY "NullSourceTable", "NullLoadDate", "StatsDescription"

)

SELECT
    *
FROM data_uniques
UNION ALL
SELECT
    *
FROM data_duplicates
UNION ALL
SELECT
    *
FROM null_types
ORDER BY "TransactSourceTable", "TransactLoadDate", "StatsDescription"
