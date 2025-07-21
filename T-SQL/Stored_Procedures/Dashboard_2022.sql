USE [PALS2_OEMData]
GO

/****** Object:  StoredProcedure [dbo].[Dashboard_2022]    Script Date: 7/14/2025 2:11:51 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		Meghana Vasavada
-- Create date: 07/18/2022
-- Description:	Loads 2022 Customer table for Dashboard
-- =============================================
CREATE PROCEDURE [dbo].[Dashboard_2022]
	-- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	 -- Insert statements for procedure here

     --SELECT <@Param1, sysname, @p1>, <@Param2, sysname, @p2>
--Populate 2022 Customer DEmographics
drop table Cust2022
select 
Customerid, FirstName, MiddleName, LastName, Customer_FullName, EmailAddress, Gender, DateOfBirth,
Chronological_Age, Age_Categories_Chronological, Age_of_purchase, Age_Categories_atPurchase,
Address1, Address2, City, PostalCode, State_Name, State_Code, County, [PFBC Region],Latitude,
Longitude, County_Code, ResidencyType, SKU, [Product Name], sku_residency_type, O_create_date, ProcessYear
into Cust2022
from
(
select distinct c.customerid, c.FirstName, isnull(c.MiddleName, ' ') as MiddleName, c.LastName,
c.FirstName + '  ' + isnull(c.MiddleName, ' ') + '  ' + c.LastName as Customer_FullName, 
c.emailaddress, c.PhoneNumber, c.DateOfBirth, isnull(c1.County,'Unassigned') as 'County',
isnull(c1.[PFBC Region],'Unassigned') as [PFBC Region] , 
c1.Latitude,c1.Longitude,c1.[County Code Number] as County_Code,
a.Address1 as Address1,a.address2 as Address2,a.City,a.PostalCode,
rl.name as State_Name, rl.code as State_Code, 
datediff(yyyy,c.DateofBirth, getdate()) as Chronological_Age,
case when datediff(yyyy,c.DateofBirth, getdate()) <=15 then '15 or Younger'
     when datediff(yyyy,c.DateofBirth, getdate()) between 16 and 24 then '16 to 24 years'
	 when datediff(yyyy,c.DateofBirth, getdate()) between 25 and 34 then '25 to 34 years'
	 when datediff(yyyy,c.DateofBirth, getdate()) between 35 and 44 then '35 to 44 years'
	 when datediff(yyyy,c.DateofBirth, getdate()) between 45 and 54 then '45 to 54 years'
	 when datediff(yyyy,c.DateofBirth, getdate()) between 55 and 64 then '55 to 64 years'
	 when datediff(yyyy,c.DateofBirth, getdate()) between 65 and 74 then '65 to 74 years'
	 when datediff(yyyy,c.DateofBirth, getdate()) between 75 and 84 then '75 to 84 years'
	 when datediff(yyyy,c.DateofBirth, getdate()) >=85 then '85 years and older'
	 else 'N/A' end as Age_Categories_Chronological,
datediff(yyyy, c.DateofBirth, o.Created) as Age_of_purchase,
case when datediff(yyyy, c.DateofBirth, o.Created) <=15 then '15 or Younger'
     when datediff(yyyy, c.DateofBirth, o.Created) between 16 and 24 then '16 to 24 years'
	 when datediff(yyyy, c.DateofBirth, o.Created) between 25 and 34 then '25 to 34 years'
	 when datediff(yyyy, c.DateofBirth, o.Created) between 35 and 44 then '35 to 44 years'
	 when datediff(yyyy, c.DateofBirth, o.Created) between 45 and 54 then '45 to 54 years'
	 when datediff(yyyy, c.DateofBirth, o.Created) between 55 and 64 then '55 to 64 years'
	 when datediff(yyyy, c.DateofBirth, o.Created) between 65 and 74 then '65 to 74 years'
	 when datediff(yyyy, c.DateofBirth, o.Created) between 75 and 84 then '75 to 84 years'
	 when datediff(yyyy, c.DateofBirth, o.Created) >=85 then '85 years and older'
	 else 'N/A' end as Age_Categories_atPurchase,
	 --when datediff(yyyy,DateofBirth, getdate()) between 25 and 34 then '25 to 34 years'
case when c.GenderId=23 then 'Male' else 'Female' end as Gender,
pr.SKU, pr.name as 'Product Name', 
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
where pr.sku in ('011','012','014','016','018','030','031','032','050','051','052','060','061','101','102','103','104','105','106','107','108',
'113','119','120','121','122','123','124','125','133','134','156')
and pr.ProductType='License'
--and o.Year='2020'
and ol.ProcessYear='2022' and cast(o.created as date) >= '2021-12-01' ) as a
where a.rn=1  --631979


--Populate Prior license Years 

drop table if exists ##Licenses
select
distinct
Customerid,Customer_FullName,SKU,Order_Date,ProcessYear, Validity
into ##Licenses
from
(
select distinct c.customerid, c.FirstName + '  ' + isnull(c.MiddleName, ' ') + '  ' + LastName as Customer_FullName, 
c.emailaddress,
pr.SKU,-- pr.name as 'Product Name', 
o.Created as Order_Date, 
--o.ResidencyType,
ol.ProcessYear,
case when pr.SKU in ('030', '031', '032') then ol.ProcessYear + 2
when pr.SKU in ('050', '051', '052') then ol.ProcessYear + 4
when pr.SKU in ('060', '061') then ol.ProcessYear + 9
when pr.sku in ('105','120','121','124','156') then ol.ProcessYear + 50
else ol.ProcessYear end as 'Validity',
rn=row_number() over(partition by c.[customerid] order by c.[customerid], o.[Created] desc)
from [POSData_DailyReplication].[dbo].[Customer] c
join [POSData_DailyReplication].[dbo].[Order] o on o.customerid=c.id
join [POSData_DailyReplication].[dbo].[OrderLine] ol on ol.[OrderId]=o.id
join [POSData_DailyReplication].[dbo].[Product] pr on pr.sku=ol.sku
join [POSData_DailyReplication].[dbo].[ProcessYear] pyr on pyr.YearTypeId=pr.ProcessYearTypeId
where pr.sku in ('011','012','014','016','018','030','031','032','050','051','052','060','061','101','102','103','104','105','106','107','108','109','110',
'113','119','120','121','122','123','124','125','133','134','156')
and pr.ProductType='License' and
ol.ProcessYear between '2017' and '2021') as a
where validity <> '2022'

drop table if exists ##Lyrs
;with yrs as (
 select distinct Customerid, Customer_FullName, sku, Order_date, ProcessYear,
 rn=row_number() over(partition by Customerid, ProcessYear order by Order_date desc)
 from ##Licenses
 )
 select * into ##Lyrs from yrs 
 where rn=1
 --customerid='023151533'

drop table if exists ##License_Purchase
;with license as (
select Customerid, Customer_FullName, count(SKU) as license_Cnt
from ##Lyrs
group by Customerid, Customer_FullName, SKU
)
select Customerid, Customer_FullName, sum(license_Cnt) as Total_license_sku
into ##License_Purchase
from license
group by Customerid, Customer_FullName
order by customerid  --(2513552 rows affected) --(2513501 rows affected)


drop table if exists ##License_years
select CustomerId, Customer_FullName, ProcessYear 
into ##License_years
from (
select distinct CustomerId, Customer_FullName,
rn =row_number() over (partition by customerid order by Order_Date desc),
ProcessYear = stuff((select distinct ', ' + cast(ProcessYear as varchar(5))
from  ##Lyrs t1 
--from ##AnnVol2020 t1 
where t1.CustomerId=t2.CustomerId 
FOR XML PATH ('')) , 1, 1, '')
from ##Lyrs  t2) as a
where a.rn=1 
order by a.ProcessYear desc

----select * from ##License_years
drop table if exists ##License_yrs_Purchased
select a.*, b.ProcessYear
into ##License_yrs_Purchased
from ##License_Purchase a
join ##License_years b on a.CustomerId=b.customerid 

--Prior Trout Permits

drop table if exists ##trout_permits
select
distinct
Customerid,Customer_FullName,SKU,Order_Date,ProcessYear
into ##trout_permits
from
(
select distinct c.customerid, c.FirstName + '  ' + isnull(c.MiddleName, ' ') + '  ' + LastName as Customer_FullName, 
c.emailaddress,
pr.SKU,-- pr.name as 'Product Name', 
o.Created as Order_Date, 
--o.ResidencyType,
ol.ProcessYear,
rn=row_number() over(partition by c.[customerid] order by c.[customerid], o.[Created] desc)
from [POSData_DailyReplication].[dbo].[Customer] c
join [POSData_DailyReplication].[dbo].[Order] o on o.customerid=c.id
join [POSData_DailyReplication].[dbo].[OrderLine] ol on ol.[OrderId]=o.id
join [POSData_DailyReplication].[dbo].[Product] pr on pr.sku=ol.sku
join [POSData_DailyReplication].[dbo].[ProcessYear] pyr on pyr.YearTypeId=pr.ProcessYearTypeId
where pr.sku in ('033','035','053','055','063','065','140','141','142','143','144','145',
'150','152','153','156','158','158DVA','158DVL','FMS82')
--and pr.ProductType='Permits' and
and ol.ProcessYear between '2017' and '2021') as a

drop table if exists ##TPyrs
;with yrs as (
 select distinct Customerid, Customer_FullName, sku, Order_date, ProcessYear,
 rn=row_number() over(partition by Customerid, ProcessYear order by Order_date desc)
 from ##trout_permits
 )
 select * into ##TPyrs from yrs 
 where rn=1
 --customerid='023151533'

drop table if exists ##TP_Purchase
;with license as (
select Customerid, Customer_FullName, count(SKU) as license_Cnt
from ##TPyrs
group by Customerid, Customer_FullName, SKU
)
select Customerid, Customer_FullName, sum(license_Cnt) as Total_license_sku
into ##TP_Purchase
from license
group by Customerid, Customer_FullName
order by customerid  --(2513552 rows affected) --(2513501 rows affected)


drop table if exists ##TP_years
select CustomerId, Customer_FullName, ProcessYear 
into ##TP_years
from (
select distinct CustomerId, Customer_FullName,
rn =row_number() over (partition by customerid order by Order_Date desc),
ProcessYear = stuff((select distinct ', ' + cast(ProcessYear as varchar(5))
from  ##TPyrs t1 
--from ##AnnVol2020 t1 
where t1.CustomerId=t2.CustomerId 
FOR XML PATH ('')) , 1, 1, '')
from ##TPyrs  t2) as a
where a.rn=1 
order by a.ProcessYear desc

drop table if exists ##TP_yrs_Purchased
select a.*, b.ProcessYear
into ##TP_yrs_Purchased
from ##TP_Purchase a
join ##TP_years b on a.CustomerId=b.customerid 

--Populate 2008 to 2021 
drop table if exists ##Customers_AllLy20082021   
select 
EmailAddress,Customerid,FirstName, MiddleName, LastName, DateOfBirth,Gender,
--Age_Categories_Chronological,
--Address1, Address2,City,PostalCode,State_Name,State_Code,County,[PFBC Region],ResidencyType,
SKU,[Product Name],O_create_date,ProcessYear as Recent_Process_Year, Validity
into ##Customers_AllLy20082021
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
case when pr.SKU in ('030', '031', '032') then ol.ProcessYear + 2
when pr.SKU in ('050', '051', '052') then ol.ProcessYear + 4
when pr.SKU in ('060', '061') then ol.ProcessYear + 9
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
'113','119','120','121','122','123','124','125','133','134','156')
and pr.ProductType='License'
--and o.Year='2020'
--and ol.ProcessYear ='2019'
and cast(o.created as date) between '2007-12-01' and '2021-11-30') as a
where a.rn=1
--and a.Age_of_purchase >=18
--and (EmailAddress <> '' and EmailAddress is not null)


--Add Prior Licenses, Trou Permits and License Types

drop table if exists ##Cust2022_pryrs
select distinct a.*,
case when a.sku in ('012','014','016','018','103','106','107','108') then 'Short-Term'
when a.sku in ('030','031','032','050','051','052','060','061') then 'Multi-Year'
when a.sku in ('011','101','102','104','113','122','123','134') then 'Annual'
when a.sku in ('105','120','121','124','156') then 'Lifetime'
else 'Other License SKU' end as License_Category_Purchased
,isnull(b.total_license_sku,0) as #Prior_Lic_Years,
--case when b.total_license_sku is null then cast(0 as varchar (4)) + '%' else 
--cast(cast(round(b.total_license_sku * 100/5,0) AS DECIMAL(18,0)) as varchar(4)) + ' %' end as Perc_Prior_Lic
case when b.total_license_sku is null then cast(0 as varchar (4)) + '%' else 
cast(cast(round(b.total_license_sku * 100/5,0) AS DECIMAL(18,0)) as varchar(4)) + ' %' end as Perc_Prior_Lic
--case when b.total_license_sku is null then 0 else
--cast(round(b.total_license_sku * 100/5,0) AS DECIMAL(18,0)) end as Perc_Prior_Lic
, b.ProcessYear as Prior_Lic_Yrs ,tp.sku as 'TroutEriePermits', tp.[Trout/Erie_name], tp.Trout_Erie_Combo
,isnull(c.total_license_sku,0) as #Prior_TP_Years
, c.ProcessYear as Prior_TP_Yrs
into ##Cust2022_pryrs
from Cust2022 a
left join ##License_yrs_Purchased b on b.customerid=a.customerid
left join ##TP_yrs_Purchased c on c.customerid=a.customerid
left join (
select distinct
Customerid,Customer_FullName,SKU,Order_Date,ProcessYear, [Trout/Erie_name],Trout_Erie_Combo
from (
select distinct c.customerid, c.FirstName + '  ' + isnull(c.MiddleName, ' ') + '  ' + LastName as Customer_FullName, 
c.emailaddress,
pr.SKU, pr.[name] as 'Trout/Erie_name',
Case when pr.sku in ('033','053','063','140','143','144','145','150','153','156','FMS82') then 'Trout'
when pr.sku in ('035','055','065','142', '152','158','158DVA','158DVL') then 'Combo_Trout_Erie'
when pr.sku ='141' then 'Erie' else null end as 'Trout_Erie_Combo',
-- pr.name as 'Product Name', 
o.Created as Order_Date, 
--o.ResidencyType,
ol.ProcessYear,
rn=row_number() over(partition by c.[customerid] order by c.[customerid], o.[Created] desc)
from [POSData_DailyReplication].[dbo].[Customer] c
join [POSData_DailyReplication].[dbo].[Order] o on o.customerid=c.id
join [POSData_DailyReplication].[dbo].[OrderLine] ol on ol.[OrderId]=o.id
join [POSData_DailyReplication].[dbo].[Product] pr on pr.sku=ol.sku
join [POSData_DailyReplication].[dbo].[ProcessYear] pyr on pyr.YearTypeId=pr.ProcessYearTypeId
where pr.sku in ('033','035','053','055','063','065','140','141','142','143','144','145',
'150','152','153','156','158','158DVA','158DVL','FMS82')
--and pr.ProductType='Permits' and
and ol.ProcessYear = 2022) as a
where a.rn=1 ) as tp on tp.CustomerId=a.CustomerId

--Add R3 Status

drop table if exists ##ret2022
select distinct a.* 
into ##ret2022
from Cust2022 a
join ##Customers_AllLy20082021 b on b.customerid=a.customerid
where b.validity ='2021' --465443

drop table if exists ##rec2022
select a.* 
into ##rec2022
from Cust2022 a
left join ##Customers_AllLy20082021 b on b.customerid=a.customerid
where b.customerid is null  --93045

drop table if exists ##react2022
select a.*
into ##react2022
from Cust2022 a
left join ##Customers_AllLy20082021 b on b.customerid=a.customerid
where b.validity < '2021' --139022


drop table Cust2022_pryrs_r3
select a.*,
case when (a.customerid=ret.customerid and Prior_Lic_Yrs like '%2021%') then 'Retained'
when (a.customerid=rec.customerid) then 'Recruited'
else 'Reactivated' end as 'R3_Status'
into Cust2022_pryrs_r3
from ##Cust2022_pryrs a
left join ##ret2022 ret on ret.customerid=a.customerid
left join ##rec2022 rec on rec.customerid=a.customerid
left join ##react2022 react on react.customerid=a.customerid

--select * from Cust2022_pryrs_r3


END
GO


