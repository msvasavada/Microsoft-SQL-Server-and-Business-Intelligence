use PALS2_OEMData
select * from [dbo].[Boat_Cleaned_Staging]
where reg_status = 'active' and primaryowneremail is null or primary_birth_date is null