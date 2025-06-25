USE [Northwind_DW]
GO

/****** Object:  Table [dbo].[Dim_Customers]    Script Date: 10/10/2018 1:01:19 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Dim_Customers](
	[Customer_Key] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [nchar](5) NULL,
	[CompanyName] [nvarchar](40) NULL,
	[ContactName] [nvarchar](30) NULL,
	[ContactTitle] [nvarchar](30) NULL,
	[Address] [nvarchar](60) NULL,
	[City] [nvarchar](15) NULL,
	[Region] [nvarchar](15) NULL,
	[PostalCode] [nvarchar](10) NULL,
	[Country] [nvarchar](15) NULL,
	[Phone] [nvarchar](24) NULL,
	[Fax] [nvarchar](24) NULL,
	[Active_Flag] [char](1) NULL,
	[Delete_Flag] [char](1) NULL,
	[Effective_Start_Date] [datetime] NULL,
	[Effective_End_Date] [datetime] NULL,
	[ETL_Row_Create_dt] [datetime] NULL,
	[Batch_or_Load_ID] [int] NULL,
	[ETL_Batch_DTM] [datetime] NULL,
	[Last_Mod_DTM] [datetime] NULL,
	[Last_Mod_User] [nvarchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[Customer_Key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Dim_Customers] ADD  DEFAULT ('Y') FOR [Active_Flag]
GO

ALTER TABLE [dbo].[Dim_Customers] ADD  DEFAULT ('N') FOR [Delete_Flag]
GO

ALTER TABLE [dbo].[Dim_Customers] ADD  DEFAULT ('9999-12-31') FOR [Effective_End_Date]
GO

ALTER TABLE [dbo].[Dim_Customers] ADD  DEFAULT (getdate()) FOR [ETL_Row_Create_dt]
GO

ALTER TABLE [dbo].[Dim_Customers] ADD  DEFAULT (getdate()) FOR [ETL_Batch_DTM]
GO

ALTER TABLE [dbo].[Dim_Customers] ADD  DEFAULT (getdate()) FOR [Last_Mod_DTM]
GO


