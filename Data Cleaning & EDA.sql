CREATE DATABASE EDA;

DROP TABLE electronicsdata
-- TRUNCATE TABLE electronicsdata
SELECT * From electronicsdata

-- INFILE STATEMENT (Allows Us to IMPORT DATA From an EXTERNAL SOURCE Into an EXISTING DATABASE)
SET sql_safe_updates = 0

LOAD DATA INFILE "D:/ElectronicsData.csv"
INTO TABLE electronicsdata
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- VIEW OF THE DATA
SELECT * From electronicsdata
SELECT count(Distinct title) From electronicsdata

-- DESCRIBING OUR DATA (NUMBER Of COLUMNs TYPE Of REACH COLUMN, If There Is ANY PRIMARY KEY, SECONDARY KEY ETC., This GIVE US OUR FIRST IMPRESSION ABOUT DATA)
DESCRIBE electronicsdata 

-- FEATURE ENGINEERING (CLEANING DATA)
SELECT * From electronicsdata

-- SUB CATEGORY
SELECT * From ELECTRONICSDATA ORDER By RAND() LIMIT 5 
SELECT DISTINCT `SUB CATEGORY` From ELECTRONICSDATA

-- CLEANING "PRICE" COLUMN
-- CLEANING "$" SIGN
SELECT Replace(Price, "$", "") As price From electronicsdata                      -- REPLACE $
UPDATE electronicsdata                                                            -- Updating It
SET price = Replace(Replace(Price , "$", ""), ", ", "")

-- CLEANING "through" WORD
SELECT price , Replace(substring_index(Replace(price, "-", ""), "through", 1), ",", "") + Replace(substring_index(Replace(price, "-", ""),"through", -1), ",","") As total
From electronicsdata WHERE price Like "%through%" GROUP By price

UPDATE electronicsdata                                            -- Updating
SET price = (Replace(substring_index(Replace(price, "-", ""),"through", 1),",","") + Replace(substring_index(Replace(price, "-", ""), "through", -1), ", ", ""))/2
Where price Like "%through%"

SELECT * From electronicsdata

-- CLEANING "DISCOUNT" COLUMN
-- FORMING discount_given COLUMN
ALTER TABLE electronicsdata                                   -- ADDED NEW COLUMN
ADD Column discount_given varchar(3) After Discount;

SELECT *,                                                     -- LOGIC
  CASE When discount Like "%No Discount%" Then "NO"
  Else "Yes" END As "discount given"
  From electronicsdata

UPDATE electronicsdata                                        -- ADD VALUEs to The COLUMN
SET discount_given = CASE When discount Like "%No Discount%" Then "No" Else "Yes" END

-- FORMING "MRP" COLUMN
SELECT * From electronicsdata
ALTER TABLE electronicsdata                                   -- CREATED COLUMN
ADD COLUMN MRP Decimal (20, 2) After Price

SELECT discount, price,                                     -- LOGIC
    CASE When DISCOUNT Like "%No Discount%" Then price
         When discount Like "%After%" Then round(price + regexp_replace(discount , "[^0-9]", ""), 2)
	Else round(price*1.27, 2) End As Disocunted_amount 
From electronicsdata

UPDATE electronicsdata
SET MRP = Case
   When DISCOUNT Like "%No Discount%" Then price
   When discount Like "%After%" Then round(price+ regexp_replace(discount , "[^0-9]", ""), 2)
	Else round(price*1.27, 2) END

-- DISCOUNT COLUMN NAME CHANGE & CARDINALITY REDUCTION
ALTER TABLE electronicsdata CHANGE Column Discount Discount_type Text;                      -- CHANGE COLUMN NAME

SELECT discount_type, Case                                    -- LOGIC
When discount_type like "%No Discount%" Then "No Discount"  
When Discount_type like "%Price valid%" Then "Price Valid Discount" 
When discount_type like "%After%" Then "Flat Discount Offers"
Else "Special Discount" END As Dis From electronicsdata;

UPDATE electronicsdata
SET discount_type = Case                                      -- APPLICATION
When discount_type like "%No Discount%" Then "No Discount"  
When Discount_type like "%Price valid%" Then "Price Valid Discount" 
When discount_type like "%After%" Then "Flat Discount Offers"
"Special Discount" END

SELECT * From electronicsdata

-- DROPPING The "CURRENCY" COLUMN
ALTER TABLE electronicsdata
DROP Column Currency

-- CLEANING RATING COLUMN
-- EXTRACTING "RATING" Only
ALTER TABLE electronicsdata 
ADD Column Average_Rating Decimal(5, 2) After rating         -- CHANGING COLUMN NAME

SELECT rating, REGEXP_SUBSTR(rating, "[0-9]") As extracted_rating From electronicsdata      -- EXTRACT FIRST NUMBER BEFORE DECIMAL Only
SELECT rating, REGEXP_SUBSTR(rating, "[0-9] + (\\.[0-9]+)?") As extracted_rating From electronicsdata;    -- EXTRACT AFTER DECIMAL Only

UPDATE electronicsdata                                      -- UPDATING DATA In RATING COLUMN
SET average_rating = REGEXP_SUBSTR(rating, "[0-9] + (\\.[0-9]+)?");
SELECT * From electronicsdata

-- EXTRACTING NUMBERs Of RATING
SELECT * From electronicsdata
ALTER TABLE electronicsdata ADD Column Reviews_Count int After rating           -- ADDED NEW COLUMN to EXTRACT NUMBER Of REVIEWs

SELECT rating, regexp_substr(rating , "[0-9] + (?= reviews)") From electronicsdata                     -- LOGIC
UPDATE electronicsdata                                                                                 -- UPDATING
SET reviews_count= regexp_substr(rating , '[0-9]+(?= reviews)') 

ALTER TABLE electronicsdata
DROP Column rating
SELECT * From electronicsdata

-- GETTING COMPANY NAME
ALTER TABLE ELECTRONICSDATA                                -- ADDED COLUMN For The SAME
ADD Column Brandname varchar(30)

SELECT title ,substring_index(title , " ", 1) from electronicsdata             -- LOGIC
UPDATE electronicsdata
SET brandname= substring_index(title , " ", 1)             -- After, This STEP CHECK DISTINCT
SELECT Distinct(brandname) From electronicsdata

SELECT * From electronicsdata
Where substring_index(title , " ", 1) Like "%$%"            -- To LOOK WHERE DOES $ COMEs FROM

UPDATE electronicsdata
SET brandname = "Nintendo"
Where substring_index(title , " ", 1) Like "%$%"

UPDATE electronicsdata
SET Brandname = "Apple"
Where Brandname Like "%mac%" OR Brandname Like '%ipad%' or Brandname Like "%Airpods%";

SELECT * From electronicsdata ORDER By price
SELECT Distinct(brandname) From electronicsdata

-- EDA
-- GLIMPSE OF DATA
SELECT * From ELECTRONICSDATA LIMIT 5                       -- ESSANCE  OF DATA
SELECT * From ELECTRONICSDATA ORDER By RAND() LIMIT 5 

-- NUMERICAL COLUMNS ANALYSIS (PRICE)
-- 1st CHECKING FOR NULL
SELECT COUNT(*) From ELECTRONICSDATA Where PRICE Is NULL

-- 2nd FINDING, MIN, MAX, AVG, STD
SELECT MIN(price) As minimum,
MAX(PRICE) As MAXIMUM, 
AVG(PRICE) As AVERAGE,
STD(PRICE) As STD
From electronicsdata                                        -- ERROR

SELECT * From electronicsdata

DELETE From ELECTRONICSDATA
Where `Sub Category` = "Home Security Systems & Cameras"    -- REMOVING The ROW

ALTER TABLE ELECTRONICSDATA
MODIFY Column PRICE Decimal(20, 2);                         -- CHANGE DATATYPE

SELECT MIN(price) As minimum,
MAX(price) As maximum, 
AVG(price) As average,
STD(price) As std
From electronicsdata;

-- 3rd PERCENTILE COUNT
DROP PROCEDURE GetPriceByPercentile
SELECT Distinct price, ROUND(PERCENT_RANK() OVER (ORDER By price), 2) As percentile From ELECTRONICSDATA

DELIMITER //
CREATE PROCEDURE GetPriceByPercentile(IN percentileValue DECIMAL(3, 2), OUT price_limit DECIMAL(10, 2))
BEGIN
    SELECT MAX(Price)
    INTO price_limit
    FROM (SELECT Distinct price, ROUND(PERCENT_RANK() OVER (ORDER BY price), 2) AS percentile FROM ELECTRONICSDATA) As k
    Where percentile = percentileValue;
END //
DELIMITER

CALL GetPriceByPercentile(0.26, @q12);
SET @q1 = ROUND((@q11+@q12)/2, 2);
SELECT @q2
SELECT @q1 As Q1, @q2 As Median ,@q3 As Q3                  -- MEAN > MEDIAN {POSTIVE SKEWED}
SELECT @Q2

-- 4th OUTLIERs
SELECT * From ELECTRONICSDATA Where PRICE <(@q1-1.5*(@q3-@q1)) OR PRICE > (@q3+1.5*(@q3-@q1))        -- OUTLIERs On POSITIVE SIDE

-- 5th CREATE DATA AS PER BUCKETS/PLOT HISTOGRAM
SELECT BUCKETS, REPEAT("*" , COUNT(*)/5) FROM 
(SELECT PRICE,
CASE 
  When PRICE BETWEEN 0 AND 500  Then "0-0.5K"
  When PRICE BETWEEN 501 AND 1500 Then "0.5K-1.5K"
  When PRICE BETWEEN 1501 AND 3000  Then "1.5K-3K"
  When PRICE BETWEEN 3001 AND 6000 Then "3K-6K"
  ELSE '>6K'
  END AS 'BUCKETS'
  FROM ELECTRONICSDATA) K 
GROUP BY BUCKETS

-- CATEGORICAL COLUMNs
-- 1st CHECKING For NULL VALUEs
SELECT COUNT(*) From ELECTRONICSDATA Where `SUB CATEGORY` Is NULL

-- 2nd COUNT Of COMPANY/PIE CHART
SELECT `sub category`, COUNT(`sub category`) As sub_category_count From electronicsdata GROUP By `sub category`;

-- BIVARIATE ANALYSIS (NUMERICAL - NUMERICAL ANALYSIS
-- 1st SCATTER PLOT
SELECT aVERAGE_RATING , REVIEWS_COUNT FROM ELECTRONICSDATA      -- INCREASE In COUNT Of REVIEWs LEADs to INCREASE In AVERAGE RATINGs
-- 2nd COVRIANCE 
SELECT round((SUM((AvERAGE_RATING - (SELECT AVG(AVERAGE_RATING) From ELECTRONICSDAta)) * (reviews_count - (SELECT AVG(reviews_count) From electronicsdata))) / (COUNT(*) - 1)), 2) As covariance
From electronicsdata;                                           -- POSITIVE RELATION
    
-- 3rd CORRELATION
SELECT ROUND((round((SUM((AvERAGE_RATING - (SELECT AVG(AVERAGE_RATING) From ELECTRONICSDAta)) * (reviews_count - (SELECT AVG(reviews_count) From electronicsdata ))) / (COUNT(*) - 1)),2))/(STD(AVERAGE_RATING)* STD(REVIEWS_COUNT)),2) AS CORRELATION
From ELECTRONICSDATA                                            -- VERY WEAK POSITIVE LINEAR RELATIONSHIP

-- 4th SLOPE Of LINEAR REGRESSION
SELECT SUM((PRICE - (SELECT AVG(PRICE) From ELECTRONICSDATA)) * (MRP - (SELECT AVG(MRP) From ELECTRONICSDATA))) / SUM(POWER(PRICE - (SELECT AVG(PRICE) From ELECTRONICSDATA), 2)) As slope
From ELECTRONICSDATA;               -- FOR EXAMPLE, If The PRICE Of a PRODUCT INCREASEs By $10, The MRP Would INCREASE By $3,770 (10*377), For PRICE & SALEs We Can See This

SELECT * FROM ELECTRONICSDATA

-- BIVARIATE ANALYSIS (CATEGORICAL - CATEGORICAL ANALYSIS)
-- 1st COTINGENCY TABLE (COUNT Of CATEGORY EACH COMPANY Is DEALING IN)
SELECT BRANDNAME, COUNT(DISTINCT(`SUB CATEGORY`)) As Sectors FROM ELECTRONICSDATA
GROUP By BRANDNAME
 
-- BIVARIATE ANALYSIS (CATEGORICAL - NUMERICAL ANALYSIS)
-- 2nd GROUPED SUMMARY STATISTICS (Mean, Variance, Standard Deviation)
SELECT bRANDNAME,
	ROUND(AVG(pRICE), 2) As mean,
	ROUND(mIN(pRICE), 2) As mINIMUM,
	ROUND(MAX(PRICE), 2) As MAXIMUM,
	ROUND(STDDEV(pRICE), 2) As stddev
From ELECTRONICSDATA
GROUP By BRANDNAME;                 -- MORE CONSISTENCY In PRICEs In CATEORIES LIKE; MASINGO, ALLSTATE, BEATS, SANDISK, INSTA360 ETC.

-- HERE WE DO THINGs LIKE; MEAN ALAYSIS, VARINACE ANALYSIS ETC ACROSS CATEGORIEs
 SELECT * FROM electronicsdata
 
 -- MUTIVARIATE ANALYSIS
 -- 1st COVRIANCE
SELECT `SUB CATEGORY`,
	round((SUM((AvERAGE_RATING - (SELECT AVG(AVERAGE_RATING) FROM ELECTRONICSDAta)) * (reviews_count - (SELECT AVG(reviews_count) FROM electronicsdata ))) / (COUNT(*) - 1)),2) As covariance
From electronicsdata
GROUP By `SUB CATEGORY`