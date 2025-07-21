select count(*) as Tot_Sales, sum([Total Price]) as Total_revenue 
from ##lic_2024

select count(*) as Tot_Sales, sum([Total Price]) as Total_revenue 
from ##Permit2024--[dbo].[HFPA_2024_0712]--[dbo].[HFPA_Lic_2024_0705]--[dbo].[HFPA_Lic_2024_0630]

select count(*) as Tot_Sales, sum([Total Price]) as Total_revenue 
from 
(select * from ##lic_2024
union all
select * from ##permit2024) as a

select count(*) as Tot_Sales, sum([Total Price]) as Total_revenue 
from ##lic_2023

select count(*) as Tot_Sales, sum([Total Price]) as Total_revenue 
from ##Permit2023--[dbo].[HFPA_2024_0712]--[dbo].[HFPA_Lic_2024_0705]--[dbo].[HFPA_Lic_2024_0630]

select count(*) as Tot_Sales, sum([Total Price]) as Total_revenue 
from 
(select * from ##lic_2023
union all
select * from ##permit2023) as a



select distinct  [Price Code], [Product Name],count(*) as Tot_Sales, sum([Total Price]) as Total_revenue 
from 
(select * from ##lic_2024
union all
select * from ##permit2024) as a
--[dbo].[HFPA_Voucher_FY2024]--[dbo].[HFPA_2024_0712]--[dbo].[HFPA_Lic_2024_0705]--[dbo].[HFPA_Lic_2024_0630
--where [Price code] in ('101','102','104','113','150','151','152') 
group by [Price Code], [Product Name]
order by [Price Code]


select distinct  [Price Code], [Product Name],count(*) as Tot_Sales, sum([Total Price]) as Total_revenue 
from 
(select * from ##lic_2023
union all
select * from ##permit2023) as a
--[dbo].[HFPA_Voucher_FY2024]--[dbo].[HFPA_2024_0712]--[dbo].[HFPA_Lic_2024_0705]--[dbo].[HFPA_Lic_2024_0630
--where [Price code] in ('101','102','104','113','150','151','152') 
group by [Price Code], [Product Name]
order by [Price Code]

select * from [dbo].[HFPA_Permit_2023_0719]
where [Price Code] = '158'


select distinct  [Price Code], [Product Name],count(*) as Tot_Sales, sum([Total Price]) as Total_revenue 
from 
(select * from ##bl2024) as a
--[dbo].[HFPA_Voucher_FY2024]--[dbo].[HFPA_2024_0712]--[dbo].[HFPA_Lic_2024_0705]--[dbo].[HFPA_Lic_2024_0630
--where [Price code] in ('101','102','104','113','150','151','152') 
group by [Price Code], [Product Name]
order by [Price Code]


select distinct  [Price Code], [Product Name],count(*) as Tot_Sales, sum([Total Price]) as Total_revenue 
from 
(select * from ##bl2023) as a
--[dbo].[HFPA_Voucher_FY2024]--[dbo].[HFPA_2024_0712]--[dbo].[HFPA_Lic_2024_0705]--[dbo].[HFPA_Lic_2024_0630
--where [Price code] in ('101','102','104','113','150','151','152') 
group by [Price Code], [Product Name]
order by [Price Code]


select distinct  [Price Code], [Product Name],count(*) as Tot_Sales, sum(Final_Total_Price) as Total_revenue 
from 
(select * from ##HFPA_Valentines_Voucher_2025 ) as a
--[dbo].[HFPA_Voucher_FY2024]--[dbo].[HFPA_2024_0712]--[dbo].[HFPA_Lic_2024_0705]--[dbo].[HFPA_Lic_2024_0630
--where [Price code] in ('101','102','104','113','150','151','152') 
group by [Price Code], [Product Name]
order by [Price Code]


select distinct  [Price Code], [Product Name],count(*) as Tot_Sales, sum(Final_Total_Price) as Total_revenue 
from 
(select * from ##HFPA_Valentines_Voucher_2024 ) as a
--[dbo].[HFPA_Voucher_FY2024]--[dbo].[HFPA_2024_0712]--[dbo].[HFPA_Lic_2024_0705]--[dbo].[HFPA_Lic_2024_0630
--where [Price code] in ('101','102','104','113','150','151','152') 
group by [Price Code], [Product Name]
order by [Price Code]