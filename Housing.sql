SELECT * FROM Cleaning.housing;
-- Change Sale date format and datatype and other columns
SELECT SaleDate, CONVERT(SaleDate, DATE) as SaleDateConverted
FROM Cleaning.housing;

ALTER TABLE Cleaning.housing
ADD SaleDateConverted DATE;

UPDATE Cleaning.housing
SET SaleDateConverted = CONVERT(SaleDate, DATE);

ALTER TABLE Cleaning.housing
DROP COLUMN SaleDate

ALTER TABLE Cleaning.housing
MODIFY COLUMN UniqueID text;

-- ✅ DONE.
-- ---------------------------------------------------------------------------------------------------------------------------------------

-- POPULATE PROPERTY ADDRESS DATA 
-- --ParcelID is same as address --> fill empty addresses using corresponding parcelID
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress,b.PropertyAddress) as PropertyAddressPopulated -- can use COALESCE too
FROM Cleaning.housing a
JOIN Cleaning.housing b -- Put together rows w same Parcelid & diff uniqueid (so it's a diff row)
	on a.ParcelID = b.ParcelID 
    AND a.UniqueID <> b.UniqueID

-- -- Temp table to add in Populated address column
DROP TEMPORARY TABLE IF EXISTS Cleaning.UpdatedPropertyAddress;
CREATE TEMPORARY TABLE Cleaning.UpdatedPropertyAddress(
a_ParcelID VARCHAR(50), 
a_PropertyAddress VARCHAR(100), 
b_ParcelID VARCHAR(50), 
b_PropertyAddress VARCHAR(100)
);

INSERT INTO Cleaning.UpdatedPropertyAddress 
(SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress. -- adds these 4 colms into temp table
FROM Cleaning.housing a
JOIN Cleaning.housing b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL);

-- Join filled temp table with original table, to replace unpopulated address with populated address column
SET SQL_SAFE_UPDATES=0;
 
UPDATE Cleaning.housing
INNER JOIN Cleaning.UpdatedPropertyAddress
	ON Cleaning.housing.ParcelID = Cleaning.UpdatedPropertyAddress.a_ParcelID
SET Cleaning.housing.PropertyAddress = Cleaning.UpdatedPropertyAddress.b_PropertyAddress;

-- -- Check for nulls in Property Address column
SELECT *
FROM Cleaning.housing
WHERE PropertyAddress is null

-- ✅ DONE. Null Property Addresses filled with correct address
 
-- ---------------------------------------------------------------------------------------------------------
-- Break out address into Address and City columns

SELECT PropertyAddress
FROM Cleaning.housing

SELECT
SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1 ) as Address, -- start at 1 until ',' 
SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) +1, LENGTH(PropertyAddress)) as City -- start at space after ',' until end
FROM Cleaning.housing

-- 1. Add empty address coln
ALTER TABLE Cleaning.housing
ADD Address VARCHAR (255);
-- 2. Add split up string
UPDATE Cleaning.housing
SET Address = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) -1 )

-- do same for city
ALTER TABLE Cleaning.housing
ADD City VARCHAR (255);

UPDATE Cleaning.housing
SET City = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) +1, LENGTH(PropertyAddress))

-- Check
SELECT *
FROM Cleaning.housing
-- ✅ DONE 
-- Break Owner address --> Address + City + State 
-- Create function similar to parsename * -- * -- * -- * -- * -- * -- * -- * --
CREATE FUNCTION SPLIT_STR (
  x VARCHAR(255),
  delim VARCHAR(12),
  pos INT 
)
RETURNS VARCHAR(255)
DETERMINISTIC 
RETURN REPLACE(SUBSTRING(SUBSTRING_INDEX(x, delim, pos),
       LENGTH(SUBSTRING_INDEX(x, delim, pos -1)) + 1),
       delim, '');
-- * -- * -- * --  * -- * -- * -- * -- * -- * -- * -- * -- * -- * -- * -- * --
SELECT 
	SPLIT_STR(OwnerAddress, ',', 1) as OwnerStAddress,
    SPLIT_STR(OwnerAddress, ',', 2) as OwnerCity,
    SPLIT_STR(OwnerAddress, ',', 3) as OwnerState
FROM Cleaning.housing
-- add columns into table -- st address
ALTER TABLE Cleaning.housing
ADD OwnerStAddress VARCHAR (255);

UPDATE Cleaning.housing
SET OwnerStAddress = SPLIT_STR(OwnerAddress, ',', 1)
-- Owner city
ALTER TABLE Cleaning.housing
ADD OwnerCity VARCHAR (255);

UPDATE Cleaning.housing
SET OwnerCity = SPLIT_STR(OwnerAddress, ',', 2)
-- Owner state
ALTER TABLE Cleaning.housing
ADD OwnerState VARCHAR (255);

UPDATE Cleaning.housing
SET OwnerState = SPLIT_STR(OwnerAddress, ',', 3)
-- check
SELECT *
FROM Cleaning.housing
-- ✅ DONE.
-- --------------------------------------------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in column 'Sold as Vacant' 
SELECT distinct(SoldAsVacant), count(SoldAsVacant) -- shows Y,N,Yes,No but we want only Yes and No
FROM Cleaning.housing
GROUP BY SoldAsVacant

SELECT SoldAsVacant,
	CASE 
		WHEN'Y' THEN 'Yes'
        WHEN'N' THEN 'No'
        ELSE SoldAsVacant
        END
FROM Cleaning.housing

-- Update table with the same conditions        

UPDATE Cleaning.housing
SET SoldAsVacant = CASE 
			WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant
        END;

-- ✅ DONE
-- --------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates
-- Created temp table with rownum
WITH rownumCTE AS ( 
SELECT *,
	row_number() OVER (
    PARTITION BY 
		ParcelID,
        PropertyAddress, 
        SalePrice,
        SaleDateConverted,
        LegalReference
        order by UniqueID
        ) row_num
				
FROM Cleaning.housing
	-- order by ParcelID
)
 

-- delete duplicates    
SELECT *
FROM rownumCTE
    WHERE row_num > 1 -- shows all the duplicates 

DELETE 
FROM Cleaning.housing 
WHERE UniqueID IN (
	SELECT UniqueID 
	FROM (
		SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDateConverted, LegalReference ORDER BY UniqueID) AS row_num
		FROM Cleaning.housing
		) nash_table
WHERE row_num > 1
ORDER BY UniqueID);
-- ✅ DONE.
-- ---------------------------------------------------------------------------------------------------------------------------------
-- Delete unused columns
ALTER TABLE Cleaning.housing
DROP COLUMN OwnerAddress, -- already split
DROP COLUMN PropertyAddress, -- already split
DROP COLUMN TaxDistrict;
-- ✅ DONE.

SELECT *
FROM Cleaning.housing









