
-- Q1: Sales performance for delivered orders

SELECT
    COUNT(*) AS delivered_orders,
    ROUND(SUM(total_amount), 2) AS total_sales,
    ROUND(AVG(total_amount), 2) AS average_order_value
FROM orders
WHERE order_status = 'delivered';



-- Q2: Monthly sales trend for delivered orders

SELECT
    strftime('%Y-%m', order_date) AS sales_month,
    COUNT(*) AS delivered_orders,
    ROUND(SUM(total_amount), 2) AS total_sales,
    ROUND(AVG(total_amount), 2) AS average_order_value
FROM orders
WHERE order_status = 'delivered'
GROUP BY strftime('%Y-%m', order_date)
ORDER BY sales_month;



-- Q3: Sales performance by product category

SELECT
    p.category,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(
        SUM(
            oi.quantity * oi.unit_price *
            (1 - oi.discount_pct / 100.0)
        ), 2
    ) AS item_sales
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.category
ORDER BY item_sales DESC;



-- Q4: Top 10 products by delivered item sales

SELECT
    p.product_id,
    p.name AS product_name,
    p.category,
    SUM(oi.quantity) AS units_sold,
    ROUND(
        SUM(
            oi.quantity * oi.unit_price *
            (1 - oi.discount_pct / 100.0)
        ), 2
    ) AS item_sales
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_id, p.name, p.category
ORDER BY item_sales DESC
LIMIT 10;


-- Q5: Sales and average sales per order by category

WITH category_orders AS (
    SELECT
        p.category,
        o.order_id,
        SUM(
            oi.quantity * oi.unit_price *
            (1 - oi.discount_pct / 100.0)
        ) AS category_order_sales
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.category, o.order_id
)
SELECT
    category,
    COUNT(*) AS category_order_count,
    ROUND(SUM(category_order_sales), 2) AS item_sales,
    ROUND(AVG(category_order_sales), 2) AS avg_sales_per_category_order
FROM category_orders
GROUP BY category
ORDER BY avg_sales_per_category_order DESC;




-- Q6: Returns and refunds by product category

SELECT
    p.category,
    COUNT(*) AS return_records,
    COUNT(DISTINCT r.order_id) AS returned_orders,
    SUM(r.refund_amount) AS total_refunds,
    ROUND(AVG(r.refund_amount), 2) AS avg_refund
FROM returns r
JOIN products p
    ON r.product_id = p.product_id
GROUP BY p.category
ORDER BY total_refunds DESC;



-- Q7: Provisional return-record rate by category

WITH category_sales AS (
    SELECT
        p.category,
        SUM(oi.quantity) AS units_sold
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.category
),
category_returns AS (
    SELECT
        p.category,
        COUNT(*) AS return_records
    FROM returns r
    JOIN products p
        ON r.product_id = p.product_id
    GROUP BY p.category
)
SELECT
    s.category,
    s.units_sold,
    COALESCE(r.return_records, 0) AS return_records,
    ROUND(
        100.0 * COALESCE(r.return_records, 0) / s.units_sold,
        2
    ) AS provisional_return_record_rate_pct
FROM category_sales s
LEFT JOIN category_returns r
    ON s.category = r.category
ORDER BY provisional_return_record_rate_pct DESC;



-- Q8: Reconcile delivered order totals with item-level sales


WITH item_totals AS (
    SELECT
        order_id,
        SUM(
            quantity * unit_price *
            (1 - discount_pct / 100.0)
        ) AS item_total
    FROM order_items
    GROUP BY order_id
)
SELECT
    ROUND(SUM(o.total_amount), 2) AS order_level_sales,
    ROUND(SUM(i.item_total), 2) AS item_level_sales,
    ROUND(SUM(o.total_amount - i.item_total), 2) AS difference
FROM orders o
JOIN item_totals i
    ON o.order_id = i.order_id
WHERE o.order_status = 'delivered';



-- Q9: Best and worst months by delivered sales

WITH monthly_sales AS (
    SELECT
        strftime('%Y-%m', order_date) AS sales_month,
        SUM(total_amount) AS total_sales
    FROM orders
    WHERE order_status = 'delivered'
    GROUP BY strftime('%Y-%m', order_date)
)
SELECT
    sales_month,
    ROUND(total_sales, 2) AS total_sales
FROM monthly_sales
WHERE total_sales = (SELECT MAX(total_sales) FROM monthly_sales)
   OR total_sales = (SELECT MIN(total_sales) FROM monthly_sales)
ORDER BY total_sales DESC;
