
SELECT 
    m."SpineID",
    m."SpineValidFrom",
    m."SpineValidTo",
    m."SpineReportingDays",
    m."OrdRetInvoiceNo",
    m."OrdRetInvoiceDate",
    m."OrdRetQuantity",
    m."OrdRetUnitPrice",
    m."OrdRetSales",
    --m."OrdRetStockID",
    --m."OrdRetCustomersID",
    m."OrdRetCancellation",
    --j1."CustDimCustomerID",
    --j1."CustDimValidFrom",
    --j1."CustDimValidTo",
    j1."CustDimCountryName",
    j1."CustDimContinent",
    j1."CustDimBusinessRegion",
    --j2."StockDimStockID",
    j2."StockDimCode",
    j2."StockDimDescription"
FROM {{ ref('0301_orders_returns_facts') }} m
INNER JOIN {{ ref('0311_customers_dim') }} j1
ON j1."SpineID" = m."SpineID"
    AND j1."CustDimCustomerID" = m."OrdRetCustomersID"
    AND j1."CustDimValidFrom" <= m."OrdRetInvoiceDate"::DATE
    AND m."OrdRetInvoiceDate"::DATE <= j1."CustDimValidTo"
INNER JOIN {{ ref('0312_stock_dim') }} j2
ON j2."SpineID" = m."SpineID"
    AND j2."StockDimStockID" = m."OrdRetStockID"
