WITH orders AS (

    SELECT DISTINCT
        "OrdersInvoiceDate"::DATE AS rep_date
    FROM {{ ref("0201_orders_historical") }}

),

cancellations AS (

    SELECT DISTINCT
        "CancellationsInvoiceDate"::DATE AS rep_date
    FROM {{ ref("0202_cancellations_historical") }}

)

SELECT
    'Orders time range'::VARCHAR(30) AS "StatsDescription",
    min(rep_date) AS "MinDate",
    max(rep_date) AS "MaxDate"
FROM orders
UNION ALL
SELECT
    'Cancellations time range'::VARCHAR(30) AS "StatsDescription",
    min(rep_date) AS "MinDate",
    max(rep_date) AS "MaxDate"
FROM cancellations
