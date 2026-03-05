CREATE DATABASE SQL_PROJECT1;
SELECT *
FROM ZCUSTOMERS;
SELECT *
FROM zorder_details;
SELECT *
FROM ZORDERS;

SELECT *
FROM ZPRODUCTS;
SELECT *
FROM ZSTORES;

UPDATE zstores
SET STORE_OPEN_DATE = STR_TO_DATE(STORE_OPEN_DATE, '%d-%m-%Y');

UPDATE ZORDERS
SET ORDER_DATE = STR_TO_DATE(ORDER_DATE, '%d-%m-%Y');

-- Total orders 

select count(*) as total_orders
from zudio_sales_data;

-- Total Profit

SELECT round(sum(sales_profit),2) as Total_profit
FROM zorder_details;

-- Total Sales
SELECT 
    SUM(zod.quantity * zp.price) AS total_sales
FROM zorder_details zod
JOIN zproducts zp
    ON zod.product_id = zp.product_id;
    
    -- Top 5 states by sales profit
SELECT 
    zs.state,
    round(SUM(zod.sales_profit),2) AS total_sales_profit
FROM zstores zs
JOIN zorders zo 
    ON zs.store_id = zo.store_id
JOIN zorder_details zod 
    ON zo.order_id = zod.order_id
GROUP BY zs.state
ORDER BY total_sales_profit DESC
LIMIT 5;

-- Total Sales Profit by Month
SELECT 
    MONTH(zo.order_date) AS month_no,
    MONTHNAME(zo.order_date) AS month_name,
    round(SUM(zod.sales_profit),2) AS total_sales_profit
FROM zorders zo
JOIN zorder_details zod 
    ON zo.order_id = zod.order_id
GROUP BY month_no, month_name
ORDER BY month_no;

--  City-wise revenue contribution 
SELECT zs.city,
ROUND(SUM(zod.sales_profit), 2) AS city_sales,
CONCAT(ROUND(SUM(zod.sales_profit) * 100.0 / (SELECT 
SUM(zod.quantity * zp.price) AS total_sales
FROM
zorder_details zod JOIN
zproducts zp ON zod.product_id = zp.product_id),2),
'%') AS revenue_percentage
FROM
    zstores zs
        JOIN
    zorders zo ON zs.store_id = zo.store_id
        JOIN
    zorder_details zod ON zo.order_id = zod.order_id
GROUP BY zs.city
ORDER BY city_sales DESC;


-- Category wise and clothing type wise sales
SELECT 
    zp.category,
    zp.clothing_type,
    SUM(zod.quantity) AS total_quantity_sold,
    round(SUM(zod.sales_profit))AS total_sales_profit
FROM zproducts zp
JOIN zorder_details zod 
    ON zp.product_id = zod.product_id
GROUP BY zp.category, zp.clothing_type
ORDER BY total_sales_profit DESC;

-- total quantity sold

SELECT  SUM(QUANTITY) AS total_quantity_sold
FROM zorder_details;



-- Average Order value
SELECT 
ROUND(SUM(zod.sales_profit) / COUNT(DISTINCT zo.order_id),
2) AS avg_order_value
FROM zorders zo
JOIN zorder_details zod 
ON zo.order_id = zod.order_id;

-- Running monthly sales.
SELECT
MONTH(zo.order_date) AS month_no,
MONTHNAME(zo.order_date) AS month_name,
SUM(zod.quantity * zp.price) AS monthly_sales,
SUM(SUM(zod.quantity * zp.price))
	OVER (ORDER BY MONTH(zo.order_date)) AS running_total
FROM zorders zo
JOIN zorder_details zod 
    ON zo.order_id = zod.order_id
JOIN zproducts zp
    ON zod.product_id = zp.product_id
GROUP BY month_no, month_name
ORDER BY month_no;


-- MOM%
WITH monthly_sales AS (
SELECT
MONTH(zo.order_date) AS month_no,
MONTHNAME(zo.order_date) AS month_name,
SUM(zod.quantity * zp.price) AS monthly_sales
FROM zorders zo
JOIN zorder_details zod ON zo.order_id = zod.order_id
JOIN zproducts zp ON zod.product_id = zp.product_id
GROUP BY month_no, month_name)

SELECT
month_name,monthly_sales,
LAG(monthly_sales) OVER (ORDER BY month_no) AS prev_month_sales,
concat(ROUND(
(monthly_sales - LAG(monthly_sales) OVER (ORDER BY month_no))
/ LAG(monthly_sales) OVER (ORDER BY month_no) * 100,2),"%"
) AS mom_perct
FROM monthly_sales
ORDER BY month_no;
-- Owned Vs Rented stores contribution in profit.
SELECT 
    zs.store_type,
    ROUND(SUM(zod.quantity * zp.price), 2) AS total_sales
FROM zstores zs
JOIN zorders zo ON zs.store_id = zo.store_id
JOIN zorder_details zod ON zo.order_id = zod.order_id
JOIN zproducts zp ON zod.product_id = zp.product_id
GROUP BY zs.store_type;

-- `Top 10 Best performing stores.
SELECT 
    zs.store_id,
    ROUND(SUM(zod.quantity * zp.price), 2) AS total_profit
FROM zstores zs
JOIN zorders zo ON zs.store_id = zo.store_id
JOIN zorder_details zod ON zo.order_id = zod.order_id
JOIN zproducts zp ON zod.product_id = zp.product_id
GROUP BY zs.store_id
ORDER BY total_profit DESC
LIMIT 10;

-- Top 10 customers by total spend
SELECT 
    zc.customer_name,
    ROUND(SUM(zod.quantity * zp.price), 2) AS total_spent
FROM zcustomers zc
JOIN zorders zo ON zc.customer_id = zo.customer_id
JOIN zorder_details zod ON zo.order_id = zod.order_id
JOIN zproducts zp ON zod.product_id = zp.product_id
GROUP BY zc.customer_name
ORDER BY total_spent DESC
LIMIT 10;


-- Repeat Customers.
SELECT COUNT(*) AS repeat_customers
FROM (
    SELECT customer_id
    FROM zorders
    GROUP BY customer_id
    HAVING COUNT(order_id) > 1
) c_repeat;

-- Average quantity per customer.

SELECT ROUND(AVG(total_quantity), 2) AS avg_quantity_per_customer
FROM (
    SELECT 
        zo.customer_id,
        SUM(zod.quantity) AS total_quantity
    FROM zorders zo
    JOIN zorder_details zod ON zo.order_id = zod.order_id
    GROUP BY zo.customer_id
) customer_qty;


-- MOST SOLD CLOTHING TYPE(BY QUANTITY).
SELECT 
    zp.clothing_type,
    SUM(zod.quantity) AS total_quantity
FROM zproducts zp
JOIN zorder_details zod ON zp.product_id = zod.product_id
GROUP BY zp.clothing_type
ORDER BY total_quantity DESC;

-- Lowest performing products.
SELECT 
    zp.product_id,zp.category,
    SUM(zod.quantity) AS total_quantity,
    ROUND(SUM(zod.quantity * zp.price), 2) AS total_sales
FROM zproducts zp
JOIN zorder_details zod 
    ON zp.product_id = zod.product_id
GROUP BY zp.product_id, zp.Category
HAVING SUM(zod.quantity) < 10
ORDER BY total_sales asc
limit 5;

-- Peak Sales Month.
SELECT 
    MONTHNAME(order_date) AS peak_month,
    ROUND(SUM(zod.quantity * zp.price), 2) AS total_sales
FROM zorders zo
JOIN zorder_details zod ON zo.order_id = zod.order_id
JOIN zproducts zp ON zod.product_id = zp.product_id
GROUP BY peak_month, MONTH(order_date)
ORDER BY total_sales DESC
LIMIT 1;

-- Monthly Sales trend.
SELECT 
    MONTHNAME(zo.order_date) AS month_z,
    ROUND(SUM(zod.quantity * zp.price), 2) AS monthly_sales
FROM zorders zo
JOIN zorder_details zod ON zo.order_id = zod.order_id
JOIN zproducts zp ON zod.product_id = zp.product_id
GROUP BY month_z, monthname(zo.order_date)
ORDER BY month_z;

-- PER SQ. FT SALES

SELECT 
    zs.store_id,
    ROUND(
        SUM(zod.quantity * zp.price) / zs.Selling_Area_Size_(sqft),
        2
    ) AS sales_per_sqft
FROM zstores zs
JOIN zorders zo ON zs.store_id = zo.store_id
JOIN zorder_details zod ON zo.order_id = zod.order_id
JOIN zproducts zp ON zod.product_id = zp.product_id
GROUP BY zs.store_id, zs.Selling_Area_Size_(sqft)
ORDER BY sales_per_sqft DESC;




-- ORDER VOLUME BY MONTH
SELECT 
    MONTHNAME(order_date) AS month,
    COUNT(order_id) AS order_count
FROM zorders
GROUP BY MONTHNAME(order_date)
ORDER BY MONTHNAME(order_date);