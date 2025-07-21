USE [PALS2_OEMData]
GO

/****** Object:  StoredProcedure [dbo].[usp_FindCustomerMatches_Engine]    Script Date: 7/14/2025 2:14:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[usp_FindCustomerMatches_Engine]
    @TestRowCount INT = NULL
AS
BEGIN
    -- ==================================================================================================
    -- Stored Procedure: usp_FindCustomerMatches_Engine (Definitive Edition)
    -- Author:           Your Name/Team
    -- Create date:      2025-07-14
    -- Description:      The definitive matching engine. Uses a high-performance, unpivoted architecture
    --                   with pre-calculated standardization and a deep, multi-tiered matching waterfall.
    --
    -- To run a full production job:
    -- EXEC dbo.usp_FindCustomerMatches_Engine;
    --
    -- To run in test mode on a subset of 1000 records:
    -- EXEC dbo.usp_FindCustomerMatches_Engine @TestRowCount = 1000;
    -- ==================================================================================================
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- ==============================================================================================
    -- STEP 0: SETUP AND LOGGING
    -- ==============================================================================================
    DECLARE @LogMsg NVARCHAR(1000), @RowCount INT, @TotalRecords INT;
    SET @LogMsg = CONVERT(NVARCHAR(23), GETDATE(), 121) + N': --- Starting usp_FindCustomerMatches_Engine (Definitive Edition) ---';
    RAISERROR(@LogMsg, 10, 1) WITH NOWAIT;

    -- ==============================================================================================
    -- STEP 1: PREPARE STAGING TABLE
    -- ==============================================================================================
    RAISERROR(N'--- Step 1: Preparing staging table ---', 10, 1) WITH NOWAIT;
    IF OBJECT_ID('tempdb..#Staging') IS NOT NULL DROP TABLE #Staging;
    CREATE TABLE #Staging (
        RowId INT PRIMARY KEY,
        P_FName VARCHAR(100), P_LName VARCHAR(100), P_LName_Soundex VARCHAR(4) NULL, P_DOB DATE, P_Zip VARCHAR(5), P_Addr1_Norm VARCHAR(255) NULL, P_Email VARCHAR(255),
        S_FName VARCHAR(100), S_LName VARCHAR(100), S_LName_Soundex VARCHAR(4) NULL, S_DOB DATE, S_Zip VARCHAR(5), S_Addr1_Norm VARCHAR(255) NULL, S_Email VARCHAR(255)
    );

    INSERT INTO #Staging (RowId, P_FName, P_LName, P_DOB, P_Zip, P_Addr1_Norm, P_Email, S_FName, S_LName, S_DOB, S_Zip, S_Addr1_Norm, S_Email)
    SELECT TOP (ISNULL(@TestRowCount, 2147483647)) RowId,
        UPPER(LTRIM(RTRIM(PRIMARY_FIRST_NAME))), UPPER(LTRIM(RTRIM(PRIMARY_LAST_NAME))), CAST(PRIMARY_BIRTH_DATE AS DATE), LEFT(LTRIM(RTRIM(PRIMARY_ZIP_CODE)), 5), dbo.fn_StandardizeAddress(PRIMARY_ADDRESS_LINE1), UPPER(LTRIM(RTRIM(PrimaryOwnerEmail))),
        UPPER(LTRIM(RTRIM(SECONDARY_FIRST_NAME))), UPPER(LTRIM(RTRIM(SECONDARY_LAST_NAME))), CAST(SECONDARY_BIRTH_DATE AS DATE), LEFT(LTRIM(RTRIM(SECONDARY_ZIP_CODE)), 5), dbo.fn_StandardizeAddress(SECONDARY_ADDRESS_LINE1), UPPER(LTRIM(RTRIM(SecondaryOwnerEmail)))
    FROM dbo.BoatMaster WHERE ProcessingStatus IN ('Staged', 'Matching');

    SELECT @TotalRecords = COUNT(*) FROM #Staging;
    SET @LogMsg = FORMATMESSAGE('    > Staging table created with %i records to process.', @TotalRecords);
    RAISERROR(@LogMsg, 10, 1) WITH NOWAIT;
    IF @TotalRecords = 0 BEGIN RAISERROR(N'--- No records to process. Procedure finished. ---', 10, 1) WITH NOWAIT; RETURN; END

    RAISERROR(N'    > Pre-calculating SOUNDEX codes for fuzzy name matching...', 10, 1) WITH NOWAIT;
    UPDATE #Staging SET P_LName_Soundex = SOUNDEX(P_LName), S_LName_Soundex = SOUNDEX(S_LName);

    UPDATE bm SET ProcessingStatus = 'Matching' FROM dbo.BoatMaster bm JOIN #Staging s ON bm.RowId = s.RowId;

    -- ==============================================================================================
    -- STEP 2: UNPIVOT DATA FOR UNIFIED MATCHING LOGIC
    -- ==============================================================================================
    RAISERROR(N'--- Step 2: Unpivoting owner data for unified matching ---', 10, 1) WITH NOWAIT;
    IF OBJECT_ID('tempdb..#UnpivotedOwners') IS NOT NULL DROP TABLE #UnpivotedOwners;
    CREATE TABLE #UnpivotedOwners (
        RowId INT, OwnerType VARCHAR(10), FName VARCHAR(100), LName VARCHAR(100), LName_Soundex VARCHAR(4), DOB DATE, Zip VARCHAR(5), Addr1_Norm VARCHAR(255), Email VARCHAR(255),
        CID_Display NVARCHAR(18) NULL, Match_Tier VARCHAR(100) NULL, Probable_CIDs NVARCHAR(MAX) NULL
    );
    CREATE CLUSTERED INDEX CIX_Unpivoted ON #UnpivotedOwners(RowId, OwnerType);

    INSERT INTO #UnpivotedOwners (RowId, OwnerType, FName, LName, LName_Soundex, DOB, Zip, Addr1_Norm, Email)
    SELECT RowId, 'Primary', P_FName, P_LName, P_LName_Soundex, P_DOB, P_Zip, P_Addr1_Norm, P_Email FROM #Staging WHERE P_LName IS NOT NULL
    UNION ALL
    SELECT RowId, 'Secondary', S_FName, S_LName, S_LName_Soundex, S_DOB, S_Zip, S_Addr1_Norm, S_Email FROM #Staging WHERE S_LName IS NOT NULL;


    BEGIN TRY
        -- ==============================================================================================
        -- STEP 3: EXECUTE UNIFIED MATCHING ENGINE
        -- ==============================================================================================
        RAISERROR(N'--- Step 3: Executing Unified Matching Engine ---', 10, 1) WITH NOWAIT;
        IF OBJECT_ID('tempdb..#MatchResults') IS NOT NULL DROP TABLE #MatchResults;
        CREATE TABLE #MatchResults(RowId INT, OwnerType VARCHAR(10), CustomerId NVARCHAR(18), MatchCount INT, All_CIDs NVARCHAR(MAX)); CREATE CLUSTERED INDEX CIX_MatchResults ON #MatchResults(RowId, OwnerType);

        -- Tier 1A: Email + LName + DOB -> Tie-Breaker 1A-1 (Postal)
        INSERT INTO #MatchResults (RowId, OwnerType, CustomerId, MatchCount, All_CIDs) SELECT s.RowId, s.OwnerType, c.CustomerId, COUNT(*) OVER (PARTITION BY s.RowId, s.OwnerType), STUFF((SELECT ',' + c_inner.CustomerId FROM [POSData_DailyReplication].dbo.Customer c_inner WHERE c_inner.EmailAddress = s.Email AND c_inner.LastName = s.LName AND CAST(c_inner.DateOfBirth AS DATE) = s.DOB FOR XML PATH('')), 1, 1, '') FROM #UnpivotedOwners s JOIN [POSData_DailyReplication].dbo.Customer c ON s.Email = c.EmailAddress AND s.LName = c.LName AND s.DOB = CAST(c.DateOfBirth AS DATE) WHERE s.CID_Display IS NULL AND s.Email IS NOT NULL;
        UPDATE s SET s.CID_Display = CASE WHEN r.MatchCount=1 THEN r.CustomerId END, s.Probable_CIDs = CASE WHEN r.MatchCount>1 THEN r.All_CIDs END, s.Match_Tier = CASE WHEN r.MatchCount=1 THEN '1A: Email+LName+DOB' WHEN r.MatchCount>1 THEN 'Review - Ambiguous 1A' END FROM #UnpivotedOwners s JOIN #MatchResults r ON s.RowId=r.RowId AND s.OwnerType = r.OwnerType;
        SET @RowCount = @@ROWCOUNT; SET @LogMsg = FORMATMESSAGE('    > Tier 1A (Email+LName+DOB) found matches for %i owners.', @RowCount); RAISERROR(@LogMsg, 10, 1) WITH NOWAIT; TRUNCATE TABLE #MatchResults;
        INSERT INTO #MatchResults (RowId, OwnerType, CustomerId, MatchCount, All_CIDs) SELECT s.RowId, s.OwnerType, c.CustomerId, COUNT(*) OVER (PARTITION BY s.RowId, s.OwnerType), s.Probable_CIDs FROM #UnpivotedOwners s CROSS APPLY STRING_SPLIT(s.Probable_CIDs, ',') spl JOIN [POSData_DailyReplication].dbo.Customer c ON LTRIM(RTRIM(spl.value)) = c.CustomerId JOIN [POSData_DailyReplication].dbo.Address a ON c.ResidencyAddressId = a.Id AND LEFT(a.PostalCode, 5) = s.Zip WHERE s.Match_Tier = 'Review - Ambiguous 1A';
        UPDATE s SET s.CID_Display = CASE WHEN r.MatchCount=1 THEN r.CustomerId END, s.Match_Tier = '1A-1: Tie-Break on Postal' FROM #UnpivotedOwners s JOIN #MatchResults r ON s.RowId=r.RowId AND s.OwnerType = r.OwnerType WHERE s.Match_Tier = 'Review - Ambiguous 1A';
        SET @RowCount = @@ROWCOUNT; SET @LogMsg = FORMATMESSAGE('    > Tier 1A-1 (Ambiguous 1A + Postal) resolved %i owners.', @RowCount); RAISERROR(@LogMsg, 10, 1) WITH NOWAIT; TRUNCATE TABLE #MatchResults;

        -- Tier 2A: FName + LName + DOB + Postal (Perfect Match)
        INSERT INTO #MatchResults (RowId, OwnerType, CustomerId, MatchCount, All_CIDs) SELECT s.RowId, s.OwnerType, c.CustomerId, COUNT(*) OVER (PARTITION BY s.RowId, s.OwnerType), STUFF((SELECT ',' + c_inner.CustomerId FROM [POSData_DailyReplication].dbo.Customer c_inner JOIN [POSData_DailyReplication].dbo.Address a_inner ON c_inner.ResidencyAddressId = a_inner.Id WHERE c_inner.FirstName = s.FName AND c_inner.LastName = s.LName AND CAST(c_inner.DateOfBirth AS DATE) = s.DOB AND LEFT(a_inner.PostalCode, 5) = s.Zip FOR XML PATH('')), 1, 1, '') FROM #UnpivotedOwners s JOIN [POSData_DailyReplication].dbo.Customer c ON s.FName = c.FirstName AND s.LName = c.LName AND s.DOB = CAST(c.DateOfBirth AS DATE) JOIN [POSData_DailyReplication].dbo.Address a ON c.ResidencyAddressId = a.Id AND s.Zip = LEFT(a.PostalCode, 5) WHERE s.CID_Display IS NULL;
        UPDATE s SET s.CID_Display = CASE WHEN r.MatchCount=1 THEN r.CustomerId END, s.Probable_CIDs = CASE WHEN r.MatchCount>1 THEN r.All_CIDs END, s.Match_Tier = CASE WHEN r.MatchCount=1 THEN '2A: FName+LName+DOB+ZIP' WHEN r.MatchCount>1 THEN 'Review - Ambiguous 2A' END FROM #UnpivotedOwners s JOIN #MatchResults r ON s.RowId=r.RowId AND s.OwnerType = r.OwnerType;
        SET @RowCount = @@ROWCOUNT; SET @LogMsg = FORMATMESSAGE('    > Tier 2A (FName+LName+DOB+ZIP) found matches for %i owners.', @RowCount); RAISERROR(@LogMsg, 10, 1) WITH NOWAIT; TRUNCATE TABLE #MatchResults;

        -- Tier 3B: FName + LName + DOB (No Address)
        INSERT INTO #MatchResults (RowId, OwnerType, CustomerId, MatchCount, All_CIDs) SELECT s.RowId, s.OwnerType, c.CustomerId, COUNT(*) OVER (PARTITION BY s.RowId, s.OwnerType), STUFF((SELECT ',' + c_inner.CustomerId FROM [POSData_DailyReplication].dbo.Customer c_inner WHERE c_inner.FirstName = s.FName AND c_inner.LastName = s.LName AND CAST(c_inner.DateOfBirth AS DATE) = s.DOB FOR XML PATH('')), 1, 1, '') FROM #UnpivotedOwners s JOIN [POSData_DailyReplication].dbo.Customer c ON s.FName = c.FirstName AND s.LName = c.LName AND s.DOB = CAST(c.DateOfBirth AS DATE) WHERE s.CID_Display IS NULL;
        UPDATE s SET s.CID_Display = CASE WHEN r.MatchCount=1 THEN r.CustomerId END, s.Probable_CIDs = CASE WHEN r.MatchCount>1 THEN r.All_CIDs END, s.Match_Tier = CASE WHEN r.MatchCount=1 THEN '3B: FName+LName+DOB' WHEN r.MatchCount>1 THEN 'Review - Ambiguous 3B' END FROM #UnpivotedOwners s JOIN #MatchResults r ON s.RowId=r.RowId AND s.OwnerType = r.OwnerType;
        SET @RowCount = @@ROWCOUNT; SET @LogMsg = FORMATMESSAGE('    > Tier 3B (FName+LName+DOB) found matches for %i owners.', @RowCount); RAISERROR(@LogMsg, 10, 1) WITH NOWAIT; TRUNCATE TABLE #MatchResults;

        -- Tier 4B: FName + LName + Normalized Address + Postal
        INSERT INTO #MatchResults (RowId, OwnerType, CustomerId, MatchCount, All_CIDs) SELECT s.RowId, s.OwnerType, c.CustomerId, COUNT(*) OVER (PARTITION BY s.RowId, s.OwnerType), STUFF((SELECT ',' + c_inner.CustomerId FROM [POSData_DailyReplication].dbo.Customer c_inner JOIN [POSData_DailyReplication].dbo.Address a_inner ON c_inner.ResidencyAddressId = a_inner.Id WHERE c_inner.FirstName = s.FName AND c_inner.LastName = s.LName AND a_inner.Address1 = s.Addr1_Norm AND LEFT(a_inner.PostalCode, 5) = s.Zip FOR XML PATH('')), 1, 1, '') FROM #UnpivotedOwners s JOIN [POSData_DailyReplication].dbo.Customer c ON s.FName = c.FirstName AND s.LName = c.LName JOIN [POSData_DailyReplication].dbo.Address a ON c.ResidencyAddressId = a.Id AND a.Address1 = s.Addr1_Norm AND s.Zip = LEFT(a.PostalCode, 5) WHERE s.CID_Display IS NULL;
        UPDATE s SET s.CID_Display = CASE WHEN r.MatchCount=1 THEN r.CustomerId END, s.Probable_CIDs = CASE WHEN r.MatchCount>1 THEN r.All_CIDs END, s.Match_Tier = CASE WHEN r.MatchCount=1 THEN '4B: Name+NormAddress+ZIP' WHEN r.MatchCount>1 THEN 'Review - Ambiguous 4B' END FROM #UnpivotedOwners s JOIN #MatchResults r ON s.RowId=r.RowId AND s.OwnerType = r.OwnerType;
        SET @RowCount = @@ROWCOUNT; SET @LogMsg = FORMATMESSAGE('    > Tier 4B (Name+NormAddress+ZIP) found matches for %i owners.', @RowCount); RAISERROR(@LogMsg, 10, 1) WITH NOWAIT; TRUNCATE TABLE #MatchResults;

        -- Tier 5A: SOUNDEX(LName) + FName + ZIP
        INSERT INTO #MatchResults (RowId, OwnerType, CustomerId, MatchCount, All_CIDs) SELECT s.RowId, s.OwnerType, c.CustomerId, COUNT(*) OVER (PARTITION BY s.RowId, s.OwnerType), STUFF((SELECT ',' + c_inner.CustomerId FROM [POSData_DailyReplication].dbo.Customer c_inner JOIN [POSData_DailyReplication].dbo.Address a_inner ON c_inner.ResidencyAddressId = a_inner.Id WHERE SOUNDEX(c_inner.LastName) = s.LName_Soundex AND c_inner.FirstName = s.FName AND LEFT(a_inner.PostalCode, 5) = s.Zip FOR XML PATH('')), 1, 1, '') FROM #UnpivotedOwners s JOIN [POSData_DailyReplication].dbo.Customer c ON SOUNDEX(c.LastName) = s.LName_Soundex AND s.FName = c.FirstName JOIN [POSData_DailyReplication].dbo.Address a ON c.ResidencyAddressId = a.Id AND s.Zip = LEFT(a.PostalCode, 5) WHERE s.CID_Display IS NULL;
        UPDATE s SET s.CID_Display = CASE WHEN r.MatchCount=1 THEN r.CustomerId END, s.Probable_CIDs = CASE WHEN r.MatchCount>1 THEN r.All_CIDs END, s.Match_Tier = CASE WHEN r.MatchCount=1 THEN '5A: SOUNDEX(LName)+FName+ZIP' WHEN r.MatchCount>1 THEN 'Review - Ambiguous 5A' END FROM #UnpivotedOwners s JOIN #MatchResults r ON s.RowId=r.RowId AND s.OwnerType = r.OwnerType;
        SET @RowCount = @@ROWCOUNT; SET @LogMsg = FORMATMESSAGE('    > Tier 5A (SOUNDEX) found matches for %i owners.', @RowCount); RAISERROR(@LogMsg, 10, 1) WITH NOWAIT; TRUNCATE TABLE #MatchResults;


        -- ==============================================================================================
        -- STEP 4: FINAL MERGE
        -- ==============================================================================================
        RAISERROR(N'--- Step 4: Merging all results into BoatMaster... ---', 10, 1) WITH NOWAIT;
        MERGE INTO dbo.BoatMaster AS Target
        USING (
            SELECT
                s.RowId,
                p.CID_Display AS Primary_CID_Display, p.Match_Tier AS Primary_Match_Tier, p.Probable_CIDs AS Probable_Primary_CIDs,
                s_owner.CID_Display AS Secondary_CID_Display, s_owner.Match_Tier AS Secondary_Match_Tier, s_owner.Probable_CIDs AS Probable_Secondary_CIDs,
                pc.Id AS Primary_GUID, sc.Id AS Secondary_GUID,
                pc.EmailAddress AS FoundPrimaryEmail, sc.EmailAddress AS FoundSecondaryEmail
            FROM #Staging s
            LEFT JOIN #UnpivotedOwners p ON s.RowId = p.RowId AND p.OwnerType = 'Primary'
            LEFT JOIN #UnpivotedOwners s_owner ON s.RowId = s_owner.RowId AND s_owner.OwnerType = 'Secondary'
            LEFT JOIN [POSData_DailyReplication].dbo.Customer pc ON p.CID_Display = pc.CustomerId
            LEFT JOIN [POSData_DailyReplication].dbo.Customer sc ON s_owner.CID_Display = sc.CustomerId
        ) AS Source ON Target.RowId = Source.RowId
        WHEN MATCHED THEN
            UPDATE SET
                Target.ProcessingStatus = CASE WHEN Source.Primary_CID_Display IS NOT NULL OR Source.Secondary_CID_Display IS NOT NULL THEN 'Matched' ELSE 'Match_Failed' END,
                Target.ModifiedDate = GETUTCDATE(),
                Target.Primary_CID_GUID = Source.Primary_GUID, Target.Primary_CID_Display = Source.Primary_CID_Display, Target.Primary_Match_Tier = Source.Primary_Match_Tier, Target.Probable_Primary_CIDs = Source.Probable_Primary_CIDs,
                Target.Secondary_CID_GUID = Source.Secondary_GUID, Target.Secondary_CID_Display = Source.Secondary_CID_Display, Target.Secondary_Match_Tier = Source.Secondary_Match_Tier, Target.Probable_Secondary_CIDs = Source.Probable_Secondary_CIDs,
                Target.PrimaryOwnerEmail = ISNULL(Target.PrimaryOwnerEmail, Source.FoundPrimaryEmail),
                Target.SecondaryOwnerEmail = ISNULL(Target.SecondaryOwnerEmail, Source.FoundSecondaryEmail);

        SET @RowCount = @@ROWCOUNT;
        SET @LogMsg = FORMATMESSAGE('    > MERGE operation complete. %i rows affected.', @RowCount);
        RAISERROR(@LogMsg, 10, 1) WITH NOWAIT;

        -- Final Logging
        DECLARE @MatchedCount INT = (SELECT COUNT(DISTINCT RowId) FROM #UnpivotedOwners WHERE CID_Display IS NOT NULL);
        DECLARE @FailedCount INT = @TotalRecords - @MatchedCount;
        SET @LogMsg = FORMATMESSAGE('Matching complete. Matched Records: %i, Failed Records: %i.', @MatchedCount, @FailedCount);
        RAISERROR(@LogMsg, 10, 1) WITH NOWAIT;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        RAISERROR(N'--- !!! AN ERROR OCCURRED. ALL CHANGES HAVE BEEN ROLLED BACK. !!! ---', 10, 1) WITH NOWAIT;
        THROW;
    END CATCH;

    IF OBJECT_ID('tempdb..#Staging') IS NOT NULL DROP TABLE #Staging;
    IF OBJECT_ID('tempdb..#MatchResults') IS NOT NULL DROP TABLE #MatchResults;
    IF OBJECT_ID('tempdb..#UnpivotedOwners') IS NOT NULL DROP TABLE #UnpivotedOwners;

    SET @LogMsg = CONVERT(NVARCHAR(23), GETDATE(), 121) + N': --- Finished usp_FindCustomerMatches_Engine ---';
    RAISERROR(@LogMsg, 10, 1) WITH NOWAIT;

    SET NOCOUNT OFF;
END;
GO


