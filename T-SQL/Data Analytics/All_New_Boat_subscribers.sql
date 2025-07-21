------------------------------------------------------------------------------
------REMOVE ALL OVERLAPPING RECORDS------------------------------------------
------------------------------------------------------------------------------

drop table ##newboatreg
select a.* into ##newboatreg
from ##boatreg a  --162070
left join (
select email, firstname, lastname from [dbo].[All_Existing_subscribers_Maestro_05282025]
union all
select email, firstname, lastname from [dbo].[All_2025_Fish_subcribers_tilldate]--##new_subcribers_active
) as b on b.email=a.email_name
where b.email is null and b.firstname is null and b.lastname is null


--select * from ##newboatreg

------------------------------------------------------------------------------
------ADDING GENERATION------------------------------------------
------------------------------------------------------------------------------

drop table if exists ##boatreg_gen
select *, 
case when cast([birth_date] as date) between '2010-01-01' and getdate() then 'Gen_Alpha'
when cast([birth_date] as date) between '1997-01-01' and '2009-12-31' then 'Gen_Z'
when cast([birth_date] as date) between '1981-01-01' and '1996-12-31' then 'Milenials'
when cast([birth_date] as date) between '1965-01-01' and '1980-12-31' then 'Gen_X'
when cast([birth_date] as date) between '1946-01-01' and '1964-12-31' then 'Boomers'
when cast([birth_date] as date) between '1928-01-01' and '1945-12-31' then 'Silent Generation'
when cast([birth_date] as date) between '1901-01-01' and '1927-12-31' then 'Greatest Generation'
else 'NULL' end as Generation
into ##boatreg_gen
from ##newboatreg
where [email_name] is not null  --239539

select * from ##boatreg_gen
--Removing unsubscribed / bounced/invalid emails
------------------------------------------------------------------------------
------DELETING UNSUBSCRIBED EMAILS AND REMOVING DUPLICATES------------------------------------------
------------------------------------------------------------------------------

drop table ##bo_gen_del
select a.* into ##bo_gen_del
from ##boatreg_gen a
left join ##delemails b on b.[remove]=a.Email_name 
where b.[remove] is null --and c.destination is null --761175  --(741023 rows affected)

drop table ##bo_gen_unique
;with cte as (
select *,
rn=row_number() over (partition by email_name, first_name, last_name order by email_name, first_name, last_name, boatProcessyear, Boatexpirationyear desc)
from ##bo_gen_del)
select * into ##bo_gen_unique
from cte where rn=1

--select * from ##bo_gen_unique

drop table ##boat_owners_new_del
select * into ##boat_owners_new_del from ##bo_gen_unique

--select * from ##boat_owners_new_del
------------------------------------------------------------------------------
------UPDATING EMAILS------------------------------------------
------------------------------------------------------------------------------
update a
set a.email_name=b.new_email
from ##boat_owners_new_del a
left join [dbo].[Change_11122023] b on a.email_name=b.Old_Email
where a.email_name=b.Old_Email

update a
set a.email_name=b.new_email
from ##boat_owners_new_del a
left join [dbo].[Update_emails_01242024] b on b.old_email=a.email_name
where a.email_name=b.old_email

update a
set a.email_name=b.new_email
from ##boat_owners_new_del a
left join [dbo].[update_Email_02092024] b on b.old_email=a.email_name
where a.email_name=b.old_email

update a
set a.email_name='rjp2034@gmail.com'
from ##boat_owners_new_del a
--left join [dbo].[update_Email_02092024] b on b.old_email=a.emailaddress
where a.email_name='deoric deoric@comcast.net'

update a
set a.email_name='Eric@wrightasphaltandconcrete.com'
from ##boat_owners_new_del a
--left join [dbo].[update_Email_02092024] b on b.old_email=a.emailaddress
where a.email_name='eric@wdwright.com'

update a
set a.email_name='psulou3@gmail.com'
from ##boat_owners_new_del a
--left join [dbo].[update_Email_02092024] b on b.old_email=a.emailaddress
where a.email_name='lstubbs@atlanticbb.net'


update a
set a.email_name=b.new
from ##boat_owners_new_del a
left join [dbo].[Update_05282024] b on b.old=a.email_name
where a.email_name=b.old and (b.old is not null and b.new is not null)

update a
set a.email_name=b.new
from ##boat_owners_new_del a
left join [dbo].[Update_Emails_06132024] b on b.old=a.email_name
where a.email_name=b.old and (b.old is not null and b.new is not null)

update a
set a.email_name=b.new
from ##boat_owners_new_del a
left join [dbo].[Update_Emails_07152024] b--[dbo].[Update_Emails_06132024] b 
on b.old=a.email_name
where a.email_name=b.old and (b.old is not null and b.new is not null)


update a
set a.email_name=b.new
from ##boat_owners_new_del a
left join [dbo].[Update_Emails_1001] b--[dbo].[Update_Emails_06132024] b 
on b.old=a.email_name
where a.email_name=b.old and (b.old is not null and b.new is not null)

--select * from ##boat_owners_new_del

update a
set a.email_name=b.new
from ##boat_owners_new_del a
left join [dbo].[Update_Emails_12092024] b--[dbo].[Update_Emails_06132024] b 
on b.old=a.email_name
where a.email_name=b.old and (b.old is not null and b.new is not null)


update a
set a.email_name=b.new
from ##boat_owners_new_del a
left join [dbo].[Update_Emails_0305] b--[dbo].[Update_Emails_06132024] b 
on b.old=a.email_name
where a.email_name=b.old and (b.old is not null and b.new is not null)

update a
set a.email_name=b.new
from ##boat_owners_new_del a
left join [dbo].[Update_Emails_04012025] b--[dbo].[Update_Emails_06132024] b 
on b.old=a.email_name
where a.email_name=b.old and (b.old is not null and b.new is not null)

------------------------------------------------------------------------------
------ADDING TROUT EXPIRATION------------------------------------------
------------------------------------------------------------------------------

drop table if exists ##boat_owners_new_del_trout
select a.*, b.Permit_Expiration as TroutExpiration
into ##boat_owners_new_del_trout
from ##boat_owners_new_del a
left join ##Uniquetroutemails b on b.emailaddress =a.email_name --and b.firstname=a.first_name and b.lastname=a.last_name

------------------------------------------------------------------------------
------ADDING LAUNCH PERMITS------------------------------------------
------------------------------------------------------------------------------

drop table if exists ##boat_owners_new_del_trout_lp
 ;with launch as (
select  a.*,
case when a.EMAIL_name=b.emailaddress then b.ProcessYear else null end as LaunchProcessYear,
case when a.EMAIL_name=b.emailaddress then b.ExpirationYear else null end as LaunchExpirationYear,
case when a.EMAIL_name=b.emailaddress then 'Launch' else 'NULL' end as LaunchPrivilege,
rn2 = row_number() over (partition by a.email_name, a.first_name, a.last_name order by  a.email_name, a.first_name, a.last_name, b.ProcessYear desc) 
--into ##newemailsover18_boatlp
from ##boat_owners_new_del_trout a
left join ##LP b on b.emailaddress=a.EMAIL_name --and b.firstname=a.first_name and b.lastname=a.last_name
)
select * into ##boat_owners_new_del_trout_lp
from launch 
--where rn2=1
------------------------------------------------------------------------------
------ADDING ALL FISHING COLUMNS------------------------------------------
------------------------------------------------------------------------------

drop table ##boat_owners_new_del_trout_lp_fish
select distinct a.*,
case when a.email_name=b.email then b.currentlicenseyear
when (a.email_name=c.emailaddress and c.expirationyear<'2025') then 'Lapsed'
when (a.email_name=c.emailaddress and c.expirationyear>='2025') then 'Valid'
else NULL end as currentlicenseyear,
case when a.email_name=b.email then b.FishProcessYear
when a.email_name=c.emailaddress then c.Processyear 
else NULL end as FishProcessYear,
case when a.email_name=b.email then b.FishExpirationYear
when a.email_name=c.emailaddress then c.ExpirationYear
else NULL end as FishExpirationYear
--when (a.email_name=c.emailaddress and c.expirationyear>='2024') then 'Valid'
into ##boat_owners_new_del_trout_lp_fish
from ##boat_owners_new_del_trout_lp a
left join (select * from [dbo].[All_2025_Fish_subcribers_tilldate]) as
b on b.EMAIL=a.email_name
left join ##Cust20082025_gen_unique c on c.emailaddress=a.email_name


--select * from ##boat_owners_new_del_trout_lp_fish
------------------------------------------------------------------------------
------REMOVING ANY OVERLAPPING EMAILS OR SUBSCRIBERS--------------------------
------------------------------------------------------------------------------

drop table ##boat_owners_new_del_trout_lp_fish_1
select a.* into ##boat_owners_new_del_trout_lp_fish_1
from ##boat_owners_new_del_trout_lp_fish a
left join (select * from [dbo].[All_2025_Fish_subcribers_tilldate]
 ) as b on b.email=a.email_name
where b.EMAIL is null

select * from ##boat_owners_new_del_trout_lp_fish_1

--select a.* from ##boat_owners_new_del_trout_lp_fish_1  a
--join [dbo].[All_subcribers_10022024] b on b.email=a.email_name
--where a.currentlicenseyear='Valid'


--select a.* from ##boat_owners_new_del_trout_lp_fish_1  a
--join ##Existing_emails_1002_3 b on b.email=a.email_name
--where a.currentlicenseyear='Valid'
------------------------------------------------------------------------------
------ADDING R3 COLUMN AND UPDATING OLD VALUES--------------------------------------------------------
------------------------------------------------------------------------------

drop table if exists ##boat_owners_new_del_trout_lp_fish_r3
;with r3 as (
select  a.*,
case when a.CURRENTLICENSEYEAR='Lapsed' then 'Lapsed'
when a.CURRENTLICENSEYEAR='Valid'  then c.R3_Status 
when ( a.FISHPROCESSYEAR < year(getdate()) and a.FISHEXPIRATIONYEAR >=year(getdate())) then 'Retained'
when (a.CURRENTLICENSEYEAR='NULL' and a.FISHPROCESSYEAR is null)
then 'No License Purchased'
when (a.CURRENTLICENSEYEAR='NULL' and a.FISHPROCESSYEAR is null)
then 'Unknown'
else 'NULL' end as R3_Status
from ##boat_owners_new_del_trout_lp_fish_1 a
--left join  ##allpriorr3 b on b.emailaddress=a.email and b.firstname =a.firstname and b.lastname =a.lastname
left join [dbo].[alllic_trout_2025] c on c.EmailAddress=a.email_name and c.FirstName=a.first_name and c.lastname=a.last_name)
, r3_unique as 
(select *,
r3_num= row_number() over (partition by email_name, first_name, last_name, FishProcessyear, FishExpirationYear, CurrentlicenseYear order by 
email_name, first_name, last_name, FishProcessyear, FishExpirationYear, CurrentlicenseYear, R3_status desc)
from r3)
select * 
into ##boat_owners_new_del_trout_lp_fish_r3
from r3_unique where r3_num=1

update ##boat_owners_new_del_trout_lp_fish_r3
--select * from ##existing_subscribers_0412_r3_1 
set R3_Status='Retained'
where FISHPROCESSYEAR < year(getdate()) 
and FISHEXPIRATIONYEAR >=year(getdate()) 
and R3_status is null

update ##boat_owners_new_del_trout_lp_fish_r3
--select * from ##existing_subscribers_0412_r3_1 
set R3_Status='No License Purchased'
where R3_status ='NULL'

select * from ##boat_owners_new_del_trout_lp_fish_r3
where currentlicenseyear='Valid'

------------------------------------------------------------------------------
------UPDATING MISSING VALUES-------------------------------------------------
------------------------------------------------------------------------------

drop table ##boat_owners_new
select a.*,
case when a.email_name = b.email then b.gender
when a.email_name=c.emailaddress then c.gender 
when a.email_name=d.email then d.gender 
else 'N/A' end as Gender 
into ##boat_owners_new
from ##boat_owners_new_del_trout_lp_fish_r3 a
left join [dbo].[All_2025_Fish_subcribers_tilldate] b on b.EMAIL=a.email_name
left join ##Cust20082025_gen_unique c on c.emailaddress=a.email_name
LEFT JOIN [dbo].[subscribersBoatLaunch06132023] d on d.EMAIL=a.email_name


--select * from ##boat_owners_new where gender <>'N/A'

update a 
set gender=b.Gender
from ##boat_owners_new  a
join [dbo].[subscribersBoatLaunch06132023] b on b.email=a.email_name
where a.gender='N/A'

--select * from [dbo].[subscribersBoatLaunch06132023]

update a 
set gender='NULL'
from ##boat_owners_new  a
where a.gender='N/A' or a.gender='NULL' or a.gender is null

------------------------------------------------------------------------------
------DELETE THE INACTIVE/TERMINATED-------------------------------------------------
------------------------------------------------------------------------------

drop table ##boat_owners_new_active
select a.* 
into ##boat_owners_new_active
from ##boat_owners_new a
left join (select * from [POSData_DailyReplication].[dbo].[Customer] where statusid in (34,35,36,37,38,39)) as b
on b.EmailAddress=a.email_name and b.FirstName=a.first_name and b.lastname=a.last_name
where b.emailaddress is null --18 deceased  --(309094 rows affected)


select * from ##boat_owners_new_active
--select * from ##boat_owners_new_active

DROP TABLE ##boat_owners_new_active_all
select DISTINCT
a.Email_name as EMAIL,
a.FIRST_NAME AS FIRSTNAME,
a.LAST_NAME AS LASTNAME,
a.GENDER,
a.GENERATION,
A.[state] AS STATECODE,
a.COUNTY,
a.[PFBC REGION] AS PFBCREGION,
a.FISHPROCESSYEAR,
a.CURRENTLICENSEYEAR,
a.FISHEXPIRATIONYEAR,
a.R3_STATUS AS CURRENTR3STATUS,
a.TROUTEXPIRATION,
'BoatReg' as BOATPRIVILEGE,
a.BOATTYPE,
a.BOATPROCESSYEAR,
a.BOATEXPIRATIONYEAR,
a.LAUNCHPRIVILEGE,
a.LAUNCHPROCESSYEAR,
a.LAUNCHEXPIRATIONYEAR
INTO ##boat_owners_new_active_all
FROM ##boat_owners_new_active a

--select distinct * from ##boat_owners_new_active_all order by FIRSTNAME desc

------------------------------------------------------------------------------
------EXPORTING TABLE-------------------------------------------------
------------------------------------------------------------------------------
select * from ##boat_owners_new_active_all --save it as latest date

