USE [PALS2_OEMData]
GO

/****** Object:  StoredProcedure [dbo].[SP_MonthlySalesrevenue5years]    Script Date: 7/14/2025 2:15:50 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SP_MonthlySalesrevenue5years]--<Procedure_Name, sysname, ProcedureName> 
	---- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DROP TABLE if exists ##MonthlyData;
WITH MultiYearLicenseTerms AS (
    SELECT SKU, DurationYears FROM (VALUES
        ('30', 3), ('31', 3), ('32', 3),
        ('50', 5), ('51', 5), ('52', 5),
        ('60', 10), ('61', 10)
    ) AS t(SKU, DurationYears)
),
-- Full license purchase history (back to 2008) — for R3 only
FullLicenseHistory AS (
    SELECT
        o.CustomerId,
        ol.ProcessYear,
        ol.SKU
    FROM [POSData_DailyReplication].[dbo].[Order] o
    JOIN [POSData_DailyReplication].[dbo].[OrderLine] ol ON o.Id = ol.OrderId
    JOIN [POSData_DailyReplication].[dbo].[Product] p ON ol.SKU = p.SKU
    WHERE
        cast(o.Created as date)>= '2008-12-01'
        AND o.Status = 'Complete'
        AND ol.Status = 'Active'
        AND p.Status = 'Active'
        AND p.ProductOwnerId = 11000
        AND ol.SKU IN (
            '030','031','032','050','051','052','060','061',
            '101','102','103','104','105','106','107','108',
            '109','110','113','119','120','121','122','123',
            '124','125','133','134'
        )
),
-- Expand multi-year license years for historical R3 data
ExpandedFullLicenseYears AS (
    SELECT
        flh.CustomerId,
        flh.ProcessYear + n.Number AS ProcessYear
    FROM FullLicenseHistory flh
    LEFT JOIN MultiYearLicenseTerms mlt ON flh.SKU = mlt.SKU
    JOIN (
        SELECT 0 AS Number UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL
        SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
        SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    ) n ON 1=1
    WHERE n.Number < ISNULL(mlt.DurationYears, 1)
),
-- Main monthly summary dataset (limited to 2020-12 to 2025-04)
MonthlyData AS (
    SELECT
        CONVERT(char(7), o.Created, 120) AS [Month],  -- YYYY-MM format (faster than FORMAT)
        o.CustomerId,
        c.GenderId,
        CASE
            WHEN ol.SKU IN ('113','107','106','103','102','061','051','031') THEN 'Non-PA'
            WHEN ol.SKU IN (
                '030','031','032','050','051','052','060','061','101','102','103','104','105','106',
                '107','108','109','110','113','119','120','121','122','123','124','125','133','134'
            ) THEN 'PA'
            ELSE NULL
        END AS ResidencyStatus,
        CASE WHEN p.MultiYear = 1 THEN 'Multi-Year' ELSE 'Annual' END AS LicensePermitDuration,
        p.ProductType,
		ol.TotalCost,
		CASE
            WHEN ol.TotalCost > 2.00 THEN

                CASE
                    WHEN ag.AgentId IS NULL THEN (ol.TotalCost - 1.00 - 0.97)
                    WHEN ag.AgentId NOT IN ('4119','2129','74','513','514','5338','1486','515','516','517','64') 
                    THEN (ol.TotalCost - 1.00 - 0.97)
                    ELSE (ol.TotalCost - 0.97)
                END
            ELSE ol.TotalCost 
			END as Agent_TotalCost,
        ol.Quantity,
        ol.ProcessYear,
        ol.SKU,
        CASE
            WHEN ol.SKU IN (
                '030','031','032','050','051','052','060','061','101','102','103','104','105','106',
                '107','108','109','110','113','119','120','121','122','123','124','125','133','134'
            ) THEN 1 ELSE 0
        END AS IsLicense,
        CASE
            WHEN ol.SKU IN (
                '033','034','035','053','054','055','063','064','065','070','071','072','073','074','075','076',
                '077','078','079','080','081','082','083','084','085','093','093Y','094','094Y','095','095Y',
                '096','096Y','098','150','151','151SLE','152','153','157','157ME0','157ME3','157ME5','158',
                '158DVA','158DVL','160','161','162','163','164','165','166','167','168','170','171','178',
                '179','191','192'
            ) THEN 1 ELSE 0
        END AS IsPermit
    FROM [POSData_DailyReplication].[dbo].[Order] o
    JOIN [POSData_DailyReplication].[dbo].[OrderLine] ol ON o.Id = ol.OrderId
    JOIN [POSData_DailyReplication].[dbo].[Product] p ON ol.SKU = p.SKU
    JOIN [POSData_DailyReplication].[dbo].[Customer] c ON o.CustomerId = c.id
	left join [POSData_DailyReplication].[dbo].[Agent] ag on o.AgentID=ag.id
    WHERE
        cast(o.Created as date) between '2024-12-01' AND '2025-12-01'
        AND o.Status = 'Complete'
        AND ol.Status = 'Active'
        AND p.Status = 'Active'
        AND p.ProductOwnerId = 11000
)

-- Final Monthly Aggregation
SELECT
    md.[Month],

    -- Residency based only on license SKU
    COUNT(DISTINCT CASE WHEN md.ResidencyStatus = 'PA' THEN md.CustomerId END) AS PA_Customers,
    COUNT(DISTINCT CASE WHEN md.ResidencyStatus = 'Non-PA' THEN md.CustomerId END) AS NonPA_Customers,

    -- Gender
    COUNT(DISTINCT CASE WHEN md.GenderId = 23 THEN md.CustomerId END) AS Male_Customers,
    COUNT(DISTINCT CASE WHEN md.GenderId = 22 THEN md.CustomerId END) AS Female_Customers,
    COUNT(DISTINCT CASE WHEN md.GenderId = 3104 THEN md.CustomerId END) AS X_Customers,

    -- License duration
    COUNT(CASE WHEN md.LicensePermitDuration = 'Annual' THEN 1 END) AS Annual_Sales,
    COUNT(CASE WHEN md.LicensePermitDuration = 'Multi-Year' THEN 1 END) AS MultiYear_Sales,

    -- R3 (from your existing master table)
    COUNT(DISTINCT CASE WHEN r.R3_Status = 'Recruited' THEN r.Id END) AS Recruited_Customers,
    COUNT(DISTINCT CASE WHEN r.R3_Status = 'Retained' THEN r.Id END) AS Retained_Customers,
    COUNT(DISTINCT CASE WHEN r.R3_Status = 'Reactivated' THEN r.Id END) AS Reactivated_Customers,

    -- Number Tiles
    SUM(CASE WHEN md.IsLicense = 1 THEN md.Quantity ELSE 0 END) AS LicensesSold,
    SUM(CASE WHEN md.IsPermit = 1 THEN md.Quantity ELSE 0 END) AS PermitsSold,
    SUM(CASE WHEN md.IsLicense = 1 THEN md.Agent_TotalCost ELSE 0 END) AS LicenseRevenue,
    SUM(CASE WHEN md.IsPermit = 1 THEN md.Agent_TotalCost ELSE 0 END) AS PermitRevenue,

    -- Line graph
    SUM(md.Quantity) AS TotalProductsSold

into ##MonthlyData
--into ##MonthlyData2025
FROM MonthlyData md
LEFT JOIN (
--select customerid, CONVERT(char(7), O_create_date, 120) AS [Month], R3_Status from [PALS2_OEMData].[dbo].[alllic_trout_2021]
--union all
--select customerid, CONVERT(char(7), O_create_date, 120) AS [Month], R3_Status from [PALS2_OEMData].[dbo].[alllic_trout_2022]
--union all
--select customerid, CONVERT(char(7), O_create_date, 120) AS [Month], R3_Status from [PALS2_OEMData].[dbo].[alllic_trout_2023]
--union all
--select customerid, CONVERT(char(7), O_create_date, 120) AS [Month], R3_Status from [PALS2_OEMData].[dbo].[alllic_trout_2024]
--union all
select c.id, CONVERT(char(7), a.O_create_date, 120) AS [Month], a.R3_Status
from [PALS2_OEMData].[dbo].[alllic_trout_2025] a
join [POSData_DailyReplication].[dbo].[Customer] c on c.customerid=a.customerid
)as r ON md.CustomerId = r.Id AND md.[Month] = r.[Month]
GROUP BY md.[Month]
ORDER BY md.[Month];

------------------------------------------------------------------------------------------------
--Append to table [dbo].[Monthly_Sales_and_revenue_5years]
--repopulate 2025 License year metrics

DELETE from [dbo].[Monthly_Sales_and_revenue_5years]
where CONVERT(date, [Month] + '-01')>='2024-12-01'

INSERT INTO [dbo].[Monthly_Sales_and_revenue_5years]
SELECT * FROM ##MonthlyData

END
GO


