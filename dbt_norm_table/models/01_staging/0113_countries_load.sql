{# using view for staging #}

WITH source_data AS (

    SELECT
        "CountryID"::INTEGER AS "CountriesID",
        "CountryName"::VARCHAR(30) AS "CountriesName",
        "Continent"::VARCHAR(15) AS "CountriesContinent",
        "BusinessRegion"::VARCHAR(10) AS "CountriesBusinessRegion"
    FROM {{ ref('03_ref_countries') }}

)

SELECT
    *
FROM source_data
ORDER BY "CountriesBusinessRegion", "CountriesContinent", "CountriesName"
