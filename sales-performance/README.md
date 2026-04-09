# Sales Performance Analysis (SQL)

## Business Context
This project simulates the work of a Business Analyst analyzing ecommerce sales performance using SQL.

---

## Business Problem
The business wants to understand overall sales performance and key revenue metrics to support decision-making.

---

## Key Business Questions
- How many total orders are there?
- What is the total revenue?
- What is the average revenue per order?
- Which month generated the highest revenue?

---

## Tools Used
- SQL (SQLite)
- DB Browser for SQLite

---

## Dataset
- Brazilian Ecommerce Dataset (Olist)

---

## SQL Analysis

### 1. Total Orders
```sql
SELECT COUNT(*) AS total_orders
FROM orders;
```

---

### 2. Total Revenue
```sql
SELECT SUM(price + freight_value) AS total_revenue
FROM order_items;
```

---

### 3. Average Revenue per Order
```sql
SELECT 
    SUM(price + freight_value) / COUNT(DISTINCT order_id) AS avg_revenue_per_order
FROM order_items;
```

---

### 4. Monthly Revenue
```sql
SELECT 
    strftime('%Y-%m', o.order_purchase_timestamp) AS order_month,
    SUM(oi.price + oi.freight_value) AS total_revenue
FROM order_items oi
JOIN orders o 
    ON oi.order_id = o.order_id
GROUP BY order_month
ORDER BY order_month;
```

---

### 5. Highest Revenue Month
```sql
SELECT 
    strftime('%Y-%m', o.order_purchase_timestamp) AS order_month,
    SUM(oi.price + oi.freight_value) AS total_revenue
FROM order_items oi
JOIN orders o 
    ON oi.order_id = o.order_id
GROUP BY order_month
ORDER BY total_revenue DESC
LIMIT 1;
```

---

## Key Insights

- The business processed a large number of orders, indicating strong demand.
- Revenue shows clear monthly trends, with a peak in November.
- Growth is driven primarily by order volume rather than high-value transactions.

---

## Recommendations

- Prepare for peak sales periods (e.g. November) by optimizing inventory and logistics.
- Increase average order value through bundling or promotional strategies.
- Monitor monthly performance trends to support better decision-making.
