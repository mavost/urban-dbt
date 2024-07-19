WITH orders AS (

    SELECT * FROM {{ ref('stg_orders') }}

),

final AS (

    SELECT
        customer_id,

        min(order_date) AS first_order,
        max(order_date) AS most_recent_order,
        count(order_id) AS number_of_orders
    FROM orders

    GROUP BY customer_id

)

SELECT * FROM final
