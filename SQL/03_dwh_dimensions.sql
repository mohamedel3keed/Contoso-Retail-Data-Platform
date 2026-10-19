/* =====================================================================
   03 (v2) - Dimension tables with SCD Type 2 on Product / Customer / Store
   - Type 2 tables: DimProduct, DimCustomer, DimStore
       StartDate / EndDate only (no IsCurrent column)
       EndDate IS NULL  = the current version of the row
       any change in the tracked attributes = a new row (new SK)
       the Business Key is no longer unique, only the CURRENT row is
       (filtered unique index WHERE EndDate IS NULL)
   - Type 1 tables: DimDate, DimPromotion, DimChannel, DimCurrency
   - Row -1 = "Unknown" member in every dimension
   Re-runnable: drops the facts first (run 04 again afterwards), then the dimensions.
   ===================================================================== */
USE RetailDWH;
GO

DROP TABLE IF EXISTS dwh.FactInventory, dwh.FactOnlineSales, dwh.FactSales;
DROP TABLE IF EXISTS dwh.DimDate, dwh.DimProduct, dwh.DimStore, dwh.DimCustomer,
                     dwh.DimPromotion, dwh.DimChannel, dwh.DimCurrency;
GO

/* ---------- DimDate (Type 1) ---------- */
CREATE TABLE dwh.DimDate
(
    DateKey                int           NOT NULL CONSTRAINT PK_DimDate PRIMARY KEY,
    FullDate               date          NOT NULL,
    CalendarYear           int           NULL,
    CalendarQuarter        int           NULL,
    CalendarMonth          int           NULL,
    CalendarMonthLabel     nvarchar(20)  NULL,
    CalendarDayOfWeek      int           NULL,
    CalendarDayOfWeekLabel nvarchar(20)  NULL,
    FiscalYear             int           NULL,
    IsWorkDay              bit           NULL,
    IsHoliday              bit           NULL,
    HolidayName            nvarchar(50)  NULL,
    LoadDate               datetime      NOT NULL DEFAULT GETDATE(),
    PackageName            nvarchar(200) NOT NULL DEFAULT N'Manual',
    ETLUser                nvarchar(128) NOT NULL DEFAULT SUSER_SNAME(),
    BatchID                int           NOT NULL DEFAULT 0
);
GO
INSERT dwh.DimDate (DateKey, FullDate) VALUES (-1, '1900-01-01');
GO

/* ---------- DimProduct (Type 2) : Product + Subcategory + Category flattened ---------- */
CREATE TABLE dwh.DimProduct
(
    ProductSK            int IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimProduct PRIMARY KEY,
    ProductKey           int           NOT NULL,              -- business key (repeats across versions)
    ProductName          nvarchar(500) NOT NULL,
    ProductDescription   nvarchar(400) NULL,
    Manufacturer         nvarchar(100) NULL,
    BrandName            nvarchar(100) NULL,
    ClassName            nvarchar(50)  NULL,
    ColorName            nvarchar(50)  NULL,
    Size                 nvarchar(50)  NULL,
    Weight               decimal(18,4) NULL,
    UnitCost             decimal(19,4) NULL,
    UnitPrice            decimal(19,4) NULL,
    StockTypeName        nvarchar(50)  NULL,
    Status               nvarchar(20)  NULL,
    AvailableForSaleDate date          NULL,
    StopSaleDate         date          NULL,
    SubcategoryName      nvarchar(100) NULL,
    CategoryName         nvarchar(100) NULL,
    ProductValueTier     nvarchar(20)  NULL,                  -- calculated: High / Medium / Low
    StartDate            date          NOT NULL,              -- version valid from
    EndDate              date          NULL,                  -- version valid until (NULL = current)
    LoadDate             datetime      NOT NULL DEFAULT GETDATE(),
    PackageName          nvarchar(200) NOT NULL DEFAULT N'Manual',
    ETLUser              nvarchar(128) NOT NULL DEFAULT SUSER_SNAME(),
    BatchID              int           NOT NULL DEFAULT 0
);
GO
CREATE UNIQUE NONCLUSTERED INDEX UX_DimProduct_ProductKey_Current
    ON dwh.DimProduct (ProductKey) WHERE EndDate IS NULL;
CREATE NONCLUSTERED INDEX IX_DimProduct_ProductKey_Dates
    ON dwh.DimProduct (ProductKey, StartDate, EndDate) INCLUDE (ProductSK);
GO
SET IDENTITY_INSERT dwh.DimProduct ON;
INSERT dwh.DimProduct (ProductSK, ProductKey, ProductName, StartDate) VALUES (-1, -1, N'Unknown', '1900-01-01');
SET IDENTITY_INSERT dwh.DimProduct OFF;
GO

/* ---------- DimStore (Type 2) : Store + Geography merged ---------- */
CREATE TABLE dwh.DimStore
(
    StoreSK         int IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimStore PRIMARY KEY,
    StoreKey        int           NOT NULL,
    StoreName       nvarchar(100) NOT NULL,
    StoreType       nvarchar(50)  NULL,
    Status          nvarchar(20)  NULL,
    OpenDate        date          NULL,
    CloseDate       date          NULL,
    EmployeeCount   int           NULL,
    SellingAreaSize decimal(18,2) NULL,
    ZipCode         nvarchar(20)  NULL,
    City            nvarchar(100) NULL,
    StateProvince   nvarchar(100) NULL,
    Country         nvarchar(100) NULL,
    Continent       nvarchar(50)  NULL,
    StartDate       date          NOT NULL,
    EndDate         date          NULL,
    LoadDate        datetime      NOT NULL DEFAULT GETDATE(),
    PackageName     nvarchar(200) NOT NULL DEFAULT N'Manual',
    ETLUser         nvarchar(128) NOT NULL DEFAULT SUSER_SNAME(),
    BatchID         int           NOT NULL DEFAULT 0
);
GO
CREATE UNIQUE NONCLUSTERED INDEX UX_DimStore_StoreKey_Current
    ON dwh.DimStore (StoreKey) WHERE EndDate IS NULL;
CREATE NONCLUSTERED INDEX IX_DimStore_StoreKey_Dates
    ON dwh.DimStore (StoreKey, StartDate, EndDate) INCLUDE (StoreSK);
GO
SET IDENTITY_INSERT dwh.DimStore ON;
INSERT dwh.DimStore (StoreSK, StoreKey, StoreName, StartDate) VALUES (-1, -1, N'Unknown', '1900-01-01');
SET IDENTITY_INSERT dwh.DimStore OFF;
GO

/* ---------- DimCustomer (Type 2) : Customer + Geography merged ---------- */
CREATE TABLE dwh.DimCustomer
(
    CustomerSK        int IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimCustomer PRIMARY KEY,
    CustomerKey       int           NOT NULL,
    FirstName         nvarchar(100) NULL,
    LastName          nvarchar(100) NULL,
    FullName          nvarchar(250) NOT NULL,
    Gender            nvarchar(20)  NULL,
    MaritalStatus     nvarchar(20)  NULL,
    BirthDate         date          NULL,
    YearlyIncome      decimal(19,4) NULL,
    TotalChildren     int           NULL,
    Education         nvarchar(100) NULL,
    Occupation        nvarchar(100) NULL,
    DateFirstPurchase date          NULL,
    CustomerType      nvarchar(50)  NULL,
    CompanyName       nvarchar(100) NULL,
    City              nvarchar(100) NULL,
    StateProvince     nvarchar(100) NULL,
    Country           nvarchar(100) NULL,
    Continent         nvarchar(50)  NULL,
    CustomerSegment   nvarchar(20)  NULL,                     -- calculated: VIP / Regular / Standard
    StartDate         date          NOT NULL,
    EndDate           date          NULL,
    LoadDate          datetime      NOT NULL DEFAULT GETDATE(),
    PackageName       nvarchar(200) NOT NULL DEFAULT N'Manual',
    ETLUser           nvarchar(128) NOT NULL DEFAULT SUSER_SNAME(),
    BatchID           int           NOT NULL DEFAULT 0
);
GO
CREATE UNIQUE NONCLUSTERED INDEX UX_DimCustomer_CustomerKey_Current
    ON dwh.DimCustomer (CustomerKey) WHERE EndDate IS NULL;
CREATE NONCLUSTERED INDEX IX_DimCustomer_CustomerKey_Dates
    ON dwh.DimCustomer (CustomerKey, StartDate, EndDate) INCLUDE (CustomerSK);
GO
SET IDENTITY_INSERT dwh.DimCustomer ON;
INSERT dwh.DimCustomer (CustomerSK, CustomerKey, FullName, StartDate) VALUES (-1, -1, N'Unknown', '1900-01-01');
SET IDENTITY_INSERT dwh.DimCustomer OFF;
GO

/* ---------- DimPromotion (Type 1) ---------- */
CREATE TABLE dwh.DimPromotion
(
    PromotionSK       int IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimPromotion PRIMARY KEY,
    PromotionKey      int           NOT NULL CONSTRAINT UQ_DimPromotion_PromotionKey UNIQUE,
    PromotionName     nvarchar(100) NOT NULL,
    PromotionType     nvarchar(100) NULL,
    PromotionCategory nvarchar(100) NULL,
    DiscountPercent   decimal(9,4)  NULL,
    StartDate         date          NULL,
    EndDate           date          NULL,
    MinQuantity       int           NULL,
    MaxQuantity       int           NULL,
    LoadDate          datetime      NOT NULL DEFAULT GETDATE(),
    PackageName       nvarchar(200) NOT NULL DEFAULT N'Manual',
    ETLUser           nvarchar(128) NOT NULL DEFAULT SUSER_SNAME(),
    BatchID           int           NOT NULL DEFAULT 0
);
GO
SET IDENTITY_INSERT dwh.DimPromotion ON;
INSERT dwh.DimPromotion (PromotionSK, PromotionKey, PromotionName) VALUES (-1, -1, N'Unknown');
SET IDENTITY_INSERT dwh.DimPromotion OFF;
GO

/* ---------- DimChannel (Type 1) ---------- */
CREATE TABLE dwh.DimChannel
(
    ChannelSK          int IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimChannel PRIMARY KEY,
    ChannelKey         int           NOT NULL CONSTRAINT UQ_DimChannel_ChannelKey UNIQUE,
    ChannelName        nvarchar(100) NOT NULL,
    ChannelDescription nvarchar(200) NULL,
    LoadDate           datetime      NOT NULL DEFAULT GETDATE(),
    PackageName        nvarchar(200) NOT NULL DEFAULT N'Manual',
    ETLUser            nvarchar(128) NOT NULL DEFAULT SUSER_SNAME(),
    BatchID            int           NOT NULL DEFAULT 0
);
GO
SET IDENTITY_INSERT dwh.DimChannel ON;
INSERT dwh.DimChannel (ChannelSK, ChannelKey, ChannelName) VALUES (-1, -1, N'Unknown');
SET IDENTITY_INSERT dwh.DimChannel OFF;
GO

/* ---------- DimCurrency (Type 1) ---------- */
CREATE TABLE dwh.DimCurrency
(
    CurrencySK    int IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimCurrency PRIMARY KEY,
    CurrencyKey   int           NOT NULL CONSTRAINT UQ_DimCurrency_CurrencyKey UNIQUE,
    CurrencyLabel nvarchar(50)  NULL,
    CurrencyName  nvarchar(100) NOT NULL,
    LoadDate      datetime      NOT NULL DEFAULT GETDATE(),
    PackageName   nvarchar(200) NOT NULL DEFAULT N'Manual',
    ETLUser       nvarchar(128) NOT NULL DEFAULT SUSER_SNAME(),
    BatchID       int           NOT NULL DEFAULT 0
);
GO
SET IDENTITY_INSERT dwh.DimCurrency ON;
INSERT dwh.DimCurrency (CurrencySK, CurrencyKey, CurrencyName) VALUES (-1, -1, N'Unknown');
SET IDENTITY_INSERT dwh.DimCurrency OFF;
GO

-- Check: every dimension should show 1 row (the Unknown member)
SELECT 'DimDate' AS t, COUNT(*) AS c FROM dwh.DimDate
UNION ALL SELECT 'DimProduct',   COUNT(*) FROM dwh.DimProduct
UNION ALL SELECT 'DimStore',     COUNT(*) FROM dwh.DimStore
UNION ALL SELECT 'DimCustomer',  COUNT(*) FROM dwh.DimCustomer
UNION ALL SELECT 'DimPromotion', COUNT(*) FROM dwh.DimPromotion
UNION ALL SELECT 'DimChannel',   COUNT(*) FROM dwh.DimChannel
UNION ALL SELECT 'DimCurrency',  COUNT(*) FROM dwh.DimCurrency;
GO
