-- DATA REMEDIATION ACTIONS
-- Execute corrective actions identified during Data Quality Audit.

-- Run only after reviewing audit findings.

SET SQL_SAFE_UPDATES = 0; 

DELETE FROM customers
WHERE
IFNULL(TRIM(customer_name),'') = ''
AND IFNULL(TRIM(email),'') = ''
AND IFNULL(TRIM(city),'') = ''
AND IFNULL(TRIM(country),'') = '';

-- PRODUCTS
DELETE FROM products
WHERE
IFNULL(TRIM(product_name),'') = ''
AND IFNULL(TRIM(category),'') = '';

-- ORDERS
DELETE FROM orders
WHERE
customer_id IS NULL
AND product_id IS NULL
AND quantity IS NULL
AND unit_price IS NULL;

-- SUBSCRIPTIONS
DELETE FROM subscriptions
WHERE
customer_id IS NULL
AND IFNULL(TRIM(plan_name),'') = ''
AND monthly_fee IS NULL
AND IFNULL(TRIM(payment_method),'') = '';

-- SUPPORT TICKETS
DELETE FROM support_tickets
WHERE
customer_id IS NULL
AND IFNULL(TRIM(category),'') = ''
AND IFNULL(TRIM(priority),'') = ''
AND csat_score IS NULL;

SET SQL_SAFE_UPDATES = 1;
