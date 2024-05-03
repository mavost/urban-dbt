{{ config(materialized='view')}}
with final as (

    SELECT
        dim_customers.*,
        fct_orders.amount,
        fct_orders.order_date,
        fct_orders.order_id
    FROM {{ ref('dim_customers') }}
    LEFT JOIN {{ ref('fct_orders') }} USING (customer_id)
    ORDER BY dim_customers.customer_id, fct_orders.order_date, fct_orders.order_id
    
)

select * from final
