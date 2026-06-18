-- DATA PROFILING & DATA QUALITY AUDIT

USE streamcart;

-- UNDERSTANDING THE DATA 
-- Understand table structure, row counts
-- and data availability before analytics.
DESCRIBE customers;
DESCRIBE orders;
DESCRIBE products;
DESCRIBE support_tickets;
DESCRIBE subscriptions;

SELECT COUNT(*) AS total_customers FROM customers;
SELECT COUNT(*) AS total_products FROM products;
SELECT COUNT(*) AS total_orders FROM orders;
SELECT COUNT(*) AS total_subscriptions FROM subscriptions;
SELECT COUNT(*) AS total_support_tickets FROM support_tickets;

-- SAMPLE DATA REVIEW
SELECT * FROM customers LIMIT 10;
SELECT * FROM products LIMIT 10;
SELECT * FROM orders LIMIT 10;
SELECT * FROM subscriptions LIMIT 10;
SELECT * FROM support_tickets LIMIT 10;


-- COMPLETENESS CHECK
-- CUSTOMERS
SELECT COUNT(*) AS total_rows,
SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS customer_id_nulls,
SUM(CASE WHEN customer_name IS NULL THEN 1 ELSE 0 END) AS customer_name_nulls,
SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS city_nulls,
SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS country_nulls,
SUM(CASE WHEN signup_date IS NULL THEN 1 ELSE 0 END) AS signup_date_nulls,
SUM(CASE WHEN is_active IS NULL THEN 1 ELSE 0 END) AS is_active_nulls
FROM customers;

-- PRODUCTS
SELECT COUNT(*) AS total_rows,
SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS product_id_nulls,
SUM(CASE WHEN product_name IS NULL THEN 1 ELSE 0 END) AS product_name_nulls,
SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS category_nulls,
SUM(CASE WHEN cost_price IS NULL THEN 1 ELSE 0 END) AS cost_price_nulls,
SUM(CASE WHEN selling_price IS NULL THEN 1 ELSE 0 END) AS selling_price_nulls
FROM products;

-- ORDERS
SELECT COUNT(*) AS total_rows,
SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS order_id_nulls,
SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS customer_id_nulls,
SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS product_id_nulls,
SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS quantity_nulls,
SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) AS unit_price_nulls,
SUM(CASE WHEN discount_pct IS NULL THEN 1 ELSE 0 END) AS discount_nulls,
SUM(CASE WHEN channel IS NULL THEN 1 ELSE 0 END) AS channel_nulls
FROM orders;

-- SUBSCRIPTIONS
SELECT COUNT(*) AS total_rows,
SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS customer_id_nulls,
SUM(CASE WHEN plan_name IS NULL THEN 1 ELSE 0 END) AS plan_name_nulls,
SUM(CASE WHEN monthly_fee IS NULL THEN 1 ELSE 0 END) AS monthly_fee_nulls,
SUM(CASE WHEN payment_method IS NULL THEN 1 ELSE 0 END) AS payment_method_nulls
FROM subscriptions;

-- SUPPORT TICKETS
SELECT COUNT(*) AS total_rows,
SUM(CASE WHEN ticket_id IS NULL THEN 1 ELSE 0 END) AS ticket_id_nulls,
SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS category_nulls,
SUM(CASE WHEN priority IS NULL THEN 1 ELSE 0 END) AS priority_nulls,
SUM(CASE WHEN csat_score IS NULL THEN 1 ELSE 0 END) AS csat_score_nulls
FROM support_tickets;

-- BLANK VALUE CHECKS
-- Identify blank or whitespace-only values that can
-- impact reporting, filtering and KPI calculations.
SELECT 'customers.customer_name' AS field_name, COUNT(*) AS blank_count
FROM customers WHERE TRIM(IFNULL(customer_name,'')) = ''
UNION ALL
SELECT 'customers.email', COUNT(*)
FROM customers WHERE TRIM(IFNULL(email,'')) = ''
UNION ALL
SELECT 'customers.city', COUNT(*)
FROM customers WHERE TRIM(IFNULL(city,'')) = ''
UNION ALL
SELECT 'customers.country', COUNT(*)
FROM customers WHERE TRIM(IFNULL(country,'')) = ''
UNION ALL
SELECT 'products.product_name', COUNT(*) 
FROM products WHERE TRIM(IFNULL(product_name,'')) = ''
UNION ALL
SELECT 'products.category', COUNT(*)
FROM products WHERE TRIM(IFNULL(category,'')) = ''
UNION ALL 
SELECT 'products.subcategory',COUNT(*)
FROM products WHERE TRIM(IFNULL(subcategory,'')) = ''
UNION ALL
SELECT 'orders.status', COUNT(*)
FROM orders WHERE TRIM(IFNULL(status,'')) = ''
UNION ALL
SELECT 'orders.channel', COUNT(*)
FROM orders WHERE TRIM(IFNULL(channel,'')) = ''
UNION ALL
SELECT 'subscriptions.plan_name', COUNT(*)
FROM subscriptions WHERE TRIM(IFNULL(plan_name,'')) = ''
UNION ALL
SELECT 'subscriptions.payment_method', COUNT(*)
FROM subscriptions WHERE TRIM(IFNULL(payment_method,'')) = ''
UNION ALL
SELECT 'support_tickets.category', COUNT(*)
FROM support_tickets WHERE TRIM(IFNULL(category,'')) = ''
UNION ALL
SELECT 'support_tickets.priority', COUNT(*)
FROM support_tickets WHERE TRIM(IFNULL(priority,'')) = '';


-- CONSISTENCY CHECKS
-- DISTINCT VALUE AUDIT
SELECT DISTINCT category FROM products;

SELECT DISTINCT channel FROM orders;

SELECT DISTINCT payment_method FROM subscriptions;

SELECT DISTINCT priority FROM support_tickets;

SELECT city, COUNT(*) AS customer_count
FROM customers
GROUP BY city
ORDER BY customer_count DESC;

SELECT country, COUNT(*) AS customer_count
FROM customers
GROUP BY country
ORDER BY customer_count DESC;

SELECT DISTINCT status FROM orders;


-- REFERENTIAL INTEGRITY CHECK
-- Identify orphan records that can lead to inaccurate
-- joins and reporting inconsistencies.

-- Orders without Customers 
SELECT *
FROM orders o LEFT JOIN customers c
ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Orders without Products 
SELECT *
FROM orders o
LEFT JOIN products p
ON o.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Subscriptions without Customers 
SELECT *
FROM subscriptions s
LEFT JOIN customers c
ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- VALIDITY CHECKS 
-- Selling Price less than Cost Price
SELECT *
FROM products
WHERE selling_price < cost_price;

-- Subscription ending before start
SELECT *
FROM subscriptions
WHERE end_date < start_date;

-- Ticket resolved before creation
SELECT *
FROM support_tickets
WHERE resolved_date < created_date;


-- BUSINESS RULE VALIDATION
-- Orders Before Customer Signup
SELECT *
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
WHERE o.order_date < c.signup_date;
-- Customers are expected to place orders after signup.
-- Records returned by this query should be reviewed
-- with business stakeholders before any corrective action.

-- Future Orders
SELECT *
FROM orders
WHERE order_date > CURDATE();

-- Future Signup Dates
SELECT *
FROM customers
WHERE signup_date > CURDATE();

-- Future Ticket Creation
SELECT *
FROM support_tickets
WHERE created_date > CURDATE();


-- -- FLAG ISSUE 
-- Issue Classification Layer
-- Records returned as Review Required
-- should be investigated before KPI creation.
SELECT
    o.*,
    c.signup_date,
    CASE
        WHEN o.order_date < c.signup_date
        THEN 'Review Required'
        ELSE 'Valid'
    END AS validation_status
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id;


-- DATASET SUMMARY
SELECT 'customers' AS table_name, COUNT(*) AS total_records
FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'subscriptions', COUNT(*) FROM subscriptions
UNION ALL
SELECT 'support_tickets', COUNT(*) FROM support_tickets;


-- AUDIT SUMMARY 
SELECT
'Orders Before Signup' AS issue,
COUNT(*) AS affected_records
FROM orders o
JOIN customers c
ON o.customer_id=c.customer_id
WHERE o.order_date < c.signup_date
UNION ALL
SELECT
'Products Below Cost',
COUNT(*)
FROM products
WHERE selling_price < cost_price
UNION ALL
SELECT
'Subscriptions Ending Before Start',
COUNT(*)
FROM subscriptions
WHERE end_date < start_date
UNION ALL
SELECT
'Tickets Resolved Before Creation',
COUNT(*)
FROM support_tickets
WHERE resolved_date < created_date
UNION ALL
SELECT
'Future Orders',
COUNT(*)
FROM orders
WHERE order_date > CURDATE()
UNION ALL
SELECT
'Future Signup Dates',
COUNT(*)
FROM customers
WHERE signup_date > CURDATE();