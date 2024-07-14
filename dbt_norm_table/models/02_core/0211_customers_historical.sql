{{
    config(
        materialized='incremental',
        unique_key=['"CustomersID"', '"CustomersGroupID"']
    )
}}

WITH
get_ids AS (

    SELECT DISTINCT "CustomersID"
    FROM {{ ref('0111_customers_load') }}

    {% if is_incremental() %}
        WHERE
            "CustomersPurchaseTime"
            > (
                SELECT
                    max("CustomersPurchaseTime")
                    - INTERVAL '{{ var("overlap_interval") }}'
                FROM {{ this }}
            )
    {% else %}
    WHERE TRUE
    {% endif %}

),

source_data AS (

    SELECT
        *,
        row_number()
            OVER (
                PARTITION BY "CustomersID", "CustomersGroupID"
                ORDER BY "CustomersPurchaseTime"
            )
        ::INTEGER AS "RowFilter"
    FROM {{ ref('0111_customers_load') }}
    WHERE "CustomersID" IN (SELECT "CustomersID" FROM get_ids)
),

add_row_labels AS (

    SELECT
        *,
        row_number()
            OVER (PARTITION BY "CustomersID" ORDER BY "CustomersPurchaseTime")
        ::INTEGER AS "RowNumberASC",
        row_number()
            OVER (PARTITION BY "CustomersID" ORDER BY "CustomersPurchaseTime" DESC)
        ::INTEGER AS "RowNumberDESC"
    FROM source_data
    WHERE "RowFilter" = 1

),

/*
only_multiples AS (

    SELECT DISTINCT "CustomersID"
    FROM add_row_labels
    WHERE "RowNumberASC" > 1

),
*/
get_neighbor_timestamp AS (

    SELECT
        *,
        lead("CustomersPurchaseTime")
            OVER (PARTITION BY "CustomersID" ORDER BY "RowNumberASC")
        AS "NextPurchaseTime"
    FROM add_row_labels
    --WHERE "CustomersID" IN (SELECT "CustomersID" FROM only_multiples)

),

set_validity AS (

    SELECT
        *,
        CASE
            WHEN "RowNumberASC" = 1 THEN '{{ var("start_date") }}'
            ELSE "CustomersPurchaseTime"
        END::DATE AS "CustomersValidFrom",
        CASE
            WHEN "RowNumberDESC" = 1 THEN '{{ var("stop_date") }}'
            ELSE "NextPurchaseTime"
        END::DATE AS "CustomersValidTo"
    FROM get_neighbor_timestamp

),

get_countries AS (

    SELECT * 
    FROM {{ ref('0213_countries_historical') }}
    WHERE "CountriesValidFrom" <= CURRENT_DATE
        AND CURRENT_DATE < "CountriesValidTo"

),

normalize_dims AS (

    SELECT
    "CustomersID",
    "CustomersGroupID",
    "CustomersCountry",
    j."CountriesName",
    j."CountriesID"::INTEGER AS "CustomersCountryID",
    "CustomersPurchaseTime",
    "CustomersValidFrom",
    "CustomersValidTo"
    FROM set_validity m
    LEFT JOIN get_countries j
    --INNER JOIN get_countries j
    ON m."CustomersCountry" = j."CountriesName"

)

SELECT
    "CustomersID",
    "CustomersGroupID",
    "CustomersCountryID",
    "CustomersCountry",
    "CustomersPurchaseTime",
    "CustomersValidFrom",
    "CustomersValidTo"
FROM normalize_dims
--WHERE "CustomersCountryID" IS NULL
ORDER BY "CustomersID", "CustomersGroupID"
