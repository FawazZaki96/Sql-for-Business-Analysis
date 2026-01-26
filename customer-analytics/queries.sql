/* ============================================================
   CUSTOMER ANALYTICS
   Role: Business Analyst / Analytics Consultant
   Standard: ANSI SQL
   Table: ecommerce_transactions
   ============================================================ */

---------------------------------------------------------------
-- KPI 1: NEW vs RETURNING CUSTOMERS (BY MONTH)
---------------------------------------------------------------
WITH first_purchase AS (
    SELECT
        CustomerID,
        MIN(DATE_TRUNC('month', InvoiceDate)) AS First_Month
    FROM ecommerce_transactions
    WHERE Quantity > 0
    GROUP BY CustomerID
),
monthly_customers AS (
    SELECT
        DATE_TRUNC('month', InvoiceDate) AS Month,
        CustomerID
    FROM ecommerce_transactions
    WHERE Quantity > 0
    GROUP BY DATE_TRUNC('month', InvoiceDate), CustomerID
)
SELECT
    mc.Month,
    COUNT(DISTINCT CASE WHEN fp.First_Month = mc.Month THEN mc.CustomerID END) AS New_Customers,
    COUNT(DISTINCT CASE WHEN fp.First_Month < mc.Month THEN mc.CustomerID END) AS Returning_Customers
FROM monthly_customers mc
JOIN first_purchase fp
  ON mc.CustomerID = fp.CustomerID
GROUP BY mc.Month
ORDER BY mc.Month;


---------------------------------------------------------------
-- KPI 2: AVERAGE ORDER VALUE (AOV) BY CUSTOMER SEGMENT
---------------------------------------------------------------
WITH orders AS (
    SELECT
        Invoice,
        CustomerID,
        SUM(Quantity * Price) AS Order_Revenue
    FROM ecommerce_transactions
    WHERE Quantity > 0
    GROUP BY Invoice, CustomerID
),
customer_orders AS (
    SELECT
        CustomerID,
        COUNT(*) AS Order_Count
    FROM orders
    GROUP BY CustomerID
),
customer_segment AS (
    SELECT
        co.CustomerID,
        CASE WHEN co.Order_Count > 1 THEN 'Repeat' ELSE 'One-Time' END AS Customer_Type
    FROM customer_orders co
)
SELECT
    cs.Customer_Type,
    AVG(o.Order_Revenue) AS AOV
FROM orders o
JOIN customer_segment cs
  ON o.CustomerID = cs.CustomerID
GROUP BY cs.Customer_Type;


---------------------------------------------------------------
-- KPI 3: TOP 20% CUSTOMERS CONTRIBUTION (PARETO 80/20)
---------------------------------------------------------------
WITH customer_revenue AS (
    SELECT
        CustomerID,
        SUM(Quantity * Price) AS Revenue
    FROM ecommerce_transactions
    WHERE Quantity > 0
    GROUP BY CustomerID
),
ranked AS (
    SELECT
        CustomerID,
        Revenue,
        RANK() OVER (ORDER BY Revenue DESC) AS Revenue_Rank,
        SUM(Revenue) OVER () AS Total_Revenue,
        SUM(Revenue) OVER (ORDER BY Revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Cumulative_Revenue
    FROM customer_revenue
)
SELECT
    CustomerID,
    Revenue,
    Revenue_Rank,
    Cumulative_Revenue / Total_Revenue * 100 AS Cumulative_Revenue_Percent
FROM ranked
ORDER BY Revenue_Rank;


---------------------------------------------------------------
-- KPI 4: CUSTOMER LIFETIME VALUE (CLV) PROXY
-- (Total Revenue per Customer + Order Frequency)
---------------------------------------------------------------
SELECT
    CustomerID,
    COUNT(DISTINCT Invoice) AS Order_Count,
    SUM(Quantity * Price) AS Total_Revenue,
    AVG(Quantity * Price) AS Avg_Line_Revenue
FROM ecommerce_transactions
WHERE Quantity > 0
GROUP BY CustomerID
ORDER BY Total_Revenue DESC;
