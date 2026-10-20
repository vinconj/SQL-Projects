SELECT *
FROM sales_bikes;

-- Creating another similar(duplicates) table and insert data:
CREATE TABLE sales_bike
LIKE sales;

RENAME TABLE sales_bike TO sales_bikes;

INSERT sales_bikes
SELECT *
FROM sales;

-- 1. CHECKING DUPLICATE ROWS: Using ROW_NUMBER(), CTEs and DELETE to indentify and remove duplicate rows
SELECT *,
ROW_NUMBER() OVER (PARTITION BY Date,Day,Month, Year, Customer_Age,Age_Group,Customer_Gender,Country,
State,Product_Category,Sub_Category,Product,Order_Quantity,Unit_Cost,Unit_Price,Profit,Cost,Revenue) AS row_num
FROM sales_bikes;

WITH duplicate_cte AS (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY Date,Day,Month, Year, Customer_Age,Age_Group,Customer_Gender,Country,
State,Product_Category,Sub_Category,Product,Order_Quantity,Unit_Cost,Unit_Price,Profit,Cost,Revenue) AS row_num
FROM sales_bikes
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Since they is no primary key so we need to create another tables similary to sales_bikes,
-- inorder to DELETE duplicates.
CREATE TABLE `bikes_sales` (
  `Date` text,
  `Day` int DEFAULT NULL,
  `Month` text,
  `Year` int DEFAULT NULL,
  `Customer_Age` int DEFAULT NULL,
  `Age_Group` text,
  `Customer_Gender` text,
  `Country` text,
  `State` text,
  `Product_Category` text,
  `Sub_Category` text,
  `Product` text,
  `Order_Quantity` int DEFAULT NULL,
  `Unit_Cost` int DEFAULT NULL,
  `Unit_Price` int DEFAULT NULL,
  `Profit` int DEFAULT NULL,
  `Cost` int DEFAULT NULL,
  `Revenue` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM bikes_sales;

INSERT INTO bikes_sales
SELECT *,
ROW_NUMBER() OVER (PARTITION BY Date,Day,Month, Year, Customer_Age,Age_Group,Customer_Gender,Country,
State,Product_Category,Sub_Category,Product,Order_Quantity,Unit_Cost,Unit_Price,Profit,Cost,Revenue) AS row_num
FROM sales_bikes;

-- Temporarily Disable Safe Updates
SET SQL_SAFE_UPDATES = 0;
-- Turn safe mode back on:
-- SET SQL_SAFE_UPDATES = 1;

DELETE 
FROM bikes_sales
WHERE row_num > 1;

SELECT *
FROM bikes_sales
WHERE row_num > 1;

-- Checking if the delete work? Should be 112,036 rows
SELECT COUNT(*) FROM bikes_sales;

-- 2. HANDLING NULL VALUES: Using IS NULL to detet and manage missing data.
-- No null value found in the dataset.
SELECT *
FROM bikes_sales
WHERE Revenue IS NULL;

-- 3. STANDARDIZE TEXT: Using TRIM(),UPPER(), LOWER() AND REPLACE() If needed to make values consistent.
-- Their is no need of standardize the text 
SELECT DISTINCT Sub_Category
FROM bikes_sales;

SELECT customer_gender, COUNT(*)
FROM bikes_sales 
GROUP BY customer_gender;

-- 4.FIXING DATE FORMATS: Concerting inconsistent date strings into proper SQL DATE format using STR_TO_DATE()
-- Verify the column type;
SHOW COLUMNS FROM bikes_sales;

SELECT DISTINCT Date
FROM bikes_sales
LIMIT 60;

-- To see how many rows use each separator:
SELECT
    SUM(Date LIKE '%/%') AS slash_dates,
    SUM(Date LIKE '%-%') AS dash_dates
FROM bikes_sales;
-- Since all dates are already YYYY-MM-DD. Then you don't need STR_TO_DATE() at all. Simply convert the column type:
ALTER TABLE bikes_sales
MODIFY COLUMN Date DATE;

-- Confirm the column type changed from TEXT to DATE
SHOW COLUMNS FROM bikes_sales;

-- 5. REMOVING UNNECCESARY COULUMNS
ALTER TABLE bikes_sales
DROP COLUMN row_num;

-- Confirm the column is gone
SELECT * FROM bikes_sales LIMIT 5;












