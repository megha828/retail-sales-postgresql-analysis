
/*
============================================================
PROJECT: RETAIL SALES DATA ANALYSIS
FILE: 02_data_profiling.sql
DATABASE: PostgreSQL

PURPOSE:
Assess the quality and consistency of the raw retail sales
dataset before performing data cleaning and transformation.

DATA PROFILING OBJECTIVES:
1. Examine the raw dataset and total record count.
2. Analyze category and region distributions.
3. Identify missing and invalid values.
4. Detect inconsistent text formatting.
5. Identify non-numeric values in numeric columns.
6. Investigate non-positive sales and quantity values.
7. Identify negative profit values.
8. Validate date formats.
9. Detect potential duplicate records.

NOTE:
All queries are read-only.
No source records are modified or deleted.
============================================================
*/
0p00

/*
------------------------------------------------------------
CHECK 1: INITIAL DATA EXPLORATION
------------------------------------------------------------
Objective:
Inspect sample records and verify the total number of rows
in the imported dataset.
*/

-- 1.1 Preview raw data

SELECT *
FROM retail.retail_sales_Org
ORDER BY id_number
LIMIT 20;


-- 1.2 Count total records

SELECT
    COUNT(*) AS total_records
FROM retail.retail_sales_Org;

-- Expected result: 1,825 records


/*
------------------------------------------------------------
CHECK 2: CATEGORY DISTRIBUTION
------------------------------------------------------------
Objective:
Identify distinct product categories and their frequency.

This helps detect:
- Unexpected category values
- Missing or invalid category labels
- Potential spelling or capitalization inconsistencies
*/

-- 2.1 Original category distribution

SELECT
    category,
    COUNT(*) AS record_cnt
FROM retail.retail_sales_Org
GROUP BY category
ORDER BY record_cnt DESC;


-- 2.2 Normalized category distribution
-- Compare with the original distribution to identify
-- differences caused by spaces or capitalization.

SELECT
    LOWER(TRIM(category)) AS normalized_category,
    COUNT(*) AS record_cnt
FROM retail.retail_sales_Org
GROUP BY LOWER(TRIM(category))
ORDER BY record_cnt DESC;


/*
------------------------------------------------------------
CHECK 3: REGION DISTRIBUTION
------------------------------------------------------------
Objective:
Identify distinct geographical regions and their frequency.

Compare original and normalized values to detect
inconsistent capitalization or extra spaces.
*/

-- 3.1 Original region distribution

SELECT
    region,
    COUNT(*) AS record_cnt
FROM retail.retail_sales_Org
GROUP BY region
ORDER BY record_cnt DESC;


-- 3.2 Normalized region distribution

SELECT
    LOWER(TRIM(region)) AS normalized_region,
    COUNT(*) AS record_cnt
FROM retail.retail_sales_Org
GROUP BY LOWER(TRIM(region))
ORDER BY record_cnt DESC;


/*
------------------------------------------------------------
CHECK 4: MISSING AND INVALID VALUE ASSESSMENT
------------------------------------------------------------
Objective:
Identify missing or invalid values across all source fields.

Missing-value conditions:
- SQL NULL
- Empty strings
- Whitespace-only strings
- Placeholder values such as 'NaN', 'NaN?', and 'null'

Functions used:
TRIM   : Removes leading and trailing spaces.
NULLIF : Converts empty strings into SQL NULL.
LOWER  : Enables case-insensitive comparisons.
FILTER : Counts records matching specific conditions.
*/

SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(sale_date), '') IS NULL
           OR LOWER(TRIM(sale_date))
              IN ('nan', 'nan?', 'null')
    ) AS invalid_date_count,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(category), '') IS NULL
           OR LOWER(TRIM(category))
              IN ('nan', 'nan?', 'null')
    ) AS invalid_category_count,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(region), '') IS NULL
           OR LOWER(TRIM(region))
              IN ('nan', 'nan?', 'null')
    ) AS invalid_region_count,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(sales), '') IS NULL
           OR LOWER(TRIM(sales))
              IN ('nan', 'nan?', 'null')
    ) AS missing_sales_count,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(quantity), '') IS NULL
           OR LOWER(TRIM(quantity))
              IN ('nan', 'nan?', 'null')
    ) AS missing_quantity_count,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(profit), '') IS NULL
           OR LOWER(TRIM(profit))
              IN ('nan', 'nan?', 'null')
    ) AS missing_profit_count

FROM retail.retail_sales_Org;


/*
------------------------------------------------------------
CHECK 5: NON-NUMERIC VALUE DETECTION
------------------------------------------------------------
Objective:
Identify values that do not follow the expected numeric
format in sales, quantity, and profit.

These fields are stored as TEXT in the raw table.

Valid examples:
100
100.50
-25
0

Invalid examples:
NaN
N/A
abc
100x
$100

Regex explanation:
^-?          Optional negative sign
\d+          One or more digits
(\.\d+)?     Optional decimal portion
$            End of string

This pattern intentionally accepts a simple decimal format.
It does not accept currency symbols, commas, or scientific
notation.

Missing values are excluded from this check because
they are already assessed in Check 4.
*/

-- 5.1 Identify non-numeric values excluding blanks

SELECT *
FROM retail.retail_sales_Org
WHERE (
        NULLIF(TRIM(sales), '') IS NOT NULL
        AND TRIM(sales) !~ '^-?\d+(\.\d+)?$'
      )
   OR (
        NULLIF(TRIM(quantity), '') IS NOT NULL
        AND TRIM(quantity) !~ '^-?\d+(\.\d+)?$'
      )
   OR (
        NULLIF(TRIM(profit), '') IS NOT NULL
        AND TRIM(profit) !~ '^-?\d+(\.\d+)?$'
      );

-- Previously observed: 6 records


-- 5.2 Identify non-numeric values including blanks

SELECT *
FROM retail.retail_sales_Org
WHERE COALESCE(TRIM(sales), '') !~ '^-?\d+(\.\d+)?$'
   OR COALESCE(TRIM(quantity), '') !~ '^-?\d+(\.\d+)?$'
   OR COALESCE(TRIM(profit), '') !~ '^-?\d+(\.\d+)?$';

-- Previously observed: 7 records


/*
------------------------------------------------------------
CHECK 6: NON-POSITIVE SALES, QUANTITY, AND NEGATIVE PROFIT
------------------------------------------------------------
Objective:
Investigate numeric values that may require additional
business validation.

Business considerations:
- Sales <= 0 may represent invalid entries or adjustments.
- Quantity <= 0 may indicate errors or returned products.
- Profit < 0 may indicate a legitimate business loss.

Do not automatically delete these records.

IMPORTANT:
CASE expressions validate the numeric format before casting.
This prevents conversion errors caused by non-numeric text.
*/


-- 6.1 Non-positive sales

SELECT *
FROM retail.retail_sales_Org
WHERE CASE
    WHEN TRIM(sales) ~ '^-?\d+(\.\d+)?$'
    THEN TRIM(sales)::NUMERIC <= 0
    ELSE FALSE
END;

-- Previously observed: 45 records


-- 6.2 Non-positive quantity

SELECT *
FROM retail.retail_sales_Org
WHERE CASE
    WHEN TRIM(quantity) ~ '^-?\d+(\.\d+)?$'
    THEN TRIM(quantity)::NUMERIC <= 0
    ELSE FALSE
END;

-- Previously observed: 1 record


-- 6.3 Negative profit

SELECT *
FROM retail.retail_sales_Org
WHERE CASE
    WHEN TRIM(profit) ~ '^-?\d+(\.\d+)?$'
    THEN TRIM(profit)::NUMERIC < 0
    ELSE FALSE
END;

-- Previously observed: 0 records


-- 6.4 Combined numeric business-rule checks

SELECT *
FROM retail.retail_sales_Org
WHERE
    CASE
        WHEN TRIM(sales) ~ '^-?\d+(\.\d+)?$'
        THEN TRIM(sales)::NUMERIC <= 0
        ELSE FALSE
    END
    OR
    CASE
        WHEN TRIM(quantity) ~ '^-?\d+(\.\d+)?$'
        THEN TRIM(quantity)::NUMERIC <= 0
        ELSE FALSE
    END
    OR
    CASE
        WHEN TRIM(profit) ~ '^-?\d+(\.\d+)?$'
        THEN TRIM(profit)::NUMERIC < 0
        ELSE FALSE
    END;

-- Previously observed: 46 records


/*
------------------------------------------------------------
CHECK 7: DATE FORMAT VALIDATION
------------------------------------------------------------
Objective:
Identify missing dates and values that do not follow
the expected YYYY-MM-DD format.

Since sale_date is stored as TEXT, format validation
is performed before date conversion.

NOTE:
The regular expression checks formatting only.
It does not guarantee a valid calendar date.

Example:
2025-02-30 matches the pattern but is not a valid date.
*/


-- 7.1 Identify missing or invalid date formats

SELECT *
FROM retail.retail_sales_Org
WHERE NULLIF(TRIM(sale_date), '') IS NULL
   OR LOWER(TRIM(sale_date)) IN ('nan', 'nan?', 'null')
   OR TRIM(sale_date) !~ '^\d{1,2}/\d{1,2}/\d{2}$';

   -- 7.2 Preview date conversion
   -- Convert source dates into PostgreSQL DATE values.
   -- Run after confirming that the source dates are valid.

   SELECT
       sale_date AS original_date,
       TO_DATE(TRIM(sale_date), 'MM/DD/YY') AS converted_date
   FROM retail.retail_sales_Org
   WHERE TRIM(sale_date) ~ '^\d{1,2}/\d{1,2}/\d{2}$'
   LIMIT 20;
/*
------------------------------------------------------------
CHECK 8: DUPLICATE RECORD DETECTION
------------------------------------------------------------
Objective:
Identify exact duplicates across the six original
business data columns.

The autogenerated columns id_number and insert_date
are excluded because they are system-generated.

Identical source records are considered potential
duplicates and require investigation before removal.
*/

SELECT
    sale_date,
    category,
    sales,
    quantity,
    profit,
    region,
    COUNT(*) AS duplicate_cnt
FROM retail.retail_sales_Org
GROUP BY
    sale_date,
    category,
    sales,
    quantity,
    profit,
    region
HAVING COUNT(*) > 1;

-- Previously observed: 0 duplicate groups


/*
============================================================
END OF DATA PROFILING

NEXT STEP: DATA CLEANING AND TRANSFORMATION

The profiling findings will guide:
- Missing-value handling
- Category and region standardization
- Numeric data conversion
- Date conversion
- Invalid record investigation
- Duplicate handling

All cleaning decisions should be supported by
documented data-quality and business rules.
============================================================
*/
