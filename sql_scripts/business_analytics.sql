USE streamcart;

-- REVENUE ANALYTICS
-- Revenue Trend Analysis
SELECT
YEAR(order_date) AS order_year,
MONTH(order_date) AS order_month,
ROUND(SUM(revenue), 2) AS revenue
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY order_year, order_month;

-- Revenue by Category
SELECT
category,
ROUND(SUM(revenue), 2) AS revenue
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY category
ORDER BY revenue DESC;

-- Revenue by Channel
SELECT
channel,
ROUND(SUM(revenue), 2) AS revenue
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY channel
ORDER BY revenue DESC;

-- Revenue by City
SELECT
city,
ROUND(SUM(revenue), 2) AS revenue
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY city
ORDER BY revenue DESC;


-- PROFITABILITY ANALYTICS
-- Most Profitable Categories
SELECT
category,
ROUND(SUM(profit), 2) AS profit
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY category
ORDER BY profit DESC;

-- Profit Margin by Category
SELECT
category,
ROUND(SUM(profit),2) AS total_profit,
ROUND(100 *SUM(profit) / SUM(revenue), 2) AS margin_pct
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY category
ORDER BY margin_pct DESC;


-- CUSTOMER ANALYTICS
-- Highest Value Customers
SELECT
customer_id,
customer_name,
ROUND(SUM(revenue), 2) AS revenue
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY customer_id, customer_name
ORDER BY revenue DESC
LIMIT 5;

-- Customer Lifetime Value Ranking
SELECT
customer_id, customer_name,
ROUND(SUM(revenue), 2) AS clv,
RANK() OVER(
ORDER BY SUM(revenue) DESC) AS customer_rank
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY customer_id, customer_name
LIMIT 10;

-- Customer Order Frequency
SELECT customer_id, customer_name, COUNT(DISTINCT order_id) AS total_orders
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY customer_id, customer_name
ORDER BY total_orders DESC;

-- Customer Segmentation
SELECT customer_id, customer_name,
ROUND(SUM(revenue), 2) AS total_spend,
CASE
WHEN SUM(revenue) >= 5000 THEN 'High Value'
WHEN SUM(revenue) >= 2000 THEN 'Medium Value' 
ELSE 'Low Value'
END AS customer_segment
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY customer_id, customer_name;

-- SUBSCRIPTION ANALYTICS
-- Revenue by Plan
SELECT plan_name, COUNT(*) AS subscribers,
ROUND(SUM(monthly_fee), 2) AS revenue
FROM subscriptions
GROUP BY plan_name
ORDER BY revenue DESC;

-- Plan Distribution
SELECT plan_name, COUNT(*) AS subscribers,
ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS subscriber_pct
FROM subscriptions
GROUP BY plan_name;

-- Payment Method Analysis
SELECT payment_method, COUNT(*) AS subscriptions,
ROUND(AVG(monthly_fee), 2) AS avg_fee
FROM subscriptions
GROUP BY payment_method
ORDER BY subscriptions DESC;

-- SUPPORT ANALYTICS
-- Ticket Volume by Category
SELECT category, COUNT(*) AS total_tickets
FROM support_tickets
GROUP BY category
ORDER BY total_tickets DESC;

-- CSAT by Category
SELECT category,
ROUND(AVG(csat_score), 2) AS avg_csat
FROM support_tickets
GROUP BY category
ORDER BY avg_csat DESC;

-- Average Resolution Time
SELECT priority,
ROUND(AVG(DATEDIFF(resolved_date, created_date)),2) AS avg_resolution_days
FROM support_tickets
GROUP BY priority
ORDER BY avg_resolution_days;

-- SLA Breach Analysis
SELECT priority, COUNT(*) AS total_tickets,
SUM(
CASE
WHEN priority='Critical' AND DATEDIFF(resolved_date,created_date) > 1 THEN 1
WHEN priority='High' AND DATEDIFF(resolved_date,created_date) > 3 THEN 1
WHEN priority='Medium' AND DATEDIFF(resolved_date,created_date) > 7 THEN 1
ELSE 0
END) AS breached_tickets
FROM support_tickets
GROUP BY priority;


-- DISCOUNT ANALYTICS
-- Revenue by Discount Band
SELECT
CASE
WHEN discount_pct = 0 THEN 'No Discount'
WHEN discount_pct <= 10 THEN '0-10%'
WHEN discount_pct <= 20 THEN '11-20%'
ELSE '20%+'
END AS discount_band,
ROUND(SUM(revenue), 2) AS revenue
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY discount_band;

-- Average Discount by Channel
SELECT channel,
ROUND(AVG(discount_pct), 2) AS avg_discount
FROM vw_sales_detail
GROUP BY channel
ORDER BY avg_discount DESC;


-- CUSTOMER ACQUISITION ANALYTICS
-- Monthly Signup Trend
SELECT YEAR(signup_date) AS signup_year, MONTH(signup_date) AS signup_month,
COUNT(*) AS new_customers
FROM customers
GROUP BY YEAR(signup_date), MONTH(signup_date)
ORDER BY signup_year, signup_month;

-- Active vs Inactive Customers
SELECT is_active, COUNT(*) AS customers
FROM customers
GROUP BY is_active;

-- Plan Type Adoption
SELECT plan_type, COUNT(*) AS customers
FROM customers
GROUP BY plan_type
ORDER BY customers DESC;