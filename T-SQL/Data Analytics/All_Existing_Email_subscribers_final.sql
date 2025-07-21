------------------------------------------------------------------
------TEMP TABLE from EXISTING SUBSCRIBERS------------------------
------------------------------------------------------------------
drop table ##Existing_emails_1
select 
EMAIL,
FIRSTNAME,
LASTNAME,
GENDER,
GENERATION,
STATECODE AS STATECODE,
COUNTY,
PFBCREGION,
FISHPROCESSYEAR,
CURRENTLICENSEYEAR,
FISHEXPIRATIONYEAR,
CURRENTR3STATUS,
TROUTEXPIRATION,
BOATPRIVILEGE,
BOATTYPE,
BOATPROCESSYEAR,
BOATEXPIRATIONYEAR,
LAUNCHPRIVILEGE,
LAUNCHPROCESSYEAR,
LAUNCHEXPIRATIONYEAR
INTO ##Existing_emails_1
FROM [dbo].[All_Existing_subscribers_Maestro_05012025]
--[dbo].[All_Existing_subscribers_Maestro_04012025]

--Here I'm working on copy of the master table
--select count(*) from ##Existing_emails_1 

------------------------------------------------------------------
------UPDATE TROUT EXPIRATION COLUMN------------------------
------------------------------------------------------------------
update a
set a.troutExpiration=cast(B.Permit_Expiration as varchar(5))
from ##Existing_emails_1 a
left join ##Uniquetroutemails b on b.emailaddress =a.email --and b.firstname=a.firstname and b.lastname=a.lastname
where troutexpiration <> cast(B.Permit_Expiration as varchar(5))

------------------------------------------------------------------
------UPDATE FISH LICENSE YEARS AND STATUS------------------------
------------------------------------------------------------------
update a
set a.FISHPROCESSYEAR=b.processyear, a.FISHEXPIRATIONYEAR =b.expirationyear,
a.CURRENTLICENSEYEAR=case when b.expirationyear >='2025' then 'Valid'
when b.expirationyear <'2025' then 'Lapsed' else 'NULL' end
from ##Existing_emails_1 a
left join ##Cust20082025_gen_unique b on b.emailaddress=a.email and b.firstname=a.firstname and b.lastname=a.lastname
where a.currentlicenseyear = 'NULL' 
or a.fishprocessyear <> b.processyear 
or a.FISHEXPIRATIONYEAR<> b.expirationyear

--check if the year and status meet the criteria
--select distinct FISHEXPIRATIONYEAR from ##Existing_emails_1 where CURRENTLICENSEYEAR ='Lapsed'
--select distinct FISHEXPIRATIONYEAR from ##Existing_emails_1 where CURRENTLICENSEYEAR ='Valid'

------------------------------------------------------------------
------UPDATE LAUNCH PERMIT STATUS---------------------------------
------------------------------------------------------------------
 update a
set a.LAUNCHPROCESSYEAR=cast(lp.processyear as nvarchar(255))
from ##Existing_emails_1 a
join ##lp lp on lp.emailaddress=a.email and a.email=lp.emailaddress --and a.firstname=lp.firstname and a.lastname=lp.lastname
where 
a.LAUNCHPROCESSYEAR <> cast(lp.processyear as nvarchar(255))

update a
set 
a.LAUNCHEXPIRATIONYEAR=cast(lp.expirationyear as nvarchar(255))
--a.LAUNCHPRIVILEGE='Launch'
from ##Existing_emails_1 a
join ##lp lp on lp.emailaddress=a.email and a.email=lp.emailaddress --and a.firstname=lp.firstname and a.lastname=lp.lastname
where 
a.LAUNCHEXPIRATIONYEAR <> cast(lp.expirationyear as nvarchar(255))
--a.LAUNCHEXPIRATIONYEAR<>lp.expirationyear

 update a
set 
a.LAUNCHPRIVILEGE='Launch'
from ##Existing_emails_1 a
join ##lp lp on lp.emailaddress=a.email and a.email=lp.emailaddress and a.firstname=lp.firstname and a.lastname=lp.lastname
where 
--a.LAUNCHPRIVILEGE ='NULL' and 
a.LAUNCHEXPIRATIONYEAR is not null or a.LAUNCHPROCESSYEAR is not null
--a.LAUNCHEXPIRATIONYEAR<>lp.expirationyear

------------------------------------------------------------------
------UPDATE BOAT REGISTRATION STATUS ----------------------------
------------------------------------------------------------------

drop table if exists ##Existing_emails_1_boat
;with boat as (
select * from ##boatreg) 
select a.*
,case when (a.EMAIL=b.EMAIL_NAME) --and a.FirstName=b.First_Name and a.LastName=b.Last_Name) 
then b.BoatprocessYear end as new_BoatProcessYear
,case when (a.EMAIL=b.EMAIL_NAME) --and a.FirstName=b.First_Name and a.LastName=b.Last_Name) 
then b.BoatExpirationYear end as new_BoatExpirationYear
,case when (a.EMAIL=b.EMAIL_NAME) --and a.FirstName=b.First_Name and a.LastName=b.Last_Name) 
then 'BoatReg' else 'NULL'  end as new_BoatPrivilege
,case when (a.EMAIL=b.EMAIL_NAME) --and a.FirstName=b.First_Name and a.LastName=b.Last_Name) 
then b.Boattype else 'NULL'  end as BoatType1
into ##Existing_emails_1_boat
from ##Existing_emails_1 a
left join boat b on 
 b.EMAIL_NAME=a.EMAIL --and b.First_Name = a.FirstName and b.Last_Name=a.LastName

 --REMOVE DUPLICATES
 drop table if exists ##Existing_emails_1_boat_uniqueboat
 ;with uniqueboat as (
 select *,
 rn=ROW_NUMBER() over (partition by email, firstname, lastname order by email, firstname, lastname, new_boatprocessyear desc)
 from ##Existing_emails_1_boat
 )
 select * into ##Existing_emails_1_boat_uniqueboat
 from uniqueboat where rn=1
------------------------------------------------------------------
-------DELETE UNSUBCRIBED EMAILS----------------------------------
------------------------------------------------------------------

drop table ##Existing_emails_1_update
select a.* into ##Existing_emails_1_update
from ##Existing_emails_1_boat_uniqueboat a
left join ##delemails b on b.[remove]=a.Email 
where b.[remove] is null 


------------------------------------------------------------------
---DELETE INACTIVE, DECEASED, TRANSFERRED, SUSPENDED SUBSCRIBERS---
------------------------------------------------------------------

drop table ##Existing_emails_1_active
select a.* 
into ##Existing_emails_1_active
from ##Existing_emails_1_update a
left join (select * from [POSData_DailyReplication].[dbo].[Customer] where statusid in (34,35,36,37,38,39)) as b
on b.EmailAddress=a.email and b.FirstName=a.firstname and b.lastname=a.lastname
where b.emailaddress is null --18 deceased  --(309094 rows affected)


------------------------------------------------------------------
-------UPDATE EMAILS OF THE SUBSCRIBERS---------------------------
------------------------------------------------------------------

update a
set a.email=b.new_email
from ##Existing_emails_1_active a
left join [dbo].[Change_11122023] b on a.email=b.Old_Email
where a.email=b.Old_Email

update a
set a.email=b.new_email
from ##Existing_emails_1_active a
left join [dbo].[Update_emails_01242024] b on b.old_email=a.email
where a.email=b.old_email


update a
set a.email=b.new_email
from ##Existing_emails_1_active a
left join [dbo].[update_Email_02092024] b on b.old_email=a.email
where a.email=b.old_email

update a
set a.email='rjp2034@gmail.com'
from ##Existing_emails_1_active a
--left join [dbo].[update_Email_02092024] b on b.old_email=a.emailaddress
where a.email='deoric deoric@comcast.net'

update a
set a.email='Eric@wrightasphaltandconcrete.com'
from ##Existing_emails_1_active a
--left join [dbo].[update_Email_02092024] b on b.old_email=a.emailaddress
where a.email='eric@wdwright.com'

update a
set a.email='psulou3@gmail.com'
from ##Existing_emails_1_active a
--left join [dbo].[update_Email_02092024] b on b.old_email=a.emailaddress
where a.email='lstubbs@atlanticbb.net'

update a
set a.email=b.new
from ##Existing_emails_1_active a
left join [dbo].[Update_05282024] b on b.old=a.email
where a.email=b.old and (b.old is not null and b.new is not null)

update a
set a.email=b.new
from ##Existing_emails_1_active a
left join [dbo].[Update_Emails_06132024] b on b.old=a.email
where a.email=b.old and (b.old is not null and b.new is not null)

update a
set a.email=b.new
from ##Existing_emails_1_active a
left join [dbo].[Update_Emails_07152024] b--[dbo].[Update_Emails_06132024] b 
on b.old=a.email
where a.email=b.old and (b.old is not null and b.new is not null)

update a
set a.email=b.new
from ##Existing_emails_1_active a
left join [dbo].[Update_Emails_1001] b--[dbo].[Update_Emails_06132024] b 
on b.old=a.email
where a.email=b.old and (b.old is not null and b.new is not null)

update a
set a.email=b.new
from ##Existing_emails_1_active a
left join [dbo].[Update_Emails_12092024] b--[dbo].[Update_Emails_06132024] b 
on b.old=a.email
where a.email=b.old and (b.old is not null and b.new is not null)

update a
set a.email=b.new
from ##Existing_emails_1_active a
left join [dbo].[Update_Emails_0305] b--[dbo].[Update_Emails_06132024] b 
on b.old=a.email
where a.email=b.old and (b.old is not null and b.new is not null)

update a
set a.email=b.new
from ##Existing_emails_1_active a
left join [dbo].[Update_Emails_04012025] b--[dbo].[Update_Emails_06132024] b 
on b.old=a.email
where a.email=b.old and (b.old is not null and b.new is not null)

------------------------------------------------------------------
-------SORT REQUIRED COLUMNS IN NEW TEMP TABLE--------------------
------------------------------------------------------------------

--create required columns 
--select * from ##Existing_emails_1_active
drop table ##Existing_emails_new_1
select 
a.EMAIL,
--a.EMAIL,
a.FIRSTNAME,
a.LASTNAME,
a.GENDER,
a.GENERATION,
a.STATECODE,
a.COUNTY,
a.PFBCREGION,
a.FISHPROCESSYEAR,
a.CURRENTLICENSEYEAR,
a.FISHEXPIRATIONYEAR,
cast(a.TROUTEXPIRATION as nvarchar(2545)) as TROUTEXPIRATION,
a.new_BoatPrivilege as BOATPRIVILEGE,
a.Boattype1 as BOATTYPE,
cast(a.new_BoatProcessYear as nvarchar(255)) as BOATPROCESSYEAR,
a.new_BoatExpirationYear AS BOATEXPIRATIONYEAR,
a.LAUNCHPRIVILEGE,
a.LAUNCHPROCESSYEAR,
a.LAUNCHEXPIRATIONYEAR
into ##Existing_emails_new_1
from ##Existing_emails_1_active a
--(309103 rows affected)


--check for valid status
--select distinct FISHEXPIRATIONYEAR from ##Existing_emails_new_1 where CURRENTLICENSEYEAR ='Lapsed'
--select distinct FISHEXPIRATIONYEAR from ##Existing_emails_new_1 where CURRENTLICENSEYEAR ='Valid'

------------------------------------------------------------------
-------UPDATE R3 COLUMN-------------------------------------------
------------------------------------------------------------------

--Update R3 column 
drop table if exists ##Existing_emails_new_r3_1
;with r3 as (
select  a.*,
case when a.CURRENTLICENSEYEAR='Lapsed' then 'Lapsed'
when a.CURRENTLICENSEYEAR='Valid'  then c.R3_Status 
when ( a.FISHPROCESSYEAR < year(getdate()) and a.FISHEXPIRATIONYEAR >=year(getdate())) then 'Retained'
when (a.CURRENTLICENSEYEAR='NULL' and a.FISHPROCESSYEAR is null and (a.BOATPROCESSYEAR is not null or a.LAUNCHPROCESSYEAR <> 'NULL'))
then 'No License Purchased'
when (a.CURRENTLICENSEYEAR='NULL' and a.FISHPROCESSYEAR is null and a.BOATPROCESSYEAR is null or a.LAUNCHPROCESSYEAR ='NULL')
then 'Unknown'
else 'NULL' end as R3_Status
from ##Existing_emails_new_1 a
--left join  ##allpriorr3 b on b.emailaddress=a.email and b.firstname =a.firstname and b.lastname =a.lastname
left join [dbo].[alllic_trout_2025] c on c.EmailAddress=a.email and c.FirstName=a.firstname and c.lastname=a.lastname)
, r3_unique as 
(select *,
r3_num= row_number() over (partition by email, firstname, lastname, FishProcessyear, FishExpirationYear, CurrentlicenseYear order by 
email, firstname, lastname, FishProcessyear, FishExpirationYear, CurrentlicenseYear, R3_status desc)
from r3)
select * 
into ##Existing_emails_new_r3_1
from r3_unique where r3_num=1

update ##Existing_emails_new_r3_1
--select * from ##existing_subscribers_0412_r3_1 
set R3_Status='Retained'
where FISHPROCESSYEAR < year(getdate()) 
and FISHEXPIRATIONYEAR >=year(getdate()) 
and R3_status is null


update ##Existing_emails_new_r3_1
set currentlicenseyear='Lapsed', R3_status='Lapsed'
--from ##Existing_emails_0422_r3_1
where FISHEXPIRATIONYEAR <'2025' and FISHEXPIRATIONYEAR is not null


update ##Existing_emails_new_r3_1
set currentlicenseyear='Valid'
--from ##Existing_emails_0422_r3_1
where FISHEXPIRATIONYEAR >='2025' and FISHEXPIRATIONYEAR is not null and currentlicenseyear ='NULL'

update a
set a.R3_Status = b.R3_Status 
from ##Existing_emails_new_r3_1 a
left join [dbo].[alllic_trout_2025] b on b.emailaddress=a.email and b.firstname=a.firstname and b.lastname=a.lastname
where a.CURRENTLICENSEYEAR='Valid' and  a.R3_status ='NULL'


------------------------------------------------------------------
-------UPDATE INCONSISTENT VALUES/DATA DISCREPANCIES--------------
------------------------------------------------------------------

update a
set 
a.fishprocessyear=b.processyear,
a.fishexpirationyear=b.expirationyear
from ##Existing_emails_new_r3_1 a
left join ##Cust20082025_gen_unique b on 
b.emailaddress=a.email --and b.firstname=a.firstname and b.lastname =a.lastname
where a.Troutexpiration <> 'NULL' and currentlicenseyear ='NULL'


update ##Existing_emails_new_r3_1
set CURRENTLICENSEYEAR=case when fishexpirationyear >='2025' then 'Valid'
when fishexpirationyear <'2025' then 'Lapsed' else 'NULL' end
where currentlicenseyear = 'NULL' and fishexpirationyear is not null

delete from ##Existing_emails_new_r3_1
from ##Existing_emails_new_r3_1
where FISHPROCESSYEAR is null and TROUTEXPIRATION <> 'NULL'


update ##Existing_emails_new_r3_1
set R3_status ='Lapsed' where CURRENTLICENSEYEAR ='Lapsed' and R3_status ='Unknown'

update a
set a.R3_Status = b.R3_Status 
from ##Existing_emails_new_r3_1 a
left join [dbo].[alllic_trout_2025] b on b.emailaddress=a.email --and b.firstname=a.firstname and b.lastname=a.lastname
where a.CURRENTLICENSEYEAR='Valid' and  a.R3_status ='Unknown'


update a
set a.r3_status = case when a.fishprocessyear < '2025' and fishexpirationyear >='2025' then 'Retained'
when a.fishprocessyear = '2025' and fishexpirationyear >='2025' then b.R3_Status 
when currentlicenseyear='Lapsed' then 'Lapsed'
else 'NULL' end
from ##Existing_emails_new_r3_1 a
left join [dbo].[alllic_trout_2025] b on b.EmailAddress=a.email
where a.R3_Status is null and a.currentlicenseyear <> 'NULL'

--------------------------------------------------------------------------------
---REMOVE ANYONE UNDER 18 YEARS AGE AND SUBSCRIBERS WITHOUT EMAILS IF ANY-------
--------------------------------------------------------------------------------


--Remove all under 18 years of age
drop table if exists ##youngerthan18
select a.* 
into ##youngerthan18
--into ##Existing_emails_0422_r3_old_1_subscribed_over18 
from ##Existing_emails_new_r3_1 a
join [dbo].[alllic_trout_2025] b on b.emailaddress =a.email and b.firstname =a.firstname and b.lastname =a.lastname
where b.Chronological_Age <18 

drop table if exists ##Existing_emails_new_r3_1_subscribed_over18
select a.* 
into ##Existing_emails_new_r3_1_subscribed_over18
from ##Existing_emails_new_r3_1 a
left join ##youngerthan18 b on b.email=a.email where b.email is null

--delete any record with blank emails
delete from ##Existing_emails_new_r3_1_subscribed_over18 
where email =' ' 

--------------------------------------------------------------------------------
---UPDATE ANY DATA DISCREPANCIES OR MISSING VALUES -----------------------------
--------------------------------------------------------------------------------

--check with incorrect spelling if exists
update ##Existing_emails_new_r3_1_subscribed_over18
set Generation ='Millennials' where Generation = 'Milenials' and Generation is not null

--check for any invalid missing record
update a
set a.email=b.emailaddress, a.R3_status=b.R3_status
from ##Existing_emails_new_r3_1_subscribed_over18 a
left join [dbo].[alllic_trout_2025] b on b.firstname = a.firstname and b.lastname =a.lastname  and b.gender=a.gender
where a.R3_status is null and a.email<>b.emailaddress and b.emailaddress is not null

--------------------------------------------------------------------------------
---SORT ALL FINAL COLUMNS INTO NEW TABLE ---------------------------------------
--------------------------------------------------------------------------------
--generate a final table structure
drop table ##Existing_emails_new
select 
EMAIL,
FIRSTNAME,
LASTNAME,
GENDER,
GENERATION,
STATECODE AS STATECODE,
COUNTY,
PFBCREGION,
FISHPROCESSYEAR,
CURRENTLICENSEYEAR,
FISHEXPIRATIONYEAR,
R3_STATUS AS CURRENTR3STATUS,
TROUTEXPIRATION,
BOATPRIVILEGE,
BOATTYPE,
BOATPROCESSYEAR,
BOATEXPIRATIONYEAR,
LAUNCHPRIVILEGE,
LAUNCHPROCESSYEAR,
LAUNCHEXPIRATIONYEAR
INTO ##Existing_emails_new
FROM ##Existing_emails_new_r3_1_subscribed_over18

--------------------------------------------------------------------------------
---SPLIT THE FINAL/MASTER TABLE INTO 3 FILES ---------------------------------------
--------------------------------------------------------------------------------

--Load into final destination in database for next refresh

select * from ##Existing_emails_new
--select * from ##Existing_emails_new where CURRENTR3STATUS='Unknown'


--drop table [dbo].[All_Existing_subscribers_Maestro_05012025]
--Assign IDs to the master table to split into 3 sub tables for csv export.
drop table if exists [dbo].[All_Existing_subscribers_Maestro_05282025]
;WITH CTE AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS unique_id,
        *
    FROM ##Existing_emails_new
)
select * 
into [dbo].[All_Existing_subscribers_Maestro_05282025]
from CTE

--create  3tables for csv upload

--select * from [dbo].[All_Existing_subscribers_Maestro_05282025]
SELECT COUNT(*) FROM [dbo].[All_Existing_subscribers_Maestro_05282025] --915019


drop table if exists ##table1
drop table if exists ##table2
drop table if exists ##table3

-- Create 3 sets to export into csv. Remove Unique_ID field
SELECT * into ##table1
FROM [dbo].[All_Existing_subscribers_Maestro_05282025]
WHERE unique_id BETWEEN 1 AND 300000;

select * from ##table1 order by unique_id

SELECT * into ##table2
FROM [dbo].[All_Existing_subscribers_Maestro_05282025]
WHERE unique_id BETWEEN 300001 AND 600000;
select * from ##table2 order by unique_id

SELECT * into ##table3
FROM [dbo].[All_Existing_subscribers_Maestro_05282025]
WHERE unique_id >= 600001
select * from ##table3 order by unique_id

