WITH payments AS (

    SELECT * FROM {{ ref('stg_payments') }}

),

orders AS (

    SELECT * FROM {{ ref('stg_orders') }}

),

final AS (

    SELECT
        orders.customer_id,
        sum(payments.amount) AS total_amount

    FROM payments

    LEFT JOIN orders ON payments.order_id = orders.order_id

    GROUP BY orders.customer_id

)

SELECT * FROM final
