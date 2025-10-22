# Nashville_Housing-SQL-Project-30
## Project Overview

**Project Title**: Nashville Housing Analysis    
**Database**: `SQL_PROJECT_P30U`

This project is designed to demonstrate SQL skills and techniques typically used by data analysts to explore, clean, and analyze Nashville Housing dataset. The project involves setting up Nashville Housing database, performing exploratory data analysis (EDA), and answering specific business questions through SQL queries. This project is ideal for those who are starting their journey in data analysis and want to build a solid foundation in SQL.

## Objectives

1. **Set up a Nashvile database**: Create and populate a Nashville Housing database with the provided nashville data.
2. **Data Cleaning**: fixing duplicates, formatting dates, handling missing data, e.t.c.
3. **Exploratory Data Analysis (EDA)**: discovering insights about property prices, trends, and neighborhoods
4. **Business Analysis**: Use SQL dataset to solve some major real estate problems

## Project Structure

### 1. Database Setup

- **Database Creation**: The project starts by creating a database named `sql_project_p30`.
- **Table Creation**: A table named `nashvile_housing` is created to store the estate data. The table structure includes columns for UniqueID, ParcelID, LandUse, PropertyAddress, SaleDate, SalePrice, LegalReference, SoldAsVacant, OwnerName, OwnerAddress, Acreage, TaxDistrict, LandValue, BuildingValue, TotalValue, YearBuilt, Bedrooms, FullBath, HalfBath

```sql
CREATE DATABASE nashville_housing;

```

### 2. Duplicate the dataset

```sql
CREATE TABLE nashville_housing_dup
LIKE `nashville_housing`;

INSERT INTO nashville_housing_dup
SELECT *
FROM  `nashville_housing`;

```
### 2. Data Cleaning
- **Record Count**: Determine the total number of records in the dataset.
- **Category Count**: Identify all unique product categories in the dataset.
- **Null Value Check**: Check for any null values in the dataset and delete records with missing data.
- **Check for Duplicate**: Check for duplicate rows in the dataset
```sql
SELECT count(*)
FROM nashville_housing
;

SELECT COUNT(DISTINCT ParcelID)
from nashville_housing;
```
-- **CHECKING FOR DUPLICATE**
```sql
WITH DUP_ROW AS (
	SELECT *, ROW_NUMBER () OVER (PARTITION BY UniqueID, 
	ParcelID, LandUse, PropertyAddress, SaleDate, SalePrice, 
	LegalReference, SoldAsVacant, OwnerName, OwnerAddress, Acreage, 
	TaxDistrict, LandValue, BuildingValue, TotalValue, YearBuilt, 
	Bedrooms, FullBath, HalfBath) AS ROW_NUM
	FROM nashville_housing
)
SELECT *
FROM DUP_ROW
WHERE ROW_NUM > 1;
```
-- **NULL VALUE**
```sql
SELECT *
FROM nashville_housing
WHERE PropertyAddress = ""
OR PropertyAddress IS NULL;

DELETE
FROM nashville_housing
WHERE PropertyAddress = ""
OR PropertyAddress IS NULL;

SELECT *
FROM nashville_housing
WHERE ParcelID = ""
OR ParcelID IS NULL;

```
-- **WE SHOULD SPLIT THE PROPERADDRESS, ITS EASIER TO  GROUP BY  CITY OR STREET**
-- **WE SHOULD HAVE PROPERTYNUMBER AND STREETCITY**
 
 ```sql
WITH SPLIT AS (
SELECT propertyaddress, 
CASE
	WHEN LOCATE(' ',  PropertyAddress) > 0 
    THEN 
		LEFT(PropertyAddress, LOCATE(' ', PropertyAddress) - 1)
	ELSE
		PropertyAddress
	END AS PropertyNumber,
    CASE
	WHEN LOCATE(' ',  PropertyAddress) > 0 
    THEN 
		TRIM(SUBSTRING(PropertyAddress, LOCATE(' ', PropertyAddress) + 1))
	ELSE
		NULL
	END AS StreetCity
FROM nashville_housing
)
SELECT *
FROM SPLIT
where NumberPart < 1
;


ALTER TABLE nashville_housing
ADD PropertyNumber INT;

ALTER TABLE nashville_housing
ADD StreetCity text;

ALTER TABLE nashville_housing 
MODIFY COLUMN PropertyNumber text;

UPDATE nashville_housing
SET
PropertyNumber = CASE
	WHEN LOCATE(' ',  PropertyAddress) > 0 THEN 
		LEFT(PropertyAddress, LOCATE(' ', PropertyAddress) - 1)
	ELSE
		PropertyAddress
	END,
    StreetCity = CASE
	WHEN LOCATE(' ',  PropertyAddress) > 0 THEN 
		TRIM(SUBSTRING(PropertyAddress, LOCATE(' ', PropertyAddress) + 1))
	ELSE 
		NULL
	END;

```
-- **UPDATING INCOMPLETE CHARACTER IN SOLDASVACANT**
```sql
UPDATE nashville_housing
SET SoldAsVacant = 'Yes'
WHERE SoldAsVacant = 'Y'
OR SoldAsVacant = 'YES'
;

UPDATE nashville_housing
SET SoldAsVacant = 'No'
WHERE SoldAsVacant = 'N'
OR SoldAsVacant = 'NO'
;

```

```sql
SELECT COUNT(*) FROM retail_sales;
SELECT COUNT(DISTINCT customer_id) FROM retail_sales;
SELECT DISTINCT category FROM retail_sales;

SELECT * FROM retail_sales
WHERE 
    sale_date IS NULL OR sale_time IS NULL OR customer_id IS NULL OR 
    gender IS NULL OR age IS NULL OR category IS NULL OR 
    quantity IS NULL OR price_per_unit IS NULL OR cogs IS NULL;

DELETE FROM retail_sales
WHERE 
    sale_date IS NULL OR sale_time IS NULL OR customer_id IS NULL OR 
    gender IS NULL OR age IS NULL OR category IS NULL OR 
    quantity IS NULL OR price_per_unit IS NULL OR cogs IS NULL;
```

### 3. Data Analysis & Exploration
### - Let's dive into the real estate data world
### - while exploring we are also going to some some major real estate problems

### P1. WHAT'S THE AVERAGE AND TOTAL SALE PRICE PER YEAR
```sql
SELECT YEAR(`SaleDate`) `YEAR`, 
ROUND(AVG(SalePrice),2) AS AVG_SALE_PY, SUM(SalePrice)
FROM nashville_housing
GROUP BY `YEAR`
ORDER BY AVG_SALE_PY DESC;

```

### P2. WHICH CITY HAVE THE HIGHEST AVERAGE PRICE
```sql
SELECT StreetCity, 
	AVG(SalePrice) AS AVG_PRICE, 
	RANK () OVER (ORDER BY AVG(SalePrice) ) AS RANKING
FROM nashville_housing
GROUP BY StreetCity
;

```
### P3. HOW HAS THE MARKET CHANGE OVER TIME
```sql
SELECT 
	SUBSTRING(SaleDate,1,7) AS `DATE`,
	 SalePrice, SUM(SalePrice) 
    OVER (PARTITION BY SUBSTRING(SaleDate,1,7) 
    ORDER BY SalePrice) AS ROLLING_PRICE
FROM nashville_housing;

```
### P4. TOTAL VALUE VS SALE PRICE
-- **TO KNOW THE VALUE OF EACH PROPERTIES COMPARED TO SELLING PRICE**
```sql
SELECT PropertyAddress, 
SalePrice, 
TotalValue, 
(SalePrice - TotalValue) AS ValueGap,
	CASE 
		WHEN SalePrice > TotalValue THEN 'AboveValue'
        WHEN SalePrice < TotalValue THEN 'BelowValue'
        ELSE 'AtValue'
    END 'Valuation'
    FROM nashville_housing
    ORDER BY ValueGap Desc;

```

# P5. TOP 20 CITY WITH THE THE BEST PROPERTY value
-- **IF ANYONE WAS GOING TO INVEST IN THIS ESTATE**
- **THEY CAN GET THEIR ANALYSIS FROM HERE**
-- **THE BEST PLACE TO BUY A PROPERTY**
  
```sql
SELECT StreetCity,  
ROUND(AVG(SalePrice - TotalValue),2) AS ValueGap
FROM nashville_housing
GROUP BY StreetCity
ORDER BY ValueGap DESC
LIMIT 20
;
```
# P6. AVERAGE SELL PRICE FOR VACANT AND NON-VACANT PROPERTIES
```sql
SELECT SoldAsVacant, AVG(SalePrice)
FROM nashville_housing
GROUP BY SoldAsVacant;

```
# P7. NEWER HOMES VS OLD HOMES WHICH SOLD MORE AND WHICH IS MORE EXPENSIVE
```sql
SELECT 
	CASE 
		WHEN YearBuilt < 2000 THEN 'Old Property'
        WHEN YearBuilt >= 2000 THEN 'New Property'
        ELSE 'Unknown'
	END AS Property_Age_Group,
    AVG(SalePrice) AS AvgSalPrice,
    MAX(SalePrice) AS MaxSalPrice,
    MIN(SalePrice) AS MinSalPrice
FROM nashville_housing
WHERE SalePrice IS NOT NULL
GROUP BY 
CASE 
		WHEN YearBuilt < 2000 THEN 'Old Property'
        WHEN YearBuilt >= 2000 THEN 'New Property'
        ELSE 'Unknown'
	END
        ;
```



# P8. DOMINATED AREA AS PER LAND USE
```sql
SELECT StreetCity, MAX(LandUse) AS DOMINANT, 
	ROW_NUMBER () OVER (PARTITION BY MAX(LandUse) ) AS ROW_NUM
FROM nashville_housing
GROUP BY StreetCity
ORDER BY ROW_NUM DESC;

```

## Findings

- **Most valuable cities**: We use the dataset to find the top 20 most valuable street which have good value rate.
- **Vacant and non vacant properties**: we found out that properties sold at non vacant is more expensive than that of vacant 
- **Old homes vs New old**: we get to know which is more expensive and more valuable either new or old homes
- **Dominanted area as per land use**which land occupant dominanted each street 

## Conclusion

This project serves as a comprehensive introduction to SQL for data analysts, covering database setup, data cleaning, exploratory data analysis, and business-driven SQL queries. The findings from this project can help drive business decisions by understanding sales patterns, customer behavior, and product performance.

## How to Use

1. **Clone the Repository**: Clone this project repository from GitHub.
2. **Set Up the Database**: Run the SQL scripts provided in the `database_setup.sql` file to create and populate the database.
3. **Run the Queries**: Use the SQL queries provided in the `analysis_queries.sql` file to perform your analysis.
4. **Explore and Modify**: Feel free to modify the queries to explore different aspects of the dataset or answer additional business questions.

## Author - Introverted-Analyst

This project is part of my portfolio, showcasing the SQL skills essential for data analyst roles. If you have any questions, feedback, or would like to collaborate, feel free to get in touch!

### Stay Updated and Join the Community

For more content on SQL, data analysis, and other data-related topics, make sure to follow me on social media and join our community:

- **Mailbox**: damedamedame174@gmail.com

Thank you for your support, and I look forward to connecting with you!
