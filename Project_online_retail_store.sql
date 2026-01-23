Online Retail Sales Analysis (SQL)

Author: Anna Gasiorowska
Database System: PostgreSQL 16
Dataset Source: Kaggle – Online Retail Dataset

Project Goal
The goal of this project is to analyze online retail sales data using SQL.

The project focuses on:
--Cleaning raw transactional data
--Identifying and removing incorrect or invalid records
--Transforming data into a clean analytical table
--Answering business questions about sales performance, customers, products, countries, and seasonality



DROP TABLE IF EXISTS online_retail_raw;

CREATE TABLE online_retail_raw (
  invoiceno   text,     -- starts with 'C' for cancelled invoices
  stockcode   text,     -- some codes contain letters
  description text,     -- some missing values
  quantity    integer,  -- positive and negative values (returns)
  invoicedate text,     -- stored as text (custom date format)
  unitprice   numeric(12,2), -- price with decimals
  customerid  text,     -- some missing values
  country     text      -- country name
);


SELECT * 
FROM online_retail_raw;

-- Interpretation:
-- This creates the RAW table. It is the original imported data.
-- RAW table can contain cancellations, returns, missing values, and other issues.


I. Cleaning data

1. Confirm database

SELECT current_database();

-- Interpretation:
-- This confirms we are working in the correct database.

2. Find missing data

SELECT COUNT(*)
FROM online_retail_raw
WHERE invoiceno IS null or TRIM(invoiceno)='';

-- RESULT 0
-- Interpretation:
-- All rows have an invoice number. Good.

SELECT COUNT(*)
FROM online_retail_raw
WHERE stockcode IS null or TRIM(stockcode)='';

-- RESULT 0
-- Interpretation:
-- All rows have a stockcode. Good.

SELECT COUNT(*)
FROM online_retail_raw
WHERE description IS null or TRIM(description)='';

-- RESULT 1454
-- Interpretation:
-- Some products have missing descriptions (names).
-- This may affect “top product name” reporting, but revenue calculations still work.

SELECT COUNT(*)
FROM online_retail_raw
WHERE quantity IS null;

-- RESULT 0
-- Interpretation:
-- Quantity is present for all rows. Good.

SELECT COUNT(*)
FROM online_retail_raw
WHERE invoicedate IS null or TRIM(invoicedate)='';

-- RESULT 0
-- Interpretation:
-- Invoicedate is present for all rows. Good.

SELECT COUNT(*)
FROM online_retail_raw
WHERE unitprice IS null;

-- RESULT 0
-- Interpretation:
-- Unitprice is present for all rows. Good.

SELECT COUNT(*)
FROM online_retail_raw
WHERE customerid IS null or TRIM(customerid)='';

-- RESULT 135080
-- Interpretation:
-- Many rows have missing customer IDs.
-- These rows cannot be used for customer analysis (top customers, number of customers).
-- We will remove them in the clean table.

SELECT COUNT(*)
FROM online_retail_raw
WHERE country IS null or TRIM(country)='';

-- RESULT 0
-- Interpretation:
-- Country is present for all rows. Good.


2. Find bad numbers

SELECT COUNT(*)
FROM online_retail_raw
WHERE quantity <=0;

-- RESULT 10624
-- Interpretation:
-- Quantity <= 0 usually means returns (negative) or invalid rows (zero).
-- These rows should not be included in sales revenue analysis, so we will remove them.

SELECT COUNT(*)
FROM online_retail_raw
WHERE unitprice <=0;

-- RESULT 2521
-- Interpretation:
-- UnitPrice <= 0 means free items, errors, or invalid transactions.
-- These rows would create wrong revenue totals, so we will remove them.


3. Find cancelled invoices

SELECT COUNT(*) AS canceled_invoices
FROM online_retail_raw
WHERE invoiceno LIKE 'C%';

-- RESULT 9288
-- Interpretation:
-- Invoices starting with “C” are cancellations.
-- Cancelled invoices are not real sales, so we must remove them from analysis.


4. Check date conversion safety

SELECT 
  invoicedate,
  invoicedate::timestamp
FROM online_retail_raw
LIMIT 20;

-- Interpretation:
-- The date column is stored as TEXT in the raw table.
-- This test confirms that we can convert it safely to TIMESTAMP.
-- If conversion works, we can analyze by month, year, day, etc.


5. Create clean table data

DROP TABLE IF EXISTS online_retail_clean;

CREATE TABLE online_retail_clean AS
SELECT
  invoiceno,
  stockcode,
  description,
  quantity,
  invoicedate::timestamp AS invoicedate,
  unitprice,
  customerid,
  country
FROM online_retail_raw
WHERE invoiceno NOT LIKE 'C%'         -- remove cancelled invoices
  AND quantity > 0                   -- remove returns / invalid quantity
  AND unitprice > 0                  -- remove zero/negative price
  AND TRIM(customerid) <> '';        -- remove missing customerid (empty text)



SELECT * 
FROM online_retail_clean;

The clean table contains only valid sales:
 - not cancelled
 - positive quantity
 - positive price
 - customer ID exists
 - date converted to timestamp
 
This clean table is used for all analysis.


II. Exploratory Data Analysis

1. Total revenue - How much total money did the company make?

SELECT 
  SUM(quantity*unitprice) as total_revenue
FROM online_retail_clean;

-- Total revenue = 8,911,407.90
-- Interpretation:
-- The company generated about £8.9 million in sales (after cleaning).


2. How many unique customers bought something?

SELECT 
  COUNT(DISTINCT customerid) as customer
FROM online_retail_clean;

-- Result: 4,338 unique customers
-- Interpretation:
-- 4,338 different customers made purchases in the cleaned dataset.

3. How many unique invoices (orders) exist?

SELECT
  COUNT(DISTINCT invoiceno) as total_invoices
FROM online_retail_clean;

-- Result: 18,532 unique invoices (orders)
-- Interpretation:
-- The dataset contains 18,532 completed orders.
-- One invoice can include many items, but it counts as one order.


4. What is the average order value (AOV)
AOV = Total revenue ÷ Number of orders

SELECT
  COUNT(DISTINCT invoiceno) AS total_orders,
  SUM(quantity * unitprice) AS total_revenue,
  ROUND(
    SUM(quantity * unitprice) / COUNT(DISTINCT invoiceno),
    2
  ) AS AOV
FROM online_retail_clean;

 Results:
-- total_orders: 18,532
-- total_revenue: 8,911,407.90
-- AOV: 480.87

-- Interpretation:
-- The average order value is about £480.87.
-- This suggests many orders contain multiple items or bulk purchases.


5. Which product generated the highest total revenue?

SELECT
  description,
  SUM(quantity * unitprice) AS total_revenue
FROM online_retail_clean
GROUP BY description
ORDER BY total_revenue DESC
LIMIT 1;

 Result:
-- “PAPER CRAFT , LITTLE BIRDIE” ≈ £168,469.60

-- Interpretation:
-- This product generated the most revenue in the dataset.
-- It is a key product and likely very popular or frequently purchased.


6. Top 10 products

SELECT
  description,
  SUM(quantity * unitprice) AS total_revenue
FROM online_retail_clean
GROUP BY description
ORDER BY total_revenue DESC
LIMIT 10;

-- Interpretation:
-- The top 10 products create a large part of total revenue.
-- This shows revenue is concentrated: a small number of products drive sales.
-- “POSTAGE” appears in the list, which suggests shipping charges are included in revenue.
-- In real business analysis, we may separate product revenue from shipping revenue.


6. Which country generated the highest total revenue?

SELECT 
  country,
  SUM(quantity * unitprice) AS total_revenue
FROM online_retail_clean
GROUP BY country
ORDER BY total_revenue DESC
LIMIT 5;

-- Interpretation:
-- The United Kingdom is the top revenue country (about £7.3M).
-- This means the business depends mainly on UK customers.
-- Other countries contribute smaller amounts compared to the UK.


7. Which month had the highest revenue?

SELECT
  EXTRACT(MONTH FROM invoicedate) AS month,
  SUM(quantity * unitprice) AS total_revenue
FROM online_retail_clean
GROUP BY month
ORDER BY total_revenue DESC
LIMIT 5;

-- Interpretation:
-- November has the highest revenue, followed by December and October.
-- This suggests strong seasonal sales in Q4, likely linked to holiday shopping and promotions.


8. Top 5 Customers by Spending

SELECT 
  customerid,
  SUM(quantity * unitprice) AS total_spent
FROM online_retail_clean
GROUP BY customerid
ORDER BY total_spent DESC
LIMIT 5;

-- Interpretation:
-- The top customer spent over £280,000, making them a very high-value customer.
-- The top 5 customers contribute a large share of revenue.
-- This shows customer concentration: a small group of customers is very important.
-- In business, these customers could be targeted for loyalty programs or special offers.


III. Project summary

* Sales Performance

-- Total sales revenue is approximately £8.9 million.
-- The average order value (AOV) is about £480 per order.
-- This suggests that customers often buy multiple items in one order.


* Customers

-- There are 4,338 unique customers.
-- A small group of customers generates a large part of total revenue.
-- The top customer spent more than £280,000.
-- High-value customers are very important for the business and should be retained.


* Products

-- The best-selling product by revenue is “PAPER CRAFT, LITTLE BIRDIE.”
-- Decorative and gift products dominate sales.
-- “POSTAGE” appears as a top revenue item, meaning shipping costs are included in revenue.
-- In real business analysis, product revenue and shipping revenue may need to be separated.

* Countries

-- The United Kingdom generates the highest revenue (about £7.3 million).
-- International sales are much smaller compared to the UK market.
-- The company mainly depends on domestic customers.


* Seasonality

-- The highest sales occur in November, December, and October.
-- This shows strong seasonal demand during the holiday period.
-- Sales planning and marketing campaigns should focus on Q4.


* Data Quality

-- Cancelled orders, returns, invalid prices, and missing customers were removed.
-- Dates were successfully converted into timestamp format.
-- The cleaned dataset allows accurate and trustworthy analysis.

