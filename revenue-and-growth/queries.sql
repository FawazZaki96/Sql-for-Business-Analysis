/* ============================================================
   REVENUE & GROWTH ANALYSIS
   Role: Business Analyst / Analytics Consultant
   Dataset: ecommerce_transactions
   Standard: ANSI SQL
   ============================================================ */

---------------------------------------------------------------
-- Assumed Table Structure
-- ecommerce_transactions(
--   Invoice,
--   StockCode,
--   Description,
--   Quantity,
--   InvoiceDate,
--   Price,
--   CustomerID,
--   Country
-- )
---------------------------------------------------------------


---------------------------------------------------------------
-- KPI 1: TOTAL REVENUE
-- Business Question: How big is the business?
---------------------------------------------------------------
SELECT 
    SUM(Quantity * Price) AS Total_Revenue
FROM ecommerce_transactions
WHERE Quantity > 0;


---------------------------------------------------------------
-- KPI 2: MONTHLY REVENUE
-- Business Question: How is revenue trending over time?
---------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT
        EXTRACT(YEAR FROM InvoiceDate) AS Year,
        EXTRACT(MONTH FROM InvoiceDate) AS Month,
        SUM(Quantity * Price) AS Revenue
    FROM ecommerce_transactions
    WHERE Quantity > 0
    GROUP BY 
        EXTRACT(YEAR FROM InvoiceDate),
        EXTRACT(MONTH FROM InvoiceDate)
)
SELECT *
FROM monthly_revenue
ORDER BY Year, Month;


---------------------------------------------------------------
-- KPI 3: MONTH-OVER-MONTH (MoM) GROWTH
-- Business Question: Are we growing or declining each month?
---------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', InvoiceDate) AS Month,
        SUM(Quantity * Price) AS Revenue
    FROM ecommerce_transactions
    WHERE Quantity > 0
    GROUP BY DATE_TRUNC('month', InvoiceDate)
),
mom_growth AS (
    SELECT
        Month,
        Revenue,
        LAG(Revenue) OVER (ORDER BY Month) AS Prev_Month_Revenue,
        (Revenue - LAG(Revenue) OVER (ORDER BY Month)) 
            / LAG(Revenue) OVER (ORDER BY Month) * 100 AS MoM_Growth_Percent
    FROM monthly_revenue
)
SELECT *
FROM mom_growth
ORDER BY Month;


---------------------------------------------------------------
-- KPI 4: CUMULATIVE REVENUE (RUNNING TOTAL)
-- Business Question: How much revenue have we accumulated over time?
---------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', InvoiceDate) AS Month,
        SUM(Quantity * Price) AS Revenue
    FROM ecommerce_transactions
    WHERE Quantity > 0
    GROUP BY DATE_TRUNC('month', InvoiceDate)
)
SELECT
    Month,
    Revenue,
    SUM(Revenue) OVER (ORDER BY Month 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Cumulative_Revenue
FROM monthly_revenue
ORDER BY Month;


---------------------------------------------------------------
-- KPI 5: YEAR-TO-DATE (YTD) REVENUE
-- Business Question: How are we performing this year vs last year?
---------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', InvoiceDate) AS Month,
        EXTRACT(YEAR FROM InvoiceDate) AS Year,
        SUM(Quantity * Price) AS Revenue
    FROM ecommerce_transactions
    WHERE Quantity > 0
    GROUP BY 
        DATE_TRUNC('month', InvoiceDate),
        EXTRACT(YEAR FROM InvoiceDate)
)
SELECT
    Year,
    Month,
    Revenue,
    SUM(Revenue) OVER (PARTITION BY Year ORDER BY Month) AS YTD_Revenue
FROM monthly_revenue
ORDER BY Year, Month;


---------------------------------------------------------------
-- KPI 6: REVENUE GROWTH ACCELERATION (TREND DIRECTION)
-- Business Question: Is growth speeding up or slowing down?
---------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', InvoiceDate) AS Month,
        SUM(Quantity * Price) AS Revenue
    FROM ecommerce_transactions
    WHERE Quantity > 0
    GROUP BY DATE_TRUNC('month', InvoiceDate)
),
growth AS (
    SELECT
        Month,
        Revenue,
        LAG(Revenue) OVER (ORDER BY Month) AS Prev_Revenue,
        Revenue - LAG(Revenue) OVER (ORDER BY Month) AS Revenue_Change
    FROM monthly_revenue
)
SELECT
    Month,
    Revenue,
    Prev_Revenue,
    Revenue_Change,
    CASE
        WHEN Revenue_Change > 0 THEN 'Growth'
        WHEN Revenue_Change < 0 THEN 'Decline'
        ELSE 'Flat'
    END AS Trend_Direction
FROM growth
ORDER BY Month;
