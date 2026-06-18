CREATE DATABASE streamcart;
USE streamcart;

-- CREATE TABLES AND CONTRAINTS 
-- customers 
CREATE TABLE customers( 
customer_id INT PRIMARY KEY,
customer_name VARCHAR(100),
email VARCHAR(100) UNIQUE,
city VARCHAR(50),
country VARCHAR(50),
signup_date DATE,
plan_type VARCHAR(20),
is_active BOOLEAN );

-- product 
CREATE TABLE products(
product_id INT PRIMARY KEY,
product_name VARCHAR(100),
category VARCHAR(50),
subcategory VARCHAR(50),
cost_price DECIMAL(10,2) CHECK(cost_price >= 0),
selling_price DECIMAL(10,2) CHECK(selling_price >=0),
launch_date DATE
);

-- orders 
CREATE TABLE orders(
order_id INT PRIMARY KEY,
customer_id INT,
product_id INT,
order_date DATE,
quantity INT CHECK(quantity >0),
unit_price DECIMAL(10,2) CHECK(unit_price >= 0),
discount_pct DECIMAL(5,2) CHECK(discount_pct BETWEEN 0 AND 100),
status VARCHAR(20) CHECK (
status IN (
        'Completed',
        'Returned',
        'Pending',
        'Cancelled')),
channel VARCHAR(20),

FOREIGN KEY(customer_id) REFERENCES customers(customer_id),
FOREIGN KEY(product_id) REFERENCES products(product_id)
);

-- subscription
CREATE TABLE subscriptions(
sub_id INT PRIMARY KEY,
customer_id INT,
plan_name VARCHAR(30),
start_date DATE,
end_date DATE,
monthly_fee DECIMAL(10,2) CHECK(monthly_fee >=0),
payment_method VARCHAR(30),

FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
);

-- support ticket 
CREATE TABLE support_tickets(
ticket_id INT PRIMARY KEY,
customer_id INT,
created_date DATE,
resolved_date DATE,
priority VARCHAR(20) CHECK (
    priority IN (
        'Low',
        'Medium',
        'High',
        'Critical')),
category VARCHAR(50),
csat_score INT CHECK(csat_score BETWEEN 1 AND 5),

FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE dim_date (
    date_key DATE PRIMARY KEY,
    year_num INT,
    quarter_num INT,
    month_num INT,
    month_name VARCHAR(20),
    week_num INT,
    day_num INT,
    day_name VARCHAR(20),
    is_weekend BOOLEAN
);

SHOW TABLES;

-- CREATE INDEXES 
CREATE INDEX idx_orders_customer
ON orders(customer_id);

CREATE INDEX idx_orders_product
ON orders(product_id);

CREATE INDEX idx_orders_date
ON orders(order_date);

CREATE INDEX idx_tickets_customer
ON support_tickets(customer_id);

CREATE INDEX idx_subscription_customer
ON subscriptions(customer_id);

CREATE INDEX idx_orders_status_date
ON orders(status, order_date);

-- CREATE VIEWS 
CREATE VIEW vw_sales_detail AS
SELECT
    o.order_id,
    o.order_date,
    o.status,
    o.channel,

    c.customer_id,
    c.customer_name,
    c.city,
    c.country,
    c.signup_date,
    c.plan_type,
    c.is_active,

    p.product_id,
    p.product_name,
    p.category,
    p.subcategory,

    o.quantity,
    o.unit_price,
    o.discount_pct,

    ROUND(
        o.quantity *
        o.unit_price *
        (1 - o.discount_pct/100),
        2
    ) AS revenue,

    ROUND(
        (p.selling_price - p.cost_price)
        * o.quantity,
        2
    ) AS profit

FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
JOIN products p
ON o.product_id = p.product_id;


CREATE VIEW vw_customer_summary AS
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    c.country,
    c.signup_date,
    c.plan_type,
    c.is_active,

    COUNT(DISTINCT o.order_id) AS total_orders,
    COALESCE(
    ROUND(
        SUM(
            o.quantity *
            o.unit_price *
            (1 - o.discount_pct/100))
            ,2)
            ,0) AS lifetime_spend,

    COALESCE(ROUND(AVG(
            o.quantity *
            o.unit_price *
            (1 - o.discount_pct/100)),2),0) AS avg_order_value,
    MAX(o.order_date) AS last_order_date

FROM customers c
LEFT JOIN orders o
ON c.customer_id=o.customer_id
GROUP BY
    c.customer_id,
    c.customer_name,
    c.city,
    c.country,
    c.signup_date,
    c.plan_type,
    c.is_active;
    
        
CREATE VIEW vw_subscription_summary AS
SELECT
    s.sub_id,
    s.customer_id,
    c.customer_name,
    c.city,

    s.plan_name,
    s.monthly_fee,

    s.payment_method,

    s.start_date,
    s.end_date,

    DATEDIFF(
        s.end_date,
        s.start_date
    ) AS subscription_days

FROM subscriptions s
JOIN customers c
ON s.customer_id=c.customer_id;


CREATE VIEW vw_support_summary AS
SELECT
    t.ticket_id,
    t.customer_id,

    c.customer_name,
    c.city,

    t.category,
    t.priority,
    t.csat_score,

    t.created_date,
    t.resolved_date,

    DATEDIFF(
        t.resolved_date,
        t.created_date
    ) AS resolution_days

FROM support_tickets t
JOIN customers c
ON t.customer_id=c.customer_id;

CREATE VIEW vw_churn_risk AS
WITH max_order_date AS
(
    SELECT MAX(order_date) AS latest_order_date
    FROM orders
),
customer_last_order AS
(
    SELECT customer_id,
           MAX(order_date) AS last_order_date
    FROM orders
    WHERE status='Completed'
    GROUP BY customer_id
)
SELECT
c.customer_id,
c.customer_name,
DATEDIFF(m.latest_order_date, clo.last_order_date) AS days_since_last_order,
CASE
    WHEN DATEDIFF(m.latest_order_date, clo.last_order_date) > 180 THEN 'High Risk'
    WHEN DATEDIFF(m.latest_order_date, clo.last_order_date) > 90 THEN 'Medium Risk'
    ELSE 'Low Risk'
END AS churn_risk
FROM customer_last_order clo
JOIN customers c
ON clo.customer_id = c.customer_id
CROSS JOIN max_order_date m;


CREATE VIEW vw_rfm_segments AS
WITH max_order_date AS
(
    SELECT MAX(order_date) AS latest_order_date
    FROM orders
),
rfm_base AS
(
    SELECT
        customer_id,
        MAX(order_date) AS last_order_date,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(revenue) AS monetary
    FROM vw_sales_detail
    WHERE status='Completed'
    GROUP BY customer_id
),
rfm_scores AS
(
    SELECT
        customer_id,

        NTILE(4) OVER(
            ORDER BY DATEDIFF(
                (SELECT latest_order_date FROM max_order_date),
                last_order_date
            ) ASC
        ) AS r_score,

        NTILE(4) OVER(
            ORDER BY frequency DESC
        ) AS f_score,

        NTILE(4) OVER(
            ORDER BY monetary DESC
        ) AS m_score

    FROM rfm_base
)
SELECT
customer_id,
r_score,
f_score,
m_score,
CASE
    WHEN r_score=4 AND f_score>=3 AND m_score>=3
        THEN 'Champion'

    WHEN r_score>=3 AND f_score>=3
        THEN 'Loyal Customer'

    WHEN r_score<=2 AND f_score<=2
        THEN 'At Risk'

    ELSE 'Regular Customer'
END AS customer_segment
FROM rfm_scores;


CREATE VIEW vw_customer_cohort AS
SELECT
customer_id,
DATE_FORMAT(
MIN(order_date),
'%Y-%m'
) AS cohort_month
FROM orders
WHERE status='Completed'
GROUP BY customer_id;


CREATE VIEW vw_customer_spending_tier AS
WITH customer_spend AS
(
    SELECT
    customer_id,
    ROUND(SUM(revenue),2) AS total_spend
    FROM vw_sales_detail
    WHERE status='Completed'
    GROUP BY customer_id
)
SELECT
customer_id,
total_spend,
NTILE(5) OVER(
ORDER BY total_spend
) AS spending_tier
FROM customer_spend;


SELECT * FROM vw_churn_risk;
SELECT * FROM vw_rfm_segments;
SELECT * FROM vw_customer_cohort;
SELECT * FROM vw_customer_spending_tier;