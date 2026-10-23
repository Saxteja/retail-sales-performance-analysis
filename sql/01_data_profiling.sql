-- Fiction Retail | Initial Data Profiling
-- Database: fiction-retail.db (SQLite)
-- Scope: structural profiling for Sales Performance Analysis.
-- Run this script against a working copy or read-only connection where possible.
-- This script does not modify data.

-- 1. Row counts for the six tables checked in the initial pass
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'returns', COUNT(*) FROM returns
UNION ALL SELECT 'promotions', COUNT(*) FROM promotions;

-- 2. Order status distribution and raw sum of orders.total_amount
-- Note: this sum is not yet validated as a sales metric.
SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(SUM(total_amount), 2) AS sum_order_total_amount
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

-- 3. Order date coverage
SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    COUNT(DISTINCT DATE(order_date)) AS distinct_order_dates
FROM orders;

-- 4. Product counts by category (product assortment, not sales performance)
SELECT
    category,
    COUNT(*) AS product_count
FROM products
GROUP BY category
ORDER BY product_count DESC;

-- 5. Next check: find orders whose order total differs from discounted item total.
-- Assumption to validate: discount_pct is a percentage from 0 to 100.
-- This is diagnostic only; do not silently replace either amount.
SELECT
    o.order_id,
    o.order_status,
    o.total_amount AS order_total,
    ROUND(
        SUM(
            oi.quantity * oi.unit_price
            * (1 - COALESCE(oi.discount_pct, 0) / 100.0)
        ),
        2
    ) AS calculated_item_total,
    ROUND(
        o.total_amount - SUM(
            oi.quantity * oi.unit_price
            * (1 - COALESCE(oi.discount_pct, 0) / 100.0)
        ),
        2
    ) AS difference
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.order_status, o.total_amount
HAVING ABS(
    o.total_amount - SUM(
        oi.quantity * oi.unit_price
        * (1 - COALESCE(oi.discount_pct, 0) / 100.0)
    )
) > 0.02
ORDER BY ABS(difference) DESC
LIMIT 30;

-- 6. Summary of reconciliation check
WITH item_totals AS (
    SELECT
        order_id,
        SUM(
            quantity * unit_price
            * (1 - COALESCE(discount_pct, 0) / 100.0)
        ) AS calculated_total
    FROM order_items
    GROUP BY order_id
)
SELECT
    COUNT(*) AS matched_orders,
    SUM(
        CASE WHEN ABS(o.total_amount - i.calculated_total) <= 0.02
             THEN 1 ELSE 0 END
    ) AS reconciled_orders,
    SUM(
        CASE WHEN ABS(o.total_amount - i.calculated_total) > 0.02
             THEN 1 ELSE 0 END
    ) AS mismatched_orders
FROM orders o
JOIN item_totals i ON o.order_id = i.order_id;

-- 7. Distribution of discount_pct values in order_items

SELECT
    discount_pct,
    COUNT(*) AS row_count
FROM order_items
GROUP BY discount_pct
ORDER BY discount_pct;

-- 8. Estimated item totals by order

WITH OrderItemTotals AS (
    SELECT 
        order_id,
        -- Calculate the estimated total per order, accounting for the discount percentage
        SUM(quantity * unit_price * (1 - (discount_pct / 100.0))) AS estimated_item_total
    FROM 
        order_items
    GROUP BY 
        order_id
)
SELECT 
    o.order_id,
    o.total_amount,
    i.estimated_item_total,
    -- Calculate the absolute difference between the recorded amount and our estimate
    ABS(o.total_amount - i.estimated_item_total) AS total_difference
FROM 
    orders o
JOIN 
    OrderItemTotals i ON o.order_id = i.order_id
ORDER BY 
    total_difference DESC
LIMIT 20;

-- 9. Primary-key uniqueness checks.

SELECT 'customers' AS table_name,
       COUNT(*) AS total_rows,
       COUNT(DISTINCT customer_id) AS unique_ids
FROM customers

UNION ALL

SELECT 'orders',
       COUNT(*),
       COUNT(DISTINCT order_id)
FROM orders

UNION ALL

SELECT 'order_items',
       COUNT(*),
       COUNT(DISTINCT order_item_id)
FROM order_items

UNION ALL

SELECT 'products',
       COUNT(*),
       COUNT(DISTINCT product_id)
FROM products

UNION ALL

SELECT 'returns',
       COUNT(*),
       COUNT(DISTINCT return_id)
FROM returns

UNION ALL

SELECT 'promotions',
       COUNT(*),
       COUNT(DISTINCT promo_id)
FROM promotions;


-- 10. Null value counts for key columns in orders and order_items.
SELECT
    'orders' AS table_name,
    'order_id' AS column_name,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_count
FROM orders

UNION ALL

SELECT 'orders', 'order_date',
       SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END)
FROM orders

UNION ALL

SELECT 'orders', 'total_amount',
       SUM(CASE WHEN total_amount IS NULL THEN 1 ELSE 0 END)
FROM orders

UNION ALL

SELECT 'orders', 'order_status',
       SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END)
FROM orders

UNION ALL

SELECT 'order_items', 'order_id',
       SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)
FROM order_items

UNION ALL

SELECT 'order_items', 'product_id',
       SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END)
FROM order_items

UNION ALL

SELECT 'order_items', 'quantity',
       SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END)
FROM order_items

UNION ALL

SELECT 'order_items', 'unit_price',
       SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END)
FROM order_items

UNION ALL

SELECT 'order_items', 'discount_pct',
       SUM(CASE WHEN discount_pct IS NULL THEN 1 ELSE 0 END)
FROM order_items;

-- 10. Invalid sales values
SELECT
    SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END)
        AS nonpositive_quantity_rows,
    SUM(CASE WHEN unit_price < 0 THEN 1 ELSE 0 END)
        AS negative_unit_price_rows,
    SUM(CASE WHEN discount_pct < 0 OR discount_pct > 100
             THEN 1 ELSE 0 END)
        AS invalid_discount_rows,
    SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END)
        AS null_unit_price_rows
FROM order_items;

-- 11. Orphaned product references in order_items

SELECT COUNT(*) AS orphaned_product_references
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 11A. Orphaned order references in order_items

SELECT COUNT(*) AS orphaned_customer_references
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 11B. Orphaned promotion references in orders
SELECT
    COUNT(*) AS orders_with_promotion,
    SUM(
        CASE
            WHEN p.promo_id IS NULL THEN 1
            ELSE 0
        END
    ) AS orphaned_promotion_references
FROM orders o
LEFT JOIN promotions p
    ON o.promo_id = p.promo_id
WHERE o.promo_id IS NOT NULL;

-- 12. Summary statistics for order_items numeric columns

SELECT
    MIN(quantity) AS min_quantity,
    MAX(quantity) AS max_quantity,
    AVG(quantity) AS avg_quantity,
    MIN(unit_price) AS min_unit_price,
    MAX(unit_price) AS max_unit_price,
    ROUND(AVG(unit_price), 2) AS avg_unit_price
FROM order_items;

-- 12A. Top 10 most expensive order items (unit_price) with product and order details

SELECT
    oi.product_id,
    p.name AS product_name,
    p.category,
    oi.unit_price,
    oi.quantity,
    oi.discount_pct,
    o.order_date,
    o.order_status
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
ORDER BY oi.unit_price DESC
LIMIT 10;

-- 12b. Summary statistics for products numeric columns
SELECT
    p.product_id,
    p.name AS product_name,
    p.category,
    p.price AS current_list_price,
    MIN(oi.unit_price) AS min_ordered_price,
    MAX(oi.unit_price) AS max_ordered_price,
    ROUND(AVG(oi.unit_price), 2) AS avg_ordered_price,
    COUNT(*) AS order_item_rows
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
WHERE p.product_id IN (
    '0adb6d73-0ae6-48c6-8449-3664b6be3210',
    '89722d2b-8564-4e63-8c36-d61f7e50970c',
    '3a592288-9478-4017-884d-c4159182d91d',
    'ee1357ed-63a8-407a-9a5e-06571dbe0a34'
)
GROUP BY p.product_id, p.name, p.category, p.price
ORDER BY max_ordered_price DESC;