/* =====================================================================
   04 - Fact tables (dwh schema)
   - Surrogate key (bigint IDENTITY) + source business key
   - Dimension keys point to the surrogate keys (xxxSK)
   - Measures from the source + calculated measures + classifications
   - Audit columns: LoadDate, PackageName, ETLUser, BatchID
   - Tables are page-compressed (SQL Express 10 GB limit)
   Grain:
     FactSales       one row = product x store x day x promotion x channel
     FactOnlineSales one row = one order line
     FactInventory   one row = product x store x snapshot date
   Extra indexes are created later in 05_dwh_indexes.sql (after the load).
   ===================================================================== */

USE RetailDWH;
GO

DROP TABLE IF EXISTS dwh.FactInventory, dwh.FactOnlineSales, dwh.FactSales;
GO

/* ---------- FactSales ---------- */
CREATE TABLE dwh.FactSales
(
    SalesSK          bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_FactSales PRIMARY KEY,
    SalesKey         int           NOT NULL,
    DateKey          int           NOT NULL,
    StoreSK          int           NOT NULL,
    ProductSK        int           NOT NULL,
    PromotionSK      int           NOT NULL,
    ChannelSK        int           NOT NULL,
    CurrencySK       int           NOT NULL,
    SalesQuantity    int           NULL,
    ReturnQuantity   int           NULL,
    DiscountQuantity int           NULL,
    UnitCost         decimal(19,4) NULL,
    UnitPrice        decimal(19,4) NULL,
    SalesAmount      decimal(19,4) NULL,
    ReturnAmount     decimal(19,4) NULL,
    DiscountAmount   decimal(19,4) NULL,
    TotalCost        decimal(19,4) NULL,
    GrossAmount      decimal(19,4) NULL,
    NetAfterReturns  decimal(19,4) NULL,
    Profit           decimal(19,4) NULL,
    ProfitMargin     decimal(9,4)  NULL,
    DiscountPct      decimal(9,4)  NULL,
    SalesCategory    nvarchar(20)  NULL,
    ProfitBand       nvarchar(20)  NULL,
    LoadDate         datetime      NOT NULL DEFAULT GETDATE(),
    PackageName      nvarchar(200) NOT NULL DEFAULT N'Manual',
    ETLUser          nvarchar(128) NOT NULL DEFAULT SUSER_SNAME(),
    BatchID          int           NOT NULL DEFAULT 0,
    CONSTRAINT FK_FactSales_DimDate      FOREIGN KEY (DateKey)     REFERENCES dwh.DimDate (DateKey),
    CONSTRAINT FK_FactSales_DimStore     FOREIGN KEY (StoreSK)     REFERENCES dwh.DimStore (StoreSK),
    CONSTRAINT FK_FactSales_DimProduct   FOREIGN KEY (ProductSK)   REFERENCES dwh.DimProduct (ProductSK),
    CONSTRAINT FK_FactSales_DimPromotion FOREIGN KEY (PromotionSK) REFERENCES dwh.DimPromotion (PromotionSK),
    CONSTRAINT FK_FactSales_DimChannel   FOREIGN KEY (ChannelSK)   REFERENCES dwh.DimChannel (ChannelSK),
    CONSTRAINT FK_FactSales_DimCurrency  FOREIGN KEY (CurrencySK)  REFERENCES dwh.DimCurrency (CurrencySK)
) WITH (DATA_COMPRESSION = PAGE);
GO

/* ---------- FactOnlineSales ---------- */
CREATE TABLE dwh.FactOnlineSales
(
    OnlineSalesSK        bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_FactOnlineSales PRIMARY KEY,
    OnlineSalesKey       int           NOT NULL,
    DateKey              int           NOT NULL,
    StoreSK              int           NOT NULL,
    ProductSK            int           NOT NULL,
    PromotionSK          int           NOT NULL,
    CurrencySK           int           NOT NULL,
    CustomerSK           int           NOT NULL,
    SalesOrderNumber     nvarchar(20)  NOT NULL,
    SalesOrderLineNumber int           NOT NULL,
    SalesQuantity        int           NULL,
    ReturnQuantity       int           NULL,
    DiscountQuantity     int           NULL,
    UnitCost             decimal(19,4) NULL,
    UnitPrice            decimal(19,4) NULL,
    SalesAmount          decimal(19,4) NULL,
    ReturnAmount         decimal(19,4) NULL,
    DiscountAmount       decimal(19,4) NULL,
    TotalCost            decimal(19,4) NULL,
    GrossAmount          decimal(19,4) NULL,
    NetAfterReturns      decimal(19,4) NULL,
    Profit               decimal(19,4) NULL,
    ProfitMargin         decimal(9,4)  NULL,
    DiscountPct          decimal(9,4)  NULL,
    SalesCategory        nvarchar(20)  NULL,
    ProfitBand           nvarchar(20)  NULL,
    LoadDate             datetime      NOT NULL DEFAULT GETDATE(),
    PackageName          nvarchar(200) NOT NULL DEFAULT N'Manual',
    ETLUser              nvarchar(128) NOT NULL DEFAULT SUSER_SNAME(),
    BatchID              int           NOT NULL DEFAULT 0,
    CONSTRAINT FK_FactOnlineSales_DimDate      FOREIGN KEY (DateKey)     REFERENCES dwh.DimDate (DateKey),
    CONSTRAINT FK_FactOnlineSales_DimStore     FOREIGN KEY (StoreSK)     REFERENCES dwh.DimStore (StoreSK),
    CONSTRAINT FK_FactOnlineSales_DimProduct   FOREIGN KEY (ProductSK)   REFERENCES dwh.DimProduct (ProductSK),
    CONSTRAINT FK_FactOnlineSales_DimPromotion FOREIGN KEY (PromotionSK) REFERENCES dwh.DimPromotion (PromotionSK),
    CONSTRAINT FK_FactOnlineSales_DimCurrency  FOREIGN KEY (CurrencySK)  REFERENCES dwh.DimCurrency (CurrencySK),
    CONSTRAINT FK_FactOnlineSales_DimCustomer  FOREIGN KEY (CustomerSK)  REFERENCES dwh.DimCustomer (CustomerSK)
) WITH (DATA_COMPRESSION = PAGE);
GO

/* ---------- FactInventory ---------- */
CREATE TABLE dwh.FactInventory
(
    InventorySK         bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_FactInventory PRIMARY KEY,
    InventoryKey        int           NOT NULL,
    DateKey             int           NOT NULL,
    StoreSK             int           NOT NULL,
    ProductSK           int           NOT NULL,
    CurrencySK          int           NOT NULL,
    OnHandQuantity      int           NULL,
    OnOrderQuantity     int           NULL,
    SafetyStockQuantity int           NULL,
    UnitCost            decimal(19,4) NULL,
    DaysInStock         int           NULL,
    MinDayInStock       int           NULL,
    MaxDayInStock       int           NULL,
    Aging               int           NULL,
    StockStatus         nvarchar(20)  NULL,
    LoadDate            datetime      NOT NULL DEFAULT GETDATE(),
    PackageName         nvarchar(200) NOT NULL DEFAULT N'Manual',
    ETLUser             nvarchar(128) NOT NULL DEFAULT SUSER_SNAME(),
    BatchID             int           NOT NULL DEFAULT 0,
    CONSTRAINT FK_FactInventory_DimDate     FOREIGN KEY (DateKey)    REFERENCES dwh.DimDate (DateKey),
    CONSTRAINT FK_FactInventory_DimStore    FOREIGN KEY (StoreSK)    REFERENCES dwh.DimStore (StoreSK),
    CONSTRAINT FK_FactInventory_DimProduct  FOREIGN KEY (ProductSK)  REFERENCES dwh.DimProduct (ProductSK),
    CONSTRAINT FK_FactInventory_DimCurrency FOREIGN KEY (CurrencySK) REFERENCES dwh.DimCurrency (CurrencySK)
) WITH (DATA_COMPRESSION = PAGE);
GO