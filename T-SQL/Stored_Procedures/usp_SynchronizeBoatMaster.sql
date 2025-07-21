USE [PALS2_OEMData]
GO

/****** Object:  StoredProcedure [dbo].[usp_SynchronizeBoatMaster]    Script Date: 7/14/2025 2:15:22 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*
-- ==================================================================================================
--                                    HOW TO EXECUTE THIS PROCEDURE
-- ==================================================================================================

-- For a Full Production Run:
-- This will process every row in your OEM_Boat table.

DECLARE @BatchId INT = (SELECT ISNULL(MAX(ETLBatchId), 0) + 1 FROM dbo.BoatMaster);
EXEC dbo.usp_SynchronizeBoatMaster
    @SourceInfo = N'dbo.OEM_Boat', -- Use the source table name for logging
    @ETLBatchId = @BatchId;
GO


-- For a Quick Test Run:
-- This is extremely useful for development. It will only process the first 1000 rows.

EXEC dbo.usp_SynchronizeBoatMaster
    @SourceInfo = N'Test Run',
    @ETLBatchId = -1, -- Use -1 or any other non-production ID for testing
    @TestRowCount = 1000;
GO

*/

CREATE PROCEDURE [dbo].[usp_SynchronizeBoatMaster]
    @SourceInfo NVARCHAR(255),
    @ETLBatchId INT,
    @TestRowCount INT = NULL
AS
BEGIN
    -- ==================================================================================================
    -- Stored Procedure: usp_SynchronizeBoatMaster (Definitive w/ Email Validation)
    -- Author:           Your Name/Team
    -- Create date:      2025-07-14
    -- Description:      The definitive cleaning and enrichment procedure. This version adds aggressive
    --                   email format validation to the existing feature set.
    -- ==================================================================================================
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- ==============================================================================================
    -- STEP 0: SETUP AND LOGGING
    -- ==============================================================================================
    DECLARE @LogMsg NVARCHAR(1000);
    DECLARE @MergeOutput TABLE(ActionTaken NVARCHAR(20));

    SET @LogMsg = CONVERT(NVARCHAR(23), GETDATE(), 121) + N': --- Starting usp_SynchronizeBoatMaster (Definitive w/ Email Validation) ---';
    RAISERROR(@LogMsg, 10, 1) WITH NOWAIT;

    IF OBJECT_ID('tempdb..#TestKeys') IS NOT NULL DROP TABLE #TestKeys;
    CREATE TABLE #TestKeys (BusinessKey NVARCHAR(100) PRIMARY KEY);

    IF @TestRowCount IS NOT NULL
    BEGIN
        SET @LogMsg = CONVERT(NVARCHAR(23), GETDATE(), 121) + N': [INFO] Running in TEST MODE for ' + CAST(@TestRowCount AS VARCHAR(10)) + N' rows.';
        RAISERROR(@LogMsg, 10, 1) WITH NOWAIT;
        INSERT INTO #TestKeys (BusinessKey) SELECT TOP (@TestRowCount) ISNULL(LTRIM(RTRIM(PA_REG)), '') + '|' + ISNULL(LTRIM(RTRIM(HIN_NUMBER)), '') FROM dbo.OEM_Boat;
    END

    IF OBJECT_ID('tempdb..#SourceStage') IS NOT NULL DROP TABLE #SourceStage;
    CREATE TABLE #SourceStage (
        BusinessKey NVARCHAR(100) NOT NULL, DataQualityScore INT NOT NULL, CleaningNotes NVARCHAR(2000) NULL, IsLikelyShifted BIT NOT NULL,
        StateId INT NULL, CountyId UNIQUEIDENTIFIER NULL,
        PA_REG NVARCHAR(50) NULL, HIN_NUMBER NVARCHAR(50) NULL, PREVIOUS_HIN_NUMBER NVARCHAR(50) NULL, WC_MAKE NVARCHAR(50) NULL,
        WC_MODEL NVARCHAR(50) NULL, MODEL_YEAR INT NULL, LENGTH_FT INT NULL, LENGTH_IN INT NULL, BOAT_TYPE NVARCHAR(50) NULL,
        POWERED NVARCHAR(50) NULL, USE_TYPE NVARCHAR(50) NULL, FEE NUMERIC(18, 2) NULL, REGIST_EXPIRATION_DATE DATETIME2(6) NULL,
        REGIST_ISSUE_DATE DATETIME2(6) NULL, REG_STATUS NVARCHAR(50) NULL, PRIMARY_FIRST_NAME NVARCHAR(50) NULL,
        PRIMARY_MIDDLE_NAME NVARCHAR(50) NULL, PRIMARY_LAST_NAME NVARCHAR(50) NULL, PRIMARY_SUFFIX_CODE NVARCHAR(20) NULL,
        PRIMARY_BIRTH_DATE DATETIME2(6) NULL, PRIMARY_OWNER_TYPE NVARCHAR(50) NULL, PRIMARY_ADDRESS_LINE1 NVARCHAR(255) NULL,
        PRIMARY_ADDRESS_LINE2 NVARCHAR(255) NULL, PRIMARY_CITY_NAME NVARCHAR(100) NULL, PRIMARY_STATE_CODE NVARCHAR(20) NULL,
        PRIMARY_ZIP_CODE NVARCHAR(20) NULL, PRIMARY_COUNTY_NAME NVARCHAR(100) NULL, PrimaryOwnerEmail NVARCHAR(255) NULL,
        SECONDARY_FIRST_NAME NVARCHAR(50) NULL, SECONDARY_MIDDLE_NAME NVARCHAR(50) NULL, SECONDARY_LAST_NAME NVARCHAR(50) NULL,
        SECONDARY_SUFFIX_CODE NVARCHAR(20) NULL, SECONDARY_BIRTH_DATE DATETIME2(6) NULL, SECONDARY_OWNER_TYPE NVARCHAR(50) NULL,
        SECONDARY_ADDRESS_LINE1 NVARCHAR(255) NULL, SECONDARY_ADDRESS_LINE2 NVARCHAR(255) NULL, SECONDARY_CITY_NAME NVARCHAR(100) NULL,
        SECONDARY_STATE_CODE NVARCHAR(20) NULL, SECONDARY_ZIP_CODE NVARCHAR(20) NULL, SECONDARY_COUNTY_NAME NVARCHAR(100) NULL, SecondaryOwnerEmail NVARCHAR(255) NULL
    );
    SET @LogMsg = CONVERT(NVARCHAR(23), GETDATE(), 121) + N': [SETUP] Temporary staging table #SourceStage created.';
    RAISERROR(@LogMsg, 10, 1) WITH NOWAIT;


    BEGIN TRY
        -- ==============================================================================================
        -- STEP 1: Pre-process, Enrich, and Load Raw Data
        -- ==============================================================================================
        SET @LogMsg = CONVERT(NVARCHAR(23), GETDATE(), 121) + N': [STEP 1] Pre-processing, enriching, and loading raw data...';
        RAISERROR(@LogMsg, 10, 1) WITH NOWAIT;

        ;WITH SourceData AS (
            SELECT * FROM dbo.OEM_Boat WHERE @TestRowCount IS NULL OR (ISNULL(LTRIM(RTRIM(PA_REG)), '') + '|' + ISNULL(LTRIM(RTRIM(HIN_NUMBER)), '')) IN (SELECT BusinessKey FROM #TestKeys)
        ),
        CorrectedShifts AS (
            SELECT *,
                Corrected_PRIMARY_BIRTH_DATE = CASE WHEN PRIMARY_BIRTH_DATE IS NULL AND TRY_CONVERT(DATETIME, PRIMARY_LAST_NAME, 112) IS NOT NULL THEN PRIMARY_LAST_NAME ELSE PRIMARY_BIRTH_DATE END,
                Corrected_PRIMARY_LAST_NAME = CASE WHEN PRIMARY_BIRTH_DATE IS NULL AND TRY_CONVERT(DATETIME, PRIMARY_LAST_NAME, 112) IS NOT NULL THEN NULL ELSE PRIMARY_LAST_NAME END,
                IsShifted = CASE WHEN PRIMARY_BIRTH_DATE IS NULL AND TRY_CONVERT(DATETIME, PRIMARY_LAST_NAME, 112) IS NOT NULL THEN 1 ELSE 0 END
            FROM SourceData
        ),
        EnrichedSource AS (
            SELECT s.*, st.Id AS FoundStateId, COALESCE(ct_exact.Id, ct_soundex.Id) AS FoundCountyId,
                   CASE WHEN ct_exact.Id IS NOT NULL THEN 'Exact' WHEN ct_soundex.Id IS NOT NULL THEN 'SOUNDEX' ELSE 'No Match' END AS CountyMatchTier
            FROM CorrectedShifts s
            LEFT JOIN [POSData_DailyReplication].dbo.RegionsLookup st ON s.PRIMARY_STATE_CODE = st.Code
            LEFT JOIN [POSData_DailyReplication].dbo.County ct_exact ON st.Id = ct_exact.StateId AND s.PRIMARY_COUNTY_NAME = ct_exact.Name
            LEFT JOIN [POSData_DailyReplication].dbo.County ct_soundex ON st.Id = ct_soundex.StateId AND SOUNDEX(s.PRIMARY_COUNTY_NAME) = SOUNDEX(ct_soundex.Name) AND ct_exact.Id IS NULL
        )
        INSERT INTO #SourceStage
        SELECT
            BusinessKey = ISNULL(LTRIM(RTRIM(src.PA_REG)), '') + '|' + ISNULL(LTRIM(RTRIM(src.HIN_NUMBER)), ''),
            DataQualityScore = 100
                - CASE WHEN src.FoundStateId IS NULL THEN 5 ELSE 0 END
                - CASE WHEN src.FoundCountyId IS NULL THEN 5 ELSE 0 END
                - CASE WHEN NULLIF(LTRIM(RTRIM(src.PRIMARY_EMAIL)), '') IS NOT NULL AND NULLIF(LTRIM(RTRIM(src.PRIMARY_EMAIL)), '') NOT LIKE '%_@__%.__%' THEN 10 ELSE 0 END, -- Email Validation Penalty
            CleaningNotes = STUFF(
                ISNULL(', ' + CASE WHEN src.IsShifted = 1 THEN 'Corrected Shifted DOB' ELSE NULL END, '') +
                ISNULL(', ' + CASE WHEN src.FoundCountyId IS NULL THEN 'County Not Found' ELSE 'County Match: ' + src.CountyMatchTier END, '') +
                ISNULL(', ' + CASE WHEN NULLIF(LTRIM(RTRIM(src.PRIMARY_EMAIL)), '') IS NOT NULL AND NULLIF(LTRIM(RTRIM(src.PRIMARY_EMAIL)), '') NOT LIKE '%_@__%.__%' THEN 'Invalid Primary Email Format' ELSE NULL END, ''),
                1, 2, ''),
            IsLikelyShifted = src.IsShifted, StateId = src.FoundStateId, CountyId = src.FoundCountyId,
            PA_REG = NULLIF(LTRIM(RTRIM(src.PA_REG)), ''), HIN_NUMBER = NULLIF(LTRIM(RTRIM(src.HIN_NUMBER)), ''), PREVIOUS_HIN_NUMBER = NULLIF(LTRIM(RTRIM(src.PREVIOUS_HIN_NUMBER)), ''),
            WC_MAKE = src.WC_MAKE, WC_MODEL = src.WC_MODEL, MODEL_YEAR = TRY_CAST(src.MODEL_YEAR AS INT),
            LENGTH_FT = TRY_CAST(src.LENGTH_FT AS INT), LENGTH_IN = TRY_CAST(src.LENGTH_IN AS INT), BOAT_TYPE = NULLIF(LTRIM(RTRIM(src.BOAT_TYPE)), ''),
            POWERED = NULLIF(LTRIM(RTRIM(src.POWERED)), ''), USE_TYPE = NULLIF(LTRIM(RTRIM(src.USE_TYPE)), ''), FEE = TRY_CAST(src.FEE AS NUMERIC(18, 2)),
            REGIST_EXPIRATION_DATE = TRY_CONVERT(DATETIME2, src.REGIST_EXPIRATION_DATE, 105), REGIST_ISSUE_DATE = TRY_CONVERT(DATETIME2, src.REGIST_ISSUE_DATE, 105),
            REG_STATUS = CASE WHEN LTRIM(RTRIM(src.REG_STATUS)) = 'Active' AND TRY_CONVERT(DATETIME2, src.REGIST_EXPIRATION_DATE, 105) >= GETDATE() THEN 'Active' ELSE 'Inactive' END,
            PRIMARY_FIRST_NAME = src.PRIMARY_FIRST_NAME, PRIMARY_MIDDLE_NAME = src.PRIMARY_MIDDLE_NAME, PRIMARY_LAST_NAME = src.Corrected_PRIMARY_LAST_NAME,
            PRIMARY_SUFFIX_CODE = NULLIF(LTRIM(RTRIM(src.PRIMARY_SUFFIX_CODE)), ''), PRIMARY_BIRTH_DATE = TRY_CONVERT(DATETIME2, src.Corrected_PRIMARY_BIRTH_DATE, 112),
            PRIMARY_OWNER_TYPE = src.PRIMARY_OWNER_TYPE, PRIMARY_ADDRESS_LINE1 = NULLIF(LTRIM(RTRIM(src.PRIMARY_ADDRESS_LINE1)), ''),
            PRIMARY_ADDRESS_LINE2 = NULLIF(LTRIM(RTRIM(src.PRIMARY_ADDRESS_LINE2)), ''), PRIMARY_CITY_NAME = src.PRIMARY_CITY_NAME,
            PRIMARY_STATE_CODE = UPPER(NULLIF(LTRIM(RTRIM(src.PRIMARY_STATE_CODE)), '')), PRIMARY_ZIP_CODE = NULLIF(LTRIM(RTRIM(src.PRIMARY_ZIP_CODE)), ''),
            PRIMARY_COUNTY_NAME = src.PRIMARY_COUNTY_NAME,
            -- Aggressive Email Validation
            PrimaryOwnerEmail = CASE WHEN NULLIF(LTRIM(RTRIM(src.PRIMARY_EMAIL)), '') LIKE '%_@__%.__%' THEN LTRIM(RTRIM(src.PRIMARY_EMAIL)) ELSE NULL END,
            SECONDARY_FIRST_NAME = src.SECONDARY_FIRST_NAME, SECONDARY_MIDDLE_NAME = src.SECONDARY_MIDDLE_NAME, SECONDARY_LAST_NAME = src.SECONDARY_LAST_NAME,
            SECONDARY_SUFFIX_CODE = NULLIF(LTRIM(RTRIM(src.SECONDARY_SUFFIX_CODE)), ''), SECONDARY_BIRTH_DATE = TRY_CONVERT(DATETIME2, src.SECONDARY_BIRTH_DATE, 112),
            SECONDARY_OWNER_TYPE = src.SECONDARY_OWNER_TYPE, SECONDARY_ADDRESS_LINE1 = NULLIF(LTRIM(RTRIM(src.SECONDARY_ADDRESS_LINE1)), ''),
            SECONDARY_ADDRESS_LINE2 = NULLIF(LTRIM(RTRIM(src.SECONDARY_ADDRESS_LINE2)), ''), SECONDARY_CITY_NAME = src.SECONDARY_CITY_NAME,
            SECONDARY_STATE_CODE = UPPER(NULLIF(LTRIM(RTRIM(src.SECONDARY_STATE_CODE)), '')), SECONDARY_ZIP_CODE = NULLIF(LTRIM(RTRIM(src.SECONDARY_ZIP_CODE)), ''),
            SECONDARY_COUNTY_NAME = src.SECONDARY_COUNTY_NAME,
            SecondaryOwnerEmail = CASE WHEN NULLIF(LTRIM(RTRIM(src.SECONDARY_EMAIL)), '') LIKE '%_@__%.__%' THEN LTRIM(RTRIM(src.SECONDARY_EMAIL)) ELSE NULL END
        FROM EnrichedSource src;

        SET @LogMsg = CONVERT(NVARCHAR(23), GETDATE(), 121) + N': [STEP 1] Staging table populated with ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + N' raw rows.';
        RAISERROR(@LogMsg, 10, 1) WITH NOWAIT;

        -- ==============================================================================================
        -- STEP 2: Standardize the staged data using functions (Performance Optimization)
        -- ==============================================================================================
        SET @LogMsg = CONVERT(NVARCHAR(23), GETDATE(), 121) + N': [STEP 2] Applying standardization functions...';
        RAISERROR(@LogMsg, 10, 1) WITH NOWAIT;

        UPDATE #SourceStage SET
            WC_MAKE = dbo.fn_ProperCase(WC_MAKE), WC_MODEL = dbo.fn_ProperCase(WC_MODEL),
            PRIMARY_FIRST_NAME = dbo.fn_ProperCase(PRIMARY_FIRST_NAME), PRIMARY_MIDDLE_NAME = dbo.fn_ProperCase(PRIMARY_MIDDLE_NAME),
            PRIMARY_LAST_NAME = dbo.fn_ProperCase(PRIMARY_LAST_NAME), PRIMARY_OWNER_TYPE = dbo.fn_ProperCase(PRIMARY_OWNER_TYPE),
            PRIMARY_CITY_NAME = dbo.fn_ProperCase(PRIMARY_CITY_NAME), PRIMARY_COUNTY_NAME = dbo.fn_ProperCase(PRIMARY_COUNTY_NAME),
            SECONDARY_FIRST_NAME = dbo.fn_ProperCase(SECONDARY_FIRST_NAME), SECONDARY_MIDDLE_NAME = dbo.fn_ProperCase(SECONDARY_MIDDLE_NAME),
            SECONDARY_LAST_NAME = dbo.fn_ProperCase(SECONDARY_LAST_NAME), SECONDARY_OWNER_TYPE = dbo.fn_ProperCase(SECONDARY_OWNER_TYPE),
            SECONDARY_CITY_NAME = dbo.fn_ProperCase(SECONDARY_CITY_NAME), SECONDARY_COUNTY_NAME = dbo.fn_ProperCase(SECONDARY_COUNTY_NAME);

        SET @LogMsg = CONVERT(NVARCHAR(23), GETDATE(), 121) + N': [STEP 2] Standardization complete.';
        RAISERROR(@LogMsg, 10, 1) WITH NOWAIT;

        BEGIN TRANSACTION;

        -- ==============================================================================================
        -- STEP 3: MERGE the cleaned and enriched data into the BoatMaster table.
        -- ==============================================================================================
        SET @LogMsg = CONVERT(NVARCHAR(23), GETDATE(), 121) + N': [STEP 3] Merging staged data into BoatMaster...';
        RAISERROR(@LogMsg, 10, 1) WITH NOWAIT;

        MERGE [dbo].[BoatMaster] AS Target
        USING #SourceStage AS Source
        ON (Target.BusinessKey = Source.BusinessKey)

        WHEN MATCHED AND (Target.ProcessingStatus = 'Archived' OR ISNULL(Target.PRIMARY_LAST_NAME, '') <> ISNULL(Source.PRIMARY_LAST_NAME, '') OR ISNULL(Target.PrimaryOwnerEmail, '') <> ISNULL(Source.PrimaryOwnerEmail, '') OR ISNULL(Target.StateId, 0) <> ISNULL(Source.StateId, 0)) THEN
            UPDATE SET
                Target.ProcessingStatus = 'Staged', Target.ModifiedDate = GETUTCDATE(), Target.ETLBatchId = @ETLBatchId, Target.SourceInfo = @SourceInfo,
                Target.DataQualityScore = Source.DataQualityScore, Target.CleaningNotes = Source.CleaningNotes, Target.IsLikelyShifted = Source.IsLikelyShifted,
                Target.StateId = Source.StateId, Target.CountyId = Source.CountyId,
                Target.PA_REG = Source.PA_REG, Target.HIN_NUMBER = Source.HIN_NUMBER, Target.REG_STATUS = Source.REG_STATUS,
                Target.PRIMARY_FIRST_NAME = Source.PRIMARY_FIRST_NAME, Target.PRIMARY_LAST_NAME = Source.PRIMARY_LAST_NAME,
                Target.PrimaryOwnerEmail = ISNULL(Source.PrimaryOwnerEmail, Target.PrimaryOwnerEmail),
                Target.SECONDARY_FIRST_NAME = Source.SECONDARY_FIRST_NAME, Target.SECONDARY_LAST_NAME = Source.SECONDARY_LAST_NAME,
                Target.SecondaryOwnerEmail = ISNULL(Source.SecondaryOwnerEmail, Target.SecondaryOwnerEmail)

        WHEN NOT MATCHED BY TARGET THEN
            INSERT ( BusinessKey, ProcessingStatus, ETLBatchId, SourceInfo, DataQualityScore, CleaningNotes, IsLikelyShifted, StateId, CountyId, PA_REG, HIN_NUMBER, PREVIOUS_HIN_NUMBER, WC_MAKE, WC_MODEL, MODEL_YEAR, LENGTH_FT, LENGTH_IN, BOAT_TYPE, POWERED, USE_TYPE, FEE, REGIST_EXPIRATION_DATE, REGIST_ISSUE_DATE, REG_STATUS, PRIMARY_FIRST_NAME, PRIMARY_MIDDLE_NAME, PRIMARY_LAST_NAME, PRIMARY_SUFFIX_CODE, PRIMARY_BIRTH_DATE, PRIMARY_OWNER_TYPE, PRIMARY_ADDRESS_LINE1, PRIMARY_ADDRESS_LINE2, PRIMARY_CITY_NAME, PRIMARY_STATE_CODE, PRIMARY_ZIP_CODE, PRIMARY_COUNTY_NAME, PrimaryOwnerEmail, SECONDARY_FIRST_NAME, SECONDARY_MIDDLE_NAME, SECONDARY_LAST_NAME, SECONDARY_SUFFIX_CODE, SECONDARY_BIRTH_DATE, SECONDARY_OWNER_TYPE, SECONDARY_ADDRESS_LINE1, SECONDARY_ADDRESS_LINE2, SECONDARY_CITY_NAME, SECONDARY_STATE_CODE, SECONDARY_ZIP_CODE, SECONDARY_COUNTY_NAME, SecondaryOwnerEmail )
            VALUES ( Source.BusinessKey, 'Staged', @ETLBatchId, @SourceInfo, Source.DataQualityScore, Source.CleaningNotes, Source.IsLikelyShifted, Source.StateId, Source.CountyId, Source.PA_REG, Source.HIN_NUMBER, Source.PREVIOUS_HIN_NUMBER, Source.WC_MAKE, Source.WC_MODEL, Source.MODEL_YEAR, Source.LENGTH_FT, Source.LENGTH_IN, Source.BOAT_TYPE, Source.POWERED, Source.USE_TYPE, Source.FEE, Source.REGIST_EXPIRATION_DATE, Source.REGIST_ISSUE_DATE, Source.REG_STATUS, Source.PRIMARY_FIRST_NAME, Source.PRIMARY_MIDDLE_NAME, Source.PRIMARY_LAST_NAME, Source.PRIMARY_SUFFIX_CODE, Source.PRIMARY_BIRTH_DATE, Source.PRIMARY_OWNER_TYPE, Source.PRIMARY_ADDRESS_LINE1, Source.PRIMARY_ADDRESS_LINE2, Source.PRIMARY_CITY_NAME, Source.PRIMARY_STATE_CODE, Source.PRIMARY_ZIP_CODE, Source.PRIMARY_COUNTY_NAME, Source.PrimaryOwnerEmail, Source.SECONDARY_FIRST_NAME, Source.SECONDARY_MIDDLE_NAME, Source.SECONDARY_LAST_NAME, Source.SECONDARY_SUFFIX_CODE, Source.SECONDARY_BIRTH_DATE, Source.SECONDARY_OWNER_TYPE, Source.SECONDARY_ADDRESS_LINE1, Source.SECONDARY_ADDRESS_LINE2, Source.SECONDARY_CITY_NAME, Source.SECONDARY_STATE_CODE, Source.SECONDARY_ZIP_CODE, Source.SECONDARY_COUNTY_NAME, Source.SecondaryOwnerEmail )

        WHEN NOT MATCHED BY SOURCE AND @TestRowCount IS NULL THEN
            UPDATE SET Target.ProcessingStatus = 'Archived', Target.ModifiedDate = GETUTCDATE(), Target.ETLBatchId = @ETLBatchId
        OUTPUT $action INTO @MergeOutput;

        COMMIT TRANSACTION;

        -- ==============================================================================================
        -- STEP 4: REPORTING AND CLEANUP
        -- ==============================================================================================
        DECLARE @Inserts INT = (SELECT COUNT(*) FROM @MergeOutput WHERE ActionTaken = 'INSERT');
        DECLARE @Updates INT = (SELECT COUNT(*) FROM @MergeOutput WHERE ActionTaken = 'UPDATE');
        SET @LogMsg = FORMATMESSAGE('[STEP 3] Merge complete. Inserts: %i, Updates: %i.', @Inserts, @Updates);
        RAISERROR(@LogMsg, 10, 1) WITH NOWAIT;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @LogMsg = CONVERT(NVARCHAR(23), GETDATE(), 121) + N': [FATAL ERROR] An error occurred. Transaction rolled back. Details: ' + ERROR_MESSAGE();
        RAISERROR (@LogMsg, 16, 1);
        THROW;
    END CATCH;

    IF OBJECT_ID('tempdb..#SourceStage') IS NOT NULL DROP TABLE #SourceStage;
    IF OBJECT_ID('tempdb..#TestKeys') IS NOT NULL DROP TABLE #TestKeys;

    SET @LogMsg = CONVERT(NVARCHAR(23), GETDATE(), 121) + N': --- Finished usp_SynchronizeBoatMaster ---';
    RAISERROR(@LogMsg, 10, 1) WITH NOWAIT;

    SET NOCOUNT OFF;
END
GO


