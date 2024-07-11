WITH source_data AS (

    SELECT
        *,
        '{{ dbt_date.date(2000, 1, 1) }}'::DATE AS "HistoryValidFrom",
        '{{ dbt_date.date(9999, 12, 31) }}'::DATE AS "HistoryValidTo"

    FROM {{ ref('02_ref_stock') }}
    WHERE "Loading" IS TRUE
)

SELECT *
FROM source_data
