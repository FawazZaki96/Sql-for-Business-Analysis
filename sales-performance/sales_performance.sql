SELECT COUNT (*) AS total_orders
FROM orders;

SELECT SUM( price + freight_value ) AS total_revenue
FROM order_items;

SELECT SUM (price + freight_value)/COUNT(DISTINCT order_id) AS avg_revenue_per_order
FROM order_items;

SELECT 
    strftime('%Y-%m', o.order_purchase_timestamp) AS order_month,
    SUM(oi.price + oi.freight_value) AS total_revenue
FROM order_items oi
JOIN orders o 
    ON oi.order_id = o.order_id
GROUP BY order_month
ORDER BY order_month;

SELECT 
    strftime('%Y-%m', o.order_purchase_timestamp) AS order_month,
    SUM(oi.price + oi.freight_value) AS total_revenue
FROM order_items oi
JOIN orders o 
    ON oi.order_id = o.order_id
GROUP BY order_month
ORDER BY total_revenue DESC
LIMIT 1;