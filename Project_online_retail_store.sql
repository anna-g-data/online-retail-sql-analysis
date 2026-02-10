Online Retail Sales Analysis (SQL)

Author: Anna Gasiorowska
Database System: PostgreSQL 16
Dataset Source: Kaggle – Online Retail Dataset

Note: This project uses a public sample dataset from Kaggle for learning purposes.

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
-- These rows cannot be used for customer analysis.
-- These rows can still be used for total revenue analysis, but they are removed to ensure accurate customer-based reporting.

SELECT COUNT(*)
FROM online_retail_raw
WHERE country IS null or TRIM(country)='';

-- RESULT 0
-- Interpretation:
-- Country is present for all rows. Good.

3. Find bad numbers

SELECT COUNT(*)
FROM online_retail_raw
WHERE quantity <=0;

-- RESULT 10624
-- Interpretation:
-- Quantity <= 0 usually means returns or invalid rows.
-- These rows should not be included in sales revenue analysis, so we will remove them.

SELECT COUNT(*)
FROM online_retail_raw
WHERE unitprice <=0;

-- RESULT 2521
-- Interpretation:
-- UnitPrice <= 0 means free items, errors, or invalid transactions.
-- These rows would create wrong revenue totals, so we will remove them.

4. Find cancelled invoices

SELECT COUNT(*) AS canceled_invoices
FROM online_retail_raw
WHERE invoiceno LIKE 'C%';

-- RESULT 9288
-- Interpretation:
-- Invoices starting with “C” are cancellations.
-- Cancelled invoices are not real sales, so we must remove them from analysis.

5. Check date conversion safety

SELECT
invoicedate,
invoicedate::timestamp
FROM online_retail_raw
LIMIT 20;

-- Interpretation:
-- The date column is stored as TEXT in the raw table.
-- This test confirms that we can convert it safely to TIMESTAMP.

6. Create clean table data

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
WHERE invoiceno NOT LIKE 'C%'
AND quantity > 0
AND unitprice > 0
AND TRIM(customerid) <> '';

SELECT *
FROM online_retail_clean;

The clean table contains only valid sales:

* not cancelled
* positive quantity
* positive price
* customer ID exists
* date converted to timestamp

This clean table is used for all analysis.

II. Exploratory Data Analysis

1. Total revenue - How much total money did the company make?

SELECT
SUM(quantity*unitprice) as total_revenue
FROM online_retail_clean;

-- Total revenue = 8,911,407.90
-- Interpretation:
-- The dataset shows approximately £8.9 million in revenue after data cleaning.

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

4. What is the average order value (AOV)

SELECT
COUNT(DISTINCT invoiceno) AS total_orders,
SUM(quantity * unitprice) AS total_revenue,
ROUND(
SUM(quantity * unitprice) / COUNT(DISTINCT invoiceno),
2
) AS AOV
FROM online_retail_clean;

-- Results:
-- total_orders: 18,532
-- total_revenue: 8,911,407.90
-- AOV: 480.87

5. Which product generated the highest total revenue?

SELECT
description,
SUM(quantity * unitprice) AS total_revenue
FROM online_retail_clean
GROUP BY description
ORDER BY total_revenue DESC
LIMIT 1;

-- Result:
-- “PAPER CRAFT, LITTLE BIRDIE” = £168,469.60

6. Top 10 products

SELECT
description,
SUM(quantity * unitprice) AS total_revenue
FROM online_retail_clean
GROUP BY description
ORDER BY total_revenue DESC
LIMIT 10;

-- Interpretation:
-- “POSTAGE” appears in the list, which suggests shipping charges are included in revenue.
-- In a real business scenario, postage would normally be treated as shipping income rather than product revenue.

7. Which country generated the highest total revenue?

SELECT
country,
SUM(quantity * unitprice) AS total_revenue
FROM online_retail_clean
GROUP BY country
ORDER BY total_revenue DESC
LIMIT 5;

--Interpretation:
-- The United Kingdom generated the highest revenue (£7.3M), far exceeding all other countries.
-- The next highest revenues came from Netherlands, EIRE, Germany, and France, but at much lower levels.
-- This confirms that the business is strongly UK-focused, with international sales representing a small portion of total revenue.

8. Which month had the highest revenue?

SELECT
EXTRACT(MONTH FROM invoicedate) AS month,
SUM(quantity * unitprice) AS total_revenue
FROM online_retail_clean
GROUP BY month
ORDER BY total_revenue DESC
LIMIT 5;

-- Interpretation:
-- The revenue stays pretty similar throughout the year, but there is a big jump in the months of October, November, and December.
-- December has the highest revenue, which is £1.09M. This could be because of higher sales during the holiday season.

9. Top 5 Customers by Spending

SELECT
customerid,
SUM(quantity * unitprice) AS total_spent
FROM online_retail_clean
GROUP BY customerid
ORDER BY total_spent DESC
LIMIT 5;

--Interpretation:
-- The top 5 customers by spending come from Netherlands (1st), UK (2nd, 3rd, 4th), and EIRE (5th).
-- Customer 14646 from the Netherlands spent the most with £280,206.
-- Three out of the top 5 customers are from the UK, highlighting the significance of the UK market.


III. Project summary

* Sales Performance

-- Total sales revenue is approximately £8.9 million.
-- The average order value (AOV) is about £480 per order.

* Customers

-- There are 4,338 unique customers.
-- A small group of customers generates a large part of total revenue.

* Products

-- The best-selling product by revenue is “PAPER CRAFT, LITTLE BIRDIE.”
-- Decorative and gift products dominate sales.

* Countries

-- The United Kingdom generates the highest revenue (about £7.3 million).
-- International sales are much smaller compared to the UK market.

* Seasonality

-- The highest sales occur in November, December, and October.
-- Sales planning and marketing campaigns should focus on Q4.

* Data Quality

-- Cancelled orders, returns, invalid prices, and missing customers were removed.
-- Dates were successfully converted into timestamp format.
-- The cleaned dataset allows accurate and trustworthy analysis.


