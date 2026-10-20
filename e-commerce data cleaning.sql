-- E-COMMERCE DATA CLEANING SCRIPT
-- Dataset: Olist Brazilian E-Commerce
-- Tables: customers, orders, products, product_category,
--         order_items, order_payments, order_reviews, sellers

-- =====================================================
-- 1. DATA CLEANING FOR CUSTOMERS TABLE
-- =====================================================
SELECT COUNT(*) 
FROM customers; -- their 99441 rows in customers table

-- 1.1 Removing duplicates on customers table
SELECT *,
ROW_NUMBER() OVER (PARTITION BY customer_id, customer_unique_id,customer_zip_code_prefix, customer_city, customer_state
 ORDER BY customer_id) AS row_num
FROM customers;

WITH dup_customer AS (
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY customer_id, customer_unique_id,customer_zip_code_prefix, customer_city, customer_state
	ORDER BY customer_id) AS row_num
FROM customers
)
SELECT *
FROM dup_customer
WHERE row_num > 1;

SET SQL_SAFE_UPDATES = 0;
-- Safe delete: always preview before deleting
DELETE c
FROM customers c
JOIN (
 SELECT customer_id,
 ROW_NUMBER() OVER (PARTITION BY customer_id, customer_unique_id,customer_zip_code_prefix, customer_city, customer_state
 ORDER BY customer_id) AS row_num
 FROM customers
) ranked ON c.customer_id = ranked.customer_id
WHERE ranked.row_num > 1;

-- 1.2 Checking null values on customers table
SELECT *
FROM customers;
SELECT
COUNT(*) - COUNT(customer_id) AS null_customer_id,
COUNT(*) - COUNT(customer_unique_id) AS null_customer_unique_id,
COUNT(*) - COUNT(customer_zip_code_prefix) AS null_customer_zip_code_prefix,
COUNT(*) - COUNT(customer_city)  AS null_customer_city,
COUNT(*) - COUNT(customer_state) AS null_customer_state
FROM customers;-- no null values found in customers table

-- 1.3 Standardize text 
SELECT DISTINCT customer_city
FROM customers;
-- this tell us if the same city is written in different so we can standardize.

SELECT TRIM(customer_city)
FROM customers;-- just to be sure that all data in same order

UPDATE customers
SET customer_city = TRIM(customer_city);

SELECT DISTINCT customer_state
FROM customers;-- this tell us if all rows in customer are the same standardize.

SELECT UPPER(customer_state)
FROM customers;

UPDATE customers
SET customer_state = TRIM(customer_state);
UPDATE customers
SET customer_state = UPPER(customer_state);

-- ============================================
-- 2. DATA CLEANING ON ORDERS TABLE
-- ============================================
SELECT *
FROM orders;
-- working on 99441 rows
SELECT COUNT(*)
FROM orders;

-- 2.1 Handling duplicates on orders table
SELECT *,
ROW_NUMBER() OVER (PARTITION BY order_id, customer_id, order_status, order_purchase_timestamp,order_approved_at,
order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date ORDER BY order_id) AS row_num
FROM  orders;

WITH duplicates AS (
	SELECT *,
	ROW_NUMBER() OVER (PARTITION BY order_id, customer_id, order_status, order_purchase_timestamp,order_approved_at,
	order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date ORDER BY order_id) AS row_num
	FROM  orders
)
SELECT *
FROM duplicates
WHERE row_num > 1; -- this tell us if their is any duplicates #no duplicates on orders dates.

-- 2.2 Checking null values on orders table
SELECT *
FROM orders;
SELECT
COUNT(*) - COUNT(order_id) AS null_order_id,
COUNT(*) - COUNT(customer_id) AS null_customer_id,
COUNT(*) - COUNT(order_status) AS null_order_status,
COUNT(*) - COUNT(order_purchase_timestamp)  AS null_order_purchase_timestamp,
COUNT(*) - COUNT(order_approved_at) AS null_order_approved_at,
COUNT(*) - COUNT(order_delivered_carrier_date) AS null_order_delivered_carrier_date,
COUNT(*) - COUNT(order_delivered_customer_date) AS null_order_delivered_customer_date,
COUNT(*) - COUNT(order_estimated_delivery_date) AS order_estimated_delivery_date
FROM orders;
-- this tell us if their is any null values in orders table

-- 2.3 Standardizing text 
SELECT DISTINCT order_status
FROM orders;

UPDATE orders
SET order_status = TRIM(order_status);

UPDATE orders
SET order_status = LOWER(order_status);

UPDATE orders
SET order_id = TRIM(order_id);

UPDATE orders
SET customer_id = TRIM(customer_id);

-- 2.4 Checking date formats 
-- Verify the column type;
SHOW COLUMNS FROM orders;

-- To see how many rows use each separator:
SELECT
    SUM(order_approved_at LIKE '%/%') AS slash_dates,
    SUM(order_approved_at LIKE '%-%') AS dash_dates
FROM orders;

-- checking whether there are invalid values and changing empty values to nulls.
SELECT *
FROM orders
WHERE STR_TO_DATE(order_approved_at, '%Y-%m-%d %H:%i:%s') IS NULL
AND order_approved_at IS NOT NULL;

SELECT COUNT(*)
FROM orders
WHERE order_approved_at = '';

UPDATE orders
SET order_approved_at = NULL
WHERE TRIM(order_approved_at) = '';

SELECT COUNT(*)
FROM orders
WHERE order_delivered_carrier_date = '';

UPDATE orders
SET order_delivered_carrier_date = NULL
WHERE TRIM(order_delivered_carrier_date)= '';

SELECT COUNT(*)
FROM orders
WHERE order_delivered_customer_date = '';

UPDATE orders
SET order_delivered_customer_date = NULL
WHERE TRIM(order_delivered_customer_date) = '';

--  Since all dates are already YYYY-MM-DD. Simply convert the column type:
ALTER TABLE orders
MODIFY order_purchase_timestamp DATETIME;

ALTER TABLE orders
MODIFY order_approved_at DATETIME;

ALTER TABLE orders
MODIFY order_delivered_carrier_date DATETIME;

ALTER TABLE orders
MODIFY order_delivered_customer_date DATETIME;

ALTER TABLE orders
MODIFY order_estimated_delivery_date DATETIME;

-- ===========================================
-- 3. DATA CLEANING ON PRODUCTS TABLE
-- ===========================================
SELECT *
FROM products;
-- 32340 row of products table
SELECT COUNT(*)
FROM products;

-- 3.1 Checking duplicates on products table
SELECT *,
ROW_NUMBER() OVER (PARTITION BY product_id, product_category_name, product_name_lenght, product_description_lenght, 
product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm 
ORDER BY product_id ) AS rn
FROM products;

WITH product_duplicates AS (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY product_id, product_category_name, product_name_lenght, product_description_lenght, 
product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm 
ORDER BY product_id ) AS rn
FROM products
)
SELECT *
FROM product_duplicates
WHERE rn > 1; -- this tell us if their is any duplicates.

-- 3.2 Checking null values on products table
SELECT
COUNT(*) - COUNT(product_id) AS null_product_id,
COUNT(*) - COUNT(product_category_name) AS null_product_category_name,
COUNT(*) - COUNT(product_name_lenght) AS null_product_name_lenght,
COUNT(*) - COUNT(product_description_lenght)  AS null_product_description_lenght,
COUNT(*) - COUNT(product_photos_qty) AS null_product_photos_qtyt,
COUNT(*) - COUNT(product_weight_g) AS null_product_weight_g,
COUNT(*) - COUNT(product_length_cm) AS null_product_length_cm,
COUNT(*) - COUNT(product_height_cm) AS null_product_height_cm,
COUNT(*) - COUNT(product_width_cm) AS null_product_width_cm
FROM products;-- this tell us if their any null values on products table

-- 3.3 Standardizing text
SELECT DISTINCT product_category_name
FROM products;

UPDATE products
SET product_category_name = TRIM(product_category_name);

UPDATE products
SET product_category_name = LOWER(product_category_name);

-- 3.4 Verifying consistency: check logical correctness such as negative values on numerical column
SELECT COUNT(*) AS negative_name_length    FROM products WHERE product_name_lenght < 0;
SELECT COUNT(*) AS negative_desc_length    FROM products WHERE product_description_lenght < 0;
SELECT COUNT(*) AS negative_photos_qty     FROM products WHERE product_photos_qty < 0;
SELECT COUNT(*) AS negative_weight         FROM products WHERE product_weight_g < 0;
SELECT COUNT(*) AS negative_length         FROM products WHERE product_length_cm < 0;
SELECT COUNT(*) AS negative_width          FROM products WHERE product_width_cm < 0;
SELECT COUNT(*) AS negative_height         FROM products WHERE product_height_cm < 0;
-- this tell us if negative values on numerical column

UPDATE products SET product_name_lenght        = ABS(product_name_lenght)        WHERE product_name_lenght        < 0;
UPDATE products SET product_description_lenght = ABS(product_description_lenght) WHERE product_description_lenght < 0;
UPDATE products SET product_photos_qty         = ABS(product_photos_qty)         WHERE product_photos_qty         < 0;
UPDATE products SET product_weight_g           = ABS(product_weight_g)           WHERE product_weight_g           < 0;
UPDATE products SET product_length_cm          = ABS(product_length_cm)          WHERE product_length_cm          < 0;
UPDATE products SET product_height_cm          = ABS(product_height_cm)          WHERE product_height_cm          < 0;
UPDATE products SET product_width_cm           = ABS(product_width_cm)           WHERE product_width_cm           < 0;

-- ================================================
-- 4. DATA CLEANING ON PRODUCT_CATEGORY
-- ================================================
SELECT * FROM product_category;

-- 71 row on product_categories
SELECT COUNT(*) FROM product_category;

-- 4.1 Checking duplicates 
SELECT *,
ROW_NUMBER() OVER (PARTITION BY product_category_name,
product_category_name_english ) AS rn
FROM product_category; -- this tell us if their is any duuplicates but bo duplicates found

-- 4.2 Standardizing text 
SELECT DISTINCT product_category_name
FROM product_category;

SELECT DISTINCT product_category_name_english
FROM product_category;

UPDATE product_category
SET product_category_name = TRIM(product_category_name);
UPDATE product_category
SET product_category_name_english = TRIM(product_category_name_english);

-- ==============================================
-- 5. DATA CLEANING ON ORDER_ITEMS
-- ==============================================
-- 5.1 Handling duplicate 
SELECT *
FROM order_items;
-- 112650 rows of order_items
SELECT COUNT(*)
FROM order_items;

SELECT *,
ROW_NUMBER() OVER (PARTITION BY order_id, order_item_id, product_id, seller_id, shipping_limit_date,
price,freight_value ORDER BY order_item_id ) AS rn
FROM order_items;

WITH oi_duplicates AS (
	SELECT *,
	ROW_NUMBER() OVER (PARTITION BY order_id, order_item_id, product_id, seller_id, shipping_limit_date,
	price,freight_value ORDER BY order_item_id ) AS rn
	FROM order_items
)
SELECT *
FROM oi_duplicates
WHERE rn > 1;-- this tell if their s any duplicates

-- 5.2 checking columns type
SHOW COLUMNS FROM order_items;

-- To see how many rows use each separator:
SELECT
    SUM(shipping_limit_date LIKE '%/%') AS slash_dates,
    SUM(shipping_limit_date LIKE '%-%') AS dash_dates
FROM order_items;

-- update shipping_limit_date column from text to date time
ALTER TABLE order_items
MODIFY COLUMN shipping_limit_date DATETIME;

-- 5.3 Verifying consistency: check logical correctness such as negative values on numerical column
SELECT 
CASE WHEN price < 1 THEN ABS(price) END
FROM order_items;

-- SET SQL_SAFE_UPDATES = 0;
UPDATE order_items SET price = ABS(price) WHERE price < 0;

SELECT 
CASE WHEN freight_value < 1 THEN ABS(freight_value) END
FROM order_items;

UPDATE order_items SET freight_value = ABS(freight_value) WHERE freight_value < 0;
-- ==================================================
-- 6. DATA CLEANING ON ORDER_PAYMENTS TABLE
-- ==================================================
SELECT *
FROM order_payments;
-- 103886 rows on order_payments table
SELECT COUNT(*)
FROM order_payments;

-- 6.1 Checking dulicates
WITH op_duplicates AS (
	SELECT *,
    ROW_NUMBER() OVER (PARTITION BY order_id, payment_sequential,payment_type, payment_installments,
    payment_value ) AS rn
    FROM order_payments
)
SELECT *
FROM op_duplicates
WHERE rn > 1;

-- 6.2 Handling null values 
-- seeing if thier null values on the table
SELECT
COUNT(*) - COUNT(order_id) AS null_order_id,
COUNT(*) - COUNT(payment_sequential) AS null_payment_sequential,
COUNT(*) - COUNT(payment_type) AS null_payment_type,
COUNT(*) - COUNT(payment_installments) AS null_payment_installments,
COUNT(*) - COUNT(payment_value) AS null_payment_value
FROM order_payments;

-- 6.3 Standardizing text
-- seeing if their is any miss spelled word or any space 
SELECT DISTINCT payment_type
FROM order_payments;

UPDATE order_payments SET payment_type = TRIM(payment_type);

-- 6.4 Check and fix negative values
SELECT COUNT(*) AS negative_sequential    FROM order_payments WHERE payment_sequential   < 0;
SELECT COUNT(*) AS negative_installments  FROM order_payments WHERE payment_installments < 0;
SELECT COUNT(*) AS negative_value         FROM order_payments WHERE payment_value        < 0;
 
-- Apply ABS() correction if negatives exist
UPDATE order_payments SET payment_sequential   = ABS(payment_sequential)   WHERE payment_sequential   < 0;
UPDATE order_payments SET payment_installments = ABS(payment_installments) WHERE payment_installments < 0;
UPDATE order_payments SET payment_value        = ABS(payment_value)        WHERE payment_value        < 0;

-- ===============================================
-- 7. DATA CLEANING ON SELLERS TABLE
-- ===============================================
SELECT *
FROM sellers;
-- 289 rows on sellers table
SELECT COUNT(*)
FROM sellers;

-- 7.1 checking duplicates 
WITH s_duplicates AS (
	SELECT *,
	ROW_NUMBER() OVER (PARTITION BY seller_id, seller_zip_code_prefix, seller_city,seller_state
	ORDER BY seller_id) AS row_num
	FROM sellers
)
SELECT *
FROM s_duplicates
WHERE row_num > 1;

-- 7.2 standardizing  text
SELECT DISTINCT seller_city
FROM sellers;

SELECT DISTINCT seller_state
FROM sellers;

UPDATE sellers
SET seller_city = TRIM(seller_city);

UPDATE sellers
SET seller_state = UPPER(seller_state);

-- ==========================================================
-- 8. FINAL VERIFICATION — ALL TABLES
-- ==========================================================
-- Run these after all cleaning steps to confirm expected row counts
-- and zero unexpected nulls in key columns.
 
SELECT 'customers'      AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders',         COUNT(*) FROM orders
UNION ALL
SELECT 'products',       COUNT(*) FROM products
UNION ALL
SELECT 'product_category', COUNT(*) FROM product_category
UNION ALL
SELECT 'order_items',    COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'sellers',        COUNT(*) FROM sellers;
 
-- Spot-check key columns for lingering nulls
SELECT
    (SELECT COUNT(*) FROM customers  WHERE customer_id  IS NULL) AS cust_id_nulls,
    (SELECT COUNT(*) FROM orders     WHERE order_id     IS NULL) AS ord_id_nulls,
    (SELECT COUNT(*) FROM products   WHERE product_id   IS NULL) AS prod_id_nulls,
    (SELECT COUNT(*) FROM order_items WHERE order_id    IS NULL) AS oi_id_nulls,
    (SELECT COUNT(*) FROM order_payments WHERE order_id IS NULL) AS op_id_nulls,
    (SELECT COUNT(*) FROM sellers    WHERE seller_id    IS NULL) AS seller_id_nulls;
 
-- ALL TABLES CLEANED AND READY FOR EDA
SELECT * FROM customers      LIMIT 5;
SELECT * FROM orders         LIMIT 5;
SELECT * FROM products       LIMIT 5;
SELECT * FROM product_category LIMIT 5;
SELECT * FROM order_items    LIMIT 5;
SELECT * FROM order_payments LIMIT 5;
SELECT * FROM order_reviews  LIMIT 5;
SELECT * FROM sellers        LIMIT 5;