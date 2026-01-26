/* ============================================================
   RETENTION & COHORT ANALYSIS
   Role: Business Analyst / Analytics Consultant
   Standard: ANSI SQL
   Table: ecommerce_transactions
   ============================================================ */

---------------------------------------------------------------
-- STEP 1: FIRST PURCHASE MONTH (COHORT ASSIGNMENT)
---------------------------------------------------------------
WITH first_purchase AS (
    SELECT
        CustomerID,
        DATE_TRUNC('month', MIN(InvoiceDate)) AS Cohort_Month
    FROM ecommerce_transactions
    WHERE Quantity > 0
    GROUP BY CustomerID
),

---------------------------------------------------------------
-- STEP 2: ALL PURCHASE MONTHS PER CUSTOMER
---------------------------------------------------------------
customer_activity AS (
    SELECT
        CustomerID,
        DATE_TRUNC('month', InvoiceDate) AS Activity_Month
    FROM ecommerce_transactions
    WHERE Quantity > 0
    GROUP BY CustomerID, DATE_TRUNC('month', InvoiceDate)
),

---------------------------------------------------------------
-- STEP 3: COHORT TABLE (MONTH INDEX)
---------------------------------------------------------------
cohort_base AS (
    SELECT
        ca.CustomerID,
        fp.Cohort_Month,
        ca.Activity_Month,
        (EXTRACT(YEAR FROM ca.Activity_Month) - EXTRACT(YEAR FROM fp.Cohort_Month)) * 12 +
        (EXTRACT(MONTH FROM ca.Activity_Month) - EXTRACT(MONTH FROM fp.Cohort_Month)) AS Cohort_Index
    FROM customer_activity ca
    JOIN first_purchase fp
      ON ca.CustomerID = fp.CustomerID
)

---------------------------------------------------------------
-- KPI 1: COHORT SIZE
---------------------------------------------------------------
SELECT
    Cohort_Month,
    COUNT(DISTINCT CustomerID) AS Cohort_Size
FROM cohort_base
WHERE Cohort_Index = 0
GROUP BY Cohort_Month
ORDER BY Cohort_Month;


---------------------------------------------------------------
-- KPI 2: RETENTION TABLE (CUSTOMERS PER COHORT PER MONTH)
---------------------------------------------------------------
SELECT
    Cohort_Month,
    Cohort_Index,
    COUNT(DISTINCT CustomerID) AS Active_Customers
FROM cohort_base
GROUP BY Cohort_Month, Cohort_Index
ORDER BY Cohort_Month, Cohort_Index;


---------------------------------------------------------------
-- KPI 3: RETENTION RATE (%)
---------------------------------------------------------------
WITH cohort_counts AS (
    SELECT
        Cohort_Month,
        Cohort_Index,
        COUNT(DISTINCT CustomerID) AS Active_Customers
    FROM cohort_base
    GROUP BY Cohort_Month, Cohort_Index
),
cohort_size AS (
    SELECT
        Cohort_Month,
        COUNT(DISTINCT CustomerID) AS Cohort_Size
    FROM cohort_base
    WHERE Cohort_Index = 0
    GROUP BY Cohort_Month
)
SELECT
    cc.Cohort_Month,
    cc.Cohort_Index,
    cc.Active_Customers,
    cs.Cohort_Size,
    ROUND(cc.Active_Customers * 100.0 / cs.Cohort_Size, 2) AS Retention_Rate_Percent
FROM cohort_counts cc
JOIN cohort_size cs
  ON cc.Cohort_Month = cs.Cohort_Month
ORDER BY cc.Cohort_Month, cc.Cohort_Index;


---------------------------------------------------------------
-- KPI 4: CHURN PROXY (CUSTOMERS NOT RETURNING NEXT MONTH)
---------------------------------------------------------------
WITH monthly_customers AS (
    SELECT DISTINCT
        DATE_TRUNC('month', InvoiceDate) AS Month,
        CustomerID
    FROM ecommerce_transactions
    WHERE Quantity > 0
),
next_month_activity AS (
    SELECT
        m1.Month AS Current_Month,
        COUNT(DISTINCT m1.CustomerID) AS Active_Customers,
        COUNT(DISTINCT m2.CustomerID) AS Retained_Customers
    FROM monthly_customers m1
    LEFT JOIN monthly_customers m2
      ON m1.CustomerID = m2.CustomerID
     AND m2.Month = m1.Month + INTERVAL '1 month'
    GROUP BY m1.Month
)
SELECT
    Current_Month,
    Active_Customers,
    Retained_Customers,
    Active_Customers - Retained_Customers AS Churned_Customers,
    ROUND((Active_Customers - Retained_Customers) * 100.0 / Active_Customers, 2) AS Churn_Rate_Percent
FROM next_month_activity
ORDER BY Current_Month;
