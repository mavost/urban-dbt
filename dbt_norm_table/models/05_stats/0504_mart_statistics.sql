
{% set rep_tables = [
    '0301_orders_returns_facts', '0311_customers_dim', '0312_stock_dim', '0320_mart_table'
] %}

WITH 


{% for rep_table in rep_tables -%}

cte_{{ rep_table }} AS (

    SELECT
        '{{ rep_table }}'::VARCHAR(30) AS "StatsDescription",
        "SpineValidFrom",
        "SpineValidTo",
        count(*)::INTEGER AS "StatsCount"
    FROM {{ ref(rep_table) }}
    GROUP BY "SpineValidFrom", "SpineValidTo"

),

{% endfor -%}

header AS (
    SELECT
        'testing'::VARCHAR(30) AS "StatsDescription",
        '2020-01-01'::DATE AS "SpineValidFrom",
        '2020-01-01'::DATE AS "SpineValidTo",
        0::INTEGER AS "StatsCount"
    WHERE FALSE
)

SELECT
    *
FROM header

{% for rep_table in rep_tables -%}

    UNION
    SELECT
        *
    FROM cte_{{ rep_table }}

{% endfor -%}

ORDER BY "SpineValidFrom", "StatsDescription"