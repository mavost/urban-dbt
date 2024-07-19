WITH customers AS (

    SELECT * FROM {{ ref('stg_customers') }}

),

customer_orders AS (

    SELECT * FROM {{ ref('customer_orders') }}

),

customer_payments AS (

    SELECT * FROM {{ ref('customer_payments') }}

),

final AS (

    SELECT
        customers.customer_id,
        customer_orders.first_order,
        customer_orders.most_recent_order,
        customer_orders.number_of_orders,
        customer_payments.total_amount AS customer_lifetime_value

    FROM customers

    LEFT JOIN
        customer_orders
        ON customers.customer_id = customer_orders.customer_id
    LEFT JOIN
        customer_payments
        ON customers.customer_id = customer_payments.customer_id

)

SELECT * FROM final
