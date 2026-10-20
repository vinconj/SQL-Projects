-- EXPLORATORY DATA ANALYSIS (EDA)
-- Dataset : Olist Brazilian E-Commerce
-- Sections : 1. Overview & Order Funnel
--            2. Revenue Analysis
--            3. Product & Category Analysis
--            4. Customer Analysis
--            5. Seller Analysis
--            6. Payment Analysis
--            7. Delivery & Logistics Analysis
--            8. Time-Based Trends
-- ================================================================


-- ================================================================
-- 1. OVERVIEW & ORDER FUNNEL
-- ================================================================

-- 1.1 Row counts across all tables
SELECT 'customers'       AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders',          COUNT(*) FROM orders
UNION ALL
SELECT 'order_items',     COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments',  COUNT(*) FROM order_payments
UNION ALL
SELECT 'products',        COUNT(*) FROM products
UNION ALL
SELECT 'product_category',COUNT(*) FROM product_category
UNION ALL
SELECT 'sellers',         COUNT(*) FROM sellers;

-- 1.2 Order status distribution — understand the funnel
SELECT order_status,
	COUNT(*) AS order_count,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;
-- Key insight: what share of orders are successfully delivered vs cancelled

-- 1.3 Cancellation rate
SELECT
    COUNT(*)                                               AS total_orders,
    SUM(order_status = 'canceled')                         AS canceled_orders,
    ROUND(SUM(order_status = 'canceled') * 100.0 / COUNT(*), 2) AS cancel_rate_pct
FROM orders;


-- ================================================================
-- 2. REVENUE ANALYSIS
-- ================================================================

-- 2.1 Overall revenue summary (delivered orders only)
SELECT
    COUNT(DISTINCT oi.order_id)          AS total_delivered_orders,
    COUNT(oi.order_item_id)              AS total_items_sold,
    ROUND(SUM(oi.price), 2)             AS total_revenue,
    ROUND(AVG(oi.price), 2)             AS avg_item_price,
    ROUND(MIN(oi.price), 2)             AS min_item_price,
    ROUND(MAX(oi.price), 2)             AS max_item_price,
    ROUND(SUM(oi.freight_value), 2)     AS total_freight_collected,
    ROUND(SUM(oi.freight_value) * 100.0 / NULLIF(SUM(oi.price + oi.freight_value), 0), 2) AS freight_pct_of_gmv
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered';

-- 2.2 Average order value (AOV) — revenue per order not per item
SELECT
    ROUND(SUM(oi.price) / COUNT(DISTINCT oi.order_id), 2) AS avg_order_value
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered';

-- 2.3 Monthly revenue trend
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id)                        AS orders_placed,
    ROUND(SUM(oi.price), 2)                           AS monthly_revenue,
    ROUND(AVG(oi.price), 2)                           AS avg_item_price
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31'
GROUP BY month
ORDER BY month;
-- Key insight: Nov 2017 spike (Black Friday), steady 2018 growth

-- 2.4 Year-over-year revenue comparison
SELECT
    YEAR(o.order_purchase_timestamp) AS year,
    COUNT(DISTINCT o.order_id)        AS total_orders,
    ROUND(SUM(oi.price), 2)          AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY year
ORDER BY year;

-- 2.5 Revenue by order value bucket (price segmentation)
SELECT
    CASE
        WHEN order_total < 50   THEN 'Under R$50'
        WHEN order_total < 100  THEN 'R$50–100'
        WHEN order_total < 200  THEN 'R$100–200'
        WHEN order_total < 500  THEN 'R$200–500'
        ELSE 'Over R$500'
    END                              AS order_value_bucket,
    COUNT(*)                         AS order_count,
    ROUND(SUM(order_total), 2)       AS bucket_revenue,
    ROUND(AVG(order_total), 2)       AS avg_order_value
FROM (
    SELECT order_id, SUM(price) AS order_total
    FROM order_items
    GROUP BY order_id
) order_totals
GROUP BY order_value_bucket
ORDER BY MIN(order_total);


-- ================================================================
-- 3. PRODUCT & CATEGORY ANALYSIS
-- ================================================================

-- 3.1 Top 10 product categories by revenue
SELECT
    COALESCE(pc.product_category_name_english, p.product_category_name, 'unknown') AS category,
    COUNT(DISTINCT oi.order_id)   AS orders,
    COUNT(oi.order_item_id)       AS items_sold,
    ROUND(SUM(oi.price), 2)       AS total_revenue,
    ROUND(AVG(oi.price), 2)       AS avg_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category pc ON p.product_category_name = pc.product_category_name
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 10;
-- Key insight: health_beauty and watches_gifts lead revenue

-- 3.2 Top 10 categories by volume (items sold)
SELECT
    COALESCE(pc.product_category_name_english, p.product_category_name, 'unknown') AS category,
    COUNT(oi.order_item_id) AS items_sold
FROM order_items oi
JOIN products p  ON oi.product_id = p.product_id
LEFT JOIN product_category pc ON p.product_category_name = pc.product_category_name
GROUP BY category
ORDER BY items_sold DESC
LIMIT 10;

-- 3.3 Average review score per category (product quality signal)
SELECT
    COALESCE(pc.product_category_name_english, p.product_category_name, 'unknown') AS category,
    COUNT(DISTINCT oi.order_id)        AS order_count,
    ROUND(AVG(rv.review_score), 2)    AS avg_review_score
FROM order_items oi
JOIN products p        ON oi.product_id = p.product_id
LEFT JOIN product_category pc ON p.product_category_name = pc.product_category_name
JOIN order_reviews rv  ON oi.order_id  = rv.order_id
GROUP BY category
HAVING order_count > 100
ORDER BY avg_review_score DESC
LIMIT 10;

-- 3.4 Most expensive product categories (avg price)
SELECT
    COALESCE(pc.product_category_name_english, p.product_category_name, 'unknown') AS category,
    ROUND(AVG(oi.price), 2) AS avg_price,
    ROUND(MIN(oi.price), 2) AS min_price,
    ROUND(MAX(oi.price), 2) AS max_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category pc ON p.product_category_name = pc.product_category_name
GROUP BY category
ORDER BY avg_price DESC
LIMIT 10;

-- 3.5 Multi-item orders: how many orders have more than 1 item?
SELECT
    item_count,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM (
    SELECT order_id, COUNT(order_item_id) AS item_count
    FROM order_items
    GROUP BY order_id
) item_counts
GROUP BY item_count
ORDER BY item_count;


-- ================================================================
-- 4. CUSTOMER ANALYSIS
-- ================================================================

-- 4.1 Customers by state (top 10)
SELECT
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    COUNT(DISTINCT o.order_id)           AS total_orders,
    ROUND(SUM(oi.price), 2)             AS total_revenue
FROM customers c
JOIN orders o       ON c.customer_id  = o.customer_id
JOIN order_items oi ON o.order_id     = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_orders DESC
LIMIT 10;
-- Key insight: SP dominates (~42% of all orders)

-- 4.2 Customers by city (top 10)
SELECT
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    COUNT(DISTINCT o.order_id)           AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_city, c.customer_state
ORDER BY total_orders DESC
LIMIT 10;

-- 4.3 Repeat customers vs one-time customers
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time customer'
        WHEN order_count = 2 THEN '2 orders'
        WHEN order_count <= 5 THEN '3–5 orders'
        ELSE '6+ orders'
    END                          AS customer_segment,
    COUNT(*)                     AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM (
    SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
) customer_frequency
GROUP BY customer_segment
ORDER BY customer_count DESC;
-- Key insight: ~96.9% of customers buy only once — retention opportunity

-- 4.4 Avg spend per customer
SELECT
    ROUND(SUM(oi.price) / COUNT(DISTINCT c.customer_unique_id), 2) AS avg_revenue_per_customer
FROM customers c
JOIN orders o       ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id    = oi.order_id
WHERE o.order_status = 'delivered';


-- ================================================================
-- 5. SELLER ANALYSIS
-- ================================================================

-- 5.1 Top 10 sellers by revenue
SELECT oi.seller_id, s.seller_city, s.seller_state,
COUNT(DISTINCT oi.order_id)   AS orders_fulfilled,
COUNT(oi.order_item_id)       AS items_sold,
ROUND(SUM(oi.price), 2)       AS total_revenue,
ROUND(AVG(oi.price), 2)       AS avg_item_price
FROM order_items oi
JOIN sellers s ON oi.seller_id = s.seller_id
JOIN orders o  ON oi.order_id  = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.seller_id, s.seller_city, s.seller_state
ORDER BY total_revenue DESC
LIMIT 10;

-- 5.2 Sellers by state
SELECT s.seller_state,
COUNT(DISTINCT s.seller_id)   AS seller_count,
COUNT(DISTINCT oi.order_id)   AS orders_fulfilled,
ROUND(SUM(oi.price), 2)       AS total_revenue
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
JOIN orders o       ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_state
ORDER BY seller_count DESC
LIMIT 10;

-- 5.3 Seller performance: avg review score per seller
SELECT oi.seller_id,
COUNT(DISTINCT oi.order_id)    AS orders_fulfilled,
ROUND(AVG(rv.review_score), 2) AS avg_review_score,
ROUND(SUM(oi.price), 2)        AS total_revenue
FROM order_items oi
JOIN order_reviews rv ON oi.order_id = rv.order_id
JOIN orders o         ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.seller_id
HAVING orders_fulfilled >= 50
ORDER BY avg_review_score DESC
LIMIT 10;

-- 5.4 Seller volume distribution (how active are sellers?)
SELECT
    CASE
        WHEN order_count < 10   THEN '1–9 orders'
        WHEN order_count < 50   THEN '10–49 orders'
        WHEN order_count < 200  THEN '50–199 orders'
        ELSE '200+ orders'
    END                     AS seller_tier,
    COUNT(*)                AS seller_count
FROM (
    SELECT seller_id, COUNT(DISTINCT order_id) AS order_count
    FROM order_items
    GROUP BY seller_id
) seller_activity
GROUP BY seller_tier
ORDER BY MIN(order_count);


-- ================================================================
-- 6. PAYMENT ANALYSIS
-- ================================================================

-- 6.1 Payment type distribution
SELECT payment_type,
	COUNT(*)                                              AS transaction_count,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)     AS pct_of_transactions,
	ROUND(SUM(payment_value), 2)                          AS total_payment_value,
	ROUND(AVG(payment_value), 2)                          AS avg_payment_value
FROM order_payments
WHERE payment_type != 'not_defined'
GROUP BY payment_type
ORDER BY transaction_count DESC;
-- Key insight: credit card dominates at ~74%, boleto at ~19%

-- 6.2 Credit card installment distribution
SELECT payment_installments,
	COUNT(*)                                            AS order_count,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)   AS pct
FROM order_payments
WHERE payment_type = 'credit_card'
GROUP BY payment_installments
ORDER BY payment_installments;
-- Key insight: avg 3.5 installments — Brazilians prefer installments

-- 6.3 High-value orders: orders paid in 10+ installments
SELECT
	COUNT(*) AS orders_10plus_installments,
	ROUND(AVG(payment_value), 2) AS avg_payment_value
FROM order_payments
WHERE payment_type = 'credit_card'
AND payment_installments >= 10;

-- 6.4 Multi-payment orders (orders paid with more than one method)
SELECT payment_count,
	COUNT(*) AS order_count
FROM (
	SELECT order_id, COUNT(DISTINCT payment_type) AS payment_count
    FROM order_payments
    GROUP BY order_id
) payment_breakdown
GROUP BY payment_count
ORDER BY payment_count;


-- ================================================================
-- 7. DELIVERY & LOGISTICS ANALYSIS
-- ================================================================

-- 7.1 Overall delivery time statistics (in days)
SELECT
	ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS avg_delivery_days,
	ROUND(MIN(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS min_delivery_days,
	ROUND(MAX(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS max_delivery_days,
		-- Approximate median using percentile trick
	ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS approx_median
FROM orders
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL;

-- 7.2 Late deliveries (arrived after estimated date)
SELECT
	COUNT(*)                                              AS total_delivered,
	SUM(order_delivered_customer_date > order_estimated_delivery_date) AS late_deliveries,
	ROUND(SUM(order_delivered_customer_date > order_estimated_delivery_date) * 100.0 / COUNT(*), 2)   AS late_pct,
	ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)), 1)             AS avg_days_late_or_early
FROM orders
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL
AND order_estimated_delivery_date IS NOT NULL;
-- Key insight: 7.6% of orders arrived late

-- 7.3 Delivery time by customer state (top 10 slowest)
SELECT c.customer_state,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_delivery_days
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING orders > 100
ORDER BY avg_delivery_days DESC
LIMIT 10;
-- Key insight: remote northern states have longer delivery times

-- 7.4 Delivery time buckets
SELECT
    CASE
        WHEN delivery_days <= 3   THEN '0–3 days (express)'
        WHEN delivery_days <= 7   THEN '4–7 days (fast)'
        WHEN delivery_days <= 14  THEN '8–14 days (standard)'
        WHEN delivery_days <= 30  THEN '15–30 days (slow)'
        ELSE 'Over 30 days'
    END                           AS delivery_bucket,
    COUNT(*)                      AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM (
    SELECT DATEDIFF(order_delivered_customer_date, order_purchase_timestamp) AS delivery_days
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
) delivery_times
GROUP BY delivery_bucket
ORDER BY MIN(delivery_days);

-- 7.5 Freight value by customer state (avg freight cost paid)
SELECT
    c.customer_state,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight_value,
    COUNT(DISTINCT o.order_id)      AS order_count
FROM orders o
JOIN customers c    ON o.customer_id  = c.customer_id
JOIN order_items oi ON o.order_id     = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY avg_freight_value DESC
LIMIT 10;

-- ================================================================
-- 8. TIME-BASED TRENDS
-- ================================================================

-- 8.1 Orders by day of week
SELECT
    DAYNAME(order_purchase_timestamp) AS day_of_week,
    DAYOFWEEK(order_purchase_timestamp) AS day_num,
    COUNT(*) AS order_count
FROM orders
GROUP BY day_of_week, day_num
ORDER BY day_num;
-- Key insight: weekdays outperform weekends; Monday is busiest

-- 8.2 Orders by hour of day (shopping behavior)
SELECT
    HOUR(order_purchase_timestamp) AS hour_of_day,
    COUNT(*)                        AS order_count
FROM orders
GROUP BY hour_of_day
ORDER BY hour_of_day;
-- Key insight: peak hours are 10–16 and 20–21

-- 8.3 Best and worst months for orders
SELECT
    MONTHNAME(order_purchase_timestamp) AS month_name,
    MONTH(order_purchase_timestamp)     AS month_num,
    COUNT(*)                            AS order_count
FROM orders
WHERE YEAR(order_purchase_timestamp) IN (2017, 2018)
GROUP BY month_name, month_num
ORDER BY order_count DESC;

-- 8.4 Growth rate month-over-month
WITH monthly_orders AS (
    SELECT
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
        COUNT(*)                                        AS order_count
    FROM orders
    WHERE order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31'
    GROUP BY month
)
SELECT
    month,
    order_count,
    LAG(order_count) OVER (ORDER BY month)        AS prev_month_count,
    ROUND(
        (order_count - LAG(order_count) OVER (ORDER BY month))
        * 100.0 / NULLIF(LAG(order_count) OVER (ORDER BY month), 0),
    1)                                             AS mom_growth_pct
FROM monthly_orders
ORDER BY month;

-- 8.5 November 2017 Black Friday spike — drill down
SELECT
    DAY(order_purchase_timestamp) AS day,
    COUNT(*)                       AS order_count,
    ROUND(SUM(oi.price), 2)       AS daily_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') = '2017-11'
GROUP BY day
ORDER BY day;
-- Look for the spike around day 24 (Black Friday)
