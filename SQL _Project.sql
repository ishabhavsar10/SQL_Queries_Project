-----------------------------------------------------------------------------
CREATE DATABASE ZomatoDB;
/* KPIs*/
-- Total Restaurants
SELECT COUNT(*) AS Total_Restaurants
FROM zomato_dataset;

-- Average Cost of Two (in millions)
SELECT 
  CONCAT('$', ROUND(SUM(Average_Cost_for_two) / 1000000, 2), 'M') AS Avg_Cost_of_Two_Millions
FROM zomato_dataset
WHERE Average_Cost_for_two IS NOT NULL AND Average_Cost_for_two != '';

-- Average Rating
SELECT 
  ROUND(AVG(CAST(Rating AS DECIMAL(3,2))), 2) AS Average_Rating
FROM zomato_dataset
WHERE Rating IS NOT NULL AND Rating REGEXP '^[0-9]+(\\.[0-9]+)?$';

-- Total Cities
SELECT COUNT(DISTINCT City) AS Total_Cities
FROM zomato_dataset
WHERE City IS NOT NULL AND City != '';

------------------------------------------------------------------------------------------------------------------
-- 1. Country table 

/* This query is to find number of restaurents per country */
SELECT Country, COUNT(*) AS No_Of_Restaurants
FROM zomato_dataset
GROUP BY country
ORDER BY No_Of_Restaurants DESC;

/* This will give the country with their currencies */
SELECT distinct COUNTRY,Currency 
FROM zomato_dataset;

------------------------------------------------------------------------------------------------------------------

SELECT 
  Country,
  YEAR(STR_TO_DATE(Datekey_Opening, '%Y-%m-%d')) AS Opening_Year,
  COUNT(*) AS Restaurant_Count
FROM zomato_dataset
GROUP BY Country, Opening_Year
ORDER BY Opening_Year,Restaurant_Count desc;
-- ---------------------------------------------------------------------------------------------------------------

CREATE TEMPORARY TABLE calendar_base AS
SELECT DISTINCT
  STR_TO_DATE(Datekey_Opening, '%Y-%m-%d') AS CalendarDate
FROM zomato_dataset
WHERE Datekey_Opening IS NOT NULL;


-- ---------------------------------------------------------------------------------------------------------------
/* Question 2 */
SELECT
  CalendarDate,
  YEAR(CalendarDate) AS Year,
  MONTH(CalendarDate) AS MonthNo,
  DATE_FORMAT(CalendarDate, '%M') AS MonthFullName,
  CONCAT('Q', QUARTER(CalendarDate)) AS Quarter,
  DATE_FORMAT(CalendarDate, '%Y-%b') AS YearMonth,
  DAYOFWEEK(CalendarDate) AS WeekdayNo,
  DATE_FORMAT(CalendarDate, '%W') AS WeekdayName,

  -- Financial Month (April = FM1, ..., March = FM12)
  CASE 
    WHEN MONTH(CalendarDate) >= 4 THEN CONCAT('FM', MONTH(CalendarDate) - 3)
    ELSE CONCAT('FM', MONTH(CalendarDate) + 9)
  END AS FinancialMonth,

  -- Financial Quarter (Apr–Jun = Q1, Jul–Sep = Q2, etc.)
  
  CASE 
    WHEN MONTH(CalendarDate) BETWEEN 4 AND 6 THEN 'FQ1'
    WHEN MONTH(CalendarDate) BETWEEN 7 AND 9 THEN 'FQ2'
    WHEN MONTH(CalendarDate) BETWEEN 10 AND 12 THEN 'FQ3'
    ELSE 'FQ4'
  END AS FinancialQuarter

FROM calendar_base
ORDER BY CalendarDate;


-----------------------------------------------------------------------------
/* Question 3 */
create database zomato;
SELECT 
  Country, 
  City, 
  COUNT(*) AS No_Of_Restaurants
FROM zomato_dataset
GROUP BY Country, City
ORDER BY No_Of_Restaurants DESC; 

-----------------------------------------------------------------------------
/* Question 4 */
SELECT
  YEAR(STR_TO_DATE(Datekey_Opening, '%Y-%m-%d')) AS Opening_Year,
  QUARTER(STR_TO_DATE(Datekey_Opening, '%Y-%m-%d')) AS Opening_Quarter,
  MONTH(STR_TO_DATE(Datekey_Opening, '%Y-%m-%d')) AS Opening_Month,
  DATE_FORMAT(STR_TO_DATE(Datekey_Opening, '%Y-%m-%d'), '%M') AS Month_Name,
  COUNT(*) AS No_Of_Restaurants
FROM zomato_dataset
WHERE Datekey_Opening IS NOT NULL
GROUP BY Opening_Year, Opening_Quarter, Opening_Month, Month_Name
ORDER BY Opening_Year, Opening_Quarter, Opening_Month;

-----------------------------------------------------------------------------
/* Question 5 */
SELECT 
  CASE 
    WHEN CAST(Rating AS DECIMAL(3,1)) BETWEEN 4.5 AND 5.0 THEN '4.5 - 5.0'
    WHEN CAST(Rating AS DECIMAL(3,1)) BETWEEN 4.0 AND 4.4 THEN '4.0 - 4.4'
    WHEN CAST(Rating AS DECIMAL(3,1)) BETWEEN 3.5 AND 3.9 THEN '3.5 - 3.9'
    WHEN CAST(Rating AS DECIMAL(3,1)) BETWEEN 3.0 AND 3.4 THEN '3.0 - 3.4'
    ELSE 'Below 3.0'
  END AS Rating_Range,
  COUNT(*) AS Restaurant_Count
FROM zomato_dataset
WHERE Rating IS NOT NULL 
  AND Rating != ''
  AND Rating REGEXP '^[0-9]+(\\.[0-9]+)?$'
GROUP BY Rating_Range
ORDER BY Rating_Range DESC; 
-------------------------------------------------------------------------------------------------------------
Drop Table zomato_data;
/* Question 6 */

SELECT
CASE
WHEN Average_cost_for_two < 200 THEN 'Below 200'
WHEN Average_cost_for_two BETWEEN 200 AND 500 THEN '200 - 500'
WHEN Average_cost_for_two BETWEEN 501 AND 1000 THEN '501 - 1000'
ELSE 'Above 1000'
END AS Price_Bucket,
COUNT(*) AS Restaurant_Count
FROM zomato_dataset
GROUP BY Price_Bucket
ORDER BY Restaurant_Count DESC;

--------------------------------------------------------------------------------------------------
/* Question 7 */

SELECT
Has_Table_booking,
ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*)
FROM zomato_dataset), 2) AS Percentage
FROM zomato_dataset
GROUP BY Has_Table_booking;

/* Question 8 */

SELECT
Has_Online_delivery,
COUNT(*) AS count,
ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM zomato_dataset), 2) AS Percentage
FROM zomato_dataset
GROUP BY Has_Online_delivery;

/* Question 9 */
-- Charts based on cuisines, city, ratings
-- A. Cuisine Popularity
SELECT
Cuisines,
COUNT(*) AS RestaurantCount,
ROUND(AVG(RATING), 2) AS AvgRating
FROM
zomato_dataset
GROUP BY Cuisines
ORDER BY
RestaurantCount DESC;

-- B. City-wise restaurant count and avg-rating
SELECT 
City,
COUNT(*) AS Restaurant_Count,
ROUND(AVG(RATING),2) AS Avg_rating
FROM zomato_dataset
GROUP BY City
ORDER BY Restaurant_Count DESC;

-- C. Rating distribution
SELECT
Rating,
COUNT(*) AS Count
FROM zomato_dataset
GROUP BY Rating
ORDER BY Rating desc;










