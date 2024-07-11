WITH source_data AS (

    SELECT
        *,
        '{{ dbt_date.date(2000, 1, 1) }}'::DATE AS "HistoryValidFrom",
        '{{ dbt_date.date(9999, 12, 31) }}'::DATE AS "HistoryValidTo"

    FROM {{ ref("0101_hashed_data") }}

)

SELECT *
FROM source_data
