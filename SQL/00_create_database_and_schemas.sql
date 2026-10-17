/* =====================================================================
   00 - Create the DWH database and the three schemas
   Run on: localhost\SQLEXPRESS (same instance as ContosoRetailDW)
   ===================================================================== */
USE master;
GO

IF DB_ID(N'RetailDWH') IS NULL
    CREATE DATABASE RetailDWH;
GO

-- SIMPLE recovery keeps the log small during big loads (12M+ rows)
ALTER DATABASE RetailDWH SET RECOVERY SIMPLE;
GO

USE RetailDWH;
GO

IF SCHEMA_ID(N'stg') IS NULL EXEC (N'CREATE SCHEMA stg');   -- raw copy of the source
IF SCHEMA_ID(N'etl') IS NULL EXEC (N'CREATE SCHEMA etl');   -- logging, errors, watermarks
IF SCHEMA_ID(N'dwh') IS NULL EXEC (N'CREATE SCHEMA dwh');   -- dimensions and facts
GO

SELECT name AS SchemaName FROM sys.schemas WHERE name IN (N'stg', N'etl', N'dwh');
GO