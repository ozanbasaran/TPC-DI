CREATE SCHEMA staging;

-- Schema of Account table
CREATE TABLE staging.account (
    CDC_FLAG VARCHAR(255) NOT NULL,
    CDC_DSN BIGINT NOT NULL,
    CA_ID BIGINT NOT NULL,
    CA_B_ID BIGINT NOT NULL,
    CA_C_ID BIGINT NOT NULL,
    CA_NAME VARCHAR(255),
    CA_TAX_ST BIGINT NOT NULL,
    CA_ST_ID VARCHAR(255) NOT NULL,
    PRIMARY KEY (CA_ID)
);
-- Schema of CashTransaction table
CREATE TABLE staging.cash_transaction (
    CT_CA_ID NUMERIC(11),
    CT_DTS TIMESTAMP,
    CT_AMT NUMERIC(10,2),
    CT_NAME CHAR(100)
);
CREATE TABLE staging.customer (
    ActionType VARCHAR,
    ActionTS TIMESTAMP,
    C_ID INT,
    C_TAX_ID VARCHAR,
    C_GNDR VARCHAR,
    C_TIER VARCHAR,
    C_DOB DATE,
    C_L_NAME VARCHAR,
    C_F_NAME VARCHAR,
    C_M_NAME VARCHAR,
    C_ADLINE1 VARCHAR,
    C_ADLINE2 VARCHAR,
    C_ZIPCODE VARCHAR,
    C_CITY VARCHAR,
    C_STATE_PROV VARCHAR,
    C_CTRY VARCHAR,
    C_PRIM_EMAIL VARCHAR,
    C_ALT_EMAIL VARCHAR,
    C_PHONE_1_CTRY_CODE VARCHAR,
    C_PHONE_1_AREA_CODE VARCHAR,
    C_PHONE_1_LOCAL VARCHAR,
    C_PHONE_1_EXT VARCHAR,
    C_PHONE_2_CTRY_CODE VARCHAR,
    C_PHONE_2_AREA_CODE VARCHAR,
    C_PHONE_2_LOCAL VARCHAR,
    C_PHONE_2_EXT VARCHAR,
    C_PHONE_3_CTRY_CODE VARCHAR,
    C_PHONE_3_AREA_CODE VARCHAR,
    C_PHONE_3_LOCAL VARCHAR,
    C_PHONE_3_EXT VARCHAR,
    C_LCL_TX_ID VARCHAR,
    C_NAT_TX_ID VARCHAR,
    CA_ID VARCHAR,
    CA_TAX_ST VARCHAR,
    CA_B_ID VARCHAR,
    CA_NAME VARCHAR
);




-- Schema of DailyMarket table
CREATE TABLE staging.daily_market (
    DM_DATE DATE,
    DM_S_SYMB VARCHAR(15),
    DM_CLOSE NUMERIC(8,2),
    DM_HIGH NUMERIC(8,2),
    DM_LOW NUMERIC(8,2),
    DM_VOL NUMERIC(12)
);

-- Creating the Date table
CREATE TABLE staging.date (
    SK_DateID NUMERIC(11) NOT NULL,
    DateValue CHAR(20) NOT NULL,
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
    HolidayFlag BOOLEAN NOT NULL,
    PRIMARY KEY (SK_DateID)
);



CREATE TABLE staging.holding_history (
    HH_H_T_ID NUMERIC(15),
    HH_T_ID NUMERIC(15),
    HH_BEFORE_QTY NUMERIC(6),
    HH_AFTER_QTY NUMERIC(6)
);

CREATE TABLE staging.trade (
    -- CDC_FLAG CHAR(1),
    -- CDC_DSN NUMERIC(12),
    T_ID VARCHAR(15),
    T_DTS VARCHAR(25),
    T_ST_ID CHAR(4),
    T_TT_ID CHAR(3),
    T_IS_CASH BOOLEAN, -- This is supposed to be a '0' or '1' but it is 'true' or 'false'
    T_S_SYMB CHAR(15),
    T_QTY NUMERIC(6),
    T_BID_PRICE NUMERIC(8,2),
    T_CA_ID NUMERIC(11),
    T_EXEC_NAME CHAR(49),
    T_TRADE_PRICE NUMERIC(8,2),
    T_CHRG NUMERIC(10,2),
    T_COMM NUMERIC(10,2),
    T_TAX NUMERIC(10,2)
);
CREATE TABLE staging.time (
    SK_TimeID NUMERIC(11),
    TimeValue CHAR(8),
    HourID NUMERIC(2),
    HourDesc CHAR(5),
    MinuteID NUMERIC(2),
    MinuteDesc CHAR(5),
    SecondID NUMERIC(2),
    SecondDesc CHAR(8),
    MarketHoursFlag CHAR(1),
    OfficeHoursFlag CHAR(1)
);




-- Schema of WatchHistory table
CREATE TABLE staging.watch_history (
    W_C_ID NUMERIC(11),
    W_S_SYMB CHAR(15),
    W_DTS timestamp,
    W_ACTION CHAR(4)
);


-- Schema of hr table
CREATE TABLE staging.hr (
    EmployeeID BIGINT NOT NULL,
    ManagerID BIGINT NOT NULL,
    EmployeeFirstName VARCHAR(255) NOT NULL,
    EmployeeLastName VARCHAR(255) NOT NULL,
    EmployeeMI VARCHAR(255),
    EmployeeJobCode BIGINT,
    EmployeeBranch VARCHAR(255),
    EmployeeOffice VARCHAR(255),
    EmployeePhone VARCHAR(255),
    PRIMARY KEY (EmployeeID)
);

-- Schema of prospect table
CREATE TABLE staging.prospect (
    AgencyID VARCHAR(255) NOT NULL,
    LastName VARCHAR(255) NOT NULL,
    FirstName VARCHAR(255) NOT NULL,
    MiddleInitial VARCHAR(255),
    Gender VARCHAR(255),
    AddressLine1 VARCHAR(255),
    AddressLine2 VARCHAR(255),
    PostalCode VARCHAR(255),
    City VARCHAR(255) NOT NULL,
    State VARCHAR(255) NOT NULL,
    Country VARCHAR(255),
    Phone VARCHAR(255),
    Income BIGINT,
    NumberCars BIGINT,
    NumberChildren BIGINT,
    MaritalStatus VARCHAR(255),
    Age BIGINT,
    CreditRating BIGINT,
    OwnOrRentFlag VARCHAR(255),
    Employer VARCHAR(255),
    NumberCreditCards BIGINT,
    NetWorth BIGINT,
    PRIMARY KEY (AgencyID)
);

-- Schema of TradeHistory table
CREATE TABLE staging.trade_history (
    TH_T_ID BIGINT NOT NULL,
    TH_DTS TIMESTAMP NOT NULL,
    TH_ST_ID VARCHAR(255) NOT NULL
);
CREATE TABLE staging.finwire_sec (
    pts CHAR(15),
    rec_type CHAR(3),
    symbol CHAR(15),
    issue_type CHAR(6),
    status CHAR(4),
    name CHAR(70),
    ex_id CHAR(6),
    sh_out CHAR(13),
    first_trade_date timestamp,
    first_trade_exchg timestamp,
    dividend CHAR(12),
    co_name_or_cik CHAR(60)
);
CREATE TABLE staging.finwire_cmp (
    pts CHAR(15) NOT NULL,
    rec_type CHAR(3) NOT NULL,
    company_name CHAR(60) NOT NULL,
    cik BIGINT NOT NULL,
    status CHAR(4) NOT NULL,
    industry_id CHAR(2) NOT NULL,
    sprating CHAR(4) NOT NULL,
    founding_date timestamp,
    addr_line1 CHAR(80) NOT NULL,
    addr_line2 CHAR(80),
    postal_code CHAR(12) NOT NULL,
    city CHAR(25) NOT NULL,
    state_province CHAR(20) NOT NULL,
    country CHAR(24),
    ceo_name CHAR(46) NOT NULL,
    description CHAR(150) NOT NULL
);

CREATE TABLE staging.finwire_fin (
    pts CHAR(15) NOT NULL,
    rec_type CHAR(3) NOT NULL,
    year CHAR(4) NOT NULL,
    quarter CHAR(1) NOT NULL,
    qtr_start_date timestamp NOT NULL,
    posting_date timestamp NOT NULL,
    revenue CHAR(17) NOT NULL,
    earnings CHAR(17) NOT NULL,
    eps CHAR(12) NOT NULL,
    diluted_eps CHAR(12) NOT NULL,
    margin CHAR(12) NOT NULL,
    inventory CHAR(17) NOT NULL,
    assets CHAR(17) NOT NULL,
    liabilities CHAR(17) NOT NULL,
    sh_out CHAR(13) NOT NULL,
    diluted_sh_out CHAR(13) NOT NULL,
    co_name_or_cik CHAR(60)
);

CREATE TABLE staging.industry (
    IN_ID CHAR(2),
    IN_NAME CHAR(50),
    IN_SC_ID CHAR(4)
);
CREATE TABLE staging.status_type (
    ST_ID CHAR(4),
    ST_NAME CHAR(10)
);
CREATE TABLE staging.tax_rate (
    TX_ID CHAR(4),
    TX_NAME CHAR(50),
    TX_RATE NUMERIC(6,5)
);

CREATE TABLE staging.trade_type (
    TT_ID CHAR(3),
    TT_NAME CHAR(12),
    TT_IS_SELL NUMERIC(1),
    TT_IS_MRKT NUMERIC(1)
);



-- Schema of BatchDate table
CREATE TABLE staging.batch_date (
    BatchDate DATE NOT NULL,
    PRIMARY KEY (BatchDate)
);
CREATE TABLE staging.audit_data (
    DataSet CHAR(20) NOT NULL,
    BatchID NUMERIC(5) NOT NULL,
    Date DATE,
    Attribute CHAR(50) NOT NULL,
    Value NUMERIC(15),
    DValue NUMERIC(15, 5)
);
