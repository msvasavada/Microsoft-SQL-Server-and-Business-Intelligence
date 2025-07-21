with mergeall as (
select * from [dbo].[All_subcribers_07192024]
union all
select * from [dbo].[All_subcribers_10022024]
union all
select * from [dbo].[All_subcribers_01142025]
union all
select * from [dbo].[All_subcribers_03062025]
union all
select * from [dbo].[All_subcribers_05012025]
union all
select * from [dbo].[All_Fish_subcribers_05012025_unique]
)
select * into [dbo].[All_2025_Fish_subcribers_tilldate]
from mergeall