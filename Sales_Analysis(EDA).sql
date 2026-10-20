--         EXPLORATORY DATA ANALYSIS (EDA)
--              Bikes Sales Dataset
--         Table: bikes_sales (Cleaned)

-- SECTION 1: DATA STRUCTURE & OVERVIEW
-- 1.1 Total number of records after cleaning
SELECT COUNT(*) AS Total_Records
FROM bikes_sales;

-- 1.2 Preview the first 10 rows
SELECT *
FROM bikes_sales
LIMIT 10;

-- 1.3 Check date range of the dataset
-- how many years of data we are working with (2011-2016)
SELECT 
    MIN(Date) AS Earliest_Date,
    MAX(Date) AS Latest_Date,
    COUNT(DISTINCT Year) AS Total_Years
FROM bikes_sales;

-- 1.4 Count of distinct values per key column
SELECT
    COUNT(DISTINCT Country)          AS Unique_Countries,
    COUNT(DISTINCT State)            AS Unique_States,
    COUNT(DISTINCT Product_Category) AS Unique_Categories,
    COUNT(DISTINCT Sub_Category)     AS Unique_SubCategories,
    COUNT(DISTINCT Product)          AS Unique_Products
FROM bikes_sales;

-- SECTION 2: DESCRIPTIVE STATISTICS
-- 2.1 Summary statistics for all numeric columns
-- the overall scale of the business and typical transaction values
SELECT
    -- Revenue
    ROUND(MIN(Revenue), 2)      AS Min_Revenue,
    ROUND(MAX(Revenue), 2)      AS Max_Revenue,
    ROUND(AVG(Revenue), 2)      AS Avg_Revenue,
    ROUND(SUM(Revenue), 2)      AS Total_Revenue,

    -- Profit
    ROUND(MIN(Profit), 2)       AS Min_Profit,
    ROUND(MAX(Profit), 2)       AS Max_Profit,
    ROUND(AVG(Profit), 2)       AS Avg_Profit,
    ROUND(SUM(Profit), 2)       AS Total_Profit,

    -- Cost
    ROUND(MIN(Cost), 2)         AS Min_Cost,
    ROUND(MAX(Cost), 2)         AS Max_Cost,
    ROUND(AVG(Cost), 2)         AS Avg_Cost,
    ROUND(SUM(Cost), 2)         AS Total_Cost,

    -- Order Quantity
    MIN(Order_Quantity)         AS Min_Order_Qty,
    MAX(Order_Quantity)         AS Max_Order_Qty,
    ROUND(AVG(Order_Quantity), 2) AS Avg_Order_Qty,

    -- Customer Age
    MIN(Customer_Age)           AS Min_Age,
    MAX(Customer_Age)           AS Max_Age,
    ROUND(AVG(Customer_Age), 2) AS Avg_Age
FROM bikes_sales;


-- SECTION 3: TIME-BASED ANALYSIS
-- 3.1 Total Revenue and Profit by Year
-- which years were the most profitable and growth trend over time
SELECT
    Year,
    COUNT(*)                            AS Total_Orders,
    SUM(Order_Quantity)                 AS Total_Units_Sold,
    ROUND(SUM(Revenue), 2)              AS Total_Revenue,
    ROUND(SUM(Profit), 2)               AS Total_Profit,
    ROUND(SUM(Profit)/SUM(Revenue)*100, 2) AS Profit_Margin_Pct
FROM bikes_sales
GROUP BY Year
ORDER BY Year;


-- 3.2 Total Revenue by Month (all years combined)
-- which months generate the most sales (seasonality)
SELECT
    Month,
    COUNT(*)               AS Total_Orders,
    ROUND(SUM(Revenue), 2) AS Total_Revenue,
    ROUND(AVG(Revenue), 2) AS Avg_Revenue
FROM bikes_sales
GROUP BY Month
ORDER BY Total_Revenue DESC;


-- 3.3 Year and Month Revenue breakdown (trend matrix)
-- monthly revenue trends across all years to spot seasonal patterns
SELECT
    Year,
    Month,
    ROUND(SUM(Revenue), 2) AS Total_Revenue
FROM bikes_sales
GROUP BY Year, Month
ORDER BY Year,
    FIELD(Month, 'January','February','March','April','May','June',
                 'July','August','September','October','November','December');


-- 3.4 Best single day for sales
-- the top 10 best performing sales days
SELECT Date,
COUNT(*)               AS Total_Orders,
ROUND(SUM(Revenue), 2) AS Daily_Revenue
FROM bikes_sales
GROUP BY Date
ORDER BY Daily_Revenue DESC
LIMIT 10;

-- SECTION 4: CUSTOMER ANALYSIS
-- 4.1 Orders and Revenue by Gender
-- whether male or female customers drive more revenue
SELECT Customer_Gender,
COUNT(*)                               AS Total_Orders,
ROUND(SUM(Revenue), 2)                 AS Total_Revenue,
ROUND(AVG(Revenue), 2)                 AS Avg_Revenue_Per_Order,
ROUND(SUM(Revenue) / (SELECT SUM(Revenue) FROM bikes_sales) * 100, 2) AS Revenue_Share_Pct
FROM bikes_sales
GROUP BY Customer_Gender;


-- 4.2 Orders and Revenue by Age Group
-- which age group spends the most
SELECT Age_Group,
COUNT(*)               AS Total_Orders,
ROUND(AVG(Customer_Age), 1) AS Avg_Age,
ROUND(SUM(Revenue), 2) AS Total_Revenue,
ROUND(AVG(Revenue), 2) AS Avg_Revenue_Per_Order
FROM bikes_sales
GROUP BY Age_Group
ORDER BY Total_Revenue DESC;

-- 4.3 Gender and Age Group combined
-- which gender-age segment is the most valuable customer group
SELECT Customer_Gender, Age_Group,
COUNT(*)               AS Total_Orders,
ROUND(SUM(Revenue), 2) AS Total_Revenue
FROM bikes_sales
GROUP BY Customer_Gender, Age_Group
ORDER BY Total_Revenue DESC;

-- 4.4 Customer Age distribution buckets
-- a more granular view of which exact age range buys the most
SELECT
    CASE
        WHEN Customer_Age < 25 THEN 'Under 25'
        WHEN Customer_Age BETWEEN 25 AND 34 THEN '25-34'
        WHEN Customer_Age BETWEEN 35 AND 44 THEN '35-44'
        WHEN Customer_Age BETWEEN 45 AND 54 THEN '45-54'
        WHEN Customer_Age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END AS Age_Bucket,
    COUNT(*) AS Total_Orders,
    ROUND(SUM(Revenue), 2) AS Total_Revenue
FROM bikes_sales
GROUP BY Age_Bucket
ORDER BY Total_Revenue DESC;

-- SECTION 5: GEOGRAPHIC ANALYSIS
-- 5.1 Revenue and Profit by Country
-- which countries are the biggest markets
SELECT
    Country,
    COUNT(*)                               AS Total_Orders,
    ROUND(SUM(Revenue), 2)                 AS Total_Revenue,
    ROUND(SUM(Profit), 2)                  AS Total_Profit,
    ROUND(SUM(Profit)/SUM(Revenue)*100, 2) AS Profit_Margin_Pct
FROM bikes_sales
GROUP BY Country
ORDER BY Total_Revenue DESC;

-- 5.2 Top 15 States by Revenue
-- the top performing states/regions within countries
SELECT
    State,
    Country,
    COUNT(*)               AS Total_Orders,
    ROUND(SUM(Revenue), 2) AS Total_Revenue,
    ROUND(SUM(Profit), 2)  AS Total_Profit
FROM bikes_sales
GROUP BY State, Country
ORDER BY Total_Revenue DESC
LIMIT 15;

-- 5.3 Worst performing countries (lowest revenue)
-- which markets need attention or have low penetration
SELECT
    Country,
    ROUND(SUM(Revenue), 2) AS Total_Revenue,
    COUNT(*)               AS Total_Orders
FROM bikes_sales
GROUP BY Country
ORDER BY Total_Revenue ASC;

-- SECTION 6: PRODUCT ANALYSIS
-- 6.1 Revenue and Profit by Product Category
-- which category (Bikes, Accessories, Clothing) dominates sales
SELECT
    Product_Category,
    COUNT(*)                               AS Total_Orders,
    SUM(Order_Quantity)                    AS Units_Sold,
    ROUND(SUM(Revenue), 2)                 AS Total_Revenue,
    ROUND(SUM(Profit), 2)                  AS Total_Profit,
    ROUND(SUM(Profit)/SUM(Revenue)*100, 2) AS Profit_Margin_Pct
FROM bikes_sales
GROUP BY Product_Category
ORDER BY Total_Revenue DESC;

-- 6.2 Revenue and Profit by Sub-Category
-- which sub-categories are top performers within each category
SELECT
    Sub_Category,
    Product_Category,
    COUNT(*)                               AS Total_Orders,
    SUM(Order_Quantity)                    AS Units_Sold,
    ROUND(SUM(Revenue), 2)                 AS Total_Revenue,
    ROUND(SUM(Profit), 2)                  AS Total_Profit,
    ROUND(SUM(Profit)/SUM(Revenue)*100, 2) AS Profit_Margin_Pct
FROM bikes_sales
GROUP BY Sub_Category, Product_Category
ORDER BY Total_Revenue DESC;

-- 6.3 Top 10 Products by Revenue
-- the best selling individual products
SELECT
    Product,
    Sub_Category,
    ROUND(SUM(Revenue), 2)  AS Total_Revenue,
    ROUND(SUM(Profit), 2)   AS Total_Profit,
    SUM(Order_Quantity)     AS Units_Sold
FROM bikes_sales
GROUP BY Product, Sub_Category
ORDER BY Total_Revenue DESC
LIMIT 10;

-- 6.4 Top 10 Products by Profit
-- the most profitable products (may differ from top revenue products)
SELECT
    Product,
    Sub_Category,
    ROUND(SUM(Profit), 2)   AS Total_Profit,
    ROUND(SUM(Revenue), 2)  AS Total_Revenue,
    ROUND(SUM(Profit)/SUM(Revenue)*100, 2) AS Profit_Margin_Pct
FROM bikes_sales
GROUP BY Product, Sub_Category
ORDER BY Total_Profit DESC
LIMIT 10;

-- 6.5 Products with the LOWEST profit (loss-making or barely profitable)
-- products that may need to be reviewed or discontinued
SELECT
    Product,
    Sub_Category,
    ROUND(SUM(Profit), 2)  AS Total_Profit,
    ROUND(SUM(Revenue), 2) AS Total_Revenue
FROM bikes_sales
GROUP BY Product, Sub_Category
ORDER BY Total_Profit ASC
LIMIT 10;

-- SECTION 7: PROFITABILITY ANALYSIS
-- 7.1 Overall profit margin
-- the business's overall profitability health
SELECT
    ROUND(SUM(Revenue), 2)                 AS Total_Revenue,
    ROUND(SUM(Cost), 2)                    AS Total_Cost,
    ROUND(SUM(Profit), 2)                  AS Total_Profit,
    ROUND(SUM(Profit)/SUM(Revenue)*100, 2) AS Overall_Profit_Margin_Pct
FROM bikes_sales;

-- 7.2 Profit margin by Country and Category
-- which country-category combinations are most profitable
SELECT
    Country,
    Product_Category,
    ROUND(SUM(Revenue), 2)                 AS Total_Revenue,
    ROUND(SUM(Profit), 2)                  AS Total_Profit,
    ROUND(SUM(Profit)/SUM(Revenue)*100, 2) AS Profit_Margin_Pct
FROM bikes_sales
GROUP BY Country, Product_Category
ORDER BY Profit_Margin_Pct DESC;

-- 7.3 Profit trend by Year
-- is the business becoming more or less profitable over time?
SELECT
    Year,
    ROUND(SUM(Profit), 2)                  AS Total_Profit,
    ROUND(SUM(Revenue), 2)                 AS Total_Revenue,
    ROUND(SUM(Profit)/SUM(Revenue)*100, 2) AS Profit_Margin_Pct,
    ROUND(AVG(Profit), 2)                  AS Avg_Profit_Per_Order
FROM bikes_sales
GROUP BY Year
ORDER BY Year;

-- 7.4 Unit Cost vs Unit Price analysis by Sub-Category
-- which products have the highest markup per unit
SELECT
    Sub_Category,
    ROUND(AVG(Unit_Cost), 2)  AS Avg_Unit_Cost,
    ROUND(AVG(Unit_Price), 2) AS Avg_Unit_Price,
    ROUND(AVG(Unit_Price) - AVG(Unit_Cost), 2) AS Avg_Markup
FROM bikes_sales
GROUP BY Sub_Category
ORDER BY Avg_Markup DESC;

-- SECTION 8: ORDER QUANTITY ANALYSIS
-- 8.1 Total and Average Order Quantity by Product Category
-- which category moves the most volume
SELECT
    Product_Category,
    SUM(Order_Quantity)              AS Total_Units_Sold,
    ROUND(AVG(Order_Quantity), 2)    AS Avg_Units_Per_Order,
    MAX(Order_Quantity)              AS Max_Order_Qty
FROM bikes_sales
GROUP BY Product_Category
ORDER BY Total_Units_Sold DESC;

-- 8.2 Order Quantity by Country
-- which country orders the highest volume
SELECT
    Country,
    SUM(Order_Quantity)           AS Total_Units_Sold,
    ROUND(AVG(Order_Quantity), 2) AS Avg_Units_Per_Order
FROM bikes_sales
GROUP BY Country
ORDER BY Total_Units_Sold DESC;

-- 8.3 Order Quantity by Age Group
-- which age group places the largest orders
SELECT
    Age_Group,
    SUM(Order_Quantity)           AS Total_Units_Sold,
    ROUND(AVG(Order_Quantity), 2) AS Avg_Order_Qty
FROM bikes_sales
GROUP BY Age_Group
ORDER BY Total_Units_Sold DESC;


-- SECTION 9: CROSS-DIMENSIONAL ANALYSIS (BONUS)
-- 9.1 Best Country + Product Category combination by Revenue
-- where exactly the biggest revenue opportunities are
SELECT
    Country,
    Product_Category,
    ROUND(SUM(Revenue), 2) AS Total_Revenue,
    ROUND(SUM(Profit), 2)  AS Total_Profit
FROM bikes_sales
GROUP BY Country, Product_Category
ORDER BY Total_Revenue DESC
LIMIT 10;

-- 9.2 Gender preference by Product Category
--  do male and female customers prefer different product categories?
SELECT
    Customer_Gender,
    Product_Category,
    COUNT(*)               AS Total_Orders,
    ROUND(SUM(Revenue), 2) AS Total_Revenue
FROM bikes_sales
GROUP BY Customer_Gender, Product_Category
ORDER BY Customer_Gender, Total_Revenue DESC;

-- 9.3 Year-over-Year Revenue Growth
-- the year-over-year growth rate of the business
SELECT
    Year,
    ROUND(SUM(Revenue), 2) AS Total_Revenue,
    ROUND(SUM(Revenue) - LAG(SUM(Revenue)) OVER (ORDER BY Year), 2) AS YoY_Growth,
    ROUND(
        (SUM(Revenue) - LAG(SUM(Revenue)) OVER (ORDER BY Year)) /
        LAG(SUM(Revenue)) OVER (ORDER BY Year) * 100
    , 2) AS YoY_Growth_Pct
FROM bikes_sales
GROUP BY Year
ORDER BY Year;

-- 9.4 Top 5 Sub-Categories per Country
-- the top 5 best-selling sub-categories in each country
SELECT *
FROM (
    SELECT Country, Sub_Category,
        ROUND(SUM(Revenue), 2) AS Total_Revenue,
        RANK() OVER (PARTITION BY Country ORDER BY SUM(Revenue) DESC) AS rnk
    FROM bikes_sales
    GROUP BY Country, Sub_Category
) ranked
WHERE rnk <= 5
ORDER BY Country, rnk;

