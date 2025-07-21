----------------------------------------------------------------------------
--------FETCH ALL 2025 LICENSE CUSTOMERS------------------------------------
----------------------------------------------------------------------------

drop table if exists ##newemails
select distinct a.* into ##newemails 
from ##Cust2025_Purchase_Email_System_format_gen_r3 a 
where cast(a.O_create_date as date) >='2024-12-01' 
and (a.emailaddress is not null and a.emailaddress<>'')

----------------------------------------------------------------------------
--------DELETE THE UNSUBSCRIBED EMAILS---------------------------------------------
----------------------------------------------------------------------------

drop table ##newemails_del
select a.* into ##newemails_del
from ##newemails a
left join ##delemails b on b.[remove]=a.EmailAddress 
where b.[remove] is null 

--select count(*) from ##newemails --182689
--select count(*) from ##newemails_del --171223

----------------------------------------------------------------------------
--------UPDATE EMAILS-------------------------------------------------------
----------------------------------------------------------------------------

update a
set a.revised_email=b.new_email
from ##newemails_del a
left join [dbo].[Change_11122023] b on a.emailaddress=b.Old_Email
where a.emailaddress=b.Old_Email

update a
set a.revised_email=b.new_email
from ##newemails_del a
left join [dbo].[Update_emails_01242024] b on b.old_email=a.emailaddress
where a.emailaddress=b.old_email

update a
set a.revised_email=b.new_email
from ##newemails_del a
left join [dbo].[update_Email_02092024] b on b.old_email=a.emailaddress
where a.emailaddress=b.old_email

update a
set a.revised_email='rjp2034@gmail.com'
from ##newemails_del a
--left join [dbo].[update_Email_02092024] b on b.old_email=a.emailaddress
where a.emailaddress='deoric deoric@comcast.net'

update a
set a.revised_email='Eric@wrightasphaltandconcrete.com'
from ##newemails_del a
--left join [dbo].[update_Email_02092024] b on b.old_email=a.emailaddress
where a.emailaddress='eric@wdwright.com'

update a
set a.revised_email='psulou3@gmail.com'
from ##newemails_del a
--left join [dbo].[update_Email_02092024] b on b.old_email=a.emailaddress
where a.emailaddress='lstubbs@atlanticbb.net'


update a
set a.revised_email=b.new
from ##newemails_del a
left join [dbo].[Update_05282024] b on b.old=a.emailaddress
where a.emailaddress=b.old and (b.old is not null and b.new is not null)

update a
set a.revised_email=b.new
from ##newemails_del a
left join [dbo].[Update_Emails_06132024] b on b.old=a.emailaddress
where a.emailaddress=b.old and (b.old is not null and b.new is not null)

update a
set a.revised_email=b.new
from ##newemails_del a
left join [dbo].[Update_Emails_07152024] b--[dbo].[Update_Emails_06132024] b 
on b.old=a.emailaddress
where a.emailaddress=b.old and (b.old is not null and b.new is not null)

update a
set a.revised_email=b.new
from ##newemails_del a
left join [dbo].[Update_Emails_1001] b--[dbo].[Update_Emails_06132024] b 
on b.old=a.emailaddress
where a.emailaddress=b.old and (b.old is not null and b.new is not null)

update a
set a.revised_email=b.new
from ##newemails_del a
left join [dbo].[Update_Emails_12092024] b--[dbo].[Update_Emails_06132024] b 
on b.old=a.emailaddress
where a.emailaddress=b.old and (b.old is not null and b.new is not null)

update a
set a.revised_email=b.new
from ##newemails_del a
left join [dbo].[Update_Emails_0305] b--[dbo].[Update_Emails_06132024] b 
on b.old=a.emailaddress
where a.emailaddress=b.old and (b.old is not null and b.new is not null)

update a
set a.revised_email=b.new
from ##newemails_del a
left join [dbo].[Update_Emails_04012025] b--[dbo].[Update_Emails_06132024] b 
on b.old=a.emailaddress
where a.emailaddress=b.old and (b.old is not null and b.new is not null)

--Add any updated emails here
--When Janelle sends an update list add it here with the query

select * from ##newemails_del


----------------------------------------------------------------------------
--------ADD TROUT EXPIRATION COLUMN-----------------------------------------
----------------------------------------------------------------------------

drop table if exists ##newemails_del_trout
select a.Revised_Email As Email,
a.Firstname, a.Lastname, a.Gender, a.Generation, a.State_Code, a.County, a.PFBCRegion, 
FishProcessYear, 
'Valid' as CurrentLicenseYear, a.Expirationyear as FishExpirationYear, a.R3_Status, b.Permit_Expiration as TroutExpiration
into ##newemails_del_trout
from ##newemails_del a
left join ##Uniquetroutemails b on b.emailaddress =a.Revised_Email 

----------------------------------------------------------------------------
--------ADD BOAT REGISTRANTS COLUMNS-----------------------------------------
----------------------------------------------------------------------------


drop table if exists ##newemails_del_trout_boat
;with boat as (
select * from ##boatreg) 
select a.*
,case when (a.EMAIL=b.[EMAIL_NAME]) --and a.FirstName=b.First_Name and a.LastName=b.Last_Name) 
then b.BoatprocessYear end as BoatProcessYear
,case when (a.EMAIL=b.[EMAIL_NAME]) --and a.FirstName=b.First_Name and a.LastName=b.Last_Name) 
then b.BoatExpirationYear end as BoatExpirationYear
,case when (a.EMAIL=b.[EMAIL_NAME]) --and a.FirstName=b.First_Name and a.LastName=b.Last_Name) 
then 'BoatReg' else 'NULL'  end as BoatPrivilege
,case when (a.EMAIL=b.[EMAIL_NAME]) --and a.FirstName=b.First_Name and a.LastName=b.Last_Name) 
then b.Boattype else 'NULL'  end as BoatType
into ##newemails_del_trout_boat
from ##newemails_del_trout a
left join boat b on 
 b.[EMAIL_NAME]=a.EMAIL --and b.First_Name = a.FirstName and b.Last_Name=a.LastName

--REMOVE DUPLICATES
 drop table if exists ##newemails_del_trout_uniqueboat
 ;with uniqueboat as (
 select *,
 rn=ROW_NUMBER() over (partition by email, firstname, lastname order by email, firstname, lastname, boatprocessyear desc)
 from ##newemails_del_trout_boat
 )
 select * into ##newemails_del_trout_uniqueboat
 from uniqueboat where rn=1

 ----------------------------------------------------------------------------
--------ADD LAUNCH PERMIT COLUMNS-----------------------------------------
----------------------------------------------------------------------------
drop table if exists ##newemails_del_trout_uniqueboat_lp
 ;with launch as (
select distinct a.*,
case when a.EMAIL=b.emailaddress then b.ProcessYear else null end as LaunchProcessYear,
case when a.EMAIL=b.emailaddress then b.ExpirationYear else null end as LaunchExpirationYear,
case when a.EMAIL=b.emailaddress then 'Launch' else 'NULL' end as LaunchPrivilege,
rn2 = row_number() over (partition by a.email, a.firstname, a.lastname order by  a.email, a.firstname, a.lastname, b.ProcessYear desc) 
--into ##newemailsover18_boatlp
from ##newemails_del_trout_uniqueboat a
left join ##LP b on b.emailaddress=a.EMAIL --and b.firstname=a.firstname and b.lastname=a.lastname
)
select * into ##newemails_del_trout_uniqueboat_lp
from launch where rn2=1

----------------------------------------------------------------------------
--------SORT REQUIRED COLUMNS IN NEW TEMP TABLE-----------------------------------------
----------------------------------------------------------------------------
select 
a.EMAIL,
--a.EMAIL,
a.FIRSTNAME,
a.LASTNAME,
a.GENDER,
a.GENERATION,
a.STATE_CODE,
a.COUNTY,
a.PFBCREGION,
a.FISHPROCESSYEAR,
a.CURRENTLICENSEYEAR,
a.FISHEXPIRATIONYEAR,
a.R3_Status,
cast(a.TROUTEXPIRATION as nvarchar(2545)) as TROUTEXPIRATION,
a.BOATPRIVILEGE,
a.BOATTYPE,
cast(a.BOATPROCESSYEAR as nvarchar(255)) as BOATPROCESSYEAR,
a.BOATEXPIRATIONYEAR,
a.LAUNCHPRIVILEGE,
a.LAUNCHPROCESSYEAR,
a.LAUNCHEXPIRATIONYEAR
into ##new_subcribers
from ##newemails_del_trout_uniqueboat_lp a

--select * from ##new_subcribers

----------------------------------------------------------------------------
--------REMOVE INACTIVE, DECEASED, TRANSFERRED------------------------------
----------------------------------------------------------------------------

select a.* into ##new_subcribers_active
from ##new_subcribers a
left join (select * from [POSData_DailyReplication].[dbo].[Customer]
where statusid in (34,35,36,37,38,39)) as b
on b.EmailAddress=a.email and b.FirstName=a.firstname and b.lastname=a.lastname
where b.emailaddress is null

--select * from ##subcribers_03062025_active 

----------------------------------------------------------------------------
--------UPDATE THE VALID VALUES------------------------------
----------------------------------------------------------------------------

update ##new_subcribers_active
set FishExpirationyear='2025' 
where FishExpirationyear='2024'

--select * from ##new_subcribers_01142025 where fishProcessyear ='2024'

update ##new_subcribers_active
set fishProcessyear='2025' 
where fishProcessyear='2024'

update ##new_subcribers_active
set FishExpirationyear='9999'
where FishExpirationyear>'2037'

update ##new_subcribers_active
set Generation ='Millennials' where Generation = 'Milenials' and Generation is not null

---------------------------------------------------------------------------
---CREATE A DBO TABLE OBJECT FOR NEW SUBSCRIBERS AND FINAL TEMP TABLE------
---------------------------------------------------------------------------

drop table ##new_subcribers_active_tilldate
select 
EMAIL,
FIRSTNAME,
LASTNAME,
GENDER,
GENERATION,
STATE_CODE AS STATECODE,
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
into ##new_subcribers_active_tilldate
FROM ##new_subcribers_active

select * from ##new_subcribers_active_tilldate --(278056 rows affected)

-----------------------------------------------------------------------------------------------------
------RETAIN THE MASTER FISH SUBSCRIBER TABLE FROM PREVIOUS RUNS-----------------------------------
-----------------------------------------------------------------------------------------------------

insert into [dbo].[All_2025_Fish_subcribers_tilldate]
select * from ##new_subcribers_active_tilldate

select count(*) from [dbo].[All_2025_Fish_subcribers_tilldate]

SELECT COUNT(*) FROM ##new_subcribers_active_tilldate

----------------------------------------------------------------------------
--------EXPORT ONLY DISTINCT ROWS INTO CSV----------------------------------
---REMOVE OVERLAPS FROM OLD SUBSCRIBER LIST AND PREVIOUS 2025 MAESTRO RUN--
---RUN THIS QUERY AFTER RUNNING EXISTING/OLD SUBSCRUBER LIST--------------
----------------------------------------------------------------------------

--RUN THIS SECTION AFTER UPATING EXISTING SUBCRIBERS / RUNNING EXISTING SUBSCRIBER QUERIES
--Export all 2025 for Maestro
drop table ##new_subcribers_active_export
select a.* 
into ##new_subcribers_active_export
from ##new_subcribers_active_tilldate a
--left join [dbo].[All_2025_Fish_subcribers_tilldate] b
--on b.email=a.email and b.firstname=a.firstname and b.lastname=a.lastname
LEFT join [dbo].[All_Existing_subscribers_Maestro_05282025] c 
on c.email=a.email and c.firstname=a.firstname and c.lastname=a.lastname
where-- b.email is null and b.firstname is null and b.lastname is null
c.email is null and c.firstname is null and c.lastname is null

-----------------------------------------------------------------------------
----EXPORT THESE NEW 2025 RECORDS TO CSV-------------------------------------
-------------------------------------------------------------------------------

SELECT * FROM ##new_subcribers_active_export --136657 unique records

--------------------------------------------------------------------------------
------IF ANY DUPLICATES FORM LAST RUN EXISTS REMOVE OR LESE LEAVE IT------------
--------------------------------------------------------------------------------

SELECT distinct * from ##new_subcribers_active_export a
inner join [dbo].[All_2025_Fish_subcribers_tilldate] b 
on b.email=a.email and b.firstname = a.firstname and b.lastname =a.lastname






