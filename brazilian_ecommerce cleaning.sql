## Cleaning the Brazilian E-Commerce Dataset

ALTER TABLE olist_geolocation_dataset
CHANGE COLUMN `ï»¿geolocation_zip_code_prefix` geolocation_zip_code_prefix INT;

ALTER TABLE olist_order_payments_data
CHANGE COLUMN `ï»¿order_id` order_id TEXT;

ALTER TABLE olist_products_data
CHANGE COLUMN `ï»¿product_id` product_id TEXT;

Drop Table olist_cleaned_orders;

-- 1. Schema integration & merging
CREATE TABLE olist_cleaned_orders AS
SELECT
	o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    oi.product_id,
    oi.freight_value,
    p.product_category_name,
    t.product_category_name_english,
    c.customer_city,
    c.customer_state
FROM olist_orders_data AS o
JOIN olist_order_items_data AS oi
ON o.order_id = oi.order_id
JOIN olist_products_data AS p
ON oi.product_id = p.product_id
JOIN olist_customers_data AS c
ON o.customer_id = c.customer_id
LEFT JOIN product_category_name_translation AS t
ON p.product_category_name = t.product_category_name
;

SELECT *
FROM olist_cleaned_orders;

-- 2. Standardizing the Timestamps
-- Convert string timestamps to proper DATETIME format
UPDATE olist_cleaned_orders
SET 
	order_purchase_timestamp = STR_TO_DATE(order_purchase_timestamp, '%m/%d/%Y %H:%i'),
    order_delivered_customer_date = STR_TO_DATE(order_delivered_customer_date, '%m/%d/%Y %H:%i'),
    order_estimated_delivery_date = STR_TO_DATE(order_estimated_delivery_date, '%m/%d/%Y %H:%i')
WHERE order_id IS NOT NULL
  AND order_purchase_timestamp <> ''
  AND order_delivered_customer_date <> ''
  AND order_estimated_delivery_date <> '';
  
SELECT order_id,
       order_purchase_timestamp,
       order_delivered_customer_date,
       order_estimated_delivery_date
FROM olist_cleaned_orders
WHERE order_purchase_timestamp = ''
   OR STR_TO_DATE(order_purchase_timestamp, '%m/%d/%Y %H:%i') IS NULL
   OR order_delivered_customer_date = ''
   OR STR_TO_DATE(order_delivered_customer_date, '%m/%d/%Y %H:%i') IS NULL
   OR order_estimated_delivery_date = ''
   OR STR_TO_DATE(order_estimated_delivery_date, '%m/%d/%Y %H:%i') IS NULL;

UPDATE olist_cleaned_orders
SET order_purchase_timestamp = STR_TO_DATE(order_purchase_timestamp, '%m/%d/%Y %H:%i')
WHERE order_purchase_timestamp LIKE '%/%/%';

UPDATE olist_cleaned_orders
SET order_delivered_customer_date = STR_TO_DATE(order_delivered_customer_date, '%m/%d/%Y %H:%i')
WHERE order_delivered_customer_date LIKE '%/%/%';

UPDATE olist_cleaned_orders
SET order_estimated_delivery_date = STR_TO_DATE(order_estimated_delivery_date, '%m/%d/%Y %H:%i')
WHERE order_estimated_delivery_date LIKE '%/%/%';

UPDATE olist_cleaned_orders
SET order_purchase_timestamp = NULL
WHERE order_purchase_timestamp = '';

UPDATE olist_cleaned_orders
SET order_delivered_customer_date = NULL
WHERE order_delivered_customer_date = '';

UPDATE olist_cleaned_orders
SET order_estimated_delivery_date = NULL
WHERE order_estimated_delivery_date = '';

SELECT order_id, order_purchase_timestamp, order_delivered_customer_date, order_estimated_delivery_date
FROM olist_cleaned_orders
WHERE order_purchase_timestamp = ''
   OR order_delivered_customer_date = ''
   OR order_estimated_delivery_date = '';

-- Modify the column types permanently
ALTER TABLE olist_cleaned_orders
MODIFY COLUMN order_purchase_timestamp DATETIME,
MODIFY COLUMN order_delivered_customer_date DATETIME,
MODIFY COLUMN order_estimated_delivery_date DATETIME;

-- 3.Handling missing values & nulls
-- Filling missing English category names with the Portugese name or 'Unknown'
UPDATE olist_cleaned_orders
SET product_category_name_english = COALESCE(product_category_name_english, product_category_name, 'unknown')
WHERE product_category_name_english IS NULL;

-- Flagging cancelled orders with missing delivery dates (This prevents them from skewing delivery time average)
DELETE FROM olist_cleaned_orders
WHERE order_status = 'canceled' AND order_delivered_customer_date IS NULL;

-- 4. Text standardization (CIty & State)
-- Convert city names to lowercase and trim whitespace
UPDATE olist_cleaned_orders
SET customer_city = LOWER(TRIM(customer_city));

-- Simple accent removal for common Brazilian city characters
UPDATE olist_geolocation_dataset
SET geolocation_city = REPLACE(REPLACE(geolocation_city,'Ã', 'a'), '£', 'e')
WHERE geolocation_city IS NOT NULL;

UPDATE olist_geolocation_dataset
SET geolocation_city = REPLACE(REPLACE(geolocation_city,'Ã', 'a'), '£', 'e')
WHERE geolocation_city LIKE 'saeo paulo';

UPDATE olist_geolocation_dataset
SET geolocation_city = REPLACE(REPLACE(geolocation_city,'Ã', 'a'), '£', 'e')
WHERE geolocation_city LIKE 'saƒÂeo paulo';

SELECT DISTINCT geolocation_city
FROM olist_geolocation_dataset
WHERE geolocation_city LIKE '%paulo%';

UPDATE olist_geolocation_dataset
SET geolocation_city = REPLACE(
    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(geolocation_city, 'ƒ', 'o'),
                'Â', ''),
            'Ã', 'a'),
        '£', 'e'),
    '‚', ''),
'', '');

SELECT DISTINCT geolocation_city
FROM olist_geolocation_dataset
ORDER BY geolocation_city;

-- Remove logical errors: Delivery date cannot be before Purchase date
DELETE FROM olist_orders_data
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- 6. Creating some metrics
-- Add a column for Delivery Lead Time (in days)
ALTER TABLE olist_cleaned_orders 
ADD COLUMN delivery_days INT;

UPDATE olist_cleaned_orders
SET delivery_days = DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)
WHERE order_delivered_customer_date IS NOT NULL;

## THE DATASET IS NOW CLEAN FOR ANALYSIS