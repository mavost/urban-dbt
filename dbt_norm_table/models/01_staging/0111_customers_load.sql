WITH source_data AS (

    SELECT
        "CustomerID"::INTEGER AS "CustomersID",
        "Country"::VARCHAR(30) AS "CustomersCountry",
        timezone('UTC', to_timestamp("ValidFrom", 'DD/MM/YYYY hh24:mi')::TIMESTAMP) AS "CustomersPurchaseTime"
    FROM {{ ref('01_ref_customers') }}

),

add_group_change AS (

    SELECT
        *,
        lag("CustomersCountry") over (PARTITION BY "CustomersID" ORDER BY "CustomersPurchaseTime") AS "PrevCountry"
    FROM source_data

),

add_row_labels AS (

    SELECT
        *,
        row_number() OVER (PARTITION BY "CustomersID" ORDER BY "CustomersPurchaseTime")::INTEGER AS "RowNumberASC",
        row_number() OVER (PARTITION BY "CustomersID" ORDER BY "CustomersPurchaseTime" DESC)::INTEGER AS "RowNumberDESC"
    FROM add_group_change
    WHERE "PrevCountry" IS NULL OR "PrevCountry" <> "CustomersCountry"

),

has_duplicates AS (

    SELECT DISTINCT
        "CustomersID"
    FROM add_row_labels
    WHERE "RowNumberASC" > 1

),

get_neighbor_time AS (

    SELECT
        *,
        row_number() OVER (ORDER BY "CustomersID", "RowNumberASC")::INTEGER AS "CustomersGroupID",
        lead("CustomersPurchaseTime") OVER (PARTITION BY "CustomersID" ORDER BY "RowNumberASC") AS "NextPurchaseTime"
    FROM add_row_labels
    --WHERE "CustomersID" IN (SELECT "CustomersID" FROM has_duplicates)

)

SELECT
    "CustomersGroupID",
    "CustomersID",
    "CustomersCountry",
    "CustomersPurchaseTime",
    CASE
        WHEN "RowNumberASC"=1 THEN '{{ dbt_date.date(2000, 1, 1) }}'
        ELSE "CustomersPurchaseTime"
    END::DATE AS "CustomersValidFrom",
    CASE
        WHEN "RowNumberDESC"=1 THEN '{{ dbt_date.date(9999, 12, 31) }}'
        ELSE "NextPurchaseTime"
    END::DATE AS "CustomersValidTo"
FROM get_neighbor_time
ORDER BY "CustomersID", "CustomersGroupID"
