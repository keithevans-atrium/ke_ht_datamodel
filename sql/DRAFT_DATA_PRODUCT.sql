-- =====================================================================
-- Black Diamond Silver Curated Data Products
-- Modular Data Product Model: DIM / FACT / BRIDGE physical schema
-- Generated from: Black Diamond Data Product Definitions (Bronze to Silver)
-- ANSI SQL DDL for dbschema / general schema-visualization tooling
-- =====================================================================

-- ---------------------------------------------------------------------
-- Supporting reference dimensions (referenced as FK targets throughout)
-- ---------------------------------------------------------------------

CREATE TABLE DIM_DATE (
    date_key            NUMBER          NOT NULL,
    calendar_date        DATE            NOT NULL,
    year                NUMBER(4,0),
    month               NUMBER(2,0),
    day                 NUMBER(2,0),
    CONSTRAINT PK_DIM_DATE PRIMARY KEY (date_key)
);

CREATE TABLE DIM_DATA_PROVIDER (
    data_provider_key       NUMBER          NOT NULL,
    firm_id                 NUMBER,
    data_provider_id        NUMBER,
    data_provider_name      VARCHAR,
    created_ts              TIMESTAMP,
    last_updated_ts         TIMESTAMP,
    CONSTRAINT PK_DIM_DATA_PROVIDER PRIMARY KEY (data_provider_key),
    CONSTRAINT UQ_DIM_DATA_PROVIDER UNIQUE (firm_id, data_provider_id)
);

CREATE TABLE DIM_REP_CODE (
    rep_code_key            NUMBER          NOT NULL,
    firm_id                 NUMBER,
    rep_code_id             NUMBER,
    rep_code_name           VARCHAR,
    rep_code_external_id    VARCHAR,
    data_provider_key       NUMBER,
    created_ts              TIMESTAMP,
    last_updated_ts         TIMESTAMP,
    CONSTRAINT PK_DIM_REP_CODE PRIMARY KEY (rep_code_key),
    CONSTRAINT UQ_DIM_REP_CODE UNIQUE (firm_id, rep_code_id),
    CONSTRAINT FK_REPCODE_PROVIDER FOREIGN KEY (data_provider_key)
        REFERENCES DIM_DATA_PROVIDER (data_provider_key)
);

CREATE TABLE DIM_PROCESS_TYPE (
    process_type_key        NUMBER          NOT NULL,
    process_type_id         NUMBER,
    process_type_name       VARCHAR,
    CONSTRAINT PK_DIM_PROCESS_TYPE PRIMARY KEY (process_type_key),
    CONSTRAINT UQ_DIM_PROCESS_TYPE UNIQUE (process_type_id)
);

-- ---------------------------------------------------------------------
-- DP-01  Account Master  (DIM_ACCOUNT)
-- Bronze: BRONZE.CDA_BD_ACCOUNTS, BRONZE.CDA_BD_DATA_PROVIDERS
-- Grain: one row per firm_id + account_id
-- ---------------------------------------------------------------------

CREATE TABLE DIM_ACCOUNT (
    account_key             NUMBER          NOT NULL,
    firm_id                 NUMBER,
    account_id              NUMBER,
    account_external_id     VARCHAR,
    data_provider_key       NUMBER,
    account_number          VARCHAR,
    account_name            VARCHAR,
    custodian               VARCHAR,
    account_type            VARCHAR,
    tax_status              VARCHAR,
    tax_methodology         VARCHAR,
    is_accord               BOOLEAN,
    start_date              DATE,
    as_of_date              DATE,
    data_as_of_date         DATE,
    closed_date             DATE,
    is_open                 BOOLEAN,
    created_ts              TIMESTAMP,
    last_updated_ts         TIMESTAMP,
    record_effective_ts     TIMESTAMP,
    record_end_ts           TIMESTAMP,
    is_current               BOOLEAN,
    CONSTRAINT PK_DIM_ACCOUNT PRIMARY KEY (account_key),
    CONSTRAINT UQ_DIM_ACCOUNT UNIQUE (firm_id, account_id),
    CONSTRAINT FK_ACCOUNT_PROVIDER FOREIGN KEY (data_provider_key)
        REFERENCES DIM_DATA_PROVIDER (data_provider_key)
);

-- ---------------------------------------------------------------------
-- DP-02  Asset Master  (DIM_ASSET)
-- Bronze: BRONZE.CDA_BD_ASSETS, CDA_BD_CHARACTERISTICS,
--         CDA_BD_FIRM_ASSET_CHARACTERISTICS, CDA_BD_ASSET_UDFS
-- Grain: one row per firm_id + asset_id
-- ---------------------------------------------------------------------

CREATE TABLE DIM_ASSET (
    asset_key               NUMBER          NOT NULL,
    firm_id                 NUMBER,
    asset_id                NUMBER,
    asset_name              VARCHAR,
    ticker                  VARCHAR,
    alternative_identifier  VARCHAR,
    cusip                   VARCHAR,
    issue_type              VARCHAR,
    sec_asset_type          VARCHAR,
    class_id                NUMBER,
    class_name              VARCHAR,
    super_class_id          NUMBER,
    super_class_name        VARCHAR,
    cap_segment_id          NUMBER,
    cap_segment_name        VARCHAR,
    sector_segment_id       NUMBER,
    sector_segment_name     VARCHAR,
    is_cash                 BOOLEAN,
    is_cash_equivalent      BOOLEAN,
    is_money_market         BOOLEAN,
    is_archived             BOOLEAN,
    price_factor            NUMBER(18,8),
    created_ts              TIMESTAMP,
    last_updated_ts         TIMESTAMP,
    CONSTRAINT PK_DIM_ASSET PRIMARY KEY (asset_key),
    CONSTRAINT UQ_DIM_ASSET UNIQUE (firm_id, asset_id)
);

-- ---------------------------------------------------------------------
-- DP-03  Account-Asset Holding Master  (DIM_HOLDING)
-- Relationship component connecting DIM_ACCOUNT and DIM_ASSET
-- Bronze: BRONZE.CDA_BD_HOLDINGS
-- Grain: one row per firm_id + holding_id
-- ---------------------------------------------------------------------

CREATE TABLE DIM_HOLDING (
    holding_key             NUMBER          NOT NULL,
    firm_id                 NUMBER,
    holding_id              NUMBER,
    holding_external_id     VARCHAR,
    account_key             NUMBER,
    asset_key               NUMBER,
    account_id              NUMBER,
    asset_id                NUMBER,
    supervised_flag         BOOLEAN,
    billable_flag           BOOLEAN,
    discretionary_flag      BOOLEAN,
    holding_data_as_of_date DATE,
    created_ts              TIMESTAMP,
    last_updated_ts         TIMESTAMP,
    CONSTRAINT PK_DIM_HOLDING PRIMARY KEY (holding_key),
    CONSTRAINT UQ_DIM_HOLDING UNIQUE (firm_id, holding_id),
    CONSTRAINT FK_HOLDING_ACCOUNT FOREIGN KEY (account_key)
        REFERENCES DIM_ACCOUNT (account_key),
    CONSTRAINT FK_HOLDING_ASSET FOREIGN KEY (asset_key)
        REFERENCES DIM_ASSET (asset_key)
);

-- ---------------------------------------------------------------------
-- DP-04  Daily Position Snapshot  (FACT_DAILY_POSITION)
-- Bronze: BRONZE.CDA_BD_DAILY_HOLDING_VALUES
-- Grain: one row per firm_id + holding_id + return_date
-- ---------------------------------------------------------------------

CREATE TABLE FACT_DAILY_POSITION (
    daily_position_key      NUMBER          NOT NULL,
    date_key                NUMBER,
    holding_key             NUMBER,
    account_key             NUMBER,
    asset_key               NUMBER,
    firm_id                 NUMBER,
    holding_id              NUMBER,
    return_date             DATE,
    beginning_market_value  NUMBER(38,8),
    ending_market_value     NUMBER(38,8),
    additions               NUMBER(38,8),
    withdrawals             NUMBER(38,8),
    income                  NUMBER(38,8),
    fees                    NUMBER(38,8),
    units                   NUMBER(38,12),
    accrual                 NUMBER(38,8),
    previous_accrual        NUMBER(38,8),
    net_external_flow       NUMBER(38,8),
    net_activity            NUMBER(38,8),
    source_created_ts       TIMESTAMP,
    source_last_updated_ts  TIMESTAMP,
    load_ts                 TIMESTAMP,
    CONSTRAINT PK_FACT_DAILY_POSITION PRIMARY KEY (daily_position_key),
    CONSTRAINT UQ_FACT_DAILY_POSITION UNIQUE (firm_id, holding_id, return_date),
    CONSTRAINT FK_DPOS_DATE FOREIGN KEY (date_key)
        REFERENCES DIM_DATE (date_key),
    CONSTRAINT FK_DPOS_HOLDING FOREIGN KEY (holding_key)
        REFERENCES DIM_HOLDING (holding_key),
    CONSTRAINT FK_DPOS_ACCOUNT FOREIGN KEY (account_key)
        REFERENCES DIM_ACCOUNT (account_key),
    CONSTRAINT FK_DPOS_ASSET FOREIGN KEY (asset_key)
        REFERENCES DIM_ASSET (asset_key)
);

-- ---------------------------------------------------------------------
-- DP-05  Transaction Activity  (FACT_TRANSACTION)
-- Bronze: BRONZE.CDA_BD_TRANSACTIONS
-- Grain: one row per firm_id + transaction_id
-- ---------------------------------------------------------------------

CREATE TABLE FACT_TRANSACTION (
    transaction_key         NUMBER          NOT NULL,
    firm_id                 NUMBER,
    transaction_id          NUMBER,
    account_key             NUMBER,
    holding_key             NUMBER,
    asset_key               NUMBER,
    return_date_key         NUMBER,
    trade_date_key          NUMBER,
    settle_date_key         NUMBER,
    entry_date_key          NUMBER,
    transaction_type        VARCHAR,
    transaction_sub_type    VARCHAR,
    action                  VARCHAR,
    description             VARCHAR,
    external_flow_affect    NUMBER(38,8),
    income_affect           NUMBER(38,8),
    fee_affect              NUMBER(38,8),
    cash_affect             NUMBER(38,8),
    units                   NUMBER(38,12),
    market_value            NUMBER(38,8),
    price                   NUMBER(38,12),
    subcode                 VARCHAR,
    transcode               VARCHAR,
    activity_category       VARCHAR,
    flow_direction          VARCHAR,
    source_last_updated_ts  TIMESTAMP,
    load_ts                 TIMESTAMP,
    CONSTRAINT PK_FACT_TRANSACTION PRIMARY KEY (transaction_key),
    CONSTRAINT UQ_FACT_TRANSACTION UNIQUE (firm_id, transaction_id),
    CONSTRAINT FK_TXN_ACCOUNT FOREIGN KEY (account_key)
        REFERENCES DIM_ACCOUNT (account_key),
    CONSTRAINT FK_TXN_HOLDING FOREIGN KEY (holding_key)
        REFERENCES DIM_HOLDING (holding_key),
    CONSTRAINT FK_TXN_ASSET FOREIGN KEY (asset_key)
        REFERENCES DIM_ASSET (asset_key),
    CONSTRAINT FK_TXN_RETURN_DATE FOREIGN KEY (return_date_key)
        REFERENCES DIM_DATE (date_key),
    CONSTRAINT FK_TXN_TRADE_DATE FOREIGN KEY (trade_date_key)
        REFERENCES DIM_DATE (date_key),
    CONSTRAINT FK_TXN_SETTLE_DATE FOREIGN KEY (settle_date_key)
        REFERENCES DIM_DATE (date_key),
    CONSTRAINT FK_TXN_ENTRY_DATE FOREIGN KEY (entry_date_key)
        REFERENCES DIM_DATE (date_key)
);

-- ---------------------------------------------------------------------
-- DP-06  Open Tax Lot Snapshot  (FACT_TAX_LOT_SNAPSHOT / FACT_TAX_LOT_HISTORY)
-- Bronze: BRONZE.CDA_BD_UGL_DATA
-- Grain: firm_id + holding_id + ugl_data_id + as-of/validity period
-- ---------------------------------------------------------------------

CREATE TABLE FACT_TAX_LOT_HISTORY (
    tax_lot_history_key     NUMBER          NOT NULL,
    holding_key             NUMBER,
    account_key             NUMBER,
    asset_key               NUMBER,
    firm_id                 NUMBER,
    holding_id              NUMBER,
    ugl_data_id             NUMBER,
    open_date_key           NUMBER,
    start_date_key          NUMBER,
    end_date_key            NUMBER,
    start_date              DATE,
    end_date                DATE,
    opening_units           NUMBER(38,12),
    opening_cost_basis      NUMBER(38,8),
    current_units           NUMBER(38,12),
    cost_basis              NUMBER(38,8),
    adjusted_cost_basis     NUMBER(38,8),
    source_last_updated_ts  TIMESTAMP,
    load_ts                 TIMESTAMP,
    CONSTRAINT PK_FACT_TAX_LOT_HISTORY PRIMARY KEY (tax_lot_history_key),
    CONSTRAINT UQ_FACT_TAX_LOT_HISTORY UNIQUE (firm_id, holding_id, ugl_data_id, start_date_key),
    CONSTRAINT FK_TLH_HOLDING FOREIGN KEY (holding_key)
        REFERENCES DIM_HOLDING (holding_key),
    CONSTRAINT FK_TLH_ACCOUNT FOREIGN KEY (account_key)
        REFERENCES DIM_ACCOUNT (account_key),
    CONSTRAINT FK_TLH_ASSET FOREIGN KEY (asset_key)
        REFERENCES DIM_ASSET (asset_key),
    CONSTRAINT FK_TLH_OPEN_DATE FOREIGN KEY (open_date_key)
        REFERENCES DIM_DATE (date_key),
    CONSTRAINT FK_TLH_START_DATE FOREIGN KEY (start_date_key)
        REFERENCES DIM_DATE (date_key),
    CONSTRAINT FK_TLH_END_DATE FOREIGN KEY (end_date_key)
        REFERENCES DIM_DATE (date_key)
);

CREATE TABLE FACT_TAX_LOT_SNAPSHOT (
    tax_lot_snapshot_key    NUMBER          NOT NULL,
    holding_key             NUMBER,
    account_key             NUMBER,
    asset_key               NUMBER,
    firm_id                 NUMBER,
    ugl_data_id             NUMBER,
    as_of_date_key          NUMBER,
    open_date_key           NUMBER,
    start_date              DATE,
    end_date                DATE,
    opening_units           NUMBER(38,12),
    opening_cost_basis      NUMBER(38,8),
    current_units           NUMBER(38,12),
    cost_basis              NUMBER(38,8),
    adjusted_cost_basis     NUMBER(38,8),
    source_last_updated_ts  TIMESTAMP,
    load_ts                 TIMESTAMP,
    CONSTRAINT PK_FACT_TAX_LOT_SNAPSHOT PRIMARY KEY (tax_lot_snapshot_key),
    CONSTRAINT UQ_FACT_TAX_LOT_SNAPSHOT UNIQUE (as_of_date_key, firm_id, holding_key, ugl_data_id),
    CONSTRAINT FK_TLS_HOLDING FOREIGN KEY (holding_key)
        REFERENCES DIM_HOLDING (holding_key),
    CONSTRAINT FK_TLS_ACCOUNT FOREIGN KEY (account_key)
        REFERENCES DIM_ACCOUNT (account_key),
    CONSTRAINT FK_TLS_ASSET FOREIGN KEY (asset_key)
        REFERENCES DIM_ASSET (asset_key),
    CONSTRAINT FK_TLS_AS_OF_DATE FOREIGN KEY (as_of_date_key)
        REFERENCES DIM_DATE (date_key),
    CONSTRAINT FK_TLS_OPEN_DATE FOREIGN KEY (open_date_key)
        REFERENCES DIM_DATE (date_key)
);

-- ---------------------------------------------------------------------
-- DP-07  Monthly Billing Snapshot  (FACT_MONTHLY_BILLING)
-- Bronze: BRONZE.CDA_BD_MONTHLY_BILLABLE_VALUES
-- Grain: one row per firm_id + account_id + year + month
-- ---------------------------------------------------------------------

CREATE TABLE FACT_MONTHLY_BILLING (
    monthly_billing_key       NUMBER          NOT NULL,
    billing_month_key         NUMBER,
    billed_through_date_key   NUMBER,
    account_key               NUMBER,
    firm_id                   NUMBER,
    account_id                NUMBER,
    year                      NUMBER(4,0),
    month                     NUMBER(2,0),
    average_daily_balance     NUMBER(38,8),
    held_day_count            NUMBER,
    business_day_count        NUMBER,
    beginning_market_value    NUMBER(38,8),
    ending_market_value       NUMBER(38,8),
    billed_through_date       DATE,
    source_last_updated_ts    TIMESTAMP,
    load_ts                   TIMESTAMP,
    CONSTRAINT PK_FACT_MONTHLY_BILLING PRIMARY KEY (monthly_billing_key),
    CONSTRAINT UQ_FACT_MONTHLY_BILLING UNIQUE (firm_id, account_id, year, month),
    CONSTRAINT FK_BILL_MONTH_DATE FOREIGN KEY (billing_month_key)
        REFERENCES DIM_DATE (date_key),
    CONSTRAINT FK_BILL_THROUGH_DATE FOREIGN KEY (billed_through_date_key)
        REFERENCES DIM_DATE (date_key),
    CONSTRAINT FK_BILL_ACCOUNT FOREIGN KEY (account_key)
        REFERENCES DIM_ACCOUNT (account_key)
);

-- ---------------------------------------------------------------------
-- DP-08  Account Rep-Code Assignment  (BRIDGE_ACCOUNT_REP_CODE)
-- Bronze: BRONZE.CDA_BD_ACCOUNT_REP_CODES, CDA_BD_REP_CODES, CDA_BD_DATA_PROVIDERS
-- Grain: one row per firm_id + account_id + rep_code_id
-- ---------------------------------------------------------------------

CREATE TABLE BRIDGE_ACCOUNT_REP_CODE (
    account_key             NUMBER          NOT NULL,
    rep_code_key            NUMBER          NOT NULL,
    data_provider_key       NUMBER,
    firm_id                 NUMBER,
    account_id              NUMBER,
    rep_code_id             NUMBER,
    allocation_weight       NUMBER(18,8),
    is_primary              BOOLEAN,
    effective_date          DATE,
    end_date                DATE,
    is_current              BOOLEAN,
    source_last_updated_ts  TIMESTAMP,
    load_ts                 TIMESTAMP,
    CONSTRAINT PK_BRIDGE_ACCOUNT_REP_CODE PRIMARY KEY (account_key, rep_code_key),
    CONSTRAINT UQ_BRIDGE_ACCOUNT_REP_CODE UNIQUE (firm_id, account_id, rep_code_id),
    CONSTRAINT FK_BARC_ACCOUNT FOREIGN KEY (account_key)
        REFERENCES DIM_ACCOUNT (account_key),
    CONSTRAINT FK_BARC_REP_CODE FOREIGN KEY (rep_code_key)
        REFERENCES DIM_REP_CODE (rep_code_key),
    CONSTRAINT FK_BARC_PROVIDER FOREIGN KEY (data_provider_key)
        REFERENCES DIM_DATA_PROVIDER (data_provider_key)
);

-- ---------------------------------------------------------------------
-- DP-09  Data Readiness and Reconciliation Status  (FACT_RECONCILIATION_STATUS)
-- Bronze: BRONZE.CDA_BD_PROCESS_STATE, BRONZE.CDA_BD_DATA_PROVIDERS
-- Grain: one row per firm_id + data_provider_id + return_date + process_type_id
-- ---------------------------------------------------------------------

CREATE TABLE FACT_RECONCILIATION_STATUS (
    reconciliation_status_key      NUMBER          NOT NULL,
    firm_id                        NUMBER,
    data_provider_key              NUMBER,
    return_date_key                NUMBER,
    process_type_key               NUMBER,
    data_format_id                 NUMBER,
    complete_ts                    TIMESTAMP,
    is_complete                    BOOLEAN,
    provider_is_active_recon       BOOLEAN,
    provider_is_active_cost_basis  BOOLEAN,
    days_behind                    NUMBER,
    source_last_updated_ts         TIMESTAMP,
    load_ts                        TIMESTAMP,
    CONSTRAINT PK_FACT_RECONCILIATION_STATUS PRIMARY KEY (reconciliation_status_key),
    CONSTRAINT UQ_FACT_RECONCILIATION_STATUS UNIQUE (firm_id, data_provider_key, return_date_key, process_type_key),
    CONSTRAINT FK_RECON_PROVIDER FOREIGN KEY (data_provider_key)
        REFERENCES DIM_DATA_PROVIDER (data_provider_key),
    CONSTRAINT FK_RECON_RETURN_DATE FOREIGN KEY (return_date_key)
        REFERENCES DIM_DATE (date_key),
    CONSTRAINT FK_RECON_PROCESS_TYPE FOREIGN KEY (process_type_key)
        REFERENCES DIM_PROCESS_TYPE (process_type_key)
);

-- =====================================================================
-- End of Silver modular data product schema (DP-01 through DP-09)
-- =====================================================================