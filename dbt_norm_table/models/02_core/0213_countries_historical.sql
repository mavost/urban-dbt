{{
    config(
        unique_key=['"CountriesName"']
    )
}}

WITH source_data AS (

    SELECT
        *,
        '{{ var("start_date") }}'::DATE AS "CountriesValidFrom",
        '{{ var("stop_date") }}'::DATE AS "CountriesValidTo"
    FROM {{ ref('0113_countries_load') }}
    {% if is_incremental() %}
        WHERE "CountriesName" NOT IN (SELECT DISTINCT "CountriesName" FROM {{ this }})
    {% else %}
        WHERE TRUE
    {% endif %}

)

SELECT
    "CountriesID",
    "CountriesName",
    "CountriesContinent",
    "CountriesBusinessRegion",
    "CountriesValidFrom",
    "CountriesValidTo"
FROM source_data
ORDER BY "CountriesBusinessRegion", "CountriesContinent", "CountriesName"
