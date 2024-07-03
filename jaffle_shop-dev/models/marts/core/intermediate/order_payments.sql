{% set payment_methods = [
    'credit_card', 'coupon', 'bank_transfer', 'gift_card'
] %}

WITH payments AS (

    SELECT * FROM {{ ref('stg_payments') }}

),

final AS (

    SELECT
        order_id,

        {% for payment_method in payment_methods -%}
            sum(
                CASE
                    WHEN
                        payment_method = '{{ payment_method }}'
                        THEN amount ELSE
                        0
                END
            ) AS {{ payment_method }}_amount,
        {% endfor -%}

        sum(amount) AS total_amount

    FROM payments

    GROUP BY order_id

)

SELECT * FROM final
