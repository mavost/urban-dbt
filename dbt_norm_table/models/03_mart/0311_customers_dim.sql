{# {{
    config(
        unique_key=['"SpineID"', '"CustDimCustomerID"', '"CustDimValidFrom"']
    )
}} #}

WITH 
get_minmax AS 
(

    SELECT 
        min("MinDate") AS "MinDate",
        max("MaxDate") AS "MaxDate"
    FROM {{ ref('0230_date_statistics') }}

),
get_spine AS (
    SELECT
        "SpineID",
        "SpineValidFrom",
        "SpineValidTo",
        "SpineReportingDays"
    FROM {{ ref('0205_date_spine_months') }}
    WHERE TRUE
        AND "SpineValidTo" >= (SELECT "MinDate" FROM get_minmax)
        AND "SpineValidFrom" <= (SELECT "MaxDate" FROM get_minmax)
        
),
get_countries AS (

    SELECT
        j."SpineID",
        j."SpineValidFrom",
        j."SpineValidTo",
        j."SpineReportingDays",
        m."CountriesID",
        m."CountriesName",
        m."CountriesContinent",
        m."CountriesBusinessRegion",
        m."CountriesValidFrom",
        m."CountriesValidTo"
    FROM {{ ref('0213_countries_historical') }} m
    INNER JOIN get_spine j
    ON TRUE
        AND m."CountriesValidFrom" <= j."SpineValidTo"
        AND m."CountriesValidTo" >= j."SpineValidFrom"

),
get_customers AS (

    SELECT
        j."SpineID",
        j."SpineValidFrom",
        j."SpineValidTo",
        j."SpineReportingDays",
        m."CustomersID",
        m."CustomersGroupID",
        m."CustomersCountryID",
        m."CustomersValidFrom",
        m."CustomersValidTo"
    FROM {{ ref('0211_customers_historical') }} m
    INNER JOIN get_spine j
    ON TRUE
        AND m."CustomersValidFrom" <= j."SpineValidTo"
        AND m."CustomersValidTo" >= j."SpineValidFrom"

),
join_country_customers AS (
    SELECT
        m."SpineID",
        m."SpineValidFrom",
        m."SpineValidTo",
        m."SpineReportingDays",
        m."CustomersID" AS "CustDimCustomerID",
        m."CustomersValidFrom" AS "CustDimValidFrom",
        m."CustomersValidTo" AS "CustDimValidTo",
        j."CountriesName" AS "CustDimCountryName",
        j."CountriesContinent" AS "CustDimContinent",
        j."CountriesBusinessRegion" AS "CustDimBusinessRegion"
        FROM get_customers m
    INNER JOIN get_countries j
    ON TRUE
        AND m."SpineID" = j."SpineID"
        AND m."CustomersCountryID" = j."CountriesID"
)

SELECT 
    *
FROM join_country_customers
ORDER BY "SpineValidFrom", "CustDimCustomerID", "CustDimValidFrom"
