USE [PALS2_OEMData]
GO

/****** Object:  StoredProcedure [dbo].[Load_for_ConversionRevenue]    Script Date: 7/14/2025 2:12:39 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Load_for_ConversionRevenue]
	-- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--Load 2022 Customers Purchasing any license
drop table if exists ##Customers_L2022
select 
Customerid,
FirstName, MiddleName, LastName,
--Customer_FullName,
EmailAddress,
O_create_date
into ##Customers_L2022
from
(
select distinct c.customerid, c.FirstName, isnull(c.MiddleName, ' ') as MiddleName, c.LastName,c.EmailAddress,
datediff(yyyy,c.DateofBirth, getdate()) as Chronological_Age,
datediff(yyyy, c.DateofBirth, o.Created) as Age_of_purchase,
pr.SKU, pr.name as 'Product Name', 
o.Created as O_create_date, 
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
left join sku_purchase sp on sp.sku=pr.sku
--left join [POSData_DailyReplication].[dbo].[County] co on co.Id=a.CountyId
--left join [dbo].[PA_ZipCode_County] pac on a.PostalCode=cast(pac.[ZIP Code]as nvarchar(20))
--left join [dbo].[PALS_County_Region] cr on cr.Customerid_txt=c.CustomerId
--left join [dbo].[PALS_County_Region] cr on right(cr.address,5)=a.PostalCode
where pr.sku in (select distinct sku from sku_purchase)
and ol.ProcessYear='2022' ) as a
where a.rn=1 
    -- Insert statements for procedure here
	--SELECT <@Param1, sysname, @p1>, <@Param2, sysname, @p2>

--Load 2019 and 2020 for Test group

drop table if exists ##Customers_AllLy20192021
select 
EmailAddress,Customerid,FirstName, MiddleName, LastName, DateOfBirth,Gender,Age_Categories_Chronological,
County,[PFBC Region],ResidencyType,
SKU,[Product Name],O_create_date,ProcessYear,rn
into ##Customers_AllLy20192021
from
(
select distinct c.customerid, c.FirstName, isnull(c.MiddleName, ' ') as MiddleName, c.LastName,
c.FirstName + '  ' + isnull(c.MiddleName, ' ') + '  ' + c.LastName as Customer_FullName, 
c.emailaddress, c.PhoneNumber, c.DateOfBirth, isnull(c1.County,'Unassigned') as 'County',
isnull(c1.[PFBC Region],'Unassigned') as [PFBC Region],
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
o.Created as O_create_date, 
o.ResidencyType,
ol.ProcessYear,
rn=row_number() over(partition by c.[customerid] order by c.[customerid], o.[Created] desc) 
from [POSData_DailyReplication].[dbo].[Customer] c
join [POSData_DailyReplication].[dbo].[Order] o on o.customerid=c.id
join [POSData_DailyReplication].[dbo].[OrderLine] ol on ol.[OrderId]=o.id
join [POSData_DailyReplication].[dbo].[Product] pr on pr.sku=ol.sku
join [POSData_DailyReplication].[dbo].[ProcessYear] pyr on pyr.YearTypeId=pr.ProcessYearTypeId
join [POSData_DailyReplication].[dbo].[Address] a on a.Id=c.ResidencyAddressId
left join [POSData_DailyReplication].[dbo].[RegionsLookup] rl on rl.id=a.StateId
left join 
(select distinct co.*, reg.[County Name], reg.[PFBC Region]
from [dbo].[ZipCode_County] co
left join [dbo].[PA_County_Map_Region] reg
on reg.[County Name]=co.County) as c1 on left(a.PostalCode, 5)=cast(c1.ZIP_code as varchar(10))
--where pr.sku in ('101','102','104','113')
where pr.sku in ('011','012','014','016','018','101','102','104','113')
and pr.ProductType='License'
--and o.Year='2020'
and ol.ProcessYear  in ('2019','2020','2021')
and cast(o.created as date) between '2018-12-01' and '2021-11-30') as a
--where a.rn=1
--and a.Age_of_purchase >=18
where (a.EmailAddress <> '' and a.EmailAddress is not null)

drop table if exists ##Customers_AllLy2019
select distinct a.Customerid,
a.EmailAddress,
a.Firstname,
a.MiddleName,
a.LastName,
a.Gender,
a.Age_Categories_Chronological,
a.County,[PFBC Region],
a.sku,
a.O_Create_Date,
a.Processyear
into ##Customers_AllLy2019
from ##Customers_AllLy20192021 a
join [dbo].[Lapsed2019to2021] b on b.emailaddress=a.EmailAddress
where a.ProcessYear='2019'

drop table if exists ##Customers_AllLy2020
select distinct a.Customerid,
a.EmailAddress,
a.Firstname,
a.MiddleName,
a.LastName,
a.Gender,
a.Age_Categories_Chronological,
a.County,[PFBC Region],
a.sku,
a.O_Create_Date,
a.Processyear
into ##Customers_AllLy2020
from ##Customers_AllLy20192021 a
join [dbo].[Lapsed2019to2021] b on b.emailaddress=a.EmailAddress
where a.ProcessYear='2020'

drop table if exists ##Customers_AllLy2021
select distinct a.Customerid,
a.EmailAddress,
a.Firstname,
a.MiddleName,
a.LastName,
a.Gender,
a.Age_Categories_Chronological,
a.County,[PFBC Region],
a.sku,
a.O_Create_Date,
a.Processyear
into ##Customers_AllLy2021
from ##Customers_AllLy20192021 a
join [dbo].[Lapsed2019to2021] b on b.emailaddress=a.EmailAddress
where a.ProcessYear='2021'

drop table if exists ##Test_Male_2019
select a.* 
into ##Test_Male_2019
from ##Customers_AllLy2019 a 
left join ##Customers_AllLy2020 b on a.CustomerId=b.CustomerId
left join ##Customers_AllLy2021 c on a.CustomerId=c.customerid
where b.CustomerId is null and c.customerid is null
and a.Gender='Male'

--select * from ##Test_Male_2019

drop table if exists ##Test_Female_2019
select a.* 
into ##Test_Female_2019
from ##Customers_AllLy2019 a 
left join ##Customers_AllLy2020 b on a.CustomerId=b.CustomerId
left join ##Customers_AllLy2021 c on a.CustomerId=c.customerid
where b.CustomerId is null and c.customerid is null
and a.Gender='Female'

--select * from ##Test_Female_2019

drop table if exists ##Test_Male_2020
select a.* 
into ##Test_Male_2020
from ##Customers_AllLy2020 a 
--left join ##Customers_AllLy2020 b on a.CustomerId=b.CustomerId
left join ##Customers_AllLy2021 c on a.CustomerId=c.customerid
where  c.customerid is null
and a.Gender='Male'

drop table if exists ##Test_Female_2020
select a.* 
into ##Test_Female_2020
from ##Customers_AllLy2020 a 
--left join ##Customers_AllLy2020 b on a.CustomerId=b.CustomerId
left join ##Customers_AllLy2021 c on a.CustomerId=c.customerid
where  c.customerid is null
and a.Gender='Female'


--Load 2019 and 2020 for Control Group


drop table if exists ##Customers_NEAllLy20192021
select 
EmailAddress,Customerid,FirstName, MiddleName, LastName, DateOfBirth,Gender,Age_Categories_Chronological,
County,[PFBC Region],ResidencyType,
SKU,[Product Name],O_create_date,ProcessYear,rn
into ##Customers_NEAllLy20192021
from
(
select distinct c.customerid, c.FirstName, isnull(c.MiddleName, ' ') as MiddleName, c.LastName,
c.FirstName + '  ' + isnull(c.MiddleName, ' ') + '  ' + c.LastName as Customer_FullName, 
c.emailaddress, c.PhoneNumber, c.DateOfBirth, isnull(c1.County,'Unassigned') as 'County',
isnull(c1.[PFBC Region],'Unassigned') as [PFBC Region],
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
o.Created as O_create_date, 
o.ResidencyType,
ol.ProcessYear,
rn=row_number() over(partition by c.[customerid] order by c.[customerid], o.[Created] desc) 
from [POSData_DailyReplication].[dbo].[Customer] c
join [POSData_DailyReplication].[dbo].[Order] o on o.customerid=c.id
join [POSData_DailyReplication].[dbo].[OrderLine] ol on ol.[OrderId]=o.id
join [POSData_DailyReplication].[dbo].[Product] pr on pr.sku=ol.sku
join [POSData_DailyReplication].[dbo].[ProcessYear] pyr on pyr.YearTypeId=pr.ProcessYearTypeId
join [POSData_DailyReplication].[dbo].[Address] a on a.Id=c.ResidencyAddressId
left join [POSData_DailyReplication].[dbo].[RegionsLookup] rl on rl.id=a.StateId
left join 
(select distinct co.*, reg.[County Name], reg.[PFBC Region]
from [dbo].[ZipCode_County] co
left join [dbo].[PA_County_Map_Region] reg
on reg.[County Name]=co.County) as c1 on left(a.PostalCode, 5)=cast(c1.ZIP_code as varchar(10))
--where pr.sku in ('101','102','104','113')
where pr.sku in ('011','012','014','016','018','101','102','104','113')
and pr.ProductType='License'
--and o.Year='2020'
and ol.ProcessYear  in ('2019','2020','2021')
and cast(o.created as date) between '2018-12-01' and '2021-11-30') as a
--where a.rn=1
where a.Age_of_purchase >=18
and (a.EmailAddress ='' or a.EmailAddress is null)


drop table if exists ##Customers_NEAllLy2019
select distinct a.Customerid,
a.EmailAddress,
a.Firstname,
a.MiddleName,
a.LastName,
a.Gender,
a.Age_Categories_Chronological,
a.County,[PFBC Region],
a.sku,
a.O_Create_Date,
a.Processyear
into ##Customers_NEAllLy2019
from ##Customers_NEAllLy20192021 a
--join [dbo].[Lapsed2019to2021] b on b.emailaddress=a.EmailAddress
where a.ProcessYear='2019'

drop table if exists ##Customers_NEAllLy2020
select distinct a.Customerid,
a.EmailAddress,
a.Firstname,
a.MiddleName,
a.LastName,
a.Gender,
a.Age_Categories_Chronological,
a.County,[PFBC Region],
a.sku,
a.O_Create_Date,
a.Processyear
into ##Customers_NEAllLy2020
from ##Customers_NEAllLy20192021 a
--join [dbo].[Lapsed2019to2021] b on b.emailaddress=a.EmailAddress
where a.ProcessYear='2020'


drop table if exists ##Customers_NEAllLy2021
select distinct a.Customerid,
a.EmailAddress,
a.Firstname,
a.MiddleName,
a.LastName,
a.Gender,
a.Age_Categories_Chronological,
a.County,[PFBC Region],
a.sku,
a.O_Create_Date,
a.Processyear
into ##Customers_NEAllLy2021
from ##Customers_NEAllLy20192021 a
--join [dbo].[Lapsed2019to2021] b on b.emailaddress=a.EmailAddress
where a.ProcessYear='2021'


drop table if exists ##Control_Male_2019
select distinct a.* 
into ##Control_Male_2019
from ##Customers_NEAllLy2019 a 
left join ##Customers_NEAllLy2020 b on a.CustomerId=b.CustomerId
left join ##Customers_NEAllLy2021  c on a.CustomerId=c.customerid
where b.CustomerId is null and c.customerid is null
and a.sku in ('101','102','104','113')
and a.Gender='Male'


drop table if exists ##Control_Female_2019
select a.* 
into ##Control_Female_2019
from ##Customers_NEAllLy2019 a 
left join ##Customers_NEAllLy2020 b on a.CustomerId=b.CustomerId
left join ##Customers_NEAllLy2021  c on a.CustomerId=c.customerid
where b.CustomerId is null and c.customerid is null
and a.Gender='Female' and a.sku in ('101','102','104','113')

drop table if exists ##Control_Male_2020
select a.* 
into ##Control_Male_2020
from ##Customers_NEAllLy2020 a 
--left join ##Customers_AllLy2020 b on a.CustomerId=b.CustomerId
left join ##Customers_NEAllLy2021 c on a.CustomerId=c.customerid
where  c.customerid is null and a.sku in ('101','102','104','113')
and a.Gender='Male'

drop table if exists ##Control_Female_2020
select a.* 
into ##Control_Female_2020
from ##Customers_NEAllLy2020 a 
--left join ##Customers_AllLy2020 b on a.CustomerId=b.CustomerId
left join ##Customers_NEAllLy2021 c on a.CustomerId=c.customerid
where  c.customerid is null
and a.Gender='Female' and a.sku in ('101','102','104','113')

END
GO


