/*
PROJECT: Retail Sales Data Analysis
FILE: 03_product_category_analysis.sql
DATABASE: Fiction Retail (SQLite)

PURPOSE
Analyze product and category performance using delivered orders only.

METRIC DEFINITIONS
- Gross Item Value = quantity * unit_price before discount.
- Discount Value = gross item value * discount_pct / 100.
- Net Item Value = gross item value - discount value.
- Units Sold = sum of quantity on delivered order lines.
- Product/category sales use order_items, not orders.total_amount.
- discount_pct is treated as a percentage (e.g. 10 = 10%).
- Sales-performance queries filter orders.order_status = 'delivered'.

SCHEMA USED
orders(order_id, customer_id, order_date, order_status, total_amount, ...)
order_items(order_item_id, order_id, product_id, quantity, unit_price, discount_pct)
products(product_id, name, category, brand, price, ...)
*/

-- ============================================================
-- 1. VALIDATE PRODUCT AND ORDER-ITEM DATA
-- ============================================================

-- 1A. Product table size and unique product IDs.
SELECT
    COUNT(*) AS product_rows,
    COUNT(DISTINCT product_id) AS unique_product_ids,
    COUNT(DISTINCT category) AS distinct_categories,
    COUNT(DISTINCT brand) AS distinct_brands
FROM products;

-- 1B. Order-item row count and basic quantity/price/discount ranges.
SELECT
    COUNT(*) AS order_item_rows,
    COUNT(DISTINCT order_id) AS orders_represented,
    COUNT(DISTINCT product_id) AS products_represented,
    SUM(quantity) AS total_units_all_statuses,
    MIN(quantity) AS minimum_quantity,
    MAX(quantity) AS maximum_quantity,
    MIN(unit_price) AS minimum_unit_price,
    MAX(unit_price) AS maximum_unit_price,
    MIN(discount_pct) AS minimum_discount_pct,
    MAX(discount_pct) AS maximum_discount_pct
FROM order_items;

-- 1C. Check for order-item rows with missing or unmatched product/order keys.
SELECT
    SUM(CASE WHEN oi.product_id IS NULL OR p.product_id IS NULL THEN 1 ELSE 0 END)
        AS rows_with_missing_or_unmatched_product,
    SUM(CASE WHEN oi.order_id IS NULL OR o.order_id IS NULL THEN 1 ELSE 0 END)
        AS rows_with_missing_or_unmatched_order
FROM order_items oi
LEFT JOIN products p ON p.product_id = oi.product_id
LEFT JOIN orders o ON o.order_id = oi.order_id;


-- ============================================================
-- 2. OVERALL DELIVERED PRODUCT PERFORMANCE
-- ============================================================

SELECT
    COUNT(*) AS delivered_order_item_rows,
    COUNT(DISTINCT oi.order_id) AS delivered_orders_with_items,
    COUNT(DISTINCT oi.product_id) AS distinct_products_sold,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS gross_item_value,
    ROUND(SUM(oi.quantity * oi.unit_price * oi.discount_pct / 100.0), 2)
        AS discount_value,
    ROUND(SUM(oi.quantity * oi.unit_price
        * (1 - oi.discount_pct / 100.0)), 2) AS net_item_value,
    ROUND(
        100.0 * SUM(oi.quantity * oi.unit_price * oi.discount_pct / 100.0)
        / NULLIF(SUM(oi.quantity * oi.unit_price), 0),
        2
    ) AS weighted_discount_rate_pct
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';


-- ============================================================
-- 3. CATEGORY PERFORMANCE
-- ============================================================

-- 3A. Rank categories by net item value.
SELECT
    p.category,
    COUNT(DISTINCT oi.product_id) AS distinct_products_sold,
    COUNT(DISTINCT oi.order_id) AS delivered_orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS gross_item_value,
    ROUND(SUM(oi.quantity * oi.unit_price * oi.discount_pct / 100.0), 2)
        AS discount_value,
    ROUND(SUM(oi.quantity * oi.unit_price
        * (1 - oi.discount_pct / 100.0)), 2) AS net_item_value,
    ROUND(
        100.0 * SUM(oi.quantity * oi.unit_price * oi.discount_pct / 100.0)
        / NULLIF(SUM(oi.quantity * oi.unit_price), 0),
        2
    ) AS weighted_discount_rate_pct
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.category
ORDER BY net_item_value DESC;

-- 3B. Each category's share of total delivered net item value.
WITH category_sales AS (
    SELECT
        p.category,
        SUM(oi.quantity * oi.unit_price
            * (1 - oi.discount_pct / 100.0)) AS net_item_value
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.category
)
SELECT
    category,
    ROUND(net_item_value, 2) AS net_item_value,
    ROUND(
        100.0 * net_item_value / NULLIF(SUM(net_item_value) OVER (), 0),
        2
    ) AS share_of_net_item_value_pct
FROM category_sales
ORDER BY net_item_value DESC;


-- ============================================================
-- 4. TOP 10 PRODUCTS BY NET ITEM VALUE
-- ============================================================

SELECT
    p.product_id,
    p.name AS product_name,
    p.category,
    p.brand,
    COUNT(DISTINCT oi.order_id) AS delivered_orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS gross_item_value,
    ROUND(SUM(oi.quantity * oi.unit_price * oi.discount_pct / 100.0), 2)
        AS discount_value,
    ROUND(SUM(oi.quantity * oi.unit_price
        * (1 - oi.discount_pct / 100.0)), 2) AS net_item_value,
    ROUND(
        100.0 * SUM(oi.quantity * oi.unit_price * oi.discount_pct / 100.0)
        / NULLIF(SUM(oi.quantity * oi.unit_price), 0),
        2
    ) AS weighted_discount_rate_pct
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_id, p.name, p.category, p.brand
ORDER BY net_item_value DESC
LIMIT 10;


-- ============================================================
-- 5. BOTTOM 10 PRODUCTS BY NET ITEM VALUE
-- Products with no delivered sales are not included.
-- ============================================================

SELECT
    p.product_id,
    p.name AS product_name,
    p.category,
    p.brand,
    COUNT(DISTINCT oi.order_id) AS delivered_orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price
        * (1 - oi.discount_pct / 100.0)), 2) AS net_item_value
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_id, p.name, p.category, p.brand
ORDER BY net_item_value ASC
LIMIT 10;


-- ============================================================
-- 6. DISCOUNT ANALYSIS BY CATEGORY
-- Weighted discount rate = total discount value / gross item value.
-- ============================================================

SELECT
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS gross_item_value,
    ROUND(SUM(oi.quantity * oi.unit_price * oi.discount_pct / 100.0), 2)
        AS discount_value,
    ROUND(SUM(oi.quantity * oi.unit_price
        * (1 - oi.discount_pct / 100.0)), 2) AS net_item_value,
    ROUND(
        100.0 * SUM(oi.quantity * oi.unit_price * oi.discount_pct / 100.0)
        / NULLIF(SUM(oi.quantity * oi.unit_price), 0),
        2
    ) AS weighted_discount_rate_pct,
    MIN(oi.discount_pct) AS minimum_discount_pct,
    MAX(oi.discount_pct) AS maximum_discount_pct
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.category
ORDER BY net_item_value DESC;


-- ============================================================
-- 7. PRODUCT PRICE VS. SALES VOLUME
-- Catalog price is shown separately from observed order-item unit price.
-- ============================================================

SELECT
    p.product_id,
    p.name AS product_name,
    p.category,
    p.brand,
    ROUND(p.price, 2) AS catalog_price,
    ROUND(AVG(oi.unit_price), 2) AS average_sold_unit_price,
    SUM(oi.quantity) AS units_sold,
    COUNT(DISTINCT oi.order_id) AS delivered_orders,
    ROUND(SUM(oi.quantity * oi.unit_price
        * (1 - oi.discount_pct / 100.0)), 2) AS net_item_value
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_id, p.name, p.category, p.brand, p.price
ORDER BY units_sold DESC;


-- ============================================================
-- 8. PRODUCTS WITH NO DELIVERED SALES
-- ============================================================

SELECT
    p.product_id,
    p.name AS product_name,
    p.category,
    p.brand,
    ROUND(p.price, 2) AS catalog_price
FROM products p
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE oi.product_id = p.product_id
      AND o.order_status = 'delivered'
)
ORDER BY p.category, p.name;


-- ============================================================
-- 9. CATEGORY RECONCILIATION
-- Order-level and item-level values can differ because they use
-- different source columns and levels of detail.
-- ============================================================

SELECT
    ROUND((
        SELECT SUM(total_amount)
        FROM orders
        WHERE order_status = 'delivered'
    ), 2) AS delivered_order_level_sales,
    ROUND((
        SELECT SUM(oi.quantity * oi.unit_price
            * (1 - oi.discount_pct / 100.0))
        FROM order_items oi
        JOIN orders o ON o.order_id = oi.order_id
        WHERE o.order_status = 'delivered'
    ), 2) AS delivered_net_item_value,
    ROUND((
        SELECT SUM(total_amount)
        FROM orders
        WHERE order_status = 'delivered'
    ) - (
        SELECT SUM(oi.quantity * oi.unit_price
            * (1 - oi.discount_pct / 100.0))
        FROM order_items oi
        JOIN orders o ON o.order_id = oi.order_id
        WHERE o.order_status = 'delivered'
    ), 2) AS order_level_minus_item_level_difference;
