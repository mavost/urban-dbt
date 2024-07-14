{# using view for staging #}

WITH source_data AS (

    SELECT
        "CountryID"::INTEGER AS "CountriesID",
        "CountryName"::VARCHAR(30) AS "CountriesName",
        "Continent"::VARCHAR(15) AS "CountriesContinent",
        "BusinessRegion"::VARCHAR(10) AS "CountriesBusinessRegion",
        row_number()
            OVER (PARTITION BY "CountryName" ORDER BY "CountryID" DESC)
        ::INTEGER AS "CountriesGroupID"
    FROM {{ ref('03_ref_countries') }}

)

SELECT
    "CountriesID",
    "CountriesName",
    "CountriesContinent",
    "CountriesBusinessRegion"
FROM source_data
WHERE "CountriesGroupID" = 1
ORDER BY "CountriesBusinessRegion", "CountriesContinent", "CountriesName"
