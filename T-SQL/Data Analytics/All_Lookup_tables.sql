-------------------------------------------------------------------------------------------
-------ALL UNSUBSCRIBED/INVALID EMAILS-----------------------------------------------------
-------------------------------------------------------------------------------------------
--insert into Unsubscribed_Invalid_Emails
--select Email from [bounced_04012025]
--Insert every list required

--Insert Files shared by Janelle (both unsubsctibed and bounced
drop table if exists ##delemails
select * into ##delemails
from [dbo].[Unsubscribed_Invalid_Emails]


---------------------------------------------------------------------------------------------
-----------ALL 2025 FISHING CUSTOMERS--------------------------------------------------------
---------------------------------------------------------------------------------------------
drop table if exists ##Cust2025_Purchase_Email_System_format_gen_r3
;with Lic2025 as 
(
select 
CUSTOMERID,
EMAILADDRESS,
FIRSTNAME,
LASTNAME,
GENDER,
Generation,
DATEOFBIRTH,
STATE_CODE,
COUNTY,
[PFBC REGION] AS PFBCREGION,
PROCESSYEAR AS FISHPROCESSYEAR,
R3_STATUS,
O_create_date,
case when SKU in ('030', '031', '032') then ProcessYear + 2
when SKU in ('050', '051', '052') then ProcessYear + 4
when SKU in ('060', '061') then ProcessYear + 9
when sku in ('105','120','121','124','156') then '9999'
else ProcessYear end as 'ExpirationYear'
from [dbo].[alllic_trout_2025]
where Chronological_Age>=18--631979
and cast(O_create_date as date) <= '2025-04-30'
and (emailaddress <> '' and EmailAddress is not null)
and customerid not in ('992178889', '013274501')
--select * from ##Cust2025email
),Cust2025_purchase as 
(
select *,
case when ExpirationYear >= '2025' then 'Valid' else 'Lapsed' end as '2025PurchaseStatus'
from  Lic2025 
), Cust2025_Purchase_Email_System 
as 
(
select *,
rn=row_number() over(partition by customerid order by customerid, FISHPROCESSYEAR desc) 
from Cust2025_purchase
)
select *,
Revised_Email = STUFF(
    SUBSTRING(EmailAddress, 1, LEN(EmailAddress) -CASE WHEN EmailAddress LIKE '%.' THEN 1 ELSE 0 END),
    1, CASE WHEN EmailAddress like '.%' THEN 1 ELSE 0 END, ''
  ) 
into ##Cust2025_Purchase_Email_System_format_gen_r3
from Cust2025_Purchase_Email_System 
where rn=1

--select * from ##Cust2025_Purchase_Email_System_format_gen_r3


-----------------------------------------------------------------
--------All Prior License Customers till date--------------------
------------------------------------------------------------------

drop table if exists ##Cust20082025
select 
Customerid, FirstName, MiddleName, LastName, Customer_FullName, EmailAddress, Gender, DateOfBirth,
Chronological_Age,SKU, [Product Name], sku_residency_type, O_create_date, ProcessYear, ExpirationYear
into ##Cust20082025
from
(
select distinct c.customerid, c.FirstName, isnull(c.MiddleName, ' ') as MiddleName, c.LastName,
c.FirstName + '  ' + isnull(c.MiddleName, ' ') + '  ' + c.LastName as Customer_FullName, 
c.emailaddress, c.PhoneNumber, c.DateOfBirth, 
datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,getdate())))  as Chronological_Age,
case when c.GenderId=23 then 'Male' else 'Female' end as Gender,
pr.SKU, pr.name as 'Product Name', 
case when pr.name like '%NON-RESIDENT%'then 'Non-Resident' else 'Resident' end as sku_residency_type,
o.Created as O_create_date, 
o.ResidencyType,
ol.ProcessYear,
case when pr.SKU in ('030', '031', '032') then ol.ProcessYear + 2
when pr.SKU in ('050', '051', '052') then ol.ProcessYear + 4
when pr.SKU in ('060', '061') then ol.ProcessYear + 9
when pr.sku in ('105','120','121','124','156') then '9999'
else ol.ProcessYear end as 'ExpirationYear',
rn=row_number() over(partition by c.[customerid] order by c.[customerid], o.[Created] desc) 
--pyr.YearTypeIdg
--into ##Vol2020
from [POSData_DailyReplication].[dbo].[Customer] c
join [POSData_DailyReplication].[dbo].[Order] o on o.customerid=c.id
join [POSData_DailyReplication].[dbo].[OrderLine] ol on ol.[OrderId]=o.id
join [POSData_DailyReplication].[dbo].[Product] pr on pr.sku=ol.sku
--join [POSData_DailyReplication].[dbo].[ProcessYear] pyr on pyr.YearTypeId=pr.ProcessYearTypeId
--join [POSData_DailyReplication].[dbo].[Address] a on a.Id=c.ResidencyAddressId
where pr.sku in ('030','031','032','050','051','052','060','061','101',
'102','103','104','105','113','156', '011','012','014','016','018',
'106','107','108','119','120','121','124', '122','123','133','134')
and pr.ProductType='License'
and ol.ProcessYear between '2008' and '2025'
and cast(o.created as date) between '2007-12-01' and '2025-04-30'
and c.StatusId not in (34,35,36,37,38,39)
) as a
where a.rn=1
--and Chronological_Age>=18--631979

drop table if exists ##Cust20082025_gen
select *, 
case when cast(dateofbirth as date) between '2010-01-01' and getdate() then 'Gen_Alpha'
when cast(dateofbirth as date) between '1997-01-01' and '2009-12-31' then 'Gen_Z'
when cast(dateofbirth as date) between '1981-01-01' and '1996-12-31' then 'Milenials'
when cast(dateofbirth as date) between '1965-01-01' and '1980-12-31' then 'Gen_X'
when cast(dateofbirth as date) between '1946-01-01' and '1964-12-31' then 'Boomers'
when cast(dateofbirth as date) between '1928-01-01' and '1945-12-31' then 'Silent Generation'
when cast(dateofbirth as date) between '1901-01-01' and '1927-12-31' then 'Greatest Generation'
else null end as Generation
into ##Cust20082025_gen
from ##Cust20082025

drop table if exists ##Cust20082025_gen_unique
;with cte as (
select*,
rn=row_number() over( partition by emailaddress, firstname, lastname order by emailaddress, firstname, lastname,  Processyear desc)
from ##Cust20082025_gen
)
select * into ##Cust20082025_gen_unique from cte
where rn=1

--select * from ##Cust20082025_gen_unique

------------------------------------------------------------------------------
---------All Trout Customers--------------------------------------------------
-------------------------------------------------------------------------------
drop table if exists ##Trout20082025
select 
Customerid, FirstName, MiddleName, LastName, EmailAddress, SKU, [Product Name], 
O_create_date, ProcessYear, Permit_Expiration
into ##Trout20082025
from
(
select distinct c.customerid, c.FirstName, isnull(c.MiddleName, ' ') as MiddleName, c.LastName,
c.emailaddress, c.PhoneNumber, c.SecondaryPhoneNumber,c.DateOfBirth,
case when c.GenderId=23 then 'Male' else 'Female' end as Gender,
pr.SKU, pr.name as 'Product Name', 
case when pr.sku  in ('033','035') then ol.ProcessYear +2
when pr.sku in ('053','055') then ol.ProcessYear+4
when pr.sku in ('063','065') then ol.ProcessYear+9
when pr.sku in ('150','152') then ol.ProcessYear
else '9999' end as 'Permit_Expiration',
--case when pr.name like '%NON-RESIDENT%'then 'Non-resident' else 'resident' end as sku_residency_type,
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
--join [POSData_DailyReplication].[dbo].[ProcessYear] pyr on pyr.YearTypeId=pr.ProcessYearTypeId
--join [POSData_DailyReplication].[dbo].[Address] a on a.Id=c.ResidencyAddressId
where pr.sku in ('033','035','053','055','063','065','150','152','153','158')
--ol.ProcessYear between '2008' and '2022'
and cast(o.created as date) between '2007-12-01' and '2025-04-30'
and c.StatusId not in (34,35,36,37,38,39)) as a
where a.rn=1 

DROP TABLE if exists ##Uniquetroutemails
;with cte2 as (
select *,
rn=row_number() over (partition by emailaddress order by emailaddress, O_create_date desc)
from ##Trout20082025)
select * into ##Uniquetroutemails
from cte2 where rn=1

--select * from ##Uniquetroutemails

---------------------------------------------------------------------------
------All Launch Permit Customers------------------------------------------
---------------------------------------------------------------------------

drop table if exists ##LP
select 
Customerid, FirstName, MiddleName, LastName, Customer_FullName, EmailAddress, Gender, DateOfBirth,
--City, PostalCode, State_Code, County, [PFBC Region], scf_dest, ResidencyType, 
SKU, [Product Name], 
sku_residency_type, O_create_date, ProcessYear, ExpirationYear
into ##LP
from
(
select distinct c.customerid, c.FirstName, isnull(c.MiddleName, ' ') as MiddleName, c.LastName,
c.FirstName + '  ' + isnull(c.MiddleName, ' ') + '  ' + c.LastName as Customer_FullName, 
c.emailaddress, c.PhoneNumber, c.DateOfBirth, 
--isnull(c1.County,'Unassigned') as 'County',
--isnull(c1.[PFBC Region],'Unassigned') as [PFBC Region] , 
--c1.Latitude,c1.Longitude,c1.[County Code Number] as County_Code,
--a.Address1 as Address1,a.address2 as Address2,a.City,
--a.PostalCode,
--rl.name as State_Name, 
--rl.code as State_Code, 
--scf.[3‑Digit Destinations] as scf_dest,
datediff(year,c.DateofBirth,dateadd(month,-month(c.DateofBirth)+1,dateadd(day,-day(c.DateofBirth)+1,getdate())))  as Chronological_Age,
case when c.GenderId=23 then 'Male' else 'Female' end as Gender,
pr.SKU, pr.name as 'Product Name', 
case when pr.name like '%NON-RESIDENT%'then 'Non-resident' else 'resident' end as sku_residency_type,
o.Created as O_create_date, 
o.ResidencyType,
ol.ProcessYear,
case when pr.SKU in ('191','192') then ol.ProcessYear + 1 else ol.ProcessYear end as 'ExpirationYear',
rn=row_number() over(partition by c.[customerid] order by c.[customerid], o.[Created] desc) 
--pyr.YearTypeIdg
--into ##Vol2020
from [POSData_DailyReplication].[dbo].[Customer] c
join [POSData_DailyReplication].[dbo].[Order] o on o.customerid=c.id
join [POSData_DailyReplication].[dbo].[OrderLine] ol on ol.[OrderId]=o.id
join [POSData_DailyReplication].[dbo].[Product] pr on pr.sku=ol.sku
--join [POSData_DailyReplication].[dbo].[ProcessYear] pyr on pyr.YearTypeId=pr.ProcessYearTypeId
--join [POSData_DailyReplication].[dbo].[Address] a on a.Id=c.ResidencyAddressId
--left join [POSData_DailyReplication].[dbo].[RegionsLookup] rl on rl.id=a.StateId
--left join 
--(select distinct co.*, reg.[County Name], reg.[PFBC Region], reg.Latitude, reg.Longitude, reg.[County Code Number]
--from [dbo].[ZipCode_County] co
--left join [dbo].[PA_County_Map_Region] reg
--on reg.[County Name]=co.County) as c1 on left(a.PostalCode, 5)=cast(c1.ZIP_code as varchar(10))
----left join [dbo].[PAZip_Prefix_new] scf on cast(scf.zip_prefix as varchar(3))=left(a.PostalCode,3)
--left join [dbo].[PAZip_Prefix] scf on cast(scf.zip_prefix as varchar(3))=left(a.PostalCode,3)
where pr.sku in ('191','192')
and c.StatusId not in (34,35,36,37,38,39)
) as a
where a.rn=1 

DROP TABLE if exists ##LP_gen
select *, 
case when cast(dateofbirth as date) between '2010-01-01' and getdate() then 'Gen_Alpha'
when cast(dateofbirth as date) between '1997-01-01' and '2009-12-31' then 'Gen_Z'
when cast(dateofbirth as date) between '1981-01-01' and '1996-12-31' then 'Milenials'
when cast(dateofbirth as date) between '1965-01-01' and '1980-12-31' then 'Gen_X'
when cast(dateofbirth as date) between '1946-01-01' and '1964-12-31' then 'Boomers'
when cast(dateofbirth as date) between '1928-01-01' and '1945-12-31' then 'Silent Generation'
when cast(dateofbirth as date) between '1901-01-01' and '1927-12-31' then 'Greatest Generation'
else null end as Generation
into ##LP_gen
from ##LP

--------------------------------------------------------------------------------------
------------ALL BOAT REGISTRANTS------------------------------------------------------
--------------------------------------------------------------------------------------

--You'll need to check for inconsistencies before running this query
--select * from [dbo].[BoatRegTransactions_20170101-20250406]

update [dbo].[BoatRegTransactions_20170101-20250527]
set 
REGISTRANT_NAME=concat(REGISTRANT_NAME, ' ',BIRTH_DATE),
Birth_date=address1,
address1=address2,
address2=City,
City=[State],
[State]=zip,
Zip=Email_name,
Email_name=Make,
Make=[Year],
[Year]=[Length],
[Length]=Powered,
Powered=Boat_type,
Boat_type=Propulsion_type,
Propulsion_type=Hull_material,
Hull_material=Renewal_fee,
Renewal_fee=null
where Birth_date in (
select distinct Birth_date from [dbo].[BoatRegTransactions_20170101-20250527]
--[dbo].[BoatRegTransactions_20170101-20250501]
WHERE TRY_CONVERT(DATE, Birth_date, 120) IS NULL) 

drop table ##boatreg
;with boatreg as (
select a.[registration_number],a.[hull_identification_number],a.[EMAIL_NAME],
First_Name=
Ltrim(SubString(a.[registrant_name],1,Isnull(Nullif(CHARINDEX(' ',a.[registrant_name]),0),1000))) 
,Middle_Name=Ltrim(SUBSTRING(a.[registrant_name],CharIndex(' ',a.[registrant_name]),
Case When (CHARINDEX(' ',a.[registrant_name],CHARINDEX(' ',a.[registrant_name])+1)-CHARINDEX(' ',a.[registrant_name]))<=0 then 0 
else CHARINDEX(' ',a.[registrant_name],CHARINDEX(' ',a.[registrant_name])+1)-CHARINDEX(' ',a.[registrant_name]) end ))
,Last_Name=
Ltrim(SUBSTRING(a.[registrant_name],Isnull(Nullif(CHARINDEX(' ',a.[registrant_name],Charindex(' ',a.[registrant_name])+1),0),
CHARINDEX(' ',a.[registrant_name])),
Case when Charindex(' ',a.[registrant_name])=0 then 0 else LEN(a.[registrant_name]) end)),
cast([birth_date] as date) as birth_date,
cast([last_reg_or_renew_date] as date) as Reg_date,
cast([reg_or_renew_expry_date] AS DATE) as Exp_date,
year(cast([reg_or_renew_expry_date] AS DATE)) as BoatExpirationYear,
year(cast([last_reg_or_renew_date] AS DATE)) as BoatProcessYear, 
--PARSE([last_reg_or_renew_date] AS DATE USING 'en-US') as Reg_date,
--PARSE([reg_or_renew_expry_date] AS DATE USING 'en-US') Exp_date,
--year(PARSE([reg_or_renew_expry_date] AS DATE USING 'en-US')) as BoatExpirationYear,
--year(PARSE([last_reg_or_renew_date] AS DATE USING 'en-US')) as BoatProcessYear, 
a.[address1], a.[address2], a.[City], a.[State], a.[Zip], 
isnull(c1.[PFBC Region],'Unassigned') as [PFBC Region],
isnull(c1.county,'Unassigned') as County, 
a.[boat_type] as Boat_Type,a.Powered,
case when powered='PB' then 'Powered' when powered='UNPB' then 'Unpowered' else 'N/A' end as Boattype
--into ##boatreg
from [dbo].[BoatRegTransactions_20170101-20250527] a
--[dbo].[BoatRegTransactions_20170101-20250501] a--[dbo].[BoatRegTransactions_20170101-20250325]a--[dbo].[BoatRegTransactions_20170101-20250401] a
--from [dbo].[BoatRegTransactions_Master] a --[dbo].[BoatRegTransactions_20170101-20241126] a--[dbo].[BoatRegTransactions_20170101-20241001] a
left join 
(select distinct co.*, reg.[County Name], reg.[PFBC Region], reg.Latitude, reg.Longitude, reg.[County Code Number]
from [dbo].[ZipCode_County] co
left join [dbo].[PA_County_Map_Region] reg
on reg.[County Name]=co.County) as c1 on left(a.Zip, 5)=cast(c1.ZIP_code as varchar(10))
where a.[EMAIL_NAME]is not null and a.[EMAIL_NAME] <>' '
)
select * into ##boatreg from boatreg
where datediff(year,[birth_date],dateadd(month,-month([birth_date])+1,dateadd(day,-day([birth_date])+1,getdate()))) between 18 and 100
and email_name like '%@%'

--select * from ##boatreg order by Reg_date

select * from ##boatreg order by Reg_date