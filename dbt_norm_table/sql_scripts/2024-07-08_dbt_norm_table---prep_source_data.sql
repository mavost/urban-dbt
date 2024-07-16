-- 2024-07-08
-------------------------------------------------------------------
/*  applied script on the following DBs/schemas:
 * - tata_retail:
 * 	- raw
 */ 

-- validate seed table
SELECT ird.*, rs."ID", rs."StockItem"
FROM "00_raw"."00_ingest_retail_data_src" ird 
JOIN "00_raw"."02_ref_stock" rs
ON ird."StockCode" = rs."StockCode"
    AND ird."Description" = rs."Description"
ORDER BY rs."ID" DESC;


-- DDL table
CREATE TABLE "00_raw"."00_ingest_retail_data_src" (
    "InvoiceNo" varchar(12) NULL,
    "StockCode" varchar(12) NULL,
    "Description" text NULL,
    "Quantity" int4 NULL,
    "InvoiceDate" timestamp NULL,
    "UnitPrice" numeric NULL,
    "CustomerID" int4 NULL,
    "Country" varchar(30) NULL
);

-- statistics after import using DBeaver
SELECT
    count(*)
FROM "00_raw"."00_ingest_retail_data_src" ird;

SELECT
    min( "InvoiceDate")
FROM "00_raw"."00_ingest_retail_data_src" irds;

SELECT
    count(*)
FROM "00_raw"."00_ingest_retail_data_src" ird ORDER BY 1;

-- clear table 
--TRUNCATE "00_raw"."00_ingest_retail_data_src";

-- date diff (370d)
SELECT max(irds."InvoiceDate") - min(irds."InvoiceDate") FROM "00_raw"."00_ingest_retail_data_src" irds;

-- split data by 50d intervals into sep. tables
DO $$
DECLARE 
    target_schema text := '00_raw';
    dataTable text := '00_ingest_retail_data_src';
    dateFilter integer;
    countData integer;
    startdate date := '2010-11-30';
    fromDate date;
    toDate date;
    subTable text;
BEGIN
FOREACH dateFilter IN ARRAY ARRAY[
0, 50, 100, 150, 200, 250, 300, 350
]
    LOOP
        fromDate := startdate + dateFilter;
        toDate := startdate + dateFilter + INTERVAL '50 DAY';
        subTable := '00_ingest_retail_days_' || dateFilter::text;

        RAISE NOTICE '---';
        RAISE NOTICE 'FromDate: %', fromDate;
        RAISE NOTICE 'ToDate: %', toDate;
        RAISE NOTICE 'Table: %', subTable;

        -- generate / flush subset tables
        /*EXECUTE 'CREATE TABLE ' || quote_ident(target_schema) || '.' || quote_ident(subTable) || '(
            "InvoiceNo" varchar(12) NULL,
            "StockCode" varchar(12) NULL,
            "Description" text NULL,
            "Quantity" int4 NULL,
            "InvoiceDate" timestamp NULL,
            "UnitPrice" numeric NULL,
            "CustomerID" int4 NULL,
            "Country" varchar(30) NULL,
            "LoadDate" date NULL
        )';*/
        EXECUTE 'TRUNCATE TABLE ' || quote_ident(target_schema) || '.' || quote_ident(subTable);

        -- split off and add data to subset table
        EXECUTE 'INSERT INTO ' || quote_ident(target_schema) || '.' || quote_ident(subTable) || 
        ' ("InvoiceNo", "StockCode", "Description", "Quantity", "InvoiceDate", "UnitPrice", "CustomerID", "Country", "LoadDate") ' ||
        'SELECT icpa."InvoiceNo", icpa."StockCode", icpa."Description", icpa."Quantity", icpa."InvoiceDate", icpa."UnitPrice", ' ||
        'icpa."CustomerID", icpa."Country", ' || quote_literal(toDate) || ' FROM '
            || quote_ident(target_schema) || '.' || quote_ident(dataTable) || ' icpa WHERE icpa."InvoiceDate" < ' 
            || quote_literal(toDate) || ' AND icpa."InvoiceDate" >= ' || quote_literal(fromDate);

        -- statistics        
        EXECUTE 'SELECT count(*) FROM ' || quote_ident(target_schema) || '.' || quote_ident(dataTable) || 
        ' WHERE "InvoiceDate" < ' || quote_literal(toDate) || ' AND "InvoiceDate" >= ' || quote_literal(fromDate)
        INTO countData;

        RAISE NOTICE 'Count: %', countData;

    END LOOP;
END; $$;
