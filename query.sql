-- Database Creation
CREATE DATABASE bs23_sql;

-- Table Creation
CREATE TABLE Customers(
    customer_id BIGSERIAL NOT NULL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    customer_email VARCHAR(50) NOT NULL,
    join_date DATE NOT NULL
);

CREATE TABLE Employees(
    employee_id BIGSERIAL NOT NULL PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    hire_date DATE NOT NULL,
    department VARCHAR(50) NOT NULL
);

CREATE TABLE Products(
    product_id BIGSERIAL NOT NULL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price FLOAT(6)
);

CREATE TABLE Sales(
    sale_id BIGSERIAL NOT NULL PRIMARY KEY,
    product_id BIGSERIAL NOT NULL,
    employee_id BIGSERIAL NOT NULL,
    customer_id BIGSERIAL NOT NULL,
    sale_date DATE NOT NULL,
    quantity INT NOT NULL,
    CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES Products(product_id),
    CONSTRAINT fk_employee FOREIGN KEY (employee_id) REFERENCES EMPLOYEES (employee_id),
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES Customers (customer_id)
 );

-- TASKS
-- 1. Process the given data to only keep the top 50 selling products.

-- Temp table of top 50 products 
CREATE TEMP TABLE top_50_products AS 
SELECT product_id, product_name, sum(quantity) as total_quantity 
FROM sales 
INNER JOIN products USING(product_id) 
GROUP BY product_id, product_name 
ORDER BY total_quantity DESC 
limit 50; 

-- Now select only these top 50 product data from sales table 
CREATE TEMP TABLE top_50_products_only_filtered_table AS
SELECT * FROM sales WHERE product_id IN (SELECT product_id FROM top_50_products)


-- 2. Compute the total revenue and costs associated with the top 50 products.

-- First we added a cost column to do the calculation. We generate random numbers 
-- less than 100 with 6 decimal points which is less than product price. 

Alter TABLE products ADD COLUMN product_cost Numeric;

UPDATE products 
SET product_cost = ROUND(random()::numeric * 100, 6);

-- Then computing the total cost and revenue for each product 
CREATE TEMP TABLE top_30_products_info AS 
SELECT p.product_name, sum(p.price * s.quantity) AS total_revenue 
, sum(p.product_cost * s.quantity) AS total_cost
FROM products AS p 
INNER JOIN sales AS s USING(product_id)
GROUP BY product_name 

-- 3. Calculate gross profit margins for each of these products
SELECT *, Round((((total_revenue - total_cost)/total_revenue) * 100)::numeric, 2) AS gross_profit_margin 
FROM top_30_products_info 


-- 4. Project future revenue for the next quarter based on historical trends.

-- First I create a temp table for showing the monthly revenue 
CREATE TEMP TABLE monthly_revenue as 
    SELECT date_trunc('month', s.sale_date) as month,
    sum(p.price * s.quantity) AS revenue
    FROM sales as s 
    INNER JOIN products as p USING(product_id)
    WHERE s.sale_date >= CURRENT_DATE - INTERVAL '12 month'
    GROUP BY date_trunc('month',s.sale_date)
    ORDER BY date_trunc('month',s.sale_date); 

-- Showed the growth, growth_rate percentage by month and year
SELECT  month,
        revenue,
        revenue - LAG (revenue) OVER (ORDER BY month) AS revenue_growth,
        ROUND(((revenue - LAG (revenue) OVER (ORDER BY month ASC))/LAG (revenue) OVER (ORDER BY month ASC)*100)::numeric,2) AS      
        revenue_percentage_growth,
        LEAD (revenue, 12) OVER (ORDER BY month) AS next_year_revenue
    FROM
        monthly_revenue