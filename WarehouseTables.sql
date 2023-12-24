-- Create Schema
CREATE SCHEMA warehouse;

-- DimBroker
CREATE TABLE warehouse.DimBroker (
    SK_BrokerID  SERIAL PRIMARY KEY,
    BrokerID  INTEGER NOT NULL,
    ManagerID  INTEGER,
    FirstName       CHAR(50) NOT NULL,
    LastName       CHAR(50) NOT NULL,
    MiddleInitial       CHAR(1),
    Branch       CHAR(50),
    Office       CHAR(50),
    Phone       CHAR(14),
    IsCurrent BOOLEAN NOT NULL,
    BatchID INTEGER NOT NULL,
    EffectiveDate DATE NOT NULL,
    EndDate DATE NOT NULL                                                 
);

-- DimCompany
CREATE TABLE warehouse.DimCompany (
    SK_CompanyID SERIAL PRIMARY KEY, 
    CompanyID INTEGER NOT NULL,
    Status CHAR(10) NOT NULL, 
    Name CHAR(60) NOT NULL,
    Industry CHAR(50) NOT NULL,
    SPrating CHAR(4),
    isLowGrade BOOLEAN,
    CEO CHAR(100) NOT NULL,
    AddressLine1 CHAR(80),
    AddressLine2 CHAR(80),
    PostalCode CHAR(12) NOT NULL,
    City CHAR(25) NOT NULL,
    StateProv CHAR(20) NOT NULL,
    Country CHAR(24),
    Description CHAR(150) NOT NULL,
    FoundingDate DATE,
    IsCurrent BOOLEAN NOT NULL,
    BatchID INTEGER NOT NULL,
    EffectiveDate DATE NOT NULL,
    EndDate DATE NOT NULL
);

-- DimCustomer
CREATE TABLE warehouse.DimCustomer (
    SK_CustomerID  SERIAL PRIMARY KEY,
    CustomerID INTEGER NOT NULL,
    TaxID CHAR(20),
    Status CHAR(10) NOT NULL,
    LastName CHAR(30) NOT NULL,
    FirstName CHAR(30) NOT NULL,
    MiddleInitial CHAR(1),
    Gender CHAR(1),
    Tier INTEGER,
    DOB DATE NOT NULL,
    AddressLine1  VARCHAR(80) NOT NULL,
    AddressLine2  VARCHAR(80),
    PostalCode    CHAR(12) NOT NULL,
    City   CHAR(25) NOT NULL,
    StateProv     CHAR(20) NOT NULL,
    Country       CHAR(24),
    Phone1 CHAR(30),
    Phone2 CHAR(30),
    Phone3 CHAR(30),
    Email1 CHAR(50),
    Email2 CHAR(50),
    NationalTaxRateDesc VARCHAR(50),
    NationalTaxRate NUMERIC(6,5),
    LocalTaxRateDesc VARCHAR(50),
    LocalTaxRate NUMERIC(6,5),
    AgencyID CHAR(30),
    CreditRating INTEGER,
    NetWorth NUMERIC(10),
    MarketingNameplate VARCHAR(100),
    IsCurrent BOOLEAN NOT NULL,
    BatchID INTEGER NOT NULL,
    EffectiveDate DATE NOT NULL,
    EndDate DATE NOT NULL
);

-- DimAccount
CREATE TABLE warehouse.DimAccount (
    SK_AccountID  SERIAL PRIMARY KEY,
    AccountID INTEGER NOT NULL,
    SK_BrokerID INTEGER NOT NULL REFERENCES warehouse.DimBroker (SK_BrokerID),
    SK_CustomerID INTEGER NOT NULL REFERENCES warehouse.DimCustomer (SK_CustomerID),
    Status CHAR(10) NOT NULL,
    AccountDesc VARCHAR(50),
    TaxStatus INTEGER NOT NULL CHECK (TaxStatus = 0 OR TaxStatus = 1 OR TaxStatus = 2),
    IsCurrent BOOLEAN NOT NULL,
    BatchID INTEGER NOT NULL,
    EffectiveDate DATE NOT NULL,
    EndDate DATE NOT NULL
);

-- DimDate
CREATE TABLE warehouse.DimDate (
    SK_DateID SERIAL PRIMARY KEY,
    DateValue DATE NOT NULL,
    DateDesc CHAR(20) NOT NULL,
    CalendarYearID NUMERIC(4) NOT NULL,
    CalendarYearDesc CHAR(20) NOT NULL,
    CalendarQtrID NUMERIC(5) NOT NULL,
    CalendarQtrDesc CHAR(20) NOT NULL,
    CalendarMonthID NUMERIC(6) NOT NULL,
    CalendarMonthDesc CHAR(20) NOT NULL,
    CalendarWeekID NUMERIC(6) NOT NULL,
    CalendarWeekDesc CHAR(20) NOT NULL,
    DayOfWeekNum NUMERIC(1) NOT NULL,
    DayOfWeekDesc CHAR(10) NOT NULL,
    FiscalYearID NUMERIC(4) NOT NULL,
    FiscalYearDesc CHAR(20) NOT NULL,
    FiscalQtrID NUMERIC(5) NOT NULL,
    FiscalQtrDesc CHAR(20) NOT NULL,
    HolidayFlag BOOLEAN
);

-- DimSecurity
CREATE TABLE warehouse.DimSecurity (
    SK_SecurityID SERIAL PRIMARY KEY,
    Symbol CHAR(15) NOT NULL,
    Issue CHAR(6) NOT NULL,
    Status CHAR(10) NOT NULL,
    Name CHAR(70) NOT NULL,
    ExchangeID CHAR(6) NOT NULL,
    SK_CompanyID INTEGER NOT NULL REFERENCES warehouse.DimCompany (SK_CompanyID),
    SharesOutstanding INTEGER NOT NULL,
    FirstTrade DATE NOT NULL,
    FirstTradeOnExchange DATE NOT NULL,
    Dividend NUMERIC(10,2) NOT NULL,
    IsCurrent BOOLEAN NOT NULL,
    BatchID NUMERIC(5) NOT NULL,
    EffectiveDate DATE NOT NULL,
    EndDate DATE NOT NULL
);

-- DimTime
CREATE TABLE warehouse.DimTime (
    SK_TimeID SERIAL PRIMARY KEY,
    TimeValue TIME NOT NULL,
    HourID NUMERIC(2) NOT NULL,
    HourDesc CHAR(20) NOT NULL,
    MinuteID NUMERIC(2) NOT NULL,
    MinuteDesc CHAR(20) NOT NULL,
    SecondID NUMERIC(2) NOT NULL,
    SecondDesc CHAR(20) NOT NULL,
    MarketHoursFlag BOOLEAN,
    OfficeHoursFlag BOOLEAN
);

-- DimTrade
CREATE TABLE warehouse.DimTrade (
    TradeID INTEGER NOT NULL,
    SK_BrokerID INTEGER REFERENCES warehouse.DimBroker (SK_BrokerID),
    SK_CreateDateID INTEGER REFERENCES warehouse.DimDate (SK_DateID),
    SK_CreateTimeID INTEGER REFERENCES warehouse.DimTime (SK_TimeID),
    SK_CloseDateID INTEGER REFERENCES warehouse.DimDate (SK_DateID),
    SK_CloseTimeID INTEGER REFERENCES warehouse.DimTime (SK_TimeID),
    Status CHAR(10) NOT NULL,
    DT_Type CHAR(12) NOT NULL,
    CashFlag BOOLEAN NOT NULL,
    SK_SecurityID INTEGER NOT NULL REFERENCES warehouse.DimSecurity (SK_SecurityID),
    SK_CompanyID INTEGER NOT NULL REFERENCES warehouse.DimCompany (SK_CompanyID),
    Quantity NUMERIC(6,0) NOT NULL,
    BidPrice NUMERIC(8,2) NOT NULL,
    SK_CustomerID INTEGER NOT NULL REFERENCES warehouse.DimCustomer (SK_CustomerID),
    SK_AccountID INTEGER NOT NULL REFERENCES warehouse.DimAccount (SK_AccountID),
    ExecutedBy CHAR(64) NOT NULL,
    TradePrice NUMERIC(8,2),
    Fee NUMERIC(10,2),
    Commission NUMERIC(10,2),
    Tax NUMERIC(10,2),
    BatchID NUMERIC(5) NOT NULL
);

-- DImessages
CREATE TABLE warehouse.DImessages (
    MessageDateAndTime TIMESTAMP NOT NULL,
    BatchID NUMERIC(5) NOT NULL,
    MessageSource CHAR(30),
    MessageText CHAR(50) NOT NULL,
    MessageType CHAR(12) NOT NULL,
    MessageData CHAR(100)
);

-- FactCashBalances
CREATE TABLE warehouse.FactCashBalances (
    SK_CustomerID INTEGER NOT NULL REFERENCES warehouse.DimCustomer (SK_CustomerID),
    SK_AccountID INTEGER NOT NULL REFERENCES warehouse.DimAccount (SK_AccountID),
    SK_DateID INTEGER NOT NULL REFERENCES warehouse.DimDate (SK_DateID),
    Cash NUMERIC(15,2) NOT NULL,
    BatchID NUMERIC(5)
);

-- FactHoldings
CREATE TABLE warehouse.FactHoldings (
    TradeID INTEGER NOT NULL,
    CurrentTradeID INTEGER NOT NULL,
    SK_CustomerID INTEGER NOT NULL REFERENCES warehouse.DimCustomer (SK_CustomerID),
    SK_AccountID INTEGER NOT NULL REFERENCES warehouse.DimAccount (SK_AccountID),
    SK_SecurityID INTEGER NOT NULL REFERENCES warehouse.DimSecurity (SK_SecurityID),
    SK_CompanyID INTEGER NOT NULL REFERENCES warehouse.DimCompany (SK_CompanyID),
    SK_DateID INTEGER NULL REFERENCES warehouse.DimDate (SK_DateID),
    SK_TimeID INTEGER NULL REFERENCES warehouse.DimTime (SK_TimeID),
    CurrentPrice NUMERIC(8,2) CHECK (CurrentPrice > 0) ,
    CurrentHolding NUMERIC(6) NOT NULL,
    BatchID NUMERIC(5)
);

-- FactMarketHistory
CREATE TABLE warehouse.FactMarketHistory (   
    SK_SecurityID INTEGER NOT NULL REFERENCES warehouse.DimSecurity (SK_SecurityID),
    SK_CompanyID INTEGER NOT NULL REFERENCES warehouse.DimCompany (SK_CompanyID),
    SK_DateID INTEGER NOT NULL REFERENCES warehouse.DimDate (SK_DateID),
    PERatio NUMERIC(10,2),
    Yield NUMERIC(5,2) NOT NULL,
    FiftyTwoWeekHigh NUMERIC(8,2) NOT NULL,
    SK_FiftyTwoWeekHighDate INTEGER NOT NULL,
    FiftyTwoWeekLow NUMERIC(8,2) NOT NULL,
    SK_FiftyTwoWeekLowDate INTEGER NOT NULL,
    ClosePrice NUMERIC(8,2) NOT NULL,
    DayHigh NUMERIC(8,2) NOT NULL,
    DayLow NUMERIC(8,2) NOT NULL,
    Volume NUMERIC(12) NOT NULL,
    BatchID NUMERIC(5)
);

-- FactWatches
CREATE TABLE warehouse.FactWatches (
    SK_CustomerID INTEGER NOT NULL REFERENCES warehouse.DimCustomer (SK_CustomerID),
    SK_SecurityID INTEGER NOT NULL REFERENCES warehouse.DimSecurity (SK_SecurityID),
    SK_DateID_DatePlaced INTEGER NOT NULL REFERENCES warehouse.DimDate (SK_DateID),
    SK_DateID_DateRemoved INTEGER REFERENCES warehouse.DimDate (SK_DateID),
    BatchID NUMERIC(5) NOT NULL 
);

-- Industry
CREATE TABLE warehouse.Industry (
    IN_ID CHAR(2) NOT NULL,
    IN_NAME CHAR(50) NOT NULL,
    IN_SC_ID CHAR(4) NOT NULL
);

-- Financial
CREATE TABLE warehouse.Financial (
    SK_CompanyID INTEGER NOT NULL REFERENCES warehouse.DimCompany (SK_CompanyID),
    FI_YEAR NUMERIC(4) NOT NULL,
    FI_QTR NUMERIC(1) NOT NULL,
    FI_QTR_START_DATE DATE NOT NULL,
    FI_REVENUE NUMERIC(15,2) NOT NULL,
    FI_NET_EARN NUMERIC(15,2) NOT NULL,
    FI_BASIC_EPS NUMERIC(10,2) NOT NULL,
    FI_DILUT_EPS NUMERIC(10,2) NOT NULL,
    FI_MARGIN NUMERIC(10,2) NOT NULL,
    FI_INVENTORY NUMERIC(15,2) NOT NULL,
    FI_ASSETS NUMERIC(15,2) NOT NULL,
    FI_LIABILITY NUMERIC(15,2) NOT NULL,
    FI_OUT_BASIC NUMERIC(12) NOT NULL,
    FI_OUT_DILUT NUMERIC(12) NOT NULL
);
-- Prospect Table
CREATE TABLE warehouse.Prospect (
    AgencyID CHAR(30) NOT NULL UNIQUE,
    SK_RecordDateID INTEGER NOT NULL,
    SK_UpdateDateID INTEGER REFERENCES warehouse.DimDate (SK_DateID),
    BatchID NUMERIC(5) NOT NULL,
    IsCustomer BIT NOT NULL,
    LastName CHAR(30) NOT NULL,
    FirstName CHAR(30) NOT NULL,
    MiddleInitial CHAR(1),
    Gender CHAR(1),
    AddressLine1 CHAR(80),
    AddressLine2 CHAR(80),
    PostalCode CHAR(12),
    City CHAR(25) NOT NULL,
    State CHAR(20) NOT NULL,
    Country CHAR(24),
    Phone CHAR(30),
    Income NUMERIC(9),
    numberCars NUMERIC(2),
    numberChildren NUMERIC(2),
    MaritalStatus CHAR(1),
    Age NUMERIC(3),
    CreditRating NUMERIC(4),
    OwnOrRentFlag CHAR(1),
    Employer CHAR(30),
    numberCreditCards NUMERIC(2),
    NetWorth NUMERIC(12),
    MarketingNameplate CHAR(100)
);

-- StatusType Table
CREATE TABLE warehouse.StatusType (
    ST_ID CHAR(4) NOT NULL,
    ST_NAME CHAR(10) NOT NULL
);

-- TaxRate Table
CREATE TABLE warehouse.TaxRate (
    TX_ID CHAR(4) NOT NULL,
    TX_NAME CHAR(50) NOT NULL,
    TX_RATE NUMERIC(6,5) NOT NULL
);

-- TradeType Table
CREATE TABLE warehouse.TradeType (
    TT_ID CHAR(3) NOT NULL,
    TT_NAME CHAR(12) NOT NULL,
    TT_IS_SELL NUMERIC(1) NOT NULL,
    TT_IS_MRKT NUMERIC(1) NOT NULL
);

-- AuditTable Table
CREATE TABLE warehouse.AuditTable (
    DataSet CHAR(20) NOT NULL,
    BatchID NUMERIC(5),
    AT_Date DATE,
    AT_Attribute CHAR(50),
    AT_Value NUMERIC(15),
    DValue NUMERIC(15,5)
);

-- Index on DimTrade Table
CREATE INDEX PIndex ON warehouse.DimTrade (TradeID);
