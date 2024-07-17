{% set rep_tables = [
    '0', '50', '100', '150'
] %}

WITH 
unionize AS (

{% for rep_table in rep_tables -%}
{% if not loop.first -%} UNION ALL {%- endif %}
    
    SELECT
        '{{ "00_ingest_retail_days_" + rep_table }}' AS "SourceTable",
        *
    FROM {{ source('ingest', "00_ingest_retail_days_" + rep_table) }}

{% endfor -%}

),

source_data AS (

    SELECT
        "SourceTable"::VARCHAR(30) AS "NullSourceTable",
        timezone('UTC', "LoadDate"::TIMESTAMP) AS "NullLoadDate",
        "InvoiceNo"::VARCHAR(12) AS "NullInvoiceNo",
        "StockCode"::VARCHAR(12) AS "NullStockCode",
        "Description"::VARCHAR(60) AS "NullDescription",
        "Quantity"::INTEGER AS "NullQuantity",
        "InvoiceDate"::TIMESTAMP AT TIME ZONE 'UTC' AS "NullInvoiceDate",
        "UnitPrice"::NUMERIC AS "NullUnitPrice",
        "CustomerID"::VARCHAR(12) AS "NullCustomerID",
        "Country"::VARCHAR(30) AS "NullCountry",
        CASE
            WHEN "InvoiceNo" IS NULL THEN 'Missing InvoiceNo'
            WHEN "StockCode" IS NULL THEN 'Missing StockCode'
            WHEN "InvoiceDate" IS NULL THEN 'Missing InvoiceDate'
            WHEN "CustomerID" IS NULL THEN 'Missing CustomerID'
            ELSE 'unknown'
        END::VARCHAR(22) AS "NullErrorType"
    FROM unionize
    WHERE
        "InvoiceNo" IS NULL
        OR "StockCode" IS NULL
        OR "InvoiceDate" IS NULL
        OR "CustomerID" IS NULL

)

SELECT
    *,
    row_number()
        OVER (PARTITION BY "NullLoadDate" ORDER BY "NullInvoiceNo")
    ::INTEGER AS "NullKeyID"
FROM source_data
