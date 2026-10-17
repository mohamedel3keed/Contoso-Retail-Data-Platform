/* =====================================================================
   01 - Staging tables (stg schema)
   Staging = the source data exactly as received, no business rules.
   Each table is cloned from ContosoRetailDW so column names/types match
   the source 1:1, then two audit columns are added.
   Facts are page-compressed because SQL Express caps a database at 10 GB.
   ===================================================================== */
USE RetailDWH;
GO

DECLARE @src sysname = N'ContosoRetailDW';

DECLARE @tables TABLE (id int IDENTITY(1,1), name sysname, isFact bit);
INSERT @tables (name, isFact) VALUES
    (N'FactSales', 1), (N'FactOnlineSales', 1), (N'FactInventory', 1),
    (N'DimDate', 0), (N'DimProduct', 0), (N'DimProductSubcategory', 0),
    (N'DimProductCategory', 0), (N'DimStore', 0), (N'DimGeography', 0),
    (N'DimCustomer', 0), (N'DimPromotion', 0), (N'DimChannel', 0),
    (N'DimCurrency', 0);

DECLARE @i int = 1, @n int = (SELECT COUNT(*) FROM @tables);
DECLARE @t sysname, @isFact bit, @sql nvarchar(max);

WHILE @i <= @n
BEGIN
    SELECT @t = name, @isFact = isFact FROM @tables WHERE id = @i;

    SET @sql = N'DROP TABLE IF EXISTS stg.' + QUOTENAME(@t) + N';';
    EXEC sp_executesql @sql;

    -- The LEFT JOIN makes SELECT...INTO drop the IDENTITY property, so SSIS
    -- can insert the source key values as plain integers.
    SET @sql = N'SELECT TOP (0) s.* INTO stg.' + QUOTENAME(@t)
             + N' FROM ' + QUOTENAME(@src) + N'.dbo.' + QUOTENAME(@t) + N' AS s'
             + N' LEFT JOIN (SELECT 1 AS x) AS j ON 1 = 0;';
    EXEC sp_executesql @sql;

    SET @sql = N'ALTER TABLE stg.' + QUOTENAME(@t)
             + N' ADD stg_BatchID int NULL,'
             + N' stg_LoadDateTime datetime NOT NULL DEFAULT GETDATE();';
    EXEC sp_executesql @sql;

    IF @isFact = 1
    BEGIN
        SET @sql = N'ALTER TABLE stg.' + QUOTENAME(@t)
                 + N' REBUILD WITH (DATA_COMPRESSION = PAGE);';
        EXEC sp_executesql @sql;
    END

    SET @i += 1;
END
GO

-- Spatial columns are not carried through SSIS data flows and nothing in
-- the project uses them, so they are removed from staging.
IF COL_LENGTH(N'stg.DimStore', N'GeoLocation') IS NOT NULL ALTER TABLE stg.DimStore DROP COLUMN GeoLocation;
IF COL_LENGTH(N'stg.DimStore', N'Geometry')    IS NOT NULL ALTER TABLE stg.DimStore DROP COLUMN Geometry;
IF COL_LENGTH(N'stg.DimGeography', N'Geometry') IS NOT NULL ALTER TABLE stg.DimGeography DROP COLUMN Geometry;
GO

-- Check: 13 staging tables with their column counts
SELECT t.name AS StagingTable, COUNT(c.column_id) AS ColumnCount
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id AND s.name = N'stg'
JOIN sys.columns c ON c.object_id = t.object_id
GROUP BY t.name
ORDER BY t.name;
GO