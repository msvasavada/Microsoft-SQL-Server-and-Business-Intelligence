USE [PALS2_OEMData]
GO

/****** Object:  StoredProcedure [dbo].[SP_Sankeyflowtable2025]    Script Date: 7/14/2025 2:16:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SP_Sankeyflowtable2024]--<Procedure_Name, sysname, ProcedureName> 
	---- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--drop table if exists Cust_2025;
drop table if exists ##Lic_2024;
With Lic_2024 as (
select 
Customerid, SKU, [Product Name],[Licenses or Permits], 
sku_residency_type, [License/Permit_Duration], 
O_create_date, ProcessYear
from
(
select distinct c.customerid, 
pr.SKU, pr.name as 'Product Name', 
case when pr.ProductType='License' then 'All Licenses' else 'All Permits' end as 'Licenses or Permits',
case when pr.name like 'LAKE ERIE%' then 'Lake Erie'
when pr.name like 'TROUT%' then 'Trout'
when (pr.name like '%comb%' AND PRODUCTTYPE='permit') then 'Trout_Erie_combo' else '' end as Permit_Type,
case when pr.SKU in ('030', '031', '032','033','035') then '3-Year'
when pr.sku in ('050', '051','052','053','055') then '5-Year'
when pr.sku in ('060', '061', '063','065') then '10-Year'
when pr.sku in ('105','120','121','124','156','151SLE', '153','157', '157ME0',
'157ME3','157ME5', '158','158DVL',
'106','107', '103','108','110') then 'Lifetime and Other'
when pr.sku in ('101','102','104','113','150','151','152','153','158', '158DVA',
'142','109','122','123','119') then 'Annual'
--when pr.sku in ('106','107', '103') then 'Tourist'
--when pr.sku in ('108') then '1-day Resident'
--when pr.sku in ('110') then 'Voluntary Youth Fishing'
else 'N/A' end as 'License/Permit_Duration',
o.Created as O_create_date, 
case when pr.name like '%NON-RESIDENT%'then 'Non-Resident' else 'Resident' end as sku_residency_type,
ol.ProcessYear,
rn=row_number() over(partition by c.[customerid] order by c.[customerid], o.[Created] desc) 
--pyr.YearTypeIdg
--into ##Vol2020
from [POSData_DailyReplication].[dbo].[Customer] c
join [POSData_DailyReplication].[dbo].[Order] o on o.customerid=c.id
join [POSData_DailyReplication].[dbo].[OrderLine] ol on ol.[OrderId]=o.id
join [POSData_DailyReplication].[dbo].[Product] pr on pr.sku=ol.sku
--join [POSData_DailyReplication].[dbo].[ProcessYear] pyr on pyr.YearTypeId=pr.ProcessYearTypeId
where pr.sku in ('011','012','014','016','018','030','031','032','050','051',
'052','060','061','101','102','103','104','105','106','107','108','109','110',
'113','119','120','121','122','123','124','125','133','134','156')
and pr.ProductType='License'
and ol.ProcessYear = '2024'
AND o.Status = 'Complete'
AND ol.Status = 'Active'
AND pr.Status = 'Active'
and pr.ProductOwnerId = 11000
and cast(o.created as date) between '2023-12-01' and '2024-11-30' ) as a
where a.rn=1  --703888
)
select * into ##Lic_2024 from Lic_2024 
--select * from ##Cust_2025
--select * from ##Permits_2025

drop table if exists ##Permits_2024;
With Permits_2024 as (
select 
Customerid, SKU, [Product Name],[Licenses or Permits], Permit_Type, [Permit_Duration], sku_residency_type,  O_create_date, ProcessYear
from
(
select distinct c.customerid, 
pr.SKU, pr.name as 'Product Name', 
case when pr.ProductType='License' then 'All Licenses' else 'All Permits' end as 'Licenses or Permits',
case when pr.name like 'LAKE ERIE%' then 'Lake Erie'
when pr.name like 'TROUT%' then 'Trout'
when (pr.name like '%comb%' AND PRODUCTTYPE='permit') then 'Trout_Erie_combo'
when pr.sku in ('070','071','072','073','074','075','076','077','078','079','080','081','082','083','084','085') then 'Voluntary'
when pr.sku in ('191','192') then 'Launch'
else '' end as Permit_Type,
case when pr.SKU in ('192') then '2-Year'
when pr.SKU in ('033','035','074','075','076','077') then '3-Year'
when pr.sku in ('053','055', '078','079','080','081') then '5-Year'
when pr.sku in ('063','065', '082','083','084','085') then '10-Year'
when pr.sku in ('105','120','121','124','156','151SLE', '153','157', '157ME0',
'157ME3','157ME5', '158','158DVL') then 'Lifetime and Other'
when pr.sku in ('150','151','152','153','158', '158DVA','142','109','122','123',
'119','070','071','072','073', '191') then 'Annual'
else 'N/A' end as 'Permit_Duration',
o.Created as O_create_date, 
case when pr.name like '%NON-RESIDENT%'then 'Non-Resident' else 'Resident' end as sku_residency_type,
ol.ProcessYear,
rn=row_number() over(partition by c.[customerid] order by c.[customerid], o.[Created] desc) 
--pyr.YearTypeIdg
--into ##Vol2020
from [POSData_DailyReplication].[dbo].[Customer] c
join [POSData_DailyReplication].[dbo].[Order] o on o.customerid=c.id
join [POSData_DailyReplication].[dbo].[OrderLine] ol on ol.[OrderId]=o.id
join [POSData_DailyReplication].[dbo].[Product] pr on pr.sku=ol.sku
--join [POSData_DailyReplication].[dbo].[ProcessYear] pyr on pyr.YearTypeId=pr.ProcessYearTypeId
where pr.sku in ('033','035','053','055','063','065','150','151','151SLE','152',
'153','157','157ME0','157ME3','157ME5','158',
'158DVA','158DVL','070','071','072','073','074','075','076','077',
'078','079','080','081','082','083','084','085', '191','192')
and pr.ProductType='Permit'
and ol.ProcessYear = '2024'
AND o.Status = 'Complete'
AND ol.Status = 'Active'
AND pr.Status = 'Active'
and pr.ProductOwnerId = 11000
and cast(o.created as date) between '2023-12-01' and '2024-11-30' ) as a
where a.rn=1  --703888
)
select * into ##Permits_2024 from Permits_2024

DROP TABLE if exists ##Cust_License_Permit_2024

select a.customerid, a.[Licenses or Permits], a.sku_residency_type, a.[License/Permit_Duration],
case when a.customerid = b.customerid then 'With Permit' else 'Without Permit' end as Permit_Status,
isnull(b.permit_type,'') as permit_type, isnull(b.[Permit_Duration],'') as [Permit_Duration]
into ##Cust_License_Permit_2024
from ##Lic_2024 a
left join ##Permits_2024 b on b.customerid=a.customerid --636731

drop table if exists [dbo].[Sankey_flow_table_2024];
WITH AllLicenses AS (
    -- From All Licenses to Residency Type
    SELECT
        'All Licenses' AS Source,
        sku_residency_type AS Target,
        COUNT(DISTINCT customerid) AS CustomerCount
    FROM ##Cust_License_Permit_2024
    GROUP BY sku_residency_type
),
Residency AS (
    -- From Residency Type to Permit Status
    SELECT
        sku_residency_type AS Source,
        Permit_Status AS Target,
        COUNT(DISTINCT customerid) AS CustomerCount
    FROM ##Cust_License_Permit_2024
    GROUP BY sku_residency_type, Permit_Status
),
PermitStatus AS (
    -- For 'With Permit': Permit Status to Permit Type
    SELECT
        Permit_Status AS Source,
        permit_type AS Target,
        COUNT(DISTINCT customerid) AS CustomerCount
    FROM ##Cust_License_Permit_2024
    WHERE Permit_Status = 'With Permit'
    GROUP BY Permit_Status, permit_type
),
StatusDuration AS (
    -- For 'Without Permit' (anything not 'With Permit'): Permit Status to Duration (skip Permit Type)
    SELECT
        Permit_Status AS Source,
        [License/Permit_Duration] AS Target,
        COUNT(DISTINCT customerid) AS CustomerCount
    FROM ##Cust_License_Permit_2024
    WHERE Permit_Status <> 'With Permit'
    GROUP BY Permit_Status, [License/Permit_Duration]
),
TypeDuration AS (
    -- For 'With Permit': Permit Type to Permit Duration
    SELECT
        permit_type AS Source,
        Permit_Duration AS Target,
        COUNT(DISTINCT customerid) AS CustomerCount
    FROM ##Cust_License_Permit_2024
    WHERE Permit_Status = 'With Permit'
    GROUP BY permit_type, Permit_Duration
)

SELECT * INTO [dbo].[Sankey_flow_table_2024]
FROM AllLicenses
UNION ALL
SELECT * FROM Residency
UNION ALL
SELECT * FROM PermitStatus
UNION ALL
SELECT * FROM StatusDuration
UNION ALL
SELECT * FROM TypeDuration
ORDER BY Source, Target;


END 
GO


