USE [PALS2_OEMData]
GO

/****** Object:  StoredProcedure [dbo].[All_Cust_2025]    Script Date: 7/14/2025 2:10:04 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[All_Cust_2025]--<Procedure_Name, sysname, ProcedureName> 
	---- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

drop table if exists ##Cust2025
select 
Customerid, FirstName, MiddleName, LastName, Customer_FullName, EmailAddress, Gender, DateOfBirth,
Chronological_Age, Age_Categories_Chronological, Age_of_purchase, Age_Categories_atPurchase,
City, PostalCode, State_Code, County, [PFBC Region], scf_dest, ResidencyType, SKU, [Product Name], [License/Permit_Category],
sku_residency_type, O_create_date, ProcessYear
into ##Cust2025
from
(
select distinct c.customerid, c.FirstName, isnull(c.MiddleName, ' ') as MiddleName, c.LastName,
c.FirstName + '  ' + isnull(c.MiddleName, ' ') + '  ' + c.LastName as Customer_FullName, 
c.emailaddress, c.PhoneNumber, c.DateOfBirth, isnull(c1.County,'Unassigned') as 'County',
isnull(c1.[PFBC Region],'Unassigned') as [PFBC Region] , 
c1.Latitude,c1.Longitude,c1.[County Code Number] as County_Code,
a.Address1 as Address1,a.address2 as Address2,a.City,
a.PostalCode,
rl.name as State_Name, rl.code as State_Code, scf.[3‑Digit Destinations] as scf_dest,
datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,getdate())))  as Chronological_Age,
case when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,getdate())))  <=15 then '15 or Younger'
     when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,getdate()))) between 16 and 24 then '16 to 24 years'
	 when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,getdate()))) between 25 and 34 then '25 to 34 years'
	 when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,getdate()))) between 25 and 34 then '25 to 34 years'
     when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,getdate()))) between 35 and 44 then '35 to 44 years'
	 when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,getdate())))  between 45 and 54 then '45 to 54 years'
	 when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,getdate())))  between 55 and 64 then '55 to 64 years'
	 when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,getdate())))  between 65 and 74 then '65 to 74 years'
	 when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,getdate())))  between 75 and 84 then '75 to 84 years'
	 when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,getdate())))  >=85 then '85 years and older'
	 else 'N/A' end as Age_Categories_Chronological,
datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,o.created)))  as Age_of_purchase,
case when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,o.created)))  <=15 then '15 or Younger'
     when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,o.created)))  between 16 and 24 then '16 to 24 years'
	 when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,o.created)))  between 25 and 34 then '25 to 34 years'
	 when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,o.created)))  between 35 and 44 then '35 to 44 years'
	 when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,o.created)))  between 45 and 54 then '45 to 54 years'
	 when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,o.created)))  between 55 and 64 then '55 to 64 years'
	 when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,o.created))) between 65 and 74 then '65 to 74 years'
	 when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,o.created)))  between 75 and 84 then '75 to 84 years'
	 when datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,o.created)))  >=85 then '85 years and older'
	 else 'N/A' end as Age_Categories_atPurchase,
	 --when datediff(yyyy,DateofBirth, getdate()) between 25 and 34 then '25 to 34 years'
case when c.GenderId=23 then 'Male' else 'Female' end as Gender,
pr.SKU, pr.name as 'Product Name', 
case when pr.SKU in ('030', '031', '032','033','035', '050', '051', '052','053','055','060', '061', '063','065') then 'Multi-yr'
when pr.sku in ('105','120','121','124','156') then 'Lifetime'
when pr.sku in ('101','102','104','113','150','152','153','158') then 'Annual'
when pr.sku in ('106','107', '103') then 'Tourist'
when pr.sku in ('108') then '1-day Resident'
when pr.sku in ('110') then 'Voluntary Youth Fishing'
else 'N/A' end as 'License/Permit_Category',
case when pr.name like '%NON-RESIDENT%'then 'Non-resident' else 'resident' end as sku_residency_type,
o.Created as O_create_date, 
o.ResidencyType,
ol.ProcessYear,
rn=row_number() over(partition by c.[customerid] order by c.[customerid], o.[Created] desc) 
--pyr.YearTypeIdg
--into ##Vol2020
from [POSData_DailyReplication].[dbo].[Customer] c
join [POSData_DailyReplication].[dbo].[Order] o on o.customerid=c.id
join [POSData_DailyReplication].[dbo].[OrderLine] ol on ol.[OrderId]=o.id
join [POSData_DailyReplication].[dbo].[Product] pr on pr.sku=ol.sku
join [POSData_DailyReplication].[dbo].[ProcessYear] pyr on pyr.YearTypeId=pr.ProcessYearTypeId
join [POSData_DailyReplication].[dbo].[Address] a on a.Id=c.ResidencyAddressId
left join [POSData_DailyReplication].[dbo].[RegionsLookup] rl on rl.id=a.StateId
left join 
(select distinct co.*, reg.[County Name], reg.[PFBC Region], reg.Latitude, reg.Longitude, reg.[County Code Number]
from [dbo].[ZipCode_County] co
left join [dbo].[PA_County_Map_Region] reg
on reg.[County Name]=co.County) as c1 on left(a.PostalCode, 5)=cast(c1.ZIP_code as varchar(10))
--left join [dbo].[PAZip_Prefix_new] scf on cast(scf.zip_prefix as varchar(3))=left(a.PostalCode,3)
left join [dbo].[PAZip_Prefix] scf on cast(scf.zip_prefix as varchar(3))=left(a.PostalCode,3)
--where pr.sku in ('101','102','104','113')
where pr.sku in ('011','012','014','016','018','030','031','032','050','051','052','060','061','101','102','103','104','105','106','107','108','109','110',
'113','119','120','121','122','123','124','125','133','134','156')
--and pr.ProductType='License'
and ol.ProcessYear = '2025'
and cast(o.created as date) between '2024-12-01' and '2025-11-30' ) as a
where a.rn=1  --703888

--Populate 2008 to 2021 
drop table if exists ##Customers_AllLy20082024 
select 
EmailAddress,Customerid,FirstName, MiddleName, LastName, DateOfBirth,Gender,
SKU,[Product Name],O_create_date,ProcessYear as Recent_Process_Year, Validity
into ##Customers_AllLy20082024
from
(
select distinct c.customerid, c.FirstName, isnull(c.MiddleName, ' ') as MiddleName, c.LastName,
c.FirstName + '  ' + isnull(c.MiddleName, ' ') + '  ' + c.LastName as Customer_FullName, 
c.emailaddress, c.PhoneNumber, c.DateOfBirth, 
case when c.GenderId=23 then 'Male' else 'Female' end as Gender,
pr.SKU, pr.name as 'Product Name', 
o.Created as O_create_date, 
o.ResidencyType,
ol.ProcessYear,
case when pr.SKU in ('030', '031', '032','033','035') then ol.ProcessYear + 2
when pr.SKU in ('050', '051', '052','053','055') then ol.ProcessYear + 4
when pr.SKU in ('060', '061', '063','065') then ol.ProcessYear + 9
when pr.sku in ('105','120','121','124','156') then ol.ProcessYear + 50
else ol.ProcessYear end as 'Validity',
rn=row_number() over(partition by c.[customerid] order by c.[customerid], o.[Created] desc) 
from [POSData_DailyReplication].[dbo].[Customer] c
join [POSData_DailyReplication].[dbo].[Order] o on o.customerid=c.id
join [POSData_DailyReplication].[dbo].[OrderLine] ol on ol.[OrderId]=o.id
join [POSData_DailyReplication].[dbo].[Product] pr on pr.sku=ol.sku
join [POSData_DailyReplication].[dbo].[ProcessYear] pyr on pyr.YearTypeId=pr.ProcessYearTypeId
join [POSData_DailyReplication].[dbo].[Address] a on a.Id=c.ResidencyAddressId
left join [POSData_DailyReplication].[dbo].[RegionsLookup] rl on rl.id=a.StateId
--left join 
--(select distinct co.*, reg.[County Name], reg.[PFBC Region]
--from [dbo].[ZipCode_County] co
--left join [dbo].[PA_County_Map_Region] reg
--on reg.[County Name]=co.County) as c1 on left(a.PostalCode, 5)=cast(c1.ZIP_code as varchar(10))
where pr.sku in ('011','012','014','016','018','030','031','032','050','051','052','060','061','101','102','103','104','105','106','107','108','109','110',
'113','119','120','121','122','123','124','125','133','134','156','033','035','053','055','063','065','150','152','153','158')
--and o.Year='2020'
--and ol.ProcessYear ='2019'
and cast(o.created as date) between '2007-12-01' and '2024-11-30') as a
where a.rn=1
--and a.Age_of_purchase >=18
--and (EmailAddress <> '' and EmailAddress is not null)


drop table if exists ##ret2025
select distinct a.* 
into ##ret2025
from ##Cust2025 a 
join ##Customers_AllLy20082024 b on b.customerid=a.customerid
where b.validity >='2024' --465443

drop table if exists ##rec2025
select a.* 
into ##rec2025
from ##Cust2025 a
left join ##Customers_AllLy20082024 b on b.customerid=a.customerid
where b.customerid is null  --93045

drop table if exists ##react2025
select a.*
into ##react2025
from ##Cust2025 a
left join ##Customers_AllLy20082024 b on b.customerid=a.customerid
where b.validity < '2024' --139022


drop table if exists ##Cust2025_PurFreq_r3
select a.*,
case when (a.customerid=ret.customerid) then 'Retained'
when (a.customerid=rec.customerid) then 'Recruited'
else 'Reactivated' end as 'R3_Status'
into ##Cust2025_PurFreq_r3
from ##Cust2025 a
left join ##ret2025 ret on ret.customerid=a.customerid
left join ##rec2025 rec on rec.customerid=a.customerid
left join ##react2025 react on react.customerid=a.customerid


select *, 
case when cast(dateofbirth as date) between '2010-01-01' and getdate() then 'Gen_Alpha'
when cast(dateofbirth as date) between '1997-01-01' and '2009-12-31' then 'Gen_Z'
when cast(dateofbirth as date) between '1981-01-01' and '1996-12-31' then 'Milenials'
when cast(dateofbirth as date) between '1965-01-01' and '1980-12-31' then 'Gen_X'
when cast(dateofbirth as date) between '1946-01-01' and '1964-12-31' then 'Boomers'
when cast(dateofbirth as date) between '1928-01-01' and '1945-12-31' then 'Silent Generation'
when cast(dateofbirth as date) between '1901-01-01' and '1927-12-31' then 'Greatest Generation'
else null end as Generation
into ##Cust2025_PurFreq_r3_gen
from ##Cust2025_PurFreq_r3


drop table if exists ##Ly2025_Multiyr
select Customerid,SKU,Order_Date,ProcessYear,Validity
into ##Ly2025_Multiyr
from (
select distinct c.customerid, pr.SKU, o.PostedDate as Order_Date, ol.ProcessYear,
case when pr.SKU in ('030', '031', '032') then ol.ProcessYear + 2
when pr.SKU in ('050', '051', '052') then ol.ProcessYear + 4
when pr.SKU in ('060', '061') then ol.ProcessYear + 9
when pr.sku in ('105','120','121','124','156') then ol.ProcessYear + 50
else ol.ProcessYear end as 'Validity',
rn=row_number() over(partition by c.[customerid] order by c.[customerid], o.[PostedDate] desc) 
from [POSData_DailyReplication].[dbo].[Customer] c
join [POSData_DailyReplication].[dbo].[Order] o on o.customerid=c.id
join [POSData_DailyReplication].[dbo].[OrderLine] ol on ol.[OrderId]=o.id
join [POSData_DailyReplication].[dbo].[Product] pr on pr.sku=ol.sku
join [POSData_DailyReplication].[dbo].[ProcessYear] pyr on pyr.YearTypeId=pr.ProcessYearTypeId
join [POSData_DailyReplication].[dbo].[Address] a on a.Id=c.ResidencyAddressId
left join [POSData_DailyReplication].[dbo].[County] co on co.Id=a.CountyId
where pr.sku in ( '030','031','032','050', '051','052','060','061','105','120','121','124','156','033','035','053','055','063','065')
and pr.ProductType='License'
and ol.ProcessYear between '2008' and '2025' -- for 2021 Retained 
--and ol.ProcessYear between '2008' and '2013' -- for 2018 Retained 
and c.CustomerId <>'111111111' ) as a
where a.rn < 2
--and o.year ='2017') as a
--and ol.ProcessYear='2020') as a

drop table if exists ##multiyr2025
select * into ##multiyr2025
from ##Ly2025_Multiyr
--where Validity >= '2020' --45,947 --for 2020 Process Year Retained (add these to 2020 Retained in R3)
where Validity >='2026'


drop table if exists ##Trout2025
select 
Customerid, FirstName, MiddleName, LastName, EmailAddress,  
SKU, [Product Name], O_create_date, ProcessYear
into ##Trout2025
from
(
select distinct c.customerid, c.FirstName, isnull(c.MiddleName, ' ') as MiddleName, c.LastName,
c.emailaddress, pr.SKU, pr.name as 'Product Name', 
o.Created as O_create_date,ol.ProcessYear,
rn=row_number() over(partition by c.[customerid] order by c.[customerid], o.[Created] desc) 
from [POSData_DailyReplication].[dbo].[Customer] c
join [POSData_DailyReplication].[dbo].[Order] o on o.customerid=c.id
join [POSData_DailyReplication].[dbo].[OrderLine] ol on ol.[OrderId]=o.id
join [POSData_DailyReplication].[dbo].[Product] pr on pr.sku=ol.sku
join [POSData_DailyReplication].[dbo].[ProcessYear] pyr on pyr.YearTypeId=pr.ProcessYearTypeId
join [POSData_DailyReplication].[dbo].[Address] a on a.Id=c.ResidencyAddressId
left join [POSData_DailyReplication].[dbo].[RegionsLookup] rl on rl.id=a.StateId
where pr.sku in ('033','035','053','055','063','065','150','152','153','158')
and ol.ProcessYear = '2025'
and cast(o.created as date) between '2024-12-01' and '2025-11-30' ) as a
where a.rn=1  --703888

--drop table if exists ##ann
--select a.* into ##ann from ##Cust2024_PurFreq_r3_gen a 
--left join ##multiyr2024 b on b.CustomerId=a.CustomerId where b.CustomerId is null
--and a.sku in ('101','102','104','113')  --706333

----drop table if exists ##ann_trout
--drop table if exists ann_trout_2023
--select a.*,b.sku as Trout_SKU,
--case when a.customerid=b.customerid then 'Trout' else 'No_Trout' end as Trout_Status
--into ann_trout_2023--##ann_trout
--from ##ann a
--left join ##Trout2023 b on b.customerid=a.CustomerId --(755347 rows affected)

--Annual LicenseTrout

drop table if exists ##ann2025
select a.* into ##ann2025 from ##Cust2025_PurFreq_r3_gen a 
left join ##multiyr2025 b on b.CustomerId=a.CustomerId where b.CustomerId is null
and a.sku in ('101','102','104','113')  --706333


--drop table if exists ##ann_trout
drop table if exists annlic_trout_2025
select a.*,b.sku as Trout_SKU,
case when a.customerid=b.customerid then 'Trout' else 'No_Trout' end as Trout_Status
into annlic_trout_2025--##ann_trout
from ##ann2025 a
left join ##Trout2025 b on b.customerid=a.CustomerId --(755347 rows affected)


--All LicenseTrout

drop table if exists alllic_trout_2025
select a.*,b.sku as Trout_SKU,
case when a.customerid=b.customerid then 'Trout' else 'No_Trout' end as Trout_Status
into alllic_trout_2025--##ann_trout
from ##Cust2025_PurFreq_r3_gen a
left join ##Trout2025 b on b.customerid=a.CustomerId --(755347 rows affected)


END
GO


