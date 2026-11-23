
/*
============================================================
PROJECT: RETAIL SALES DATA ANALYSIS
FILE: 03_data_cleaning.sql
DATABASE: PostgreSQL

PURPOSE:
Create a cleaned retail sales table and transform raw
data into appropriate data types for business analysis.

DATA CLEANING RULES:
1. Convert sale_date from TEXT to DATE.
2. Standardize category and region values.
3. Replace missing category/region with 'Unknown'.
4. Convert invalid numeric values to NULL.
5. Convert valid sales and profit to NUMERIC(10,2).
6. Convert valid whole-number quantity to INTEGER.
7. Flag records requiring further review.
8. Prevent duplicate insertion of source records.

ASSUMPTIONS:
- Source dates follow M/D/YY format.
- Date values have been validated during profiling.
- Sales and quantity should be greater than zero.
- Negative profit is allowed as a business loss.
- Source numeric values fit their target column ranges.

No records are deleted from the raw table.
============================================================
*/


/*
------------------------------------------------------------
STEP 1: CREATE CLEANED TABLE
------------------------------------------------------------
*/

CREATE TABLE IF NOT EXISTS retail.retail_sales_upd (

    sale_id BIGSERIAL PRIMARY KEY,

    -- Reference to original source record
    org_id_number BIGINT NOT NULL UNIQUE,

    sale_date DATE NOT NULL,

    category VARCHAR(100),

    sales NUMERIC(10,2),

    quantity INTEGER,

    profit NUMERIC(10,2),

    region VARCHAR(20),

    data_quality_status VARCHAR(20),

    -- Restrict category to approved values
    CONSTRAINT valid_catgory CHECK (
        category IN (
            'Books',
            'Clothing',
            'Electronics',
            'Home Goods',
            'Sports',
            'Unknown'
        )
    ),

    -- Restrict region to approved values
    CONSTRAINT Valid_Region CHECK (
        region IN (
            'East',
            'West',
            'North',
            'South',
            'Unknown'
        )
    ),

    -- Restrict data quality status
    CONSTRAINT valid_data_quality_status CHECK (
        data_quality_status IN ('VALID', 'REVIEW')
    )
);


/*
------------------------------------------------------------
STEP 2: CLEAN AND LOAD DATA
------------------------------------------------------------
Objective:
Transform raw data into standardized, analysis-ready
records while retaining records requiring investigation.
*/

INSERT INTO retail.retail_sales_upd (

    org_id_number,
    sale_date,
    category,
    sales,
    quantity,
    profit,
    region,
    data_quality_status

)

SELECT

    id_number,

    -- 2.1 Convert date from M/D/YY to DATE
    TO_DATE(TRIM(sale_date), 'MM/DD/YY'),

    -- 2.2 Standardize category
    CASE
        WHEN NULLIF(TRIM(category), '') IS NULL
          OR LOWER(TRIM(category)) IN ('nan', 'nan?', 'null')
        THEN 'Unknown'
        ELSE INITCAP(TRIM(category))
    END,

    -- 2.3 Clean and convert sales
    CASE
        WHEN NULLIF(TRIM(sales), '') IS NULL
          OR TRIM(sales) !~ '^-?\d+(\.\d+)?$'
        THEN NULL
        ELSE TRIM(sales)::NUMERIC(10,2)
    END,

    -- 2.4 Clean and convert quantity
    CASE
        WHEN NULLIF(TRIM(quantity), '') IS NULL
          OR TRIM(quantity) !~ '^-?\d+$'
        THEN NULL
        ELSE TRIM(quantity)::INTEGER
    END,

    -- 2.5 Clean and convert profit
    CASE
        WHEN NULLIF(TRIM(profit), '') IS NULL
          OR TRIM(profit) !~ '^-?\d+(\.\d+)?$'
        THEN NULL
        ELSE TRIM(profit)::NUMERIC(10,2)
    END,

    -- 2.6 Standardize region
    CASE
        WHEN NULLIF(TRIM(region), '') IS NULL
          OR LOWER(TRIM(region)) IN ('nan', 'nan?', 'null')
        THEN 'Unknown'
        ELSE INITCAP(TRIM(region))
    END,

    /*
    2.7 Assign data quality status

    REVIEW:
    - Missing or invalid category/region
    - Missing or non-numeric sales/quantity/profit
    - Non-positive sales or quantity

    VALID:
    - All required checks pass
    */

    CASE
        WHEN NULLIF(TRIM(category), '') IS NULL
          OR LOWER(TRIM(category)) IN ('nan', 'nan?', 'null')

          OR NULLIF(TRIM(region), '') IS NULL
          OR LOWER(TRIM(region)) IN ('nan', 'nan?', 'null')

          OR NULLIF(TRIM(sales), '') IS NULL
          OR TRIM(sales) !~ '^-?\d+(\.\d+)?$'

          OR NULLIF(TRIM(quantity), '') IS NULL
          OR TRIM(quantity) !~ '^-?\d+$'

          OR NULLIF(TRIM(profit), '') IS NULL
          OR TRIM(profit) !~ '^-?\d+(\.\d+)?$'

          OR CASE
                WHEN TRIM(sales) ~ '^-?\d+(\.\d+)?$'
                THEN TRIM(sales)::NUMERIC <= 0
                ELSE FALSE
             END

          OR CASE
                WHEN TRIM(quantity) ~ '^-?\d+$'
                THEN TRIM(quantity)::NUMERIC <= 0
                ELSE FALSE
             END

        THEN 'REVIEW'
        ELSE 'VALID'
    END

FROM retail.retail_sales_Org

-- Prevent inserting the same source record twice
ON CONFLICT (org_id_number) DO NOTHING;


/*
------------------------------------------------------------
STEP 3: POST-LOAD VALIDATION
------------------------------------------------------------
Objective:
Verify successful loading, data-quality classifications,
and consistency between source and cleaned datasets.
*/


-- 3.1 Preview cleaned data

SELECT *
FROM retail.retail_sales_upd
ORDER BY sale_id
LIMIT 20;


-- 3.2 Compare raw and cleaned record counts

SELECT
    (SELECT COUNT(*)
     FROM retail.retail_sales_Org) AS raw_records,

    (SELECT COUNT(*)
     FROM retail.retail_sales_upd) AS cleaned_records;


-- 3.3 Count records by data-quality status

SELECT
    data_quality_status,
    COUNT(*) AS record_cnt
FROM retail.retail_sales_upd
GROUP BY data_quality_status
ORDER BY record_cnt DESC;


-- 3.4 Review flagged records

SELECT *
FROM retail.retail_sales_upd
WHERE data_quality_status = 'REVIEW'
ORDER BY org_id_number;


-- 3.5 Verify no duplicate source IDs

SELECT
    org_id_number,
    COUNT(*) AS duplicate_cnt
FROM retail.retail_sales_upd
GROUP BY org_id_number
HAVING COUNT(*) > 1;


/*
============================================================
END OF DATA CLEANING AND TRANSFORMATION

NEXT STEP:
Validate cleaned records and perform business analysis.
============================================================
*/
