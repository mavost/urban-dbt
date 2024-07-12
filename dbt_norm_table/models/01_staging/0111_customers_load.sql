{# using view for staging #}

WITH source_data AS (

    SELECT
        "CustomerID"::INTEGER AS "CustomersID",
        "Country"::VARCHAR(30) AS "CustomersCountry",
        timezone('UTC', to_timestamp("ValidFrom", 'DD/MM/YYYY hh24:mi')::TIMESTAMP) AS "CustomersPurchaseTime"
    FROM {{ ref('01_ref_customers') }}

),

add_group_discriminator AS (

    SELECT
        *,
        lag("CustomersCountry") over (PARTITION BY "CustomersID" ORDER BY "CustomersPurchaseTime") AS "PrevCountry"
    FROM source_data

),

group_label AS (
    
    SELECT
        "CustomersID",
        "CustomersPurchaseTime",
        row_number() OVER (ORDER BY "CustomersID", "CustomersPurchaseTime")::INTEGER AS "CustomersGroupID",
        1::INTEGER AS "CustomersOnes"
    FROM add_group_discriminator
    WHERE "PrevCountry" IS NULL OR "PrevCountry" <> "CustomersCountry"

),

add_grouping AS (

    SELECT
        m.*,
        j."CustomersGroupID" AS "ControlCustomersGroupID",
        j."CustomersOnes",
        sum(j."CustomersOnes") OVER (PARTITION BY m."CustomersID" ORDER BY m."CustomersPurchaseTime")::INTEGER AS "CustomersGroupID"
    FROM add_group_discriminator m
    LEFT JOIN group_label j
    ON m."CustomersID"=j."CustomersID" AND m."CustomersPurchaseTime"=j."CustomersPurchaseTime"

),

add_grouping_index AS (

    SELECT
        *,
        row_number() OVER (PARTITION BY "CustomersID", "CustomersGroupID" ORDER BY "CustomersPurchaseTime")::INTEGER AS "CustomersGroupIndex"
    FROM add_grouping

)

SELECT
    "CustomersID",
    "CustomersCountry",
    "CustomersPurchaseTime",
    "CustomersGroupID",
    "CustomersGroupIndex"
    --,"CustomersOnes"
    --,"ControlCustomersGroupID"
FROM add_grouping_index
ORDER BY "CustomersID", "CustomersGroupID", "CustomersGroupIndex"
