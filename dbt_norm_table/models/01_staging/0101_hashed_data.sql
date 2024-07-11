{# {{ config(materialized='table') }} #}

WITH source_data AS (

    SELECT
        "InvoiceNo",
        "StockCode",
        "Description",
        "Quantity",
        "InvoiceDate",
        "UnitPrice",
        "CustomerID",
        "Country",
        'ingest_retail_days_0' AS "SourceTable"
    FROM {{ source('ingest', 'ingest_retail_days_0') }}
    WHERE
        "InvoiceNo" IS NOT NULL
        AND "StockCode" IS NOT NULL
        AND "InvoiceDate" IS NOT NULL
        AND "CustomerID" IS NOT NULL

),

cleaned_data AS (

    SELECT
        "SourceTable"::VARCHAR(30) AS "HashSourceTable",
        "InvoiceNo"::VARCHAR(12) AS "HashInvoiceNo",
        "StockCode"::VARCHAR(12) AS "HashStockCode",
        coalesce("Description", '')::VARCHAR(60) AS "HashDescription",
        coalesce("Quantity", 0)::INTEGER AS "HashQuantity",
        coalesce("UnitPrice", 0.0)::NUMERIC AS "HashUnitPrice",
        "CustomerID"::VARCHAR(12) AS "HashCustomerID",
        coalesce("Country", '')::VARCHAR(30) AS "HashCountry",
        timezone('UTC', "InvoiceDate"::TIMESTAMP) AS "HashInvoiceDate"
    FROM source_data

),

hashed_data AS (

    SELECT

        md5(
            "HashInvoiceNo" || "HashStockCode" || "HashDescription"
            || "HashQuantity"::VARCHAR(12) || "HashInvoiceDate"::VARCHAR(30)
            || "HashUnitPrice"::VARCHAR(12) || "HashCustomerID" || "HashCountry"
        )::UUID AS "HashID",
        timezone('UTC', {{ dbt_date.now('UTC') }}::TIMESTAMP) AS "HashLoadDate",
        *

    FROM cleaned_data

)

SELECT
    "HashID",
    "HashLoadDate",
    row_number()
        OVER (PARTITION BY "HashID" ORDER BY "HashLoadDate")
    ::INTEGER AS "HashRowCount",
    "HashInvoiceNo",
    "HashStockCode",
    "HashDescription",
    "HashQuantity",
    "HashInvoiceDate",
    "HashUnitPrice",
    "HashCustomerID",
    "HashCountry"
FROM hashed_data
