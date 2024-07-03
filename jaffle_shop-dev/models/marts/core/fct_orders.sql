{% set payment_methods = [
    'credit_card', 'coupon', 'bank_transfer', 'gift_card'
] %}

WITH orders AS (

    SELECT * FROM {{ ref('stg_orders') }}

),

order_payments AS (

    SELECT * FROM {{ ref('order_payments') }}

),

final AS (

    SELECT
        orders.order_id,
        orders.customer_id,
        orders.order_date,
        orders.status,

        {% for payment_method in payment_methods -%}

            order_payments.{{ payment_method }}_amount,

        {% endfor -%}

        order_payments.total_amount::numeric(20, 2) AS amount

    FROM orders

    LEFT JOIN order_payments ON orders.order_id = order_payments.order_id

)

SELECT * FROM final
