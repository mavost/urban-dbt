{{ config(materialized='table') }}

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
        "InvoiceNo" IS NOT NULL AND
        "StockCode" IS NOT NULL AND
        "InvoiceDate" IS NOT NULL AND
        "CustomerID" IS NOT NULL

),

cleaned_data AS (

    SELECT
        "SourceTable"::VARCHAR(30) AS "HashSourceTable",
        "InvoiceNo"::VARCHAR(12) AS "HashInvoiceNo",
        "StockCode"::VARCHAR(12) AS "HashStockCode",
        COALESCE("Description", '')::VARCHAR(60) AS "HashDescription",
        COALESCE("Quantity", 0)::INTEGER AS "HashQuantity",
        TIMEZONE('UTC', "InvoiceDate"::TIMESTAMP) AS "HashInvoiceDate",
        COALESCE("UnitPrice", 0.0)::NUMERIC AS "HashUnitPrice",
        "CustomerID"::VARCHAR(12) AS "HashCustomerID",
        COALESCE("Country", '')::VARCHAR(30) AS "HashCountry"
    FROM source_data

),

hashed_data AS (

    SELECT

        MD5("HashInvoiceNo" || "HashStockCode" || "HashDescription" ||
            "HashQuantity"::VARCHAR(12) || "HashInvoiceDate"::VARCHAR(30) ||
            "HashUnitPrice"::VARCHAR(12) || "HashCustomerID" || "HashCountry"
        )::UUID AS "HashID",
        TIMEZONE('UTC', {{dbt_date.now('UTC')}}::TIMESTAMP) AS "HashLoadDate",
        *

    FROM cleaned_data

)

SELECT
    "HashID",
    "HashLoadDate",
    ROW_NUMBER() OVER (PARTITION BY "HashID" ORDER BY "HashLoadDate")::INTEGER AS "HashRowCount",
    "HashInvoiceNo",
    "HashStockCode",
    "HashDescription",
    "HashQuantity",
    "HashInvoiceDate",
    "HashUnitPrice",
    "HashCustomerID",
    "HashCountry"
FROM hashed_data