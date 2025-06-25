USE [Northwind_DW]
GO

/****** Object:  Table [dbo].[Audit_table]    Script Date: 10/10/2018 1:00:44 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Audit_table](
	[AuditKey] [int] IDENTITY(1,1) NOT NULL,
	[ParentAuditKey] [int] NOT NULL,
	[PkgName] [nvarchar](100) NULL,
	[PkgID] [nvarchar](100) NULL,
	[ExecStartDT] [datetime] NULL,
	[ExecEndDT] [datetime] NULL,
	[TableName] [nvarchar](100) NULL,
	[ExecutionInstanceGUID] [nvarchar](100) NULL,
	[TableInitialRowCnt] [int] NULL,
	[ExtractRowCnt] [int] NULL,
	[InsertRowCnt] [int] NULL,
	[UpdateRowCnt] [int] NULL,
	[ErrorRowCnt] [int] NULL,
	[DeletedRowCnt] [int] NULL,
	[TableFinalRowCnt] [int] NULL,
	[SuccessfulProcessingInd] [char](1) NULL,
PRIMARY KEY CLUSTERED 
(
	[AuditKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Audit_table] ADD  DEFAULT ('N') FOR [SuccessfulProcessingInd]
GO


