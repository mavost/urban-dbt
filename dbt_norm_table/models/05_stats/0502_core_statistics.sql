WITH

orders AS (

    SELECT
        "OrdersLoadDate" AS "StatsLoadDate",
        'Orders'::VARCHAR(30) AS "StatsDescription",
        count(*)::INTEGER AS "StatsCount"
    FROM {{ ref("0201_orders_historical") }}
    GROUP BY "OrdersLoadDate"

),

cancellations AS (

    SELECT
        "CancellationsLoadDate" AS "StatsLoadDate",
        'Cancellations'::VARCHAR(30) AS "StatsDescription",
        count(*)::INTEGER AS "StatsCount"
    FROM {{ ref("0202_cancellations_historical") }}
    GROUP BY "CancellationsLoadDate"

)

SELECT
    *
FROM orders
UNION ALL
SELECT
    *
FROM cancellations
ORDER BY "StatsLoadDate"
