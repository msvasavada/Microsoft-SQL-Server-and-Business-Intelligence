-------------------------------------------------------------------------------------------
-------ALL UNSUBSCRIBED/INVALID EMAILS-----------------------------------------------------
-------------------------------------------------------------------------------------------
use PALS2_OEMData

drop table if exists ##delemails
select * into ##delemails
from [dbo].[Unsubscribed_Invalid_Emails]


---------------------------------------------------------------------------------------------
-----------ALL FISHING CUSTOMERS (IMPROVED BLOCK)--------------------------------------------
---------------------------------------------------------------------------------------------

-- Thia will serve as the base for the subsequent, more specific customer queries.
DROP TABLE IF EXISTS ##AllFishCustomers;

-- Common Table Expression (CTE) for all license and permit purchases in the last 10 years
WITH AllPurchases AS (
    SELECT
        c.Id AS CustomerId,
        c.CustomerId AS CustomerNumber,
        c.FirstName,
        c.MiddleName,
        c.LastName,
        c.EmailAddress,
        CASE
            WHEN c.GenderId = 23 THEN 'Male'
            WHEN c.GenderId = 22 THEN 'Female'
            WHEN c.GenderId = 3104 THEN 'X'
            ELSE 'Unknown'
        END AS Gender,
        c.DateOfBirth,
        ol.ProcessYear,
        ol.SKU,
        p.Name AS ProductName,
        p.ProductType,
        o.Created AS OrderDate,
        -- Calculate Expiration Year based on multi-year and lifetime SKUs
        CASE
            WHEN p.Lifetime = 1 THEN 9999
            -- The multi-year SKU list combines licenses and permits for a single source of truth
            WHEN myl.DurationYears IS NOT NULL THEN ol.ProcessYear + myl.DurationYears
            ELSE ol.ProcessYear + 1 -- Default to 1 year if not specified otherwise
        END AS ExpirationYear,
        -- Assign R3 status based on purchase history
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM [POSData_DailyReplication].[dbo].[OrderLine] ol_prev
                JOIN [POSData_DailyReplication].[dbo].[Order] o_prev ON ol_prev.OrderId = o_prev.Id
                WHERE o_prev.CustomerId = c.Id AND ol_prev.ProcessYear = ol.ProcessYear - 1
            ) THEN 'Retained'
            WHEN EXISTS (
                SELECT 1
                FROM [POSData_DailyReplication].[dbo].[OrderLine] ol_prev
                JOIN [POSData_DailyReplication].[dbo].[Order] o_prev ON ol_prev.OrderId = o_prev.Id
                WHERE o_prev.CustomerId = c.Id AND ol_prev.ProcessYear < ol.ProcessYear - 1
            ) THEN 'Reactivated'
            ELSE 'Recruited'
        END AS R3Status
    FROM [POSData_DailyReplication].[dbo].[Customer] c
    JOIN [POSData_DailyReplication].[dbo].[Order] o ON c.Id = o.CustomerId
    JOIN [POSData_DailyReplication].[dbo].[OrderLine] ol ON o.Id = ol.OrderId
    JOIN [POSData_DailyReplication].[dbo].[Product] p ON ol.SKU = p.SKU
    -- Left join to a CTE or derived table for multi-year license/permit durations
    LEFT JOIN (
        VALUES
        -- Multi-Year Licenses
        ('30', 3), ('31', 3), ('32', 3), ('50', 5), ('51', 5), ('52', 5), ('60', 10), ('61', 10),
        -- Multi-Year Permits
        ('033', 3), ('034', 3), ('035', 3), ('074', 3), ('075', 3), ('076', 3), ('077', 3),
        ('053', 5), ('054', 5), ('055', 5), ('078', 5), ('079', 5), ('080', 5), ('081', 5),
        ('063', 10), ('064', 10), ('065', 10), ('082', 10), ('083', 10), ('084', 10), ('085', 10),
        ('192', 2), ('191', 1) -- Note: '191' is a 1-year launch permit, included for completeness
    ) AS myl(SKU, DurationYears) ON p.SKU = myl.SKU
    WHERE
        ol.ProcessYear >= YEAR(GETDATE()) - 10
        AND o.Status = 'Complete' -- Critical filter for valid orders [cite: 6]
        AND ol.Status = 'Active'   -- Critical filter for valid order lines [cite: 6]
        AND p.Status = 'Active'    -- Critical filter for active products [cite: 7]
        AND p.ProductOwnerId = 11000 -- Critical filter for product owner [cite: 8]
        AND c.StatusId NOT IN (34, 35, 36, 37, 38, 39)
        AND c.EmailAddress IS NOT NULL AND LTRIM(RTRIM(c.EmailAddress)) <> ''
        AND c.EmailAddress LIKE '%_@__%._%' -- Basic email format validation
),
-- Final customer data with generational info and cleaned email
FinalCustomerData AS (
    SELECT
        ap.*,
        -- Clean email address
        STUFF(
            SUBSTRING(ap.EmailAddress, 1, LEN(ap.EmailAddress) - CASE WHEN ap.EmailAddress LIKE '%.' THEN 1 ELSE 0 END),
            1, CASE WHEN ap.EmailAddress LIKE '.%' THEN 1 ELSE 0 END, ''
        ) AS RevisedEmail,
        -- Determine generation
        CASE
            WHEN ap.DateOfBirth >= '2010-01-01' AND ap.DateOfBirth <= GETDATE() THEN 'Gen Alpha'
            WHEN ap.DateOfBirth >= '1997-01-01' AND ap.DateOfBirth < '2010-01-01' THEN 'Gen Z'
            WHEN ap.DateOfBirth >= '1981-01-01' AND ap.DateOfBirth < '1997-01-01' THEN 'Millennials' -- Corrected Spelling
            WHEN ap.DateOfBirth >= '1965-01-01' AND ap.DateOfBirth < '1981-01-01' THEN 'Gen X'
            WHEN ap.DateOfBirth >= '1946-01-01' AND ap.DateOfBirth < '1965-01-01' THEN 'Boomers'
            WHEN ap.DateOfBirth >= '1928-01-01' AND ap.DateOfBirth < '1946-01-01' THEN 'Silent Generation'
            WHEN ap.DateOfBirth < '1928-01-01' THEN 'Greatest Generation'
            ELSE 'Unknown'
        END AS Generation,
        -- Add a row number to handle duplicate customers, prioritizing the most recent purchase
        ROW_NUMBER() OVER(PARTITION BY ap.CustomerNumber ORDER BY ap.OrderDate DESC) as rn
    FROM AllPurchases ap
)
-- Select the final, unique customer records into the temporary table
SELECT *
INTO ##AllFishCustomers
FROM FinalCustomerData
WHERE rn = 1;

------------------------------------------------------------------------------
---------All Trout Customers (IMPROVED BLOCK)---------------------------------
-------------------------------------------------------------------------------
-- This query now efficiently uses the ##AllFishCustomers table

DROP TABLE IF EXISTS ##Uniquetroutemails;

-- Use a CTE to select and rank trout customers from the existing temp table
WITH TroutCustomers AS (
    SELECT
        *,
        -- Rank customers by email to get the most recent record per email address
        ROW_NUMBER() OVER(PARTITION BY EmailAddress ORDER BY OrderDate DESC) as rn
    FROM
        ##AllFishCustomers
    WHERE
        -- Filter for specific Trout Permit SKUs [cite: 1]
        SKU IN ('033', '035', '053', '055', '063', '065', '150', '152', '153', '158')
)
-- Select the unique email records into the final temp table
SELECT
    CustomerNumber, -- Changed from Customerid to match ##AllFishCustomers
    FirstName,
    MiddleName,
    LastName,
    EmailAddress,
    SKU,
    ProductName,
    OrderDate, -- Changed from O_create_date
    ProcessYear,
    ExpirationYear -- Changed from Permit_Expiration to use consistent field
INTO ##Uniquetroutemails
FROM TroutCustomers
WHERE rn = 1;

---------------------------------------------------------------------------
------All Launch Permit Customers (IMPROVED BLOCK)-------------------------
---------------------------------------------------------------------------

DROP TABLE IF EXISTS ##LP_gen;

-- Use a CTE to select Launch Permit customers from the main temp table.
-- The generation is already calculated in ##AllFishCustomers, simplifying this query.
WITH LaunchPermitCustomers AS (
    SELECT
        CustomerNumber,
        FirstName,
        MiddleName,
        LastName,
        FirstName + ' ' + ISNULL(MiddleName, '') + ' ' + LastName AS Customer_FullName,
        EmailAddress,
        Gender,
        DateOfBirth,
        Generation, -- Using the already-calculated Generation field
        SKU,
        ProductName,
        -- Determine residency type based on product name
        CASE WHEN ProductName LIKE '%NON-RESIDENT%' THEN 'Non-resident' ELSE 'Resident' END AS sku_residency_type,
        OrderDate,
        ProcessYear,
        ExpirationYear
    FROM
        ##AllFishCustomers
    WHERE
        
        SKU IN ('191', '192')
)
SELECT *
INTO ##LP_gen
FROM LaunchPermitCustomers;

--------------------------------------------------------------------------------------
------------ALL BOAT REGISTRANTS (FROM CLEANED DATA)----------------------------------
--------------------------------------------------------------------------------------
-- This block is unchanged as requested.
DROP TABLE IF EXISTS ##boatreg;

WITH boatreg_cte AS (
    SELECT
        a.[REGISTRATION_NUMBER],
        a.[HULL_IDENTIFICATION_NUMBER],
        a.[EMAIL_NAME], -- This is the email from the clean boat registration table
        -- Name parsing logic (operates on REGISTRANT_NAME from the clean table)
        LTRIM(RTRIM(SUBSTRING(a.[REGISTRANT_NAME], 1, ISNULL(NULLIF(CHARINDEX(' ', a.[REGISTRANT_NAME]), 0) - 1, LEN(a.[REGISTRANT_NAME]))))) AS First_Name,
        LTRIM(RTRIM(SUBSTRING(a.[REGISTRANT_NAME],
                CHARINDEX(' ', a.[REGISTRANT_NAME]) + 1,
                CASE
                    WHEN CHARINDEX(' ', a.[REGISTRANT_NAME], CHARINDEX(' ', a.[REGISTRANT_NAME]) + 1) > 0 THEN
                        CHARINDEX(' ', a.[REGISTRANT_NAME], CHARINDEX(' ', a.[REGISTRANT_NAME]) + 1) - (CHARINDEX(' ', a.[REGISTRANT_NAME]) + 1)
                    ELSE LEN(a.[REGISTRANT_NAME]) -- If no second space, take rest of string for potential last name
                END
        ))) AS Middle_Name, -- This logic for Middle_Name might need review based on actual name structures
        LTRIM(RTRIM(SUBSTRING(a.[REGISTRANT_NAME],
                CASE
                    WHEN CHARINDEX(' ', a.[REGISTRANT_NAME], CHARINDEX(' ', a.[REGISTRANT_NAME]) + 1) > 0 THEN
                        CHARINDEX(' ', a.[REGISTRANT_NAME], CHARINDEX(' ', a.[REGISTRANT_NAME]) + 1) + 1
                    WHEN CHARINDEX(' ', a.[REGISTRANT_NAME]) > 0 THEN -- Only one space, assume second part is last name
                        CHARINDEX(' ', a.[REGISTRANT_NAME]) + 1
                    ELSE
                        1 -- No spaces, assume entire string is first/last name - adjust as needed
                END,
                LEN(a.[REGISTRANT_NAME])
        ))) AS Last_Name,
        a.[BIRTH_DATE],                      -- Already DATE type from [BoatRegTransactions_Clean]
        a.[LAST_REG_OR_RENEW_DATE] AS Reg_date, -- Already DATE type
        a.[REG_OR_RENEW_EXPRY_DATE] AS Exp_date, -- Already DATE type
        YEAR(a.[REG_OR_RENEW_EXPRY_DATE]) AS BoatExpirationYear,
        YEAR(a.[LAST_REG_OR_RENEW_DATE]) AS BoatProcessYear,
        a.[ADDRESS1],
        a.[ADDRESS2],
        a.[CITY],
        a.[STATE],
        a.[ZIP],                              -- Already INT type
        ISNULL(c1.[PFBC Region], 'Unassigned') AS [PFBC Region],
        ISNULL(c1.County, 'Unassigned') AS County,
        a.[BOAT_TYPE] AS Boat_Type,           -- Column name in clean table is BOAT_TYPE
        a.[POWERED],
        CASE
            WHEN a.[POWERED] = 'PB' THEN 'Powered'
            WHEN a.[POWERED] = 'UNPB' THEN 'Unpowered'
            ELSE 'N/A'
        END AS Boattype
    FROM
        [dbo].[BoatRegTransactions_Clean] a
    LEFT JOIN
        (SELECT DISTINCT
            zc.[ZIP_code], -- Assuming this is VARCHAR/NVARCHAR
            zc.County,
            pmr.[PFBC Region]
        FROM
            [dbo].[ZipCode_County] zc
        LEFT JOIN
            [dbo].[PA_County_Map_Region] pmr ON pmr.[County Name] = zc.County
        ) AS c1 ON SUBSTRING(CAST(a.[ZIP] AS NVARCHAR(10)), 1, 5) = c1.[ZIP_code] -- Join on ZIP, casting INT ZIP to string
    WHERE
        a.[EMAIL_NAME] IS NOT NULL AND LTRIM(RTRIM(a.[EMAIL_NAME])) <> ''
)
SELECT
    *
INTO
    ##boatreg
FROM
    boatreg_cte
WHERE
    -- Age calculation (BIRTH_DATE is already a date)
    DATEDIFF(YEAR, [BIRTH_DATE], GETDATE()) -
    CASE
        WHEN MONTH([BIRTH_DATE]) > MONTH(GETDATE()) OR
                (MONTH([BIRTH_DATE]) = MONTH(GETDATE()) AND DAY([BIRTH_DATE]) > DAY(GETDATE())) THEN 1
        ELSE 0
    END BETWEEN 18 AND 100
    AND EMAIL_NAME LIKE '%_@__%._%'; -- Basic email validation