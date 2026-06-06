CREATE DATABASE streamcart;
USE streamcart;

-- customers 
CREATE TABLE customers( 
customer_id INT PRIMARY KEY,
customer_name VARCHAR(100),
email VARCHAR(100),
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
cost_price DECIMAL(10,2),
selling_price DECIMAL(10,2),
launch_date DATE
);

-- orders 
CREATE TABLE orders(
order_id INT PRIMARY KEY,
customer_id INT,
product_id INT,
order_date DATE,
quantity INT,
unit_price DECIMAL(10,2),
discount_pct DECIMAL(5,2),
status VARCHAR(20),
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
monthly_fee DECIMAL(10,2),
payment_method VARCHAR(30),
FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
);

-- support ticket 
CREATE TABLE support_tickets(
ticket_id INT PRIMARY KEY,
customer_id INT,
created_date DATE,
resolved_date DATE,
priority VARCHAR(20),
category VARCHAR(50),
csat_score INT,
FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
);

SHOW TABLES;
