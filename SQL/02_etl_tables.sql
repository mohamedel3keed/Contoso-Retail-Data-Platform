/* =====================================================================
   02 - ETL control objects (etl schema)
   - seq_BatchID          : one number per ETL run
   - ETLExecutionLog      : one row per package execution
   - ErrorRecords         : rejected rows with traceability
   - DataQualityMetrics   : total / valid / rejected / success rate
   - Watermark            : last loaded key per fact (incremental load)
   - usp_LogPackageStart / usp_LogPackageEnd : called from SSIS
   ===================================================================== */
USE RetailDWH;
GO

IF OBJECT_ID(N'etl.seq_BatchID', N'SO') IS NULL
    CREATE SEQUENCE etl.seq_BatchID AS int START WITH 1 INCREMENT BY 1;
GO

IF OBJECT_ID(N'etl.ETLExecutionLog', N'U') IS NULL
CREATE TABLE etl.ETLExecutionLog
(
    LogID             int IDENTITY(1,1) NOT NULL CONSTRAINT PK_ETLExecutionLog PRIMARY KEY,
    BatchID           int           NOT NULL,
    PackageName       nvarchar(200) NOT NULL,
    ExecutionDate     date          NOT NULL DEFAULT CAST(GETDATE() AS date),
    StartTime         datetime      NOT NULL DEFAULT GETDATE(),
    EndTime           datetime      NULL,
    DurationSeconds   AS DATEDIFF(SECOND, StartTime, EndTime),
    TotalRecords      bigint        NULL,
    SuccessfulRecords bigint        NULL,
    FailedRecords     bigint        NULL,
    Status            nvarchar(20)  NOT NULL DEFAULT N'Running'
                      CONSTRAINT CK_ETLExecutionLog_Status CHECK (Status IN (N'Running', N'Success', N'Failed')),
    ErrorMessage      nvarchar(max) NULL,
    ETLUser           nvarchar(128) NOT NULL DEFAULT SUSER_SNAME()
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ETLExecutionLog_BatchID' AND object_id = OBJECT_ID(N'etl.ETLExecutionLog'))
    CREATE INDEX IX_ETLExecutionLog_BatchID ON etl.ETLExecutionLog (BatchID);
GO

IF OBJECT_ID(N'etl.ErrorRecords', N'U') IS NULL
CREATE TABLE etl.ErrorRecords
(
    ErrorID         bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_ErrorRecords PRIMARY KEY,
    RecordID        nvarchar(100)  NOT NULL,           -- business key of the rejected row
    SourceTable     nvarchar(128)  NOT NULL,
    ErrorReason     nvarchar(500)  NOT NULL,
    ErrorDate       datetime       NOT NULL DEFAULT GETDATE(),
    ErrorColumn     nvarchar(128)  NULL,
    ProcessingStage nvarchar(30)   NOT NULL DEFAULT N'Validation',  -- Validation / Transformation / Load
    BatchID         int            NULL,
    PackageName     nvarchar(200)  NULL,
    RawRecord       nvarchar(max)  NULL                -- optional copy of the bad row
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ErrorRecords_Batch_Source' AND object_id = OBJECT_ID(N'etl.ErrorRecords'))
    CREATE INDEX IX_ErrorRecords_Batch_Source ON etl.ErrorRecords (BatchID, SourceTable);
GO

IF OBJECT_ID(N'etl.DataQualityMetrics', N'U') IS NULL
CREATE TABLE etl.DataQualityMetrics
(
    MetricID              int IDENTITY(1,1) NOT NULL CONSTRAINT PK_DataQualityMetrics PRIMARY KEY,
    BatchID               int           NOT NULL,
    SourceTable           nvarchar(128) NOT NULL,
    ProcessingStage       nvarchar(30)  NOT NULL DEFAULT N'Validation',
    TotalRecords          bigint        NOT NULL,
    ValidRecords          bigint        NOT NULL,
    RejectedRecords       bigint        NOT NULL,
    ValidationSuccessRate AS CASE WHEN TotalRecords = 0 THEN NULL
                                  ELSE CAST(100.0 * ValidRecords / TotalRecords AS decimal(6,2)) END,
    CapturedAt            datetime      NOT NULL DEFAULT GETDATE()
);
GO

IF OBJECT_ID(N'etl.Watermark', N'U') IS NULL
CREATE TABLE etl.Watermark
(
    TableName      nvarchar(128) NOT NULL CONSTRAINT PK_Watermark PRIMARY KEY,
    LastLoadedKey  bigint        NOT NULL DEFAULT 0,   -- highest source key already loaded
    LastBatchID    int           NULL,
    LastLoadedAt   datetime      NULL
);
GO

INSERT etl.Watermark (TableName)
SELECT v.TableName
FROM (VALUES (N'FactSales'), (N'FactOnlineSales'), (N'FactInventory')) AS v (TableName)
WHERE NOT EXISTS (SELECT 1 FROM etl.Watermark w WHERE w.TableName = v.TableName);
GO

CREATE OR ALTER PROCEDURE etl.usp_LogPackageStart
    @BatchID     int,
    @PackageName nvarchar(200),
    @LogID       int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT etl.ETLExecutionLog (BatchID, PackageName) VALUES (@BatchID, @PackageName);
    SET @LogID = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE etl.usp_LogPackageEnd
    @LogID             int,
    @Status            nvarchar(20),
    @TotalRecords      bigint = NULL,
    @SuccessfulRecords bigint = NULL,
    @FailedRecords     bigint = NULL,
    @ErrorMessage      nvarchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE etl.ETLExecutionLog
       SET EndTime           = GETDATE(),
           Status            = @Status,
           TotalRecords      = @TotalRecords,
           SuccessfulRecords = @SuccessfulRecords,
           FailedRecords     = @FailedRecords,
           ErrorMessage      = @ErrorMessage
     WHERE LogID = @LogID;
END
GO