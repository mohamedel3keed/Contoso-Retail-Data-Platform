/* =====================================================================
   03 - Dimension tables (dwh schema)
   ===================================================================== */
USE RetailDWH;
GO

DROP TABLE IF EXISTS dwh.FactInventory, dwh.FactOnlineSales, dwh.FactSales;
DROP TABLE IF EXISTS dwh.DimDate, dwh.DimProduct, dwh.DimStore, dwh.DimCustomer,
                     dwh.DimPromotion, dwh.DimChannel, dwh.DimCurrency;
GO

/* ---------- DimDate ---------- */
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

/* ---------- DimProduct ---------- */
CREATE TABLE dwh.DimProduct
(
    ProductSK            int IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimProduct PRIMARY KEY,
    ProductKey           int           NOT NULL CONSTRAINT UQ_DimProduct_ProductKey UNIQUE,
    ProductLabel         nvarchar(100) NULL,
    ProductName          nvarchar(500) NOT NULL,
    ProductDescription   nvarchar(400) NULL,
    Manufacturer         nvarchar(100) NULL,
    BrandName            nvarchar(100) NULL,
    ClassName            nvarchar(50)  NULL,
    StyleName            nvarchar(50)  NULL,
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
    ProductValueTier     nvarchar(20)  NULL,
    RowHash              binary(32)    NULL,
    LoadDate             datetime      NOT NULL DEFAULT GETDATE(),
    PackageName          nvarchar(200) NOT NULL DEFAULT N'Manual',
    ETLUser              nvarchar(128) NOT NULL DEFAULT SUSER_SNAME(),
    BatchID              int           NOT NULL DEFAULT 0
);
GO
SET IDENTITY_INSERT dwh.DimProduct ON;
INSERT dwh.DimProduct (ProductSK, ProductKey, ProductName) VALUES (-1, -1, N'Unknown');
SET IDENTITY_INSERT dwh.DimProduct OFF;
GO

/* ---------- DimStore ---------- */
CREATE TABLE dwh.DimStore
(
    StoreSK         int IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimStore PRIMARY KEY,
    StoreKey        int           NOT NULL CONSTRAINT UQ_DimStore_StoreKey UNIQUE,
    StoreName       nvarchar(100) NOT NULL,
    StoreType       nvarchar(50)  NULL,
    StoreManager    int           NULL,
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
    RowHash         binary(32)    NULL,
    LoadDate        datetime      NOT NULL DEFAULT GETDATE(),
    PackageName     nvarchar(200) NOT NULL DEFAULT N'Manual',
    ETLUser         nvarchar(128) NOT NULL DEFAULT SUSER_SNAME(),
    BatchID         int           NOT NULL DEFAULT 0
);
GO
SET IDENTITY_INSERT dwh.DimStore ON;
INSERT dwh.DimStore (StoreSK, StoreKey, StoreName) VALUES (-1, -1, N'Unknown');
SET IDENTITY_INSERT dwh.DimStore OFF;
GO

/* ---------- DimCustomer ---------- */
CREATE TABLE dwh.DimCustomer
(
    CustomerSK        int IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimCustomer PRIMARY KEY,
    CustomerKey       int           NOT NULL CONSTRAINT UQ_DimCustomer_CustomerKey UNIQUE,
    CustomerLabel     nvarchar(100) NULL,
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
    HouseOwnerFlag    nvarchar(10)  NULL,
    NumberCarsOwned   int           NULL,
    DateFirstPurchase date          NULL,
    CustomerType      nvarchar(50)  NULL,
    CompanyName       nvarchar(100) NULL,
    City              nvarchar(100) NULL,
    StateProvince     nvarchar(100) NULL,
    Country           nvarchar(100) NULL,
    Continent         nvarchar(50)  NULL,
    CustomerSegment   nvarchar(20)  NULL,
    RowHash           binary(32)    NULL,
    LoadDate          datetime      NOT NULL DEFAULT GETDATE(),
    PackageName       nvarchar(200) NOT NULL DEFAULT N'Manual',
    ETLUser           nvarchar(128) NOT NULL DEFAULT SUSER_SNAME(),
    BatchID           int           NOT NULL DEFAULT 0
);
GO
SET IDENTITY_INSERT dwh.DimCustomer ON;
INSERT dwh.DimCustomer (CustomerSK, CustomerKey, FullName) VALUES (-1, -1, N'Unknown');
SET IDENTITY_INSERT dwh.DimCustomer OFF;
GO

/* ---------- DimPromotion ---------- */
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
    RowHash           binary(32)    NULL,
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

/* ---------- DimChannel ---------- */
CREATE TABLE dwh.DimChannel
(
    ChannelSK          int IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimChannel PRIMARY KEY,
    ChannelKey         int           NOT NULL CONSTRAINT UQ_DimChannel_ChannelKey UNIQUE,
    ChannelName        nvarchar(100) NOT NULL,
    ChannelDescription nvarchar(200) NULL,
    RowHash            binary(32)    NULL,
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

/* ---------- DimCurrency ---------- */
CREATE TABLE dwh.DimCurrency
(
    CurrencySK    int IDENTITY(1,1) NOT NULL CONSTRAINT PK_DimCurrency PRIMARY KEY,
    CurrencyKey   int           NOT NULL CONSTRAINT UQ_DimCurrency_CurrencyKey UNIQUE,
    CurrencyLabel nvarchar(50)  NULL,
    CurrencyName  nvarchar(100) NOT NULL,
    RowHash       binary(32)    NULL,
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