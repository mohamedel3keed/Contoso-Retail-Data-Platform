/* =====================================================================
   05 - Extra indexes on the fact tables
   Run AFTER the Full Load (indexes slow down big inserts).
   Before the next Full Load, drop them again - this is also the basis
   of the "before / after" performance experiment.
   - Unique index on the business key: fast lookups for the incremental load
   - Indexes on the dimension keys: fast joins for reporting
   ===================================================================== */

USE RetailDWH;
GO

DECLARE @ix TABLE (tbl sysname, idx sysname, cols nvarchar(200), isUnique bit);
INSERT @ix VALUES
 (N'FactSales',       N'UX_FactSales_SalesKey',             N'SalesKey',        1),
 (N'FactSales',       N'IX_FactSales_DateKey',              N'DateKey',         0),
 (N'FactSales',       N'IX_FactSales_ProductSK',            N'ProductSK',       0),
 (N'FactSales',       N'IX_FactSales_StoreSK',              N'StoreSK',         0),
 (N'FactOnlineSales', N'UX_FactOnlineSales_OnlineSalesKey', N'OnlineSalesKey',  1),
 (N'FactOnlineSales', N'IX_FactOnlineSales_DateKey',        N'DateKey',         0),
 (N'FactOnlineSales', N'IX_FactOnlineSales_ProductSK',      N'ProductSK',       0),
 (N'FactOnlineSales', N'IX_FactOnlineSales_CustomerSK',     N'CustomerSK',      0),
 (N'FactInventory',   N'UX_FactInventory_InventoryKey',     N'InventoryKey',    1),
 (N'FactInventory',   N'IX_FactInventory_DateKey',          N'DateKey',         0),
 (N'FactInventory',   N'IX_FactInventory_ProductSK',        N'ProductSK',       0),
 (N'FactInventory',   N'IX_FactInventory_StoreSK',          N'StoreSK',         0);

DECLARE @t sysname, @i sysname, @c nvarchar(200), @u bit, @sql nvarchar(max);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT tbl, idx, cols, isUnique FROM @ix;
OPEN cur;
FETCH NEXT FROM cur INTO @t, @i, @c, @u;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = @i AND object_id = OBJECT_ID(N'dwh.' + @t))
    BEGIN
        SET @sql = N'CREATE ' + CASE WHEN @u = 1 THEN N'UNIQUE ' ELSE N'' END
                 + N'NONCLUSTERED INDEX ' + QUOTENAME(@i)
                 + N' ON dwh.' + QUOTENAME(@t) + N' (' + @c + N')'
                 + N' WITH (DATA_COMPRESSION = PAGE);';
        EXEC sp_executesql @sql;
    END
    FETCH NEXT FROM cur INTO @t, @i, @c, @u;
END
CLOSE cur;
DEALLOCATE cur;
GO

-- Check database size (SQL Express limit = 10 GB per database)
EXEC sp_spaceused;
GO