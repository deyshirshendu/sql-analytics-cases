use sisudb;

-- 1. Retrieve the second highest salary from a table of employees

-- Create the table
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    salary INT
);

-- Insert sample data
INSERT INTO employees (emp_id, emp_name, salary) VALUES
(101, 'Alice', 60000),
(102, 'Bob', 75000),
(103, 'Carol', 50000),
(104, 'Dave', 85000),
(105, 'Emma', 75000);

SELECT * from employees

-- solution 1
SELECT MAX(salary) as second_highest_salary
FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees)

-- solution 2
WITH Ranked_Salary as (
	SELECT salary, DENSE_RANK() OVER(ORDER BY salary DESC) as ranking
	FROM employees
)
SELECT DISTINCT salary
FROM Ranked_Salary
WHERE ranking = 2


-- 2. Find duplicate records in a table

-- Create the table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(50),
    email VARCHAR(100)
);

-- Insert sample data
INSERT INTO customers (customer_id, name, email) VALUES
(1, 'Alice', 'alice@example.com'),
(2, 'Bob', 'bob@example.com'),
(3, 'Alice', 'alice@example.com'),  -- duplicate
(4, 'Carol', 'carol@example.com'),
(5, 'Dave', 'dave@example.com'),
(6, 'Bob', 'bob@example.com');      -- duplicate

SELECT * FROM customers

-- solution 1
WITH counted_set AS (
	SELECT name, email, COUNT(*) AS cnt
	FROM customers
	GROUP BY name, email
),
full_customers_data AS (
	SELECT c.*, s.cnt
	FROM customers c
	LEFT JOIN counted_set s
	ON c.name = s.name AND c.email = s.email
)
SELECT customer_id, name, email
FROM full_customers_data
WHERE cnt > 1;



-- 3. Get the count of customers who placed more than 3 orders in a month

-- Create the orders table
DROP TABLE IF EXISTS orders
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE
);

-- Insert sample orders
INSERT INTO orders (order_id, customer_id, order_date) VALUES
(1, 101, '2024-06-01'),
(2, 101, '2024-06-10'),
(3, 101, '2024-06-15'),
(4, 101, '2024-06-25'),
(5, 102, '2024-06-01'),
(6, 102, '2024-06-05'),
(7, 103, '2024-06-08'),
(8, 104, '2024-07-01'),
(9, 104, '2024-07-10'),
(10, 104, '2024-07-15'),
(11, 104, '2024-07-20'),
(12, 105, '2024-07-05');


SELECT * FROM orders

-- solution 1
SELECT COUNT(*) as no_of_Customer_with_more_than_2_order
FROM (
	SELECT customer_id, MONTH(order_date) as order_month, COUNT(*) as frequency
	FROM orders
	GROUP BY customer_id, MONTH(order_date)
	HAVING COUNT(*) > 3
) s


-- 4. Find customers who placed at least one order in January but did not place any orders in February.

DROP TABLE IF EXISTS orders
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE
);

INSERT INTO orders (order_id, customer_id, order_date) VALUES
(1, 101, '2025-01-05'),
(2, 101, '2025-01-20'),
(3, 101, '2025-02-10'),
(4, 102, '2025-01-12'),
(5, 103, '2025-02-02'),
(6, 104, '2025-01-08'),
(7, 104, '2025-02-15'),
(8, 105, '2025-01-18'),
(9, 106, '2025-02-24'),
(10, 106, '2025-02-10');


Select * from orders

-- solution 1

SELECT customer_id FROM orders WHERE MONTH(order_date) = 1
EXCEPT
SELECT customer_id FROM orders WHERE MONTH(order_date) = 2;


/*
UNION -- A Union B
INTERSECT -- A Intersection B
EXCEPT -- Set(A) - Set(B)
CROSS JOIN -- Cartersian Product of A and B (all combinations)
*/

-- Solution 2

SELECT DISTINCT customer_id
FROM orders
WHERE MONTH(order_date) = 1
  AND customer_id NOT IN (
      SELECT customer_id
      FROM orders
      WHERE MONTH(order_date) = 2
  );


-- 5. Write a query to pivot rows into columns — for example, show monthly sales totals per product in separate columns.

DROP TABLE IF EXISTS sales
CREATE TABLE sales (
    product_id INT,
    order_date DATE,
    sales_amount INT
);

INSERT INTO sales (product_id, order_date, sales_amount) VALUES
(101, '2025-01-05', 100),
(101, '2025-01-15', 150),
(101, '2025-02-10', 200),
(102, '2025-01-20', 300),
(102, '2025-02-18', 250),
(102, '2025-03-05', 350),
(103, '2025-03-15', 400),
(103, '2025-01-25', 500);

SELECT * FROM sales

-- SOLUTION 1

SELECT product_id,
	SUM(CASE WHEN MONTH(order_date) = 1 THEN sales_amount ELSE 0 END) AS Jan_Sales,
	SUM(CASE WHEN MONTH(order_date) = 2 THEN sales_amount ELSE 0 END) AS Feb_Sales,
	SUM(CASE WHEN MONTH(order_date) = 3 THEN sales_amount ELSE 0 END) AS Mar_Sales
FROM sales
GROUP BY product_id

-- SOLUTION 2 USING PIVOT

SELECT product_id,
	[1] as Jan_Sales,
	[2] as Feb_Sales,
	[3] as Mar_Sales
FROM (
	SELECT product_id, MONTH(order_date) as Order_Month, sales_amount
	FROM sales
) AS SOURCE 
PIVOT (
	SUM(sales_amount)
	FOR Order_month IN ([1],[2],[3])
) AS pivot_table;


-- 6. From a transactions table, calculate the 3-month moving average of revenue.

DROP TABLE IF EXISTS transactions
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    transaction_date DATE,
    revenue INT
);

INSERT INTO transactions (transaction_id, transaction_date, revenue) VALUES
(1, '2024-01-15', 1000),
(2, '2024-02-10', 1200),
(3, '2024-02-20', 800),
(4, '2024-03-12', 1500),
(5, '2024-04-05', 2000),
(6, '2024-04-18', 1000),
(7, '2024-05-01', 1700),
(8, '2024-05-28', 900);

SELECT * FROM transactions

WITH monthly_transactions AS (
	SELECT MONTH(transaction_date) as order_month, SUM(revenue) as total_revenue
	FROM transactions
	GROUP BY MONTH(transaction_date)
)
SELECT 
	CASE order_month 
		WHEN 1 THEN 'Jan'
		WHEN 2 THEN 'Feb'
		WHEN 3 THEN 'Mar'
		WHEN 4 THEN 'Apr'
		WHEN 5 THEN 'May'
	END AS MONTH_NAME, 
	total_revenue,
	AVG(total_revenue) OVER (
		ORDER BY order_month 
		ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
	) AS rolling_average
FROM monthly_transactions


-- 7. Find customers who placed an order in every month of 2024.

DROP TABLE IF EXISTS orders
CREATE TABLE orders (
    order_id INT,
    customer_id INT,
    order_date DATE
);

INSERT INTO orders (order_id, customer_id, order_date) VALUES
(1, 101, '2024-01-15'),
(2, 101, '2024-02-10'),
(3, 101, '2024-03-12'),
(4, 101, '2024-04-05'),
(5, 101, '2024-05-01'),
(6, 101, '2024-06-18'),
(7, 101, '2024-07-25'),
(8, 101, '2024-08-02'),
(9, 101, '2024-09-11'),
(10, 101, '2024-10-09'),
(11, 101, '2024-11-03'),
(12, 101, '2024-12-21'),
(13, 102, '2024-01-12'),
(14, 102, '2024-02-10'),
(15, 102, '2024-03-22'),
(16, 103, '2024-01-08');

SELECT * FROM orders

WITH count_orders AS (
	SELECT customer_id, FORMAT(order_date, 'MMM') AS order_month, COUNT(*) AS cnt
	FROM orders
	GROUP BY customer_id, FORMAT(order_date, 'MMM')
)
SELECT customer_id
FROM count_orders
GROUP BY customer_id
HAVING COUNT(*) = 12

-- Better and safer solution
WITH count_orders AS (
	SELECT customer_id, MONTH(order_date) AS order_month
	FROM orders
	WHERE YEAR(order_date) = 2024
	GROUP BY customer_id, MONTH(order_date)
)
SELECT customer_id
FROM count_orders
GROUP BY customer_id
HAVING COUNT(DISTINCT order_month) = 12;


-- 8. From an orders table, find the first and last order date per customer.
DROP TABLE IF EXISTS orders
CREATE TABLE orders (
    order_id INT,
    customer_id INT,
    order_date DATE
);

INSERT INTO orders (order_id, customer_id, order_date) VALUES
(1, 101, '2024-01-15'),
(2, 101, '2024-03-10'),
(3, 101, '2024-04-05'),
(4, 102, '2024-02-12'),
(5, 102, '2024-05-01'),
(6, 103, '2024-01-08');


SELECT * FROM orders

WITH min_order_dates AS (
	SELECT customer_id, MIN(order_date) AS first_order_date
	FROM orders
	GROUP BY customer_id
),
max_order_dates AS (
	SELECT customer_id, MAX(order_date) AS last_order_date
	FROM orders
	GROUP BY customer_id
)
SELECT M.customer_id, M.first_order_date AS first_order_date, N.last_order_date AS last_order_date
FROM min_order_dates M
JOIN max_order_dates N
ON M.customer_id = N.customer_id


-- EASY WAY OUT
SELECT 
    customer_id,
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date
FROM orders
GROUP BY customer_id;


-- 9. Rank products within each category based on total sales (highest to lowest).

DROP TABLE IF EXISTS product_sales
CREATE TABLE product_sales (
    product_id INT,
    category VARCHAR(50),
    sales_amount INT
);

INSERT INTO product_sales (product_id, category, sales_amount) VALUES
(1, 'Electronics', 5000),
(2, 'Electronics', 3000),
(3, 'Electronics', 7000),
(4, 'Clothing', 2000),
(5, 'Clothing', 2500),
(6, 'Clothing', 2000),
(7, 'Furniture', 9000),
(8, 'Furniture', 8500);

SELECT * FROM product_sales;


SELECT product_id, category, 
	DENSE_RANK() OVER(PARTITION BY category ORDER BY sales_amount DESC) AS ranking
FROM product_sales;


-- BETTER AND SAFER WAY, in case a product has multiple entries
WITH sales_agg AS (
  SELECT product_id, category, SUM(sales_amount) AS total_sales
  FROM product_sales
  GROUP BY product_id, category
)
SELECT product_id, category, total_sales,
       DENSE_RANK() OVER (PARTITION BY category ORDER BY total_sales DESC) AS ranking
FROM sales_agg;


-- 10. Given a table with login and logout timestamps, calculate session duration per user, and then find the average session duration per user.

DROP TABLE IF EXISTS user_sessions
CREATE TABLE user_sessions (
    session_id INT,
    user_id INT,
    login_time DATETIME,
    logout_time DATETIME
);

INSERT INTO user_sessions (session_id, user_id, login_time, logout_time) VALUES
(1, 101, '2024-06-01 09:00:00', '2024-06-01 10:15:00'),
(2, 101, '2024-06-02 14:30:00', '2024-06-02 15:00:00'),
(3, 102, '2024-06-01 08:45:00', '2024-06-01 09:15:00'),
(4, 102, '2024-06-03 10:00:00', '2024-06-03 10:30:00'),
(5, 103, '2024-06-02 18:00:00', '2024-06-02 18:50:00');

SELECT * FROM user_sessions

WITH sessionwise_duration AS (
	SELECT *, CAST(DATEDIFF(MINUTE, login_time, logout_time) AS float) AS session_duration
	FROM user_sessions
)
SELECT user_id, AVG(session_duration) AS avg_session_duration
FROM sessionwise_duration
GROUP BY user_id
