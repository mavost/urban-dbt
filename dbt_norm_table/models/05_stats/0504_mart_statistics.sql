
{% set rep_tables = [
    '0301_orders_returns_facts', '0311_customers_dim', '0312_stock_dim', '0320_mart_table'
] %}

{% for rep_table in rep_tables -%}
{% if not loop.first -%} UNION ALL {%- endif %}

SELECT
    '{{ rep_table }}'::VARCHAR(30) AS "StatsDescription",
    "SpineValidFrom",
    "SpineValidTo",
    count(*)::INTEGER AS "StatsCount"
FROM {{ ref(rep_table) }}
GROUP BY "SpineValidFrom", "SpineValidTo"

{% endfor -%}

ORDER BY "SpineValidFrom", "StatsDescription"