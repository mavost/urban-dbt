{% set rep_tables = [
    '0', '50', '100', '150'
] %}

WITH 
unionize AS (

{% for rep_table in rep_tables -%}
{% if not loop.first -%} UNION ALL {%- endif %}
    
    SELECT
        *,
        '{{ "00_ingest_retail_days_" + rep_table }}' AS "SourceTable"
    FROM {{ source('ingest', "00_ingest_retail_days_" + rep_table) }}

{% endfor -%}

),

source_data AS (

    SELECT
        "InvoiceNo",
        "StockCode",
        "Description",
        "Quantity",
        "InvoiceDate",
        "UnitPrice",
        "CustomerID",
        "Country",
        "SourceTable",
        timezone('UTC', "LoadDate"::TIMESTAMP) AS "TransactLoadDate"
    FROM unionize
    WHERE
        "InvoiceNo" IS NOT NULL
        AND "StockCode" IS NOT NULL
        AND "InvoiceDate" IS NOT NULL
        AND "CustomerID" IS NOT NULL

),

cleaned_data AS (

    SELECT
        "SourceTable"::VARCHAR(30) AS "TransactSourceTable",
        "TransactLoadDate",
        "InvoiceNo"::VARCHAR(12) AS "TransactInvoiceNo",
        upper("StockCode")::VARCHAR(12) AS "TransactStockCode",
        coalesce("Description", '')::VARCHAR(60) AS "TransactDescription",
        coalesce("Quantity", 0)::INTEGER AS "TransactQuantity",
        coalesce("UnitPrice", 0.0)::NUMERIC AS "TransactUnitPrice",
        "CustomerID"::INTEGER AS "TransactCustomerID",
        coalesce("Country", '')::VARCHAR(30) AS "TransactCountry",
        timezone('UTC', "InvoiceDate"::TIMESTAMP) AS "TransactInvoiceDate"
    FROM source_data

),

hashed_data AS (

    SELECT

        md5(
            "TransactInvoiceNo" || "TransactStockCode" || "TransactDescription"
            || "TransactQuantity"::VARCHAR(12) || "TransactInvoiceDate"::VARCHAR(30)
            || "TransactUnitPrice"::VARCHAR(12) || "TransactCustomerID"::VARCHAR(12)
            || "TransactCountry"
        )::UUID AS "TransactHashID",
        *

    FROM cleaned_data

)

SELECT
    "TransactSourceTable",
    "TransactLoadDate",
    "TransactHashID",
    row_number()
        OVER (PARTITION BY "TransactHashID" ORDER BY "TransactLoadDate")
    ::INTEGER AS "TransactRowCount",
    "TransactInvoiceNo",
    "TransactStockCode",
    "TransactDescription",
    "TransactQuantity",
    "TransactInvoiceDate",
    "TransactUnitPrice",
    "TransactCustomerID",
    "TransactCountry"
FROM hashed_data
