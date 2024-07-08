{{ config(materialized='view') }}

WITH dim_customers AS (

    SELECT * FROM {{ ref('dim_customers') }}

),

fct_orders AS (

    SELECT * FROM {{ ref('fct_orders') }}

),

final AS (

    SELECT
        dim_customers.customer_id,
        dim_customers.first_order,
        dim_customers.most_recent_order,
        dim_customers.number_of_orders,
        dim_customers.customer_lifetime_value,
        fct_orders.amount,
        fct_orders.order_date,
        fct_orders.order_id
    FROM dim_customers
    LEFT JOIN fct_orders ON dim_customers.customer_id = fct_orders.customer_id

)

SELECT * FROM final ORDER BY customer_id, order_date, order_id
