WITH source_data AS (

    {{ dbt_utils.date_spine(
        datepart="month",
        start_date="cast('2018-01-01' as date)",
        end_date="cast('2026-01-02' as date)"
    )
    }}

), calc_data AS (

    SELECT
        row_number() OVER (ORDER BY date_month)::INTEGER  AS "SpineID",
        date_month::DATE AS "SpineValidFrom",
        (date_month + INTERVAL '1 MONTH' - INTERVAL '1 DAY')::DATE AS "SpineValidTo"
    FROM source_data

)    

SELECT
    "SpineID",
    "SpineValidFrom",
    "SpineValidTo",
    "SpineValidTo"-"SpineValidFrom"+1 AS "SpineReportingDays"
FROM  calc_data
