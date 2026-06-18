USE streamcart;

-- CHURN RISK ANALYSIS 
-- Helps retention teams proactively target customers before they churn.
-- CHURN RISK ANALYSIS
WITH max_order_date AS(
SELECT MAX(order_date) AS latest_order_date
FROM orders
),
customer_metrics AS
(
SELECT customer_id,
MAX(order_date) AS last_order_date,
ROUND(SUM(revenue),2) AS lifetime_revenue
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY customer_id
)
SELECT c.customer_id, c.customer_name, cm.lifetime_revenue,
DATEDIFF(m.latest_order_date, cm.last_order_date) AS days_since_last_order,
CASE
WHEN DATEDIFF(m.latest_order_date,cm.last_order_date) > 180 THEN 'High Risk'
WHEN DATEDIFF(m.latest_order_date,cm.last_order_date) > 90 THEN 'Medium Risk'
ELSE 'Low Risk'
END AS churn_risk
FROM customer_metrics cm
JOIN customers c
ON cm.customer_id=c.customer_id
CROSS JOIN max_order_date m
ORDER BY days_since_last_order DESC;

-- RFM SEGMENTATION
-- R = Recency
-- F = Frequency
-- M = Monetary
-- RFM BASE ANALYSIS
WITH max_order_date AS(
SELECT MAX(order_date) AS latest_order_date 
FROM orders
),
rfm_base AS
(
SELECT customer_id, MAX(order_date) AS last_order_date, COUNT(DISTINCT order_id) AS frequency,
ROUND(SUM(revenue), 2) AS monetary
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY customer_id
)
SELECT r.customer_id,
DATEDIFF(m.latest_order_date, r.last_order_date) AS recency,
r.frequency, r.monetary
FROM rfm_base r
CROSS JOIN max_order_date m;

-- RFM SEGMENTATION
WITH max_order_date AS(
SELECT MAX(order_date) AS latest_order_date
FROM orders
),
rfm_base AS
(
SELECT customer_id, MAX(order_date) AS last_order_date,
COUNT(DISTINCT order_id) AS frequency,
SUM(revenue) AS monetary
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY customer_id
),
rfm_scores AS
(
SELECT customer_id,
NTILE(4)
OVER(
ORDER BY DATEDIFF((SELECT latest_order_date FROM max_order_date),last_order_date) ASC) AS r_score,
NTILE(4)
OVER(
ORDER BY frequency DESC) AS f_score,
NTILE(4)
OVER(
ORDER BY monetary DESC) AS m_score
FROM rfm_base
)
SELECT customer_id, r_score, f_score, m_score,
CONCAT(r_score, f_score, m_score) AS rfm_code,
CASE
WHEN r_score=4 AND f_score>=3 AND m_score>=3 THEN 'Champion'
WHEN r_score>=3 AND f_score>=3 THEN 'Loyal Customer'
WHEN r_score<=2 AND f_score<=2 THEN 'At Risk'
ELSE 'Regular Customer'
END AS customer_segment
FROM rfm_scores;
-- RFM is a behavioral segmentation technique that classifies customers based on recency, purchase frequency, 
-- and monetary contribution. It helps prioritize retention campaigns, 
-- identify high-value customers, and target churn-risk segments without requiring predictive modeling.


-- CUSTOMER AQUISITION ANALYSIS
-- How many customers continue purchasing?
WITH first_purchase AS(
SELECT customer_id,
MIN(order_date) AS first_order
FROM orders
WHERE status='Completed'
GROUP BY customer_id
)
SELECT
YEAR(first_order) AS cohort_year,
MONTH(first_order) AS cohort_month,
COUNT(*) AS customers
FROM first_purchase
GROUP BY YEAR(first_order), MONTH(first_order)
ORDER BY cohort_year, cohort_month;


-- COHORT ANALYSIS
-- Monthly Cohort
WITH customer_cohort AS(
SELECT customer_id,
DATE_FORMAT(MIN(order_date),'%Y-%m') AS cohort_month
FROM orders
WHERE status='Completed'
GROUP BY customer_id
)
SELECT cohort_month,
COUNT(*) AS customers
FROM customer_cohort
GROUP BY cohort_month
ORDER BY cohort_month;
-- A cohort groups customers based on a shared starting event, such as their first purchase month, 
-- allowing us to evaluate retention behavior over time.


-- CUSTOMER SPENDING TIERS
-- How are customers distributed by spending power?
-- CUSTOMER SPENDING TIERS
WITH customer_spend AS(
SELECT customer_id,
ROUND(SUM(revenue),2) AS total_spend
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY customer_id
),
tiered_customers AS(
SELECT customer_id, total_spend,
NTILE(5)
OVER(ORDER BY total_spend) AS spending_tier
FROM customer_spend
)
SELECT customer_id, total_spend, spending_tier,
CASE
WHEN spending_tier=5 THEN 'VIP'
WHEN spending_tier=4 THEN 'Premium'
WHEN spending_tier=3 THEN 'Standard'
ELSE 'Low Value'
END AS customer_class
FROM tiered_customers;

-- REVENUE MOMENTUM
-- Month-over-Month Revenue Growth
WITH monthly_revenue AS(
SELECT YEAR(order_date) AS order_year, MONTH(order_date) AS order_month, SUM(revenue) AS revenue
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT order_year, order_month, revenue,
LAG(revenue)
OVER(
ORDER BY order_year,order_month
) AS previous_month_revenue,
ROUND((revenue - LAG(revenue)OVER(ORDER BY order_year,order_month)) / LAG(revenue)OVER(ORDER BY order_year,order_month)*100,2) AS growth_pct
FROM monthly_revenue;


-- CUSTOMER PURCHASE TREND
-- Purchase Gap Analysis
WITH purchase_history AS(
SELECT customer_id, order_date,
LAG(order_date)
OVER(
PARTITION BY customer_id
ORDER BY order_date
) AS previous_order_date
FROM orders
WHERE status='Completed'
)
SELECT customer_id, order_date, previous_order_date,
DATEDIFF(order_date, previous_order_date) AS days_between_orders
FROM purchase_history;


-- TOP PRODUCTS BY CATEGORY
WITH product_profit AS(
SELECT category, product_name, SUM(profit) AS total_profit
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY category, product_name
)
SELECT * FROM(
SELECT category, product_name, total_profit,
ROUND(100 * total_profit / SUM(total_profit) OVER(PARTITION BY category), 2) AS category_profit_pct,
DENSE_RANK()
OVER( PARTITION BY category
ORDER BY total_profit DESC) AS category_rank
FROM product_profit
) x WHERE category_rank <= 3;


-- PARETO ANALYSIS
WITH customer_revenue AS(
SELECT customer_id, SUM(revenue) AS total_revenue
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY customer_id
)
SELECT customer_id, total_revenue,
ROUND(100 * SUM(total_revenue)
OVER(ORDER BY total_revenue DESC) / SUM(total_revenue) OVER(), 2) AS cumulative_revenue_pct
FROM customer_revenue;


-- RUNNING REVENUE TOTAL
WITH monthly_revenue AS
(
SELECT
YEAR(order_date) AS order_year,
MONTH(order_date) AS order_month,
SUM(revenue) AS revenue
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY
YEAR(order_date),
MONTH(order_date)
)
SELECT order_year, order_month, revenue,
SUM(revenue)
OVER(ORDER BY order_year,order_month
) AS cumulative_revenue
FROM monthly_revenue;


-- 3 MONTH MOVING AVERAGE
WITH monthly_revenue AS
(
SELECT
YEAR(order_date) AS order_year,
MONTH(order_date) AS order_month,
SUM(revenue) AS revenue
FROM vw_sales_detail
WHERE status='Completed'
GROUP BY
YEAR(order_date),
MONTH(order_date)
)
SELECT order_year, order_month, revenue,
ROUND(AVG(revenue)OVER(
ORDER BY order_year,order_month
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_3_month
FROM monthly_revenue;