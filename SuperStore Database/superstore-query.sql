-------------------------------
--- PART 1. CREATE TABLE
-------------------------------
--- TABLE orders
CREATE TABLE IF NOT EXISTS orders (
    Row_ID INT PRIMARY KEY,
    Order_ID VARCHAR(20),
    Order_Date DATE,
    Ship_Date DATE,
    Ship_Mode VARCHAR(20),
    Customer_ID VARCHAR(10),
    Customer_Name VARCHAR(100),
	Segment VARCHAR(50),
    Country VARCHAR(50),
    City VARCHAR(50),
    State VARCHAR(50),
    Postal_Code VARCHAR(10),
    Region VARCHAR(10),
    Product_ID VARCHAR(20),
	Category VARCHAR(50),
    Sub_Category VARCHAR(50),
    Product_Name VARCHAR(255),
    Sales NUMERIC(10,2),
    Quantity SMALLINT,
    Discount NUMERIC(4,2),
    Profit NUMERIC(10,4)
);

COPY orders
FROM 'C:\Users\jingn\Documents\SQL\SuperStore SQL\superstore-orders.csv'
DELIMITER ','
CSV HEADER;

SELECT *
FROM orders;

--- TABLE returned 
CREATE TABLE IF NOT EXISTS returned (
    Order_ID VARCHAR(20) PRIMARY KEY,
	Returned VARCHAR(10)
);
	
COPY returned
FROM 'C:\Users\jingn\Documents\SQL\SuperStore SQL\superstore-returns.csv'
DELIMITER ','
CSV HEADER;

-- Total orders returned = 296
SELECT COUNT(order_id)
FROM returned;

-- Total orders we have = 5,111 but the row_id = 10,194
  
-------------------------------
--- PART 2. Normalization Task
-------------------------------
-- We can normalize orders table by creating 'products' as a dimension table that only contains information about that product
-- Create table 'products'  
CREATE TABLE products AS
SELECT DISTINCT 
    Product_ID,
    Product_Name,
	Category,
    Sub_Category,
    Segment
FROM orders;

-- 4344, DISTINCT = 1862
SELECT COUNT(product_name)
FROM products;

SELECT 
 	segment, COUNT(product_id)
FROM products
GROUP BY segment;

-- Add constraint primary key to table 'products'
ALTER TABLE products
ADD CONSTRAINT product_pkey PRIMARY KEY (Product_ID, Product_Name, Category, Sub_Category, Segment);

-- Drop the redundant columns in our fact table
ALTER TABLE orders
DROP COLUMN Category,
DROP COLUMN Sub_Category,
DROP COLUMN Product_Name,
DROP COLUMN Segment;


-- Check the constraint that we have in all our table now
SELECT constraint_name, table_name, constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'public' AND table_name = 'products'; --'orders' / 'returned'

SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'products'; --'orders' / 'returned'

-------------------------------
--- PART 3. Data analysis
-------------------------------
-- To use SQL for analytical task, I should not have done normalization, because now that I want to run queries on multiple
-- tables, I have to join the tables again. However, as I am learning and trying to understand the concepts,
-- I have done normalization and now I can also practice how to join them together

-- !!! TASK FROM MANAGER: He would like to see the Total of lost revenue returned orders, grouped by category and subcategory. 
-- Sort the table by the total value, showing the highest value first. The result should include 3 columns: category, subcategory, and then total value


-------------------------------
--- SOLUTION BREAKDOWN
--------------------------------- 


-- filter: only the orders that are returned
-- output: 
	-- products TABLE	
		-- p.category, p.subCategory
	-- orders
		-- o.sales
	-- ORDER BY o.sales DESC
-- @ NOTE: order table only contains returned order, there is no need to filter [returned = 1]
-- as of now, we only care about the returned_orders, it is wise to use a subquery to return the table that only contains info about returned orders.
WITH returned_orders AS (
	SELECT 
	o.product_id, o.sales
	FROM orders o
	WHERE EXISTS
		(SELECT 1
		FROM returned
		WHERE o.order_id = returned.order_id)
)
-- now merge with product table to get the category and the subcategory of the products included in each ORDER
SELECT 
	-- products
	p.category, p.sub_category,
	-- returned_orders
	SUM(r.sales) AS total_lost_sales
FROM returned_orders r 
LEFT JOIN products p ON p.product_id = r.product_id
GROUP BY p.category, p.sub_category
ORDER BY p.category ASC, SUM(r.sales) DESC;

WITH returned_orders AS (
	SELECT 
	o.product_id, o.sales
	FROM orders o
	WHERE NOT EXISTS
		(SELECT 1
		FROM returned
		WHERE o.order_id = returned.order_id)
)
-- now merge with product table to get the category and the subcategory of the products included in each ORDER
SELECT 
	-- products
	p.category, p.sub_category,
	-- returned_orders
	SUM(r.sales) AS total_actual_sales
FROM returned_orders r 
LEFT JOIN products p ON p.product_id = r.product_id
GROUP BY p.category, p.sub_category
ORDER BY p.category ASC, SUM(r.sales) DESC;

-- ratio of lost revenue with actual revenue
-- We need to join returned table with orders table
-- Tag the orders that were returned to 1 and the remaining orders to 0
-- AVG this tag and we can get the percentage of returned orders

WITH merged_table AS (
	SELECT 
		o.order_id, o.sales,
		-- same as the query that we have just executed, we want to get the sales of these products
		p.category, p.sub_category,
		-- flag
		CASE WHEN r.returned = 'Yes' THEN 1
			WHEN r.returned IS NULL THEN 0 END AS returned_flag
	FROM orders o
	LEFT JOIN returned r ON r.order_id = o.order_id
	LEFT JOIN products p ON p.product_id = o.product_id
)

-- Percentage of sales lost from returned order to actual sales
-- SELECT AVG(returned_flag)::numeric*100 AS percentage_of_returned_orders
-- FROM merged_table;
-- SELECT 
-- 	category, sub_category,
--     ROUND(SUM(CASE WHEN returned_flag = 1 THEN sales ELSE 0 END) * 1.0 / SUM(sales),2) AS lost_sales_ratio
-- FROM merged_table
-- GROUP BY category, sub_category
-- ORDER BY category ASC, SUM(sales) DESC;


SELECT 
	category, sub_category, returned_flag, SUM(sales)
FROM merged_table
GROUP BY category, sub_category, returned_flag
ORDER BY category ASC, returned_flag, SUM(sales) DESC;


COPY (
    WITH merged_table AS (
	SELECT 
		o.order_id, o.sales,
		-- same as the query that we have just executed, we want to get the sales of these products
		p.category, p.sub_category,
		-- flag
		CASE WHEN r.returned = 'Yes' THEN 1
			WHEN r.returned IS NULL THEN 0 END AS returned_flag
	FROM orders o
	LEFT JOIN returned r ON r.order_id = o.order_id
	LEFT JOIN products p ON p.product_id = o.product_id
	)
	
	SELECT 
		category, sub_category, returned_flag, SUM(sales)
	FROM merged_table
	GROUP BY category, sub_category, returned_flag
	ORDER BY category ASC, returned_flag, SUM(sales) DESC
)
TO 'C:\Users\jingn\Documents\Ongoing Projects\Superstore\lost_sales.txt'
WITH (FORMAT CSV, HEADER);


