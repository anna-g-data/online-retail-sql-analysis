Online Retail Sales Analysis (SQL)

Author: Anna Gasiorowska  
Database: PostgreSQL 16  
Dataset: Kaggle – Online Retail Dataset  

Project Overview  
This project analyzes online retail sales data using SQL.  
The objective is to clean raw transactional data and generate business insights related to sales performance, customers, products, countries, and seasonality.

Key Objectives  
- Clean raw transactional data  
- Remove invalid and inconsistent records  
- Create a clean analytical table  
- Perform exploratory data analysis  
- Generate business insights  

Data Cleaning Summary  
- Removed cancelled invoices (InvoiceNo starting with 'C')  
- Removed negative and zero quantities (returns and invalid data)  
- Removed zero or negative prices  
- Removed rows with missing customer IDs  
- Converted invoice date from text to timestamp  
- Created a clean table: online_retail_clean  

Results Snapshot  
- Total Revenue: £8.9M  
- Unique Customers: 4,338  
- Total Orders: 18,532  
- Average Order Value: £480.87  
- Top Country: United Kingdom  
- Top Product: PAPER CRAFT, LITTLE BIRDIE  
- Peak Sales Months: October–December  

Business Insights  
- Revenue is highly concentrated among a small group of customers.  
- The UK market generates the majority of total revenue.  
- Strong seasonality occurs in Q4, driven by holiday demand.  
- Shipping costs (“POSTAGE”) appear in revenue and should ideally be separated from product revenue.  

Limitations  
- Customer analysis excludes transactions with missing customer IDs.  
- Revenue includes shipping charges, which may inflate product-level analysis.  
- Dataset represents historical data and may not reflect current business trends.  

Tools Used  
- PostgreSQL 16  
- SQL  
- pgAdmin 4  
