
/*
=========================================================
Project: Retail Sales Data Analysis
File: 01_create_schema_and_raw_table.sql
Database: PostgreSQL

Purpose:
1. Create a dedicated schema for retail sales data.
2. Create a raw table for importing CSV data.
3. Preserve original source values for data cleaning.
4. Validate the imported dataset.

Expected records: 1,825
=========================================================
*/


-- STEP 1: Create schema
-- IF NOT EXISTS prevents an error if the schema already exists.

CREATE SCHEMA IF NOT EXISTS retail;


-- STEP 2: Verify schema creation

SELECT
    schema_name,
    schema_owner
FROM information_schema.schemata
WHERE schema_name = 'retail';


-- STEP 3: Check database and user

SELECT current_database() AS database_name;

SELECT current_user AS database_user;


-- STEP 4: Create raw sales table
-- All source columns are stored as TEXT to preserve
-- original CSV values before data cleaning.

CREATE TABLE IF NOT EXISTS retail.retail_sales_org (
    id_number BIGSERIAL PRIMARY KEY,
    sale_date TEXT,
    category TEXT,
    sales TEXT,
    quantity TEXT,
    profit TEXT,
    region TEXT,
    insert_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

/*
=========================================================
STEP 5: Import CSV Data

Method: pgAdmin Import/Export Data

1. Open pgAdmin and connect to the database.
2. Navigate to:
   Schemas > retail > Tables > retail_sales_org
3. Right-click the table and select Import/Export Data.
4. Choose Import.
5. Select the source CSV file.
6. Set:
   Format: CSV
   Header: Yes
   Delimiter: Comma (,)
7. In the Columns tab, select only:
   sale_date, category, sales, quantity, profit, region

8. Exclude:
   id_number   (automatically generated)
   insert_date (automatically generated)

9. Click OK to import.

Expected rows: 1,825

Note: Import only once into an empty raw table.
Reimporting the same CSV will create duplicate records.
=========================================================
*/


-- STEP 6: Validate imported record count

SELECT COUNT(*) AS total_records
FROM retail.retail_sales_org;


-- STEP 7: Preview imported data

SELECT *
FROM retail.retail_sales_org
ORDER BY id_number
LIMIT 10;


-- STEP 8: Check column definitions

SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'retail'
  AND table_name = 'retail_sales_org'
ORDER BY ordinal_position;
