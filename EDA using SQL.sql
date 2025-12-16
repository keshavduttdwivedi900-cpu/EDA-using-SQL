-- DATA CLEANING AND EDA USING SQL 
-- FLOW --> LOAD DATA --> CLEANING OF DATA --> FEATURE ENGINEERING --> EDA AND INFERENCES 
CREATE DATABASE campusX
USE CAMPUSX
SELECT * FROM ELECTRONICSDATA 

TRUNCATE TABLE ELECTRONICSDATA

-- INFILE STATEMENT 

set sql_safe_updates = 0

LOAD DATA INFILE "C:\\Data_Analyst\\Projects\\ElectronicsData.csv"
INTO TABLE electronicsdata
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

select * from ELECTRONICSDATA
DESCRIBE ELECTRONICSDATA  

-- CLEANING OF DATA 
SELECT * FROM ELECTRONICSDATA




SELECT DISTINCT `SUB CATEGORY` FROM ELECTRONICSDATA

--  PRICE COLUMN  
       -- $,THROUGH 
SELECT PRICE , REPLACE(REPLACE(PRICE,"$",""),",","") FROM ELECTRONICSDATA 

UPDATE ELECTRONICSDATA
SET PRICE = REPLACE(REPLACE(PRICE,"$",""),",","") 

SELECT PRICE,(SUBSTRING_INDEX(REPLACE(PRICE,"-",""), "through",1) + 
SUBSTRING_INDEX(REPLACE(PRICE,"-",""),"through",-1))/2 from ELECTRONICSDATA

UPDATE ELECTRONICSDATA 
SET PRICE = (SUBSTRING_INDEX(REPLACE(PRICE,"-",""),"through",1)+
SUBSTRING_INDEX(REPLACE(PRICE,"-",""),"through",-1))/2
where price like "%through%"

-- DISCOUNT COLUMN

select * from ELECTRONICSDATA 
describe ELECTRONICSDATA  
ALTER TABLE ELECTRONICSDATA
ADD COLUMN DISCOUNT_GIVEN VARCHAR(3) AFTER DISCOUNT 

SELECT DISCOUNT , 
   CASE WHEN DISCOUNT LIKE "%No Discoun%" then "NO" 
   else "Yes" 
   end from electronicsdata
   
UPDATE electronicsdata
SET discount_given = 
    CASE 
        WHEN discount LIKE '%No Discount%' THEN 'No'
        ELSE 'Yes'
    END;
    
alter table electronicsdata 
add  column MRP decimal (50 ,2) after Price ;

SELECT Price , Discount ,
   case when Discount like "%No Discount%"  then price 
        when Discount like "%After%" then round(price + regexp_replace(Discount , '[^0-9]',''),2) 
        else round(price*1.27,2) 
        end 
        from electronicsdata 
        
update electronicsdata 
set MRP = case when Discount like "%No Discount%"  then price 
        when Discount like "%After%" then round(price + regexp_replace(Discount , '[^0-9]',''),2) 
        else round(price*1.27,2) 
        end 
        
select * from electronicsdata 

select distinct discount from electronicsdata 

alter table electronicsdata change column Discount Discount_type text ;

select Discount_type ,
   case when discount_type like "%No Discount%" then "No Discount" 
		when discount_type like "%Price Valid%" then "Price Valid"
        when discount_type like "%After%" then "Flat Discount Offers"
        else "Special Discount" end 
        from electronicsdata   ;  
        
update electronicsdata 
set discount_type =  case when discount_type like "%No Discount%" then "No Discount" 
		when discount_type like "%Price Valid%" then "Price Valid"
        when discount_type like "%After%" then "Flat Discount Offers"
        else "Special Discount" end ;

-- drop currency column
alter table electronicsdata
drop column currency

select * from electronicsdata 

-- RATING 
   -- EXTRACT RATING 
   -- COUNT OF REVIEWS 

ALTER TABLE ELECTRONICSDATA 
ADD COLUMN AVERAGE_RATING DECIMAL(5,2) AFTER RATING 

select rating , REGEXP_SUBSTR(RATING , '[0-9]') FROM ELECTRONICSDATA 
SELECT RATING , REGEXP_SUBSTR(RATING , '[0-9]+(\\.[0-9]+)?') FROM ELECTRONICSDATA 
UPDATE ELECTRONICSDATA 
SET AVERAGE_RATING = REGEXP_SUBSTR(RATING , '[0-9]+(\\.[0-9]+)?') ;


-- Number of reviews 
select * from electronicsdata ;

select rating , regexp_substr(rating , '[0-9]+(\\.[0-9]+)?') from electronicsdata ;

select Rating , Regexp_SUBSTR(RATING, '[0-9]+(?= reviews)') from electronicsdata;

alter table electronicsdata
add column reviews_count int after rating 

update electronicsdata
set reviews_count = Regexp_SUBSTR(RATING, '[0-9]+(?= reviews)') 

select * from electronicsdata

alter table electronicsdata 
drop column rating 

-- 

select * from electronicsdata 

select distinct title from electronicsdata 

alter table electronicsdata 
add column Brandname varchar(30) after title  

select title , 
substring_index (title, " " ,1) from electronicsdata 

update electronicsdata 
set Brandname = substring_index(title," ",1)

select * from electronicsdata 

select distinct brandname from electronicsdata 

update electronicsdata 
set Brandname = "Apple" 
where brandname like "%mac%" or brandname like "%ipad%" or brandname like "%Airpods%"

-- 
select * from electronicsdata 
select * from electronicsdata order by rand() limit 5

-- Data Cleaning Task Completed 

-- Performing EDA 

-- Univariate Analysis { Numerical Column } 
-- Price 
-- 1 NULL VALUES 
SELECT COUNT(*) FROM ELECTRONICSDATA WHERE PRICE IS NULL 

-- 2. FIND MIN , MAX , AVERAGE , STD 
SELECT MIN(PRICE) AS MINIMUM ,
MAX(PRICE) AS MAXIMUM , 
AVG(PRICE) AS AVERAGE , 
STD(PRICE) AS STD 
FROM ELECTRONICSDATA 

ALTER TABLE ELECTRONICSDATA 
MODIFY COLUMN PRICE DECIMAL(20,2) 

SELECT * 
FROM ELECTRONICSDATA 
WHERE PRICE NOT REGEXP '^[0-9]+(\.[0-9]{1,2})?$' OR PRICE IS NULL;

DELETE FROM ELECTRONICSDATA 
WHERE `Sub Category` = 'Home Security Systems & Cameras' and Brandname = "Lorex";

ALTER TABLE ELECTRONICSDATA 
MODIFY COLUMN PRICE DECIMAL(20,2)

SELECT MIN(PRICE) AS MINIMUM ,
MAX(PRICE) AS MAXIMUM , 
AVG(PRICE) AS AVERAGE , 
STD(PRICE) AS STD 
FROM ELECTRONICSDATA 

-- PERCENTILE
SEELCT price , max(percentile) from
( 
SELECT PRICE , ROUND(PERCENT_RANK() OVER (ORDER BY PRICE),2) AS PERCENTILE FROM ELECTRONICSDATA 
)k group by price 

delimiter //
create procedure GetPriceBypercentile(in percentilevalue decimal(3,2), out price_limit decimal(10,2))
begin 
select max(price)
into price_limit 
from 
(
select price , round(percent_rank() over (order by price),2) as percentile from electronicsdata
)k
where percentile = percentilevalue;
end // 
delimiter ;

call GetPriceBypercentile(0.25 , @q1);
call GetPriceBypercentile(0.50 , @q2);
call GetPriceBypercentile(0.73, @q3);
select @q1 as 'Quarter1' , @q2 as 'Median' , @q3 as 'Quarter 3'

-- Outliers
select * from electronicsdata where price <(@q1-1.5*(@q3-@q1)) or price > (@q1+1.5*(@q3-@q1))  -- > positively skewness distribution 

-- histogram 


SELECT Buckets , repeat("*",count(*)) from 
(
select price ,
case 
   WHEN PRICE BETWEEN 0 AND 500 THEN '0-0.5K'
   WHEN PRICE BETWEEN 501 AND 1500 THEN '0.5K-1.5K'
   WHEN PRICE BETWEEN 1501 AND 3000 THEN '1.5K-3K'
   WHEN PRICE BETWEEN 3001 AND 6000 THEN '3K-6K'
   ELSE '>6K'
   END AS 'BUCKETS'
FROM ELECTRONICSDATA
)k
group by buckets

-- categorical column 
-- 1 null values

select count(*) from electronicsdata where `sub category` is null 

-- 
select `sub category` , count(`sub category`) as counts from electronicsdata group by `sub category`


-- BIVARIATE ANALYSIS 
-- NUMERICAL NUMERICAL COLUMNS 
select * from electronicsdata

-- scatter plot 
select reviews_count , Average_rating from Electronicsdata 

-- covariance 
select 
round(sum((average_rating - (select avg (average_rating) from electronicsdata))*
(reviews_count - (select avg(reviews_count) from electronicsdata)))/
(count(*) -1 ),2) as covariance 
from electronicsdata 


-- correlation 
select 
(round(sum((average_rating - (select avg (average_rating) from electronicsdata))*
(reviews_count - (select avg(reviews_count) from electronicsdata)))/
(count(*) -1 ),2))/
(std(average_rating)*std(reviews_count))
as corelation 
from electronicsdata 
--  > very weak positive linear relation 

-- slope 
SELECT ROUND(
    SUM(
        (average_rating - (SELECT AVG(average_rating) FROM electronicsdata)) *
        (reviews_count - (SELECT AVG(reviews_count) FROM electronicsdata))
    ) /
    SUM(
        POWER(
            average_rating - (SELECT AVG(average_rating) FROM electronicsdata),
            2
        )
    ),
2) AS result
FROM electronicsdata;

-- categorical - categorical column 
select * from electronicsdata 

select *   from electronicsdata where brandname like "%$%" 
update electronicsdata 
set brandname = "Nintendo" where brandname like "%$%"

select brandname ,
   count(distinct(`Sub category`)) as sectors 
from electronicsdata
group by brandname 

-- numerical - categorical analysis
select * from electronicsdata
select brandname ,
round(MIN(PRICE),2) AS MINIMUM ,
round(MAX(PRICE),2) AS MAXIMUM , 
round(AVG(PRICE),2) AS AVERAGE , 
round(STD(PRICE),2) AS STD 
FROM ELECTRONICSDATA 
group by brandname 

-- multivariate analysis 
select `sub category` , round(sum((Price - (select avg (Price) from electronicsdata))*
(MRP - (select avg(MRP) from electronicsdata)))/
(count(*) -1 ),2) as covariance 
FROM ELECTRONICSDATA
GROUP BY `SUB CATEGORY`




































        


        
        
        
		
        







