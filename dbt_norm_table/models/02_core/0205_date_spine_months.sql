{{
    config(
        materialized='view',
        unique_key=['"SpineID"']
    )
}}

WITH source_data AS (

    {{ dbt_utils.date_spine(
        datepart="month",
        start_date="cast('2008-01-01' as date)",
        end_date="cast('2025-01-02' as date)"
    )
    }}

),

calc_data AS (

    SELECT
        cast(row_number() OVER (ORDER BY date_month) AS INTEGER) AS "SpineID",
        cast(date_month AS DATE) AS "SpineValidFrom",
        cast((
            date_month + INTERVAL '1 MONTH' - INTERVAL '1 DAY'
        ) AS DATE) AS "SpineValidTo"
    FROM source_data

)

SELECT
    "SpineID",
    "SpineValidFrom",
    "SpineValidTo",
    "SpineValidTo" - "SpineValidFrom" + 1 AS "SpineReportingDays"
FROM calc_data
