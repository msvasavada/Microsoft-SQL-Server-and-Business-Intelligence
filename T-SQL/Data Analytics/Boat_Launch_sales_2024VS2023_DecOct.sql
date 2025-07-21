select * from [dbo].[HFPA_Boat_launch_2024_DecOct]--[dbo].[HFPA_Permit_2024_0511_date]
select * from [dbo].[HFPA_Boat_launch_2023_DecOct]--[dbo].[HFPA_Permit_2023_0511_date]

drop table ##bl2024
select 
[Transaction ID], [Transaction Date and Time], [Total Price], [Price Code], [Product Name], [Product Price], [Sales Tax]
into ##bl2024
from [dbo].[HFPA_Boat_Launch_2024_1114]
union all 
select * from [dbo].[HFPA_Boat_launch_2024_DecOct]
where cast([Transaction Date and Time] as date)>='2024-10-04'--[dbo].[HFPA_2024_0712]--[dbo].[HFPA_Permit_2024_0705]
--join ##Trout2024 b on b.customerid = replace(a.[customer id],'-','')

drop table ##bl2023
select 
[Transaction ID], [Transaction Date and Time], [Total Price], [Price Code], [Product Name], [Product Price], [Sales Tax]
into ##bl2023
from [dbo].[HFPA_Boat_Launch_2023_1114]
union all 
select * from [dbo].[HFPA_Boat_launch_2023_DecOct]
where cast([Transaction Date and Time] as date)>='2023-10-05'--[dbo].[HFPA_2024_0712]--[dbo].[HFPA_Permit_2024_0705]
--join ##Trout2024 b on b.customerid = replace(a.[customer id],'-','')


--select count(*) from [dbo].[HFPA_Permit_2023]
--select count(*) from [dbo].[HFPA_Permit_2024]

---------------------------------------------------------------------------------------------------------------------------------

drop table ##nthweek2024_weekno
select a.[Transaction ID], a.[Transaction Date and Time], a.[Total Price],
b.weekstartdate, b.weekenddate,
case when (cast(a.[Transaction Date and Time] as date) >= b.WeekStartDate and cast(a.[Transaction Date and Time] as date) <= b.WeekEndDate) then b.WeekNo else 0 end as Week_num_2024
--cast(O_create_date as date) as start_dt, cast(dateadd(dd,6,o_create_date)as date) as enddt
into ##nthweek2024_weekno
from ##bl2024 a 
right join ##Weeknum_2024_all b on b.WeekStartDate=cast(a.[Transaction Date and Time] as date) 
or b.day2=cast(a.[Transaction Date and Time] as date) or b.day3=cast(a.[Transaction Date and Time] as date)
or b.day4=cast(a.[Transaction Date and Time] as date) or b.day5=cast(a.[Transaction Date and Time] as date)
or b.day6=cast(a.[Transaction Date and Time] as date) or b.WeekEndDate=cast(a.[Transaction Date and Time] as date)
--where a.[Order Line Status]='Active'


--select * from ##nthweek2024_weekno


drop table ##alltransper2024
;with cte as (
select weekstartdate, weekenddate, Week_num_2024, 
count(isnull([Transaction ID],0)) as cust_num, sum([Total Price]) as tot_amt
from ##nthweek2024_weekno 
group by weekstartdate, weekenddate, Week_num_2024 --order by Week_num_2021
)
select weekstartdate, weekenddate, Week_num_2024, cust_num, tot_amt,
sum(cust_num)  over (order by weekenddate) as cum_sales,
sum(tot_amt)  over (order by weekenddate) as cum_amt
into ##alltransper2024
from cte

select weekstartdate, WeekEndDate, Week_num_2024, cust_num, cum_sales, tot_amt, cum_amt
from ##alltransper2024 order by Week_num_2024

----------------------------------------------------------------------------------------------------------------------

--2023


drop table ##nthweek2023_weekno
select a.[Transaction ID], a.[Transaction Date and Time], a.[Total Price],
b.weekstartdate, b.weekenddate,
case when (cast(a.[Transaction Date and Time] as date) >= b.WeekStartDate 
and cast(a.[Transaction Date and Time] as date) <= b.WeekEndDate) then b.WeekNo else 0 end as Week_num_2023
--cast(O_create_date as date) as start_dt, cast(dateadd(dd,6,o_create_date)as date) as enddt
into ##nthweek2023_weekno
from ##bl2023 a 
right join ##Weeknum_2023_all b on b.WeekStartDate=cast(a.[Transaction Date and Time] as date) 
or b.day2=cast(a.[Transaction Date and Time] as date) or b.day3=cast(a.[Transaction Date and Time] as date)
or b.day4=cast(a.[Transaction Date and Time] as date) or b.day5=cast(a.[Transaction Date and Time] as date)
or b.day6=cast(a.[Transaction Date and Time] as date) or b.WeekEndDate=cast(a.[Transaction Date and Time] as date)
--where a.[Order Line Status]='Active'


--select * from ##nthweek2023_weekno


drop table ##alltransper2023
;with cte as (
select weekstartdate, weekenddate, Week_num_2023, 
count(isnull([Transaction ID],0)) as cust_num, sum([Total Price]) as tot_amt
from ##nthweek2023_weekno 
group by weekstartdate, weekenddate, Week_num_2023 --order by Week_num_2021
)
select weekstartdate, weekenddate, Week_num_2023, cust_num, tot_amt,
sum(cust_num)  over (order by weekenddate) as cum_sales,
sum(tot_amt)  over (order by weekenddate) as cum_amt
into ##alltransper2023
from cte

select weekstartdate, WeekEndDate, Week_num_2023, cust_num, cum_sales, tot_amt, cum_amt
from ##alltransper2023 order by Week_num_2023



select weekstartdate, WeekEndDate, Week_num_2024, cust_num, cum_sales, tot_amt, cum_amt
from ##alltranslic2024
select weekstartdate, WeekEndDate, Week_num_2024, cust_num, cum_sales, tot_amt, cum_amt
from ##alltransper2024

select weekstartdate, WeekEndDate, Week_num_2023, cust_num, cum_sales, tot_amt, cum_amt
from ##alltranslic2023
select weekstartdate, WeekEndDate, Week_num_2023, cust_num, cum_sales, tot_amt, cum_amt
from ##alltransper2023


;with sales2024 as (
select weekstartdate, WeekEndDate, Week_num_2024, cust_num, cum_sales, tot_amt, cum_amt
from ##alltranslic2024
union all
select weekstartdate, WeekEndDate, Week_num_2024, cust_num, cum_sales, tot_amt, cum_amt
from ##alltransper2024)
select Weekstartdate, weekenddate, week_num_2024,
sum(cust_num) as cust_num,
sum(cum_sales) as cum_sales,
sum(tot_amt) as tot_amt,
sum(cum_amt) as cum_amt
from sales2024 group by weekstartdate, WeekEndDate, Week_num_2024


;with sales2023 as (
select weekstartdate, WeekEndDate, Week_num_2023, cust_num, cum_sales, tot_amt, cum_amt
from ##alltranslic2023
union all
select weekstartdate, WeekEndDate, Week_num_2023, cust_num, cum_sales, tot_amt, cum_amt
from ##alltransper2023)
select Weekstartdate, weekenddate, week_num_2023,
sum(cust_num) as cust_num,
sum(cum_sales) as cum_sales,
sum(tot_amt) as tot_amt,
sum(cum_amt) as cum_amt
from sales2023 group by weekstartdate, WeekEndDate, Week_num_2023