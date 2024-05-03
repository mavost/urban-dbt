{{ config(materialized='view') }}

with dim_customers as (

    select * from {{ ref('dim_customers') }}

),

fct_orders as (

    select * from {{ ref('fct_orders') }}

),

final as (

    select
        dim_customers.*,
        fct_orders.amount,
        fct_orders.order_date,
        fct_orders.order_id
    from dim_customers
    left join fct_orders on dim_customers.customer_id = fct_orders.customer_id

)

select * from final order by customer_id, order_date, order_id
