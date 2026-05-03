**Project Overview**

This project focuses on cleaning and preparing the Brazilian Olist E-Commerce dataset for analysis using MySQL.
The objective is to transform raw transactional data into a clean and analysis-ready dataset by applying structured SQL operations across multiple related tables.
The final cleaned table created is:
olist_cleaned_orders
This integrated table supports better reporting, analytics, and business decision-making.

## Key SQL Operations Performed

### 1. Column Cleaning

* Renamed corrupted column headers caused by encoding issues
* Standardized field names for easier querying

### 2. Schema Integration & Table Merging

* Joined multiple Olist tables including:

  * orders
  * customers
  * products
  * order items
  * product category translations

* Created a unified cleaned table using:

CREATE TABLE olist_cleaned_orders AS
SELECT ...

### 3. Timestamp Standardization

* Converted text-based timestamps into proper `DATETIME` format using:

STR_TO_DATE()

* Removed empty values
* Converted invalid timestamps to `NULL`
* Modified column types permanently

### 4. Missing Values Handling

* Filled missing English category names using:

COALESCE()

* Removed canceled orders with missing delivery dates

### 5. Text Standardization

* Cleaned city names using:

  * LOWER()
  * TRIM()
  * REPLACE()

* Corrected encoding issues in Brazilian city names

### 6. Logical Error Removal

* Deleted invalid records where delivery date occurred before purchase date

### 7. Metric Creation

* Added delivery performance metric:

delivery_days

using:

DATEDIFF()

## Final Outcome

The dataset is now cleaned and ready for:

* Exploratory Data Analysis (EDA)
* Sales Performance Analysis
* Delivery Performance Evaluation
* Customer Behavior Analysis
* Product Category Insights
* Business Intelligence Reporting


## Sample Final Metric Query

SELECT order_id, delivery_days
FROM olist_cleaned_orders
ORDER BY delivery_days DESC;

## Author

Odunze-Aasiugwu Onyinye Shirley
