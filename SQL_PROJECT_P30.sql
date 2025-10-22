-- DROP TABLE IF EXISTS
-- DUPLICATE YOUR DATASET 
CREATE TABLE nashville_housing_dup
LIKE `nashville_housing`;

INSERT INTO nashville_housing_dup
SELECT *
FROM  `nashville_housing`;

-- DATA CLEANING

SELECT count(*)
FROM nashville_housing
;

SELECT COUNT(DISTINCT ParcelID)
from nashville_housing;

-- CHECKING FOR DUPLICATE

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

-- NULL VALUE

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

SELECT *
FROM nashville_housing
;

-- CHANGE COLUMN STRING

ALTER TABLE nashville_housing
MODIFY COLUMN `SaleDate` DATE;

-- WE SHOULD SPLIT THE PROPERADDRESS, ITS EASIER TO  GROUP BY  CITY OR STREET
-- WE SHOULD HAVE PROPERTYNUMBER AND STREETCITY
 
 
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
    
    
SELECT PropertyNumber
FROM nashville_housing
WHERE propertynumber = 0;


UPDATE nashville_housing
SET propertynumber = 0
WHERE propertynumber < 1
OR PropertyNumber = '';

UPDATE nashville_housing
SET StreetCity = REPLACE(StreetCity,'  ',' ')
;


-- UPDATING INCOMPLETE CHARACTER IN SOLDASVACANT 

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

SELECT *
FROM nashville_housing;



-- DATA EXPLORATION
-- WHILE EXPLORING WE ARE ALSO GOING TO SOLVE SOME MAJOR PROBLEMS 


-- P1. WHAT'S THE AVERAGE AND TOTAL SALE PRICE PER YEAR

SELECT YEAR(`SaleDate`) `YEAR`, 
ROUND(AVG(SalePrice),2) AS AVG_SALE_PY, SUM(SalePrice)
FROM nashville_housing
GROUP BY `YEAR`
ORDER BY AVG_SALE_PY DESC;


-- P2. WHICH CITY HAVE THE HIGHEST AVERAGE PRICE

SELECT StreetCity, 
	AVG(SalePrice) AS AVG_PRICE, 
	RANK () OVER (ORDER BY AVG(SalePrice) ) AS RANKING
FROM nashville_housing
GROUP BY StreetCity
;


-- P3. HOW HAS THE MARKET CHANGE OVER TIME

SELECT *
FROM nashville_housing;



SELECT 
	SUBSTRING(SaleDate,1,7) AS `DATE`,
	 SalePrice, SUM(SalePrice) 
    OVER (PARTITION BY SUBSTRING(SaleDate,1,7) 
    ORDER BY SalePrice) AS ROLLING_PRICE
FROM nashville_housing;

-- P4. TOTAL VALUE VS SALE PRICE
-- TO KNOW THE VALUE OF EACH PROPERTIES COMPARED TO SELLING PRICE

SELECT PropertyAddress, SalePrice, TotalValue, (SalePrice - TotalValue) AS ValueGap,
	CASE 
		WHEN SalePrice > TotalValue THEN 'AboveValue'
        WHEN SalePrice < TotalValue THEN 'BelowValue'
        ELSE 'AtValue'
    END 'Valuation'
    FROM nashville_housing
    ORDER BY ValueGap Desc;
    
-- P5. TOP 20 CITY WITH THE THE BEST PROPERTY value
-- IF ANYONE WAS GOING TO INVEST IN THIS ESTATE 
-- THEY CAN GET THEIR ANALYSIS FROM HERE 
-- THE BEST PLACE TO BUY A PROPERTY

SELECT StreetCity,  
ROUND(AVG(SalePrice - TotalValue),2) AS ValueGap
FROM nashville_housing
GROUP BY StreetCity
ORDER BY ValueGap DESC
LIMIT 20
;

-- P6. AVERAGE SELL PRICE FOR VACANT AND NON-VACANT PROPERTIES

SELECT *
FROM nashville_housing
;

SELECT SoldAsVacant, AVG(SalePrice)
FROM nashville_housing
GROUP BY SoldAsVacant;

-- P7. NEWER HOMES VS OLD HOMES WHICH SOLD MORE AND WHICH IS MORE EXPENSIVE
SELECT *
FROM nashville_housing;


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




-- P8. DOMINATED AREA AS PER LAND USE

SELECT StreetCity, MAX(LandUse) AS DOMINANT, 
	ROW_NUMBER () OVER (PARTITION BY MAX(LandUse) ) AS ROW_NUM
FROM nashville_housing
GROUP BY StreetCity
ORDER BY ROW_NUM DESC;