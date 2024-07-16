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
        timezone('UTC', "LoadDate"::TIMESTAMP) AS "LoadDate",
        '00_ingest_retail_days_0' AS "SourceTable"
    FROM {{ source('ingest', '00_ingest_retail_days_0') }}
    WHERE
        "InvoiceNo" IS NULL
        OR "StockCode" IS NULL
        OR "InvoiceDate" IS NULL
        OR "CustomerID" IS NULL

),

error_description AS (

    SELECT
        "LoadDate" AS "NullLoadDate",
        "SourceTable"::VARCHAR(30) AS "NullSourceTable",
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
    FROM source_data

)

SELECT
    *,
    row_number()
        OVER (PARTITION BY "NullLoadDate" ORDER BY "NullInvoiceNo")
    ::INTEGER AS "NullKeyID"
FROM error_description
