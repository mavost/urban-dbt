
/*
    Welcome to your first dbt model!
    Did you know that you can also configure models directly within SQL files?
    This will override configurations stated in dbt_project.yml

    Try changing "table" to "view" below
*/

{{ config(materialized='table', alias='userloading')}}

with source_data as (

    select 
    id,  cast({{ dbt_date.to_unixtimestamp(dbt_date.now())}} as integer) + row_number() OVER(ORDER BY id) AS row, user_name as uname, email as eeeemail from {{ source('my_source', 'users') }}

)

select *
from source_data
