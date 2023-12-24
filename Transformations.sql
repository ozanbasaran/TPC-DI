-- First Start with DimDate
-- Historical Load Transformation for DimDate
INSERT INTO warehouse.DimDate (
    SK_DateID,
    DateValue,
    DateDesc,
    CalendarYearID,
    CalendarYearDesc,
    CalendarQtrID,
    CalendarQtrDesc,
    CalendarMonthID,
    CalendarMonthDesc,
    CalendarWeekID,
    CalendarWeekDesc,
    DayOfWeekNum,
    DayOfWeekDesc,
    FiscalYearID,
    FiscalYearDesc,
    FiscalQtrID,
    FiscalQtrDesc,
    HolidayFlag
)
SELECT
    SK_DateID,
    DateValue::DATE,
    DateDesc,
    CalendarYearID,
    CalendarYearDesc,
    CalendarQtrID,
    CalendarQtrDesc,
    CalendarMonthID,
    CalendarMonthDesc,
    CalendarWeekID,
    CalendarWeekDesc,
    DayOfWeekNum,
    DayOfWeekDesc,
    FiscalYearID,
    FiscalYearDesc,
    FiscalQtrID,
    FiscalQtrDesc,
    HolidayFlag
FROM staging.date;


-- DimTime
INSERT INTO warehouse.dimtime (
    SK_TimeID,
    TimeValue,
    HourID,
    HourDesc,
    MinuteID,
    MinuteDesc,
    SecondID,
    SecondDesc,
    MarketHoursFlag,
    OfficeHoursFlag
)
SELECT
    SK_TimeID,
    timevalue::time without time zone,  -- Explicitly cast to the correct type
    HourID,
    HourDesc,
    MinuteID,
    MinuteDesc,
    SecondID,
    SecondDesc,
    MarketHoursFlag::boolean,
    OfficeHoursFlag::boolean
FROM
    staging.time;

-- StatusType
INSERT INTO warehouse.StatusType (ST_ID, ST_NAME)
SELECT ST_ID, ST_NAME
FROM staging.status_type;

-- TaxRate
INSERT INTO warehouse.TaxRate (TX_ID, TX_NAME, TX_RATE)
SELECT TX_ID, TX_NAME, TX_RATE
FROM staging.tax_rate;

-- TradeType
INSERT INTO warehouse.TradeType (TT_ID, TT_NAME, TT_IS_SELL, TT_IS_MRKT)
SELECT TT_ID, TT_NAME, TT_IS_SELL, TT_IS_MRKT
FROM staging.trade_type;


-- DimBroker 
INSERT INTO warehouse.DimBroker (IsCurrent, EffectiveDate, EndDate, BatchID, BrokerID, ManagerID, FirstName, LastName, MiddleInitial, Branch, Office, Phone)
SELECT
	True AS IsCurrent,
	(SELECT MIN(DateValue) FROM warehouse.DimDate) as EffectiveDate,
	'9999-12-31' AS EndDate,
	1 as BatchID,
	EmployeeID as BrokerID,
	ManagerID as ManagerID,
	EmployeeFirstName as FirstName,
	EmployeeLastName as LastName,
	EmployeeMI as MiddleInitial,
	EmployeeBranch as Branch,
	EmployeeOffice as Office,
	EmployeePhone as Phone
FROM staging.HR
WHERE EmployeeJobCode = 314;


--DimCompany
INSERT INTO warehouse.DimCompany (
    IsCurrent,
    EffectiveDate,
    EndDate,
    BatchID,
    CompanyID,
    Name,
    SPRating,
    CEO,
    Description,
    FoundingDate,
    AddressLine1,
    AddressLine2,
    PostalCode,
    City,
    stateprov,
    Country,
    Status,
    Industry,
    isLowGrade
)
SELECT
    TRUE AS IsCurrent,
    TO_DATE(PTS, 'YYYYMMDD') AS EffectiveDate,
    '9999-12-31' AS EndDate,
    1 AS BatchID,
    CIK AS CompanyID,
    NULLIF(COALESCE(company_name, ''), '') AS Name,
    NULLIF(COALESCE(SPrating, ''), '') AS SPRating,
    NULLIF(COALESCE(ceo_name, ''), '') AS CEO,
    NULLIF(COALESCE(Description, ''), '') AS Description,
    founding_date AS FoundingDate,
    NULLIF(COALESCE(addr_line1, ''), '') AS AddressLine1,
    NULLIF(COALESCE(addr_line2, ''), '') AS AddressLine2,
    NULLIF(COALESCE(postal_code, ''), '') AS PostalCode,
    NULLIF(COALESCE(City, ''), '') AS City,
    NULLIF(COALESCE(state_province, ''), '') AS State_Prov,
    NULLIF(COALESCE(Country, ''), '') AS Country,
    ST_ID AS Status,
    IN_ID AS Industry,
    CASE WHEN SPrating LIKE 'A%' OR SPrating LIKE 'BBB%' THEN FALSE ELSE TRUE END AS isLowGrade
FROM
    staging.finwire_cmp CMP
JOIN
    staging.status_type S ON CMP.Status = S.ST_ID
JOIN
    staging.industry I ON CMP.industry_id = I.IN_ID;
INSERT INTO warehouse.DImessages (
    MessageSource,
    MessageType,
    MessageText,
    MessageData,
    batchid,
    messagedateandtime
)
SELECT
    'DimCompany' AS MessageSource,
    'Alert' AS MessageType,
    'Invalid SPRating' AS MessageText,
    'CO_ID = ' || CompanyID || ', CO_SP_RATE = ' || COALESCE(SPRating, 'NULL') AS MessageData,
    1 AS batchid,
    NOW() AS messagedateandtime  -- Use NOW() to get the current timestamp
FROM
    warehouse.DimCompany
WHERE
    SPRating NOT IN ('AAA', 'AA+', 'AA-', 'A+', 'A-', 'BBB+', 'BBB-', 'BB+', 'BB-', 'B+', 'B-', 'CCC+', 'CCC-', 'CC', 'C', 'D');


-- DimCustomer
Drop table if exists Customers_Preproc;
CREATE TEMP TABLE Customers_Preproc AS
SELECT
    CAST(staging.customer.C_ID AS INT) AS CustomerID,
    TRIM(staging.customer.C_TAX_ID) AS TaxID,
    TRIM(UPPER(CASE WHEN staging.customer.C_GNDR NOT IN ('m', 'f') OR staging.customer.C_GNDR IS NULL THEN 'u' ELSE staging.customer.C_GNDR END)) AS Gender,
    CAST(staging.customer.C_TIER AS INT) AS Tier,
    staging.customer.C_DOB AS DOB,
    TRIM(staging.customer.C_PRIM_EMAIL) AS Email1,
    TRIM(staging.customer.C_ALT_EMAIL) AS Email2,
    TRIM(staging.customer.C_F_NAME) AS FirstName,
    TRIM(staging.customer.C_M_NAME) AS MiddleInitial,
    TRIM(staging.customer.C_L_NAME) AS LastName,
    TRIM(staging.customer.C_ADLINE1) AS AddressLine1,
    TRIM(staging.customer.C_ADLINE2) AS AddressLine2,
    TRIM(staging.customer.C_ZIPCODE) AS PostalCode,
    TRIM(staging.customer.C_CITY) AS City,
    TRIM(staging.customer.C_STATE_PROV) AS StateProv,
    TRIM(staging.customer.C_CTRY) AS Country,
    CASE
        WHEN staging.customer.c_phone_1_ctry_code IS NOT NULL AND staging.customer.c_phone_1_area_code IS NOT NULL AND staging.customer.c_phone_1_local IS NOT NULL
            THEN CONCAT('+' , CAST(staging.customer.c_phone_1_ctry_code AS TEXT), ' (', CAST(staging.customer.c_phone_1_area_code AS TEXT), ') ', CAST(staging.customer.c_phone_1_local AS TEXT))
        WHEN staging.customer.c_phone_1_ctry_code IS NULL AND (staging.customer.c_phone_1_area_code IS NOT NULL AND staging.customer.c_phone_1_local IS NOT NULL)
            THEN CONCAT('(', CAST(staging.customer.c_phone_1_area_code AS TEXT), ') ', CAST(staging.customer.c_phone_1_local AS TEXT))
        WHEN (c_phone_1_ctry_code IS NULL AND staging.customer.c_phone_1_area_code IS NULL) AND staging.customer.c_phone_1_local IS NOT NULL
            THEN staging.customer.c_phone_1_local
    END AS Phone1_V1,
    CASE
        WHEN staging.customer.c_phone_2_ctry_code IS NOT NULL AND staging.customer.c_phone_2_area_code IS NOT NULL AND staging.customer.c_phone_2_local IS NOT NULL
            THEN CONCAT('+' , CAST(staging.customer.c_phone_2_ctry_code AS TEXT), ' (', CAST(staging.customer.c_phone_2_area_code AS TEXT), ') ', CAST(staging.customer.c_phone_2_local AS TEXT))
        WHEN staging.customer.c_phone_2_ctry_code IS NULL AND (staging.customer.c_phone_2_area_code IS NOT NULL AND staging.customer.c_phone_2_local IS NOT NULL)
            THEN CONCAT('(', CAST(staging.customer.c_phone_2_area_code AS TEXT), ') ', CAST(staging.customer.c_phone_2_local AS TEXT))
        WHEN (staging.customer.c_phone_2_ctry_code IS NULL AND staging.customer.c_phone_2_area_code IS NULL) AND staging.customer.c_phone_2_local IS NOT NULL
            THEN staging.customer.c_phone_2_local
    END AS Phone2_V1,
    CASE
        WHEN staging.customer.c_phone_3_ctry_code IS NOT NULL AND staging.customer.c_phone_3_area_code IS NOT NULL AND staging.customer.c_phone_3_local IS NOT NULL
            THEN CONCAT('+' , CAST(staging.customer.c_phone_3_ctry_code AS TEXT), ' (', CAST(staging.customer.c_phone_3_area_code AS TEXT), ') ', CAST(staging.customer.c_phone_3_local AS TEXT))
        WHEN staging.customer.c_phone_3_ctry_code IS NULL AND (staging.customer.c_phone_3_area_code IS NOT NULL AND staging.customer.c_phone_3_local IS NOT NULL)
            THEN CONCAT('(', CAST(staging.customer.c_phone_3_area_code AS TEXT), ') ', CAST(staging.customer.c_phone_3_local AS TEXT))
        WHEN (staging.customer.c_phone_3_ctry_code IS NULL AND staging.customer.c_phone_3_area_code IS NULL) AND staging.customer.c_phone_3_local IS NOT NULL
            THEN staging.customer.c_phone_3_local
    END AS Phone3_V1,
    TRIM(TR.TX_NAME) AS NationalTaxRateDesc,
    TR.TX_RATE AS NationalTaxRate,
    TRIM(TR2.TX_NAME) AS LocalTaxRateDesc,
    TR2.TX_RATE AS LocalTaxRate,
    TRIM(staging.customer.c_phone_1_ext) AS C_EXT1,
    TRIM(staging.customer.c_phone_2_ext) AS C_EXT2,
    TRIM(staging.customer.c_phone_3_ext) AS C_EXT3,
    TRIM(P.AgencyID) AS AgencyID,
    P.CreditRating,
    P.NetWorth,
    CASE
        WHEN P.NetWorth > 1000000 OR P.Income > 200000 THEN 'HighValue'
        WHEN P.NumberChildren > 3 OR P.NumberCreditCards > 5 THEN 'Expenses'
        WHEN P.Age > 45 THEN 'Boomer'
        WHEN P.Income < 50000 OR P.CreditRating < 600 OR P.NetWorth < 100000 THEN 'MoneyAlert'
        WHEN P.NumberCars > 3 OR P.NumberCreditCards > 7 THEN 'Spender'
        WHEN P.Age < 25 AND P.NetWorth > 1000000 THEN 'Inherited'
    END AS MarketingNameplate,
    staging.customer.actiontype,
    staging.customer.ActionTS
FROM
    staging.customer
    JOIN staging.tax_rate AS TR ON staging.customer.c_nat_tx_id = TR.TX_ID
    JOIN staging.tax_rate AS TR2 ON staging.customer.C_LCL_TX_ID = TR2.TX_ID
    JOIN staging.prospect AS P ON
        COALESCE(UPPER(TRIM(staging.customer.C_F_NAME)), ' ') = COALESCE(UPPER(TRIM(P.FirstName)), ' ')
        AND COALESCE(UPPER(TRIM(staging.customer.C_L_NAME)), ' ') = COALESCE(UPPER(TRIM(P.LastName)), ' ')
        AND COALESCE(UPPER(TRIM(staging.customer.C_ADLINE1)), ' ') = COALESCE(UPPER(TRIM(P.AddressLine1)), ' ')
        AND COALESCE(UPPER(TRIM(staging.customer.C_ADLINE2)), ' ') = COALESCE(UPPER(TRIM(P.AddressLine2)), ' ')
        AND COALESCE(UPPER(TRIM(staging.customer.C_ZIPCODE)), ' ') = COALESCE(UPPER(TRIM(P.PostalCode)), ' ');

DROP TABLE IF EXISTS Customers;
CREATE TEMP TABLE Customers AS (
    -- Select everything from the previously defined table + adding phones.
SELECT *,
    CASE WHEN C_EXT1 IS NOT NULL THEN Phone1_V1 || C_EXT1 ELSE Phone1_V1 END AS Phone1,
    CASE WHEN C_EXT2 IS NOT NULL THEN Phone2_V1 || C_EXT2 ELSE Phone2_V1 END AS Phone2,
    CASE WHEN C_EXT3 IS NOT NULL THEN Phone3_V1 || C_EXT3 ELSE Phone3_V1 END AS Phone3
FROM Customers_Preproc
);


-- Depending on the customer's status, use conditional logic to determine how to update the table.
-- These are the three cases: NEW, UPDATED, and INACTIVE
DROP TABLE IF EXISTS CustomersNew;
CREATE TEMP TABLE CustomersNew AS (
    SELECT *, 'ACTIVE' AS Status FROM Customers WHERE ActionType = 'NEW'
);
DROP TABLE IF EXISTS CustomersUpd;
CREATE TEMP TABLE CustomersUpd AS (
    SELECT * FROM staging.customer WHERE ActionType = 'UPDCUST'
);
DROP TABLE IF EXISTS CustomersInactive;
CREATE TEMP TABLE CustomersInactive AS (
    SELECT C_ID, ActionTS
    FROM staging.customer
    WHERE ActionType = 'INACT'
);

DROP TABLE IF EXISTS CustomersNewAndUpd;
CREATE TEMP TABLE CustomersNewAndUpd AS (
    SELECT
        COALESCE(CustomersUpd.c_id, CustomersNew.CustomerID) AS CustomerID,
        COALESCE(CustomersUpd.c_tax_id, CustomersNew.TaxID) AS TaxID,
        'ACTIVE' AS Status,
        COALESCE(CustomersUpd.c_l_name, CustomersNew.LastName) AS LastName,
        COALESCE(CustomersUpd.c_f_name, CustomersNew.FirstName) AS FirstName,
        COALESCE(CustomersUpd.c_m_name, CustomersNew.MiddleInitial) AS MiddleInitial,
        COALESCE(CustomersUpd.c_gndr, CustomersNew.Gender) AS Gender,
        COALESCE(CAST(CustomersUpd.c_tier AS INT), CAST(CustomersNew.Tier AS INT)) AS Tier,
        COALESCE(CustomersUpd.c_dob, CustomersNew.DOB) AS DOB,
        COALESCE(CustomersUpd.c_adline1, CustomersNew.AddressLine1) AS AddressLine1,
        COALESCE(CustomersUpd.c_adline2, CustomersNew.AddressLine2) AS AddressLine2,
        COALESCE(CustomersUpd.c_zipcode, CustomersNew.PostalCode) AS PostalCode,
        COALESCE(CustomersUpd.c_city, CustomersNew.City) AS City,
        COALESCE(CustomersUpd.c_state_prov, CustomersNew.StateProv) AS StateProv,
        COALESCE(CustomersUpd.c_ctry, CustomersNew.Country) AS Country,
        COALESCE(CustomersUpd.c_phone_1_local, CustomersNew.Phone1) AS Phone1,
        COALESCE(CustomersUpd.c_phone_2_local, CustomersNew.Phone2) AS Phone2,
        COALESCE(CustomersUpd.c_phone_3_local, CustomersNew.Phone3) AS Phone3,
        COALESCE(CustomersUpd.c_prim_email, CustomersNew.Email1) AS Email1,
        COALESCE(CustomersUpd.c_alt_email, CustomersNew.Email2) AS Email2,
        CustomersNew.NationalTaxRateDesc AS NationalTaxRateDesc,
        CustomersNew.NationalTaxRate AS NationalTaxRate,
        CustomersNew.LocalTaxRateDesc AS LocalTaxRateDesc,
        CustomersNew.LocalTaxRate AS LocalTaxRate,
        CustomersNew.AgencyID AS AgencyID,
        CustomersNew.CreditRating CreditRating,
        CustomersNew.NetWorth AS NetWorth,
        CustomersNew.MarketingNameplate AS MarketingNameplate,
        CustomersNew.ActionTS AS ActionTS,
        COALESCE(CustomersUpd.ActionType, CustomersNew.ActionType) AS ActionType
    FROM CustomersUpd
    JOIN CustomersNew  ON CustomersUpd.c_id = CustomersNew.CustomerID
);

drop table if exists CustomersFinal;
CREATE TEMP TABLE CustomersFinal AS (
    -- NEW and UPDCUST
    SELECT *
    FROM CustomersNewAndUpd
    UNION
    SELECT CNU.CustomerID
         , CNU.TaxID
         , 'INACTIVE' AS Status
         , CNU.LastName
         , CNU.FirstName
         , CNU.MiddleInitial
         , CNU.Gender
         , CNU.Tier
         , CNU.DOB
         , CNU.AddressLine1
         , CNU.AddressLine2
         , CNU.PostalCode
         , CNU.City
         , CNU.StateProv
         , CNU.Country
         , CNU.Phone1
         , CNU.Phone2
         , CNU.Phone3
         , CNU.Email1
         , CNU.Email2
         , CNU.NationalTaxRateDesc
         , CNU.NationalTaxRate
         , CNU.LocalTaxRateDesc
         , CNU.LocalTaxRate
         , CNU.AgencyID
         , CNU.CreditRating
         , CNU.NetWorth
         , CNU.MarketingNameplate
         , CI.ActionTS
         , 'INACT' AS ActionType
    FROM CustomersNewAndUpd CNU
    INNER JOIN CustomersInactive CI
    ON CNU.CustomerID = CI.C_ID
    INNER JOIN (
            -- NOTE: ActionTS is the timestamp on which the register was updated.
            -- Grouped By CustID, so it pulls the most up-to-date customer row to be able to set it to INACT.
            SELECT CustomerID, MAX( ActionTS ) ActionTSLatestCustomer
            FROM CustomersNewAndUpd
            GROUP BY CustomerID
        ) LC
        ON CNU.CustomerID = LC.CustomerID AND CNU.ActionTS = LC.ActionTSLatestCustomer
);
INSERT INTO warehouse.DimCustomer (
    CustomerID,
    TaxID,
    LastName,
    FirstName,
    MiddleInitial,
    Gender,
    Tier,
    DOB,
    AddressLine1,
    AddressLine2,
    PostalCode,
    City,
    StateProv,
    Country,
    Status,
    Phone1,
    Phone2,
    Phone3,
    Email1,
    Email2,
    NationalTaxRateDesc,
    NationalTaxRate,
    LocalTaxRateDesc,
    LocalTaxRate,
    AgencyID,
    CreditRating,
    NetWorth,
    MarketingNameplate,
    EffectiveDate,
    IsCurrent,
    EndDate,
    BatchID
)
SELECT
    CustomerID,
    TaxID,
    LastName,
    FirstName,
    MiddleInitial,
    UPPER(COALESCE(Gender, 'U')) AS Gender,
    Tier,
    DOB,
    AddressLine1,
    AddressLine2,
    PostalCode,
    City,
    StateProv,
    Country,
    Status,
    Phone1,
    Phone2,
    Phone3,
    Email1,
    Email2,
    NationalTaxRateDesc,
    NationalTaxRate,
    LocalTaxRateDesc,
    LocalTaxRate,
    AgencyID,
    CreditRating,
    NetWorth,
    MarketingNameplate,
    CASE
        WHEN ActionType = 'INACT' THEN CURRENT_DATE
        WHEN ActionType = 'UPDCUST' THEN CURRENT_DATE
        WHEN ActionType = 'NEW' THEN '2017-07-07'::DATE
        ELSE NULL
    END AS EffectiveDate,
    CASE
        WHEN ActionType = 'INACT' THEN False  -- IsCurrent logic for INACT
        ELSE True
    END AS IsCurrent,
    CASE
        WHEN ActionType = 'INACT' THEN CURRENT_DATE
        WHEN ActionType = 'UPDCUST' THEN CURRENT_DATE
        WHEN ActionType = 'NEW' THEN '2017-07-07'::DATE
    END AS EndDate,
    1
FROM CustomersFinal;
-- Insert into Dimessages for invalid customer tier
INSERT INTO warehouse.DImessages (
    MessageSource,
    MessageType,
    MessageText,
    MessageData,
    messagedateandtime,
    batchid
)
SELECT
    'DimCustomer',
    'Alert',
    'Invalid customer tier',
    'C_ID = ' || CustomersFinal.CustomerID || ', C_TIER = ' || CustomersFinal.Tier,
    CURRENT_TIMESTAMP,
    1
FROM CustomersFinal
WHERE CustomersFinal.Tier NOT IN ('1', '2', '3');

-- Insert into Dimessages for invalid DOB
INSERT INTO warehouse.DImessages (
    MessageSource,
    MessageType,
    MessageText,
    MessageData,
    messagedateandtime,
    batchid
)
SELECT
    'DimCustomer',
    'Alert',
    'DOB out of range',
    'C_ID = ' || CustomersFinal.CustomerID || ', C_DOB = ' || CustomersFinal.DOB,
    CURRENT_TIMESTAMP,
    1
FROM CustomersFinal
WHERE CustomersFinal.DOB < (CURRENT_DATE - INTERVAL '100 years')
   OR CustomersFinal.DOB > CURRENT_DATE;

-- DimAccount
DROP TABLE IF EXISTS Accounts;
CREATE TEMP TABLE Accounts AS (
    SELECT
        C.CA_ID AS AccountID,
        Br.SK_BrokerID AS SK_BrokerID,
        DimC.SK_CustomerID AS SK_CustomerID,
        C.c_id AS Customer_Id,
        C.ca_name AS AccountDesc,
        C.ca_tax_st AS TaxStatus,
        C.actiontype As ActionType,
        C.actionts As ActionTS
    FROM
        staging.customer C
    INNER JOIN warehouse.DimBroker Br ON C.ca_b_id::INT = Br.BrokerID
    INNER JOIN warehouse.DimCustomer DimC ON C.C_ID = DimC.CustomerID
);
DROP TABLE IF EXISTS AccountsNewAndAddAcct;
CREATE TEMP TABLE AccountsNewAndAddAcct AS (
	SELECT *, 'ACTIVE' AS Status
	FROM Accounts
	WHERE ActionType IN ('NEW', 'ADDACCT')
);
DROP TABLE IF EXISTS AccountsUpd;
CREATE TEMP TABLE AccountsUpd AS (
	SELECT * FROM Accounts WHERE ActionType = 'UPDACCT'
);
DROP TABLE IF EXISTS AccountsCloseAcct;
CREATE TEMP TABLE AccountsCloseAcct AS (
	SELECT C.CA_ID AS AccountID
		, C.ActionTS AS ActionTS
	FROM staging.customer C
	WHERE ActionType = 'CLOSEACCT'
);

DROP TABLE IF EXISTS AccountsNewAndAddAcctAndUpd;
CREATE TEMP TABLE AccountsNewAndAddAcctAndUpd AS (
	SELECT AccountID
		, SK_BrokerID
		, SK_CustomerID
		, 'ACTIVE' AS Status
		, AccountDesc
		, TaxStatus
		, ActionTS
		, ActionType
	FROM AccountsNewAndAddAcct
	UNION
	SELECT UpdAcct.AccountID
		, COALESCE( UpdAcct.SK_BrokerID, NewAcct.SK_BrokerID ) AS SK_BrokerID
		, COALESCE( UpdAcct.SK_CustomerID, NewAcct.SK_CustomerID ) AS SK_CustomerID
		, NewAcct.Status AS Status
		, COALESCE ( UpdAcct.AccountDesc, NewAcct.AccountDesc ) AS AccountDesc
		, COALESCE ( UpdAcct.TaxStatus, NewAcct.TaxStatus) AS TaxStatus
		, UpdAcct.ActionTS
		, UpdAcct.ActionType
	FROM AccountsNewAndAddAcct NewAcct
	JOIN AccountsUpd UpdAcct
	ON NewAcct.AccountID = UpdAcct.AccountID
);
DROP TABLE IF EXISTS AccountsUpdCust;
CREATE TEMP TABLE AccountsUpdCust AS (
    SELECT C.CA_ID AS AccountID,
           C.ActionType,
           C.ActionTS,
           Br.BrokerID,
           DimC.CustomerID
    FROM staging.customer C
    INNER JOIN warehouse.DimBroker Br ON C.ca_b_id::INT = Br.BrokerID
    INNER JOIN warehouse.DimCustomer DimC ON C.C_ID = DimC.CustomerID
    WHERE C.ActionType = 'UPDCUST'
);

DROP TABLE IF EXISTS AccountsInact;
CREATE TEMP TABLE AccountsInact AS (
    SELECT C.CA_ID AS AccountID
        , C.ActionTS AS ActionTS
    FROM staging.customer C
    WHERE ActionType = 'INACT'
);
DROP TABLE IF EXISTS AccountsFinal;
CREATE TEMP TABLE AccountsFinal AS (
	-- NEW, ADDACCT and UPDACCT
	SELECT *
	FROM AccountsNewAndAddAcctAndUpd
	UNION
	-- CLOSEACCT
	SELECT AcctNewUpd.AccountID
		, SK_BrokerID
		, SK_CustomerID
		, 'INACTIVE' AS Status
		, AccountDesc
		, TaxStatus
		, AcctNewUpd.ActionTS
		, 'CLOSEACCT' AS ActionType
	FROM AccountsNewAndAddAcctAndUpd AcctNewUpd
		INNER JOIN AccountsCloseAcct AcctClose
			ON AcctNewUpd.AccountID = AcctClose.AccountID
		INNER JOIN (
			SELECT AccountID, MAX( ActionTS ) AS ActionTSLatestAccount
			FROM AccountsNewAndAddAcctAndUpd
			GROUP BY AccountID
		) LastAcct
			ON AcctNewUpd.AccountID = LastAcct.AccountID
			AND AcctNewUpd.ActionTS = LastAcct.ActionTSLatestAccount
);
INSERT INTO warehouse.DimAccount (accountid, sk_brokerid, sk_customerid, status, accountdesc, taxstatus, iscurrent, batchid, effectivedate, enddate)
SELECT
    CAST(AccountID AS INT),
    SK_BrokerID,
    CAST(COALESCE(SK_CustomerID, 0) AS INT) AS SK_CustomerID,
    Status,
    AccountDesc,
    CAST(TaxStatus AS INT),
    CASE WHEN LEAD(ActionTS) OVER (PARTITION BY AccountID ORDER BY ActionTS ASC) IS NULL THEN True ELSE False END AS IsCurrent,
    1 AS BatchID,
    ActionTS AS EffectiveDate,
    COALESCE(LEAD(ActionTS) OVER (PARTITION BY AccountID ORDER BY ActionTS ASC), '9999-12-31 00:00:00') AS EndDate
FROM AccountsFinal;
UPDATE warehouse.DimAccount
SET SK_CustomerID = (
    SELECT DimCustomer.SK_CustomerID
    FROM warehouse.DimCustomer DimCustomer
    WHERE DimCustomer.CustomerID = AccountsUpdCust.CustomerID
)
FROM AccountsUpdCust
WHERE warehouse.DimAccount.sk_customerid = AccountsUpdCust.CustomerID;

UPDATE warehouse.DimAccount
SET
    SK_CustomerID = DimCustomer.SK_CustomerID,
    Status = 'INACTIVE',
    IsCurrent = FALSE,
    EndDate = CASE
        WHEN ActionType = 'INACT' THEN da.EffectiveDate
        ELSE '9999-12-31 00:00:00'
    END,
    BatchID = 1 -- Assuming this is Incremental Update 1
FROM warehouse.DimAccount AS da
INNER JOIN warehouse.DimCustomer AS DimCustomer ON da.sk_customerid = DimCustomer.CustomerID
INNER JOIN staging.customer AS C ON DimCustomer.CustomerID = C.C_ID
WHERE
    ActionType = 'INACT'
    AND da.sk_customerid = C.C_ID;


DROP TABLE IF EXISTS SecurityData;
CREATE TEMP TABLE SecurityData AS (
    SELECT
        DimCo.SK_CompanyID,
        S.Symbol,
        S.Issue_Type AS Issue,
        S.Name,
        ST.ST_name AS Status,
        S.Ex_ID,
        S.Sh_out,
        S.First_Trade_Date,
        S.First_Trade_Exchg,
        S.Dividend,
        TO_DATE(REPLACE(SUBSTRING(REPLACE(S.PTS, '-', ' ') FROM 1 FOR 14), ' ', ''), 'YYYYMMDDHH24MISS') AS EDate
    FROM
        staging.finwire_sec S
    JOIN warehouse.DimCompany DimCo ON (
            (LENGTH(TRANSLATE(S.Co_Name_Or_CIK, '0123456789', '')) = 0 AND CAST(DimCo.CompanyID AS VARCHAR) = S.Co_Name_Or_CIK)
            OR
            (LENGTH(TRANSLATE(S.Co_Name_Or_CIK, '0123456789', '')) > 0 AND DimCo.Name = S.Co_Name_Or_CIK)
        )
    JOIN warehouse.StatusType ST ON S.Status = ST.ST_ID
    WHERE
        TO_DATE(REPLACE(SUBSTRING(REPLACE(S.PTS, '-', ' ') FROM 1 FOR 14), ' ', ''), 'YYYYMMDDHH24MISS') BETWEEN DimCo.EffectiveDate AND DimCo.EndDate
);
SELECT * FROM SecurityData;

INSERT INTO warehouse.DimSecurity(Symbol, Issue, Status, Name, ExchangeID,SK_CompanyID, SharesOutstanding, FirstTrade, FirstTradeOnExchange, Dividend, BatchID, IsCurrent, EndDate, EffectiveDate)
SELECT
    Symbol,
    Issue,
    status,
    Name,
    Ex_ID as ExchangeID,
    SK_CompanyID,
    Sh_out::integer as SharesOutstanding,
    First_Trade_Date as FirstTrade,
    First_Trade_Exchg as FirstTradeOnExchange,
    Dividend::numeric(10,2) as Dividend,
    1 AS BatchID,
    CASE WHEN LEAD(EDate) OVER (PARTITION BY Symbol ORDER BY EDate ASC) IS NULL THEN true ELSE false END AS IsCurrent,
    COALESCE(LEAD(EDate) OVER (PARTITION BY Symbol ORDER BY EDate ASC), '9999-12-31'::DATE) AS EndDate,
    EDate AS EffectiveDate
FROM
    SecurityData;

--FactCashBalances
DROP TABLE IF EXISTS DateVariables;
CREATE TEMP TABLE DateVariables AS (
    SELECT
        datevalue,
        sk_dateid
    FROM
        warehouse.dimdate
);
DROP TABLE IF EXISTS TimeVariables;
CREATE TEMP TABLE TimeVariables AS (
    SELECT
        timevalue,
        sk_timeid
    FROM
        warehouse.dimtime
);
DROP TABLE IF EXISTS td;
CREATE TEMP TABLE td AS (
    SELECT
        T.T_ID as TradeID,
        DA.SK_AccountID,
        DA.SK_BrokerID,
        S.SK_SecurityID,  -- Include SK_SecurityID directly
        S.sk_companyid as SK_CompanyID,
        T.T_IS_CASH as CashFlag,
        T.T_QTY as Quantity,
        T.T_BID_PRICE as BidPrice,
        T.T_EXEC_NAME as ExecutedBy,
        T.T_TRADE_PRICE as TradePrice,
        T.T_CHRG as Fee,
        T.T_COMM as Commission,
        T.T_TAX as Tax,
        TT.TT_NAME AS DT_Type,
        ST.ST_NAME AS Status,
        DA.SK_CustomerID,
        CASE WHEN TH.TH_ST_ID='SBMT' AND T.T_TT_ID IN ('TMB','TMS') OR TH.TH_ST_ID='PNDG' THEN TH.TH_DTS ELSE NULL END AS CreatSKDATE,
        CASE WHEN TH.TH_ST_ID IN ('CMPT','CNCL') THEN TH.TH_DTS ELSE NULL END AS CreatSKTIME,
        CASE WHEN TH.TH_ST_ID='SBMT' AND T.T_TT_ID IN ('TMB','TMS') OR TH.TH_ST_ID='PNDG' THEN TH.TH_DTS ELSE NULL END AS CloseSKDATE,
        CASE WHEN TH.TH_ST_ID IN ('CMPT','CNCL') THEN TH.TH_DTS ELSE NULL END as CloseSKTIME
    FROM
        staging.Trade T
        JOIN staging.Trade_History TH ON CAST(T.T_ID AS BIGINT) = TH.TH_T_ID
        JOIN warehouse.DimAccount DA ON T.T_CA_ID = DA.AccountID
        JOIN warehouse.StatusType ST ON TH.Th_ST_ID = ST.ST_ID
        JOIN warehouse.TradeType TT ON T.T_TT_ID = TT.TT_ID
        JOIN warehouse.DimSecurity S ON T.T_S_SYMB = S.Symbol
);



INSERT INTO warehouse.DimTrade (
    TradeID,
    SK_AccountID,
    SK_BrokerID,
    SK_SecurityID,
    SK_CompanyID,
    CashFlag,
    Quantity,
    BidPrice,
    ExecutedBy,
    TradePrice,
    Fee,
    Commission,
    Tax,
    DT_Type,
    Status,
    SK_CustomerID,
    SK_CreateDateID,
    SK_CreateTimeID,
    SK_CloseDateID,
    SK_CloseTimeID,
    BatchID
)
SELECT
    CAST(TradeID AS INT),
    SK_AccountID,
    SK_BrokerID,
    SK_SecurityID,
    CAST(SK_CompanyID AS INT),
    CashFlag,
    Quantity,
    BidPrice,
    ExecutedBy,
    TradePrice,
    Fee,
    Commission,
    Tax,
    DT_Type,
    Status,
    SK_CustomerID,
    (SELECT sk_dateid FROM DateVariables WHERE datevalue = CreatSKDATE),
    (SELECT sk_timeid FROM TimeVariables WHERE timevalue = CAST(CreatSKTIME AS time)),
    (SELECT sk_dateid FROM DateVariables WHERE datevalue = CloseSKDATE),
    (SELECT sk_timeid FROM TimeVariables WHERE timevalue = CAST(CloseSKTIME AS time)),
    1
FROM
    td;


INSERT INTO warehouse.dimessages (
    MessageSource,
    MessageType,
    MessageText,
    MessageData,
    messagedateandtime,
    batchid
)
SELECT
    'DimTrade',
    'Alert',
    'Invalid trade commission',
    'T_ID = ' || TradeID || ', T_COMM = ' || Commission,
    now(),
    1
FROM
    td
WHERE
    Commission IS NOT NULL
    AND Commission > TradePrice * Quantity;
-- Insert into DimMessages for invalid trade fee
INSERT INTO warehouse.dimessages (
    MessageSource,
    MessageType,
    MessageText,
    MessageData,
    messagedateandtime,
    batchid
                                  )
SELECT
    'DimTrade',
    'Alert',
    'Invalid trade fee',
    'T_ID = ' || TradeID || ', T_CHRG = ' || Fee,
    now(),
    1
FROM
    td
WHERE
    Fee IS NOT NULL
    AND Fee > TradePrice * Quantity;


-- Create a temporary table to store the aggregated cash transactions for each account and day
DROP TABLE IF EXISTS tmp_cash_aggregation;
CREATE TEMP TABLE tmp_cash_aggregation AS (
    SELECT
        CT_CA_ID AS AccountID,
        CAST(CT_DTS AS DATE) AS TransactionDate,
        SUM(CT_AMT) AS TotalAmount
    FROM
        staging.cash_transaction
    GROUP BY
        CT_CA_ID,
        CAST(CT_DTS AS DATE)
);


  -- Insert into FactCashBalances
    INSERT INTO warehouse.FactCashBalances (
        SK_CustomerID,
        SK_AccountID,
        SK_DateID,
        Cash,
        BatchID
    )
    SELECT
        DA.SK_CustomerID,
        DA.SK_AccountID,
        D.SK_DateID,
        COALESCE(FCB.Cash, 0) + COALESCE(TCA.TotalAmount, 0) AS Cash,
        (SELECT MAX(BatchID) + 1 FROM warehouse.FactCashBalances) AS BatchID
    FROM
        tmp_cash_aggregation TCA
    JOIN
        warehouse.DimAccount DA ON TCA.AccountID = DA.AccountID
    JOIN
        warehouse.DimDate D ON TCA.TransactionDate = D.DateValue
    LEFT JOIN
        warehouse.FactCashBalances FCB ON DA.SK_AccountID = FCB.SK_AccountID AND D.SK_DateID = FCB.SK_DateID
    ;


-- Temporary table to store the result of the transformation
DROP TABLE IF EXISTS fc;
CREATE TEMP TABLE fc AS (
    SELECT
        DM.DM_DATE AS TradeDate,
        DM.DM_S_SYMB AS SecuritySymbol,
        DM.DM_CLOSE AS ClosePrice,
        DM.DM_HIGH AS DayHigh,
        DM.DM_LOW AS DayLow,
        DM.DM_VOL AS Volume,
        DM_SK.SK_SecurityID,
        DM_SK.SK_CompanyID,
        DV.SK_DateID,
        FW.EPS,
        COALESCE(DM.DM_CLOSE / NULLIF(SUM(CAST(FW.EPS AS NUMERIC(7, 2))) OVER(PARTITION BY DM.DM_S_SYMB ORDER BY DM.DM_DATE ROWS BETWEEN 3 PRECEDING AND CURRENT ROW), 0), NULL) AS PERatio,
        COALESCE(DM_SEC.Dividend / NULLIF(DM.DM_CLOSE, 0) * 100, NULL) AS Yield,
        -- Add other columns and transformations based on the specifications
        MAX(DM.DM_HIGH) OVER (PARTITION BY DM.DM_S_SYMB ORDER BY DM.DM_DATE ROWS BETWEEN 51 PRECEDING AND CURRENT ROW) AS FiftyTwoWeekHigh,
        MIN(DM.DM_LOW) OVER (PARTITION BY DM.DM_S_SYMB ORDER BY DM.DM_DATE ROWS BETWEEN 51 PRECEDING AND CURRENT ROW) AS FiftyTwoWeekLow,
        FIRST_VALUE(DM.DM_DATE) OVER (PARTITION BY DM.DM_S_SYMB ORDER BY DM.DM_HIGH DESC, DM.DM_DATE ROWS BETWEEN 51 PRECEDING AND CURRENT ROW) AS SK_FiftyTwoWeekHighDate,
        FIRST_VALUE(DM.DM_DATE) OVER (PARTITION BY DM.DM_S_SYMB ORDER BY DM.DM_LOW ASC, DM.DM_DATE ROWS BETWEEN 51 PRECEDING AND CURRENT ROW) AS SK_FiftyTwoWeekLowDate
    FROM
        staging.daily_market DM
        JOIN warehouse.DimSecurity DM_SK ON DM.DM_S_SYMB = DM_SK.Symbol
        JOIN warehouse.DimDate DV ON DM.DM_DATE = DV.DateValue
        LEFT JOIN staging.FinWire_Fin FW ON DM.DM_DATE = TO_DATE(FW.pts, 'YYYYMMDD') -- Adjust the casting here
        LEFT JOIN warehouse.DimSecurity DM_SEC ON DM.DM_S_SYMB = DM_SEC.Symbol
);

ALTER TABLE warehouse.factmarkethistory
ALTER COLUMN sk_fiftytwoweekhighdate TYPE date
USING (TO_DATE(sk_fiftytwoweekhighdate::text, 'YYYYMMDD'));

ALTER TABLE warehouse.factmarkethistory
ALTER COLUMN sk_fiftytwoweeklowdate TYPE date
    USING (TO_DATE(sk_fiftytwoweeklowdate::text, 'YYYYMMDD'));

-- Insert data into FactMarketHistory
INSERT INTO warehouse.FactMarketHistory (
    SK_SecurityID,
    SK_CompanyID,
    SK_DateID,
    ClosePrice,
    DayHigh,
    DayLow,
    Volume,
    FiftyTwoWeekHigh,
    SK_FiftyTwoWeekHighDate,
    FiftyTwoWeekLow,
    SK_FiftyTwoWeekLowDate,
    PERatio,
    Yield,
    BatchID
)
SELECT
    SK_SecurityID,
    SK_CompanyID,
    SK_DateID,
    ClosePrice,
    DayHigh,
    DayLow,
    Volume,
    FiftyTwoWeekHigh,
    SK_FiftyTwoWeekHighDate,
    FiftyTwoWeekLow,
    SK_FiftyTwoWeekLowDate,
    PERatio,
    Yield,
    -- You may need to replace the value below with the actual BatchID
    1 AS BatchID
FROM
    fc;
INSERT INTO warehouse.dimessages (
    MessageSource,
    MessageType,
    MessageText,
    MessageData,
    messagedateandtime,
    batchid
)
SELECT
    'FactMarketHistory' AS MessageSource,
    'Alert' AS MessageType,
    'No earnings for company' AS MessageText,
    'DM_S_SYMB = ' || DS.Symbol AS MessageData,
    now(),
    1
FROM
    warehouse.DimSecurity DS
WHERE
    NOT EXISTS (
        SELECT 1
        FROM
            staging.finwire_fin FW
        WHERE
            FW.EPS IS NOT NULL
    );

INSERT INTO warehouse.FactWatches(SK_CustomerID, SK_SecurityID, SK_DateID_DatePlaced, SK_DateID_DateRemoved, BatchID)
SELECT
    DC.SK_CustomerID as SK_CustomerID,
    DS.SK_SecurityID as SK_SecurityID,
    DD_Placed.SK_DateID as SK_DateID_DatePlaced,
    NULL AS SK_DateID_DateRemoved,
    1 AS BatchID
FROM staging.Watch_History WH
JOIN warehouse.DimCustomer DC ON WH.W_C_ID::integer = DC.CustomerID::integer
JOIN warehouse.DimSecurity DS ON WH.W_S_SYMB::varchar = DS.Symbol::varchar
JOIN warehouse.DimDate DD_Placed ON WH.W_DTS::date = DD_Placed.DateValue::date
WHERE WH.W_ACTION = 'ACTV';

INSERT INTO warehouse.industry (in_id, in_name, in_sc_id)
SELECT in_id, in_name, in_sc_id
FROM staging.industry;


-- Temporary table to store the result of the transformation
CREATE TEMP TABLE financial_tempo AS (
    SELECT
        DC.SK_CompanyID,
        FW.year::numeric AS fi_year,
        FW.quarter::numeric AS fi_qtr,
        FW.qtr_start_date::date AS fi_qtr_start_date,
        FW.revenue::numeric AS fi_revenue,
        FW.earnings::numeric AS fi_net_earn,
        FW.eps::numeric(10, 2) AS fi_basic_eps,
        FW.diluted_eps::numeric(10, 2) AS fi_dilut_eps,
        FW.margin::numeric(10, 2) AS fi_margin,
        FW.inventory::numeric AS fi_inventory,
        FW.assets::numeric AS fi_assets,
        FW.liabilities::numeric AS fi_liability,
        FW.sh_out::numeric AS fi_out_basic,
        FW.diluted_sh_out::numeric AS fi_out_dilut
    FROM
        staging.finwire_fin FW
        JOIN warehouse.DimCompany DC ON FW.co_name_or_cik = DC.name OR FW.co_name_or_cik = DC.name
);
-- Insert data into Financial
INSERT INTO warehouse.Financial (
    SK_CompanyID,
    fi_year,
    fi_qtr,
    fi_qtr_start_date,
    fi_revenue,
    fi_net_earn,
    fi_basic_eps,
    fi_dilut_eps,
    fi_margin,
    fi_inventory,
    fi_assets,
    fi_liability,
    fi_out_basic,
    fi_out_dilut
)
SELECT
    SK_CompanyID,
    fi_year,
    fi_qtr,
    fi_qtr_start_date,
    fi_revenue,
    fi_net_earn,
    fi_basic_eps,
    fi_dilut_eps,
    fi_margin,
    fi_inventory,
    fi_assets,
    fi_liability,
    fi_out_basic,
    fi_out_dilut
FROM
    financial_tempo;


-- Temporary table to store the result of the transformation
CREATE TEMP TABLE prospect_temp AS (
    SELECT
        p.*,
        -- Generate SK_RecordDateID and SK_UpdateDateID using the current timestamp
        (SELECT sk_dateid FROM warehouse.dimdate WHERE datevalue = CURRENT_DATE) AS sk_recorddateid,
        (SELECT sk_dateid FROM warehouse.dimdate WHERE datevalue = CURRENT_DATE) AS sk_updatedateid,
        CASE
            WHEN dc.sk_customerid IS NOT NULL THEN TRUE
            ELSE FALSE
        END AS iscustomer,
        CASE
            WHEN age > 45 THEN 'Boomer'
            WHEN p.networth > 1000000 OR income > 200000 THEN 'HighValue'
            WHEN numberchildren > 3 OR numbercreditcards > 5 THEN 'Expenses'
            WHEN income < 50000 OR p.creditrating < 600 OR p.networth < 100000 THEN 'MoneyAlert'
            WHEN numbercars > 3 OR numbercreditcards > 7 THEN 'Spender'
            WHEN age < 25 AND p.networth > 1000000 THEN 'Inherited'
        END AS marketingnameplate,
        -- Add other tag logic here
        1 AS batchid -- Adjust as per your section 4.4.2.4.5.15.2 description
    FROM
        staging.prospect p
        LEFT JOIN warehouse.dimcustomer dc ON
            UPPER(p.firstname) = UPPER(dc.firstname) AND
            UPPER(p.lastname) = UPPER(dc.lastname) AND
            UPPER(p.addressline1) = UPPER(dc.addressline1) AND
            UPPER(p.addressline2) = UPPER(dc.addressline2) AND
            p.postalcode = dc.postalcode
);
CREATE TABLE warehouse.prospect (
    agencyid          VARCHAR(255) NOT NULL,
    lastname          VARCHAR(255) NOT NULL,
    firstname         VARCHAR(255) NOT NULL,
    middleinitial     VARCHAR(1),
    gender            VARCHAR(1),
    addressline1      VARCHAR(255),
    addressline2      VARCHAR(255),
    postalcode        VARCHAR(12),
    city              VARCHAR(255),
    state             VARCHAR(255),
    country           VARCHAR(255),
    phone             VARCHAR(20),
    income            NUMERIC(15, 2),
    numbercars        INTEGER,
    numberchildren    INTEGER,
    maritalstatus     VARCHAR(10),
    age               INTEGER,
    creditrating      INTEGER,
    ownorrentflag     VARCHAR(1),
    employer          VARCHAR(255),
    numbercreditcards INTEGER,
    networth          NUMERIC(15, 2),
    sk_recorddateid   INTEGER,
    sk_updatedateid   INTEGER,
    iscustomer        BOOLEAN, -- Changed data type to boolean
    marketingnameplate VARCHAR(255),
    batchid           INTEGER
);
-- Insert data into Prospect
INSERT INTO warehouse.prospect (
    agencyid,
    lastname,
    firstname,
    middleinitial,
    gender,
    addressline1,
    addressline2,
    postalcode,
    city,
    state,
    country,
    phone,
    income,
    numbercars,
    numberchildren,
    maritalstatus,
    age,
    creditrating,
    ownorrentflag,
    employer,
    numbercreditcards,
    networth,
    sk_recorddateid,
    sk_updatedateid,
    iscustomer,
    marketingnameplate,
    batchid
)
SELECT
    agencyid,
    lastname,
    firstname,
    middleinitial,
    gender,
    addressline1,
    addressline2,
    postalcode,
    city,
    state,
    country,
    phone,
    income,
    numbercars,
    numberchildren,
    maritalstatus,
    age,
    creditrating,
    ownorrentflag,
    employer,
    numbercreditcards,
    networth,
    sk_recorddateid,
    sk_updatedateid,
    iscustomer,
    marketingnameplate,
    batchid
FROM
    prospect_temp;

-- Insert a status message into DimMessages
INSERT INTO warehouse.dimessages (MessageSource, MessageType, MessageText, MessageData,messagedateandtime,batchid)
VALUES ('Prospect', 'Status', 'Inserted rows', 'Number of rows: ' || (SELECT COUNT(*) FROM warehouse.prospect AS newRowsCount),now(),1);

DROP TABLE IF EXISTS  factholdings_temp;
CREATE TEMP TABLE factholdings_temp AS (
    SELECT
        dt.SK_CustomerID,
        dt.SK_AccountID,
        dt.SK_SecurityID,
        dt.SK_CompanyID,
        dt.bidprice AS CurrentPrice,
        dt.SK_CloseDateID AS SK_DateID,
        dt.SK_CloseTimeID AS SK_TimeID,
        hh.HH_T_ID AS TradeId,
        hh.HH_H_T_ID AS CurrentTradeID,
        hh.HH_AFTER_QTY AS CurrentHolding,
        dt.BatchID
    FROM
        staging.holding_history hh
    JOIN
        warehouse.DimTrade dt ON hh.HH_T_ID = dt.TradeID
);

-- Insert data into FactHoldings
INSERT INTO warehouse.FactHoldings (
    SK_CustomerID,
    SK_AccountID,
    SK_SecurityID,
    SK_CompanyID,
    CurrentPrice,
    SK_DateID,
    SK_TimeID,
    TradeId,
    CurrentTradeID,
    CurrentHolding,
    BatchID
)
SELECT
    SK_CustomerID,
    SK_AccountID,
    SK_SecurityID,
    SK_CompanyID,
    CurrentPrice,
    SK_DateID,
    SK_TimeID,
    TradeId,
    CurrentTradeID,
    CurrentHolding,
    BatchID
FROM
    factholdings_temp;

-- Insert records into DimMessages if no holdings found
INSERT INTO warehouse.dimessages (MessageSource, MessageType, MessageText, MessageData, MessageDateAndTime, BatchID)
SELECT
    'FactHoldings',
    'Alert',
    'No holdings found',
    '',
    NOW(),
    1
WHERE
    NOT EXISTS (SELECT 1 FROM factholdings_temp);