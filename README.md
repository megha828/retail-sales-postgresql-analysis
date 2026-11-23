# Retail Sales Analysis | PostgreSQL SQL Portfolio Project

## Project Overview

This project demonstrates an end-to-end SQL workflow for transforming raw retail sales data into a reliable analytical dataset and extracting actionable business insights. Using PostgreSQL, I profiled source data, standardized inconsistent values, applied data-quality rules, created a reusable reporting view, and analyzed revenue, profit, sales volume, and performance across categories, regions, and time.

 Scope :2023 retail sales data, with 1,825 source records and 1,762 records in the validated reporting view.

## Business Objectives

- Assess the quality and usability of raw retail sales records.
- Establish consistent sales, profit, volume, and margin KPIs.
- Identify leading product categories and regions by revenue and profitability.
- Understand monthly performance, month-over-month changes, and weekday patterns.
- Document data limitations and make reproducible, evidence-based reporting decisions.

## Tools and SQL Concepts

 Database:  PostgreSQL  
 Techniques:  SQL data profiling, `CASE`, `TRIM`, `NULLIF`, numeric casting, regular expressions, date conversion, `GROUP BY`, conditional aggregates with `FILTER`, `CREATE VIEW`, CTEs, `LAG()`, window functions, `DATE_TRUNC()`, `EXTRACT()`, and `ROUND()`.

## Data and Workflow

The dataset contains retail sales records with dates, product categories, regions, sales amounts, quantities, profits, and a source record identifier. Raw text values required cleaning before numerical analysis.

1.  Import and profile:  Load the source into a raw/staging table and inspect types, missing values, invalid numeric strings, duplicates, and category/region distributions.
2.  Clean and standardize:  Trim text, normalize category and region names, handle blank or placeholder values (such as `NaN`), safely convert numeric fields, and standardize dates. Preserve unresolved category and region values as `Unknown` rather than inventing replacements.
3.  Classify data quality:  Mark records `VALID` or `REVIEW` according to defined quality rules; retain flagged records for investigation.
4.  Prepare reporting dataset:  Create `retail.retail_sales_valid` using `data_quality_status = 'VALID'`, `sales > 0`, `quantity > 0`, and `profit >= 0`.
5.  Analyze:  Calculate KPIs, category and regional performance, monthly/yearly totals, month-over-month revenue growth, and weekday sales patterns.

### Data Quality and Reporting Scope

| Measure | Records |
|---|---:|
| Raw / cleaned source records | 1,825 |
| Records included in validated reporting view | 1,762 |
| Records outside reporting view | 63 |
| Reporting-view coverage | 96.55% |

The reporting view is a  defined analytical subset , not a claim that excluded records represent zero economic activity. Financial results below refer only to records in that view. The `profit >= 0` criterion is part of this project's reporting definition; in real-world datasets, legitimate loss-making transactions should not automatically be classified as invalid.

 Unknown categories:  Seven records were identified with an `Unknown` category. I examined the category distribution on affected dates, including a date with two unknowns. Although some categories might appear inferable under a strict one-record-per-category-per-day assumption, I chose not to overwrite source values without reliable evidence. Missing regions were likewise retained as `Unknown`.

 Reconciliation:  The annual sales, profit, and unit totals match the overall KPI query. The count of `VALID` records was also checked against the reporting-view count after the quality rules were aligned.

## Key Performance Indicators — 2023

| Metric | Result |
|---|---:|
| Total revenue |  $1,769,209.75  |
| Total profit |  $436,898.19  |
| Units sold |  17,796  |
| Profit margin |  24.69%  |
| Average revenue per record |  $1,004.09  |

*Profit margin = total profit / total revenue × 100. Average revenue per record is not necessarily average order value because one row has not been established as one order.*

## Analysis and Business Findings

### 1. Revenue Contribution by Category

| Category | Revenue | Share of Revenue |
|---|---:|---:|
| Books | $370,971.86 | 20.97% |
| Electronics | $361,271.84 | 20.42% |
| Clothing | $350,981.80 | 19.84% |
| Home Goods | $344,634.23 | 19.48% |
| Sports | $341,350.02 | 19.29% |

 Finding:  Revenue is relatively balanced across categories: the largest and smallest shares differ by only 1.68 percentage points. Books leads in revenue, but no single category dominates the business.

### 2. Category Profitability

| Category | Total Profit | Units Sold | Profit Margin |
|---|---:|---:|---:|
| Books | $90,909.63 | 3,692 | 24.51% |
| Electronics | $87,070.55 | 3,484 | 24.10% |
| Clothing | $87,583.42 | 3,589 | 24.95% |
| Home Goods | $84,570.43 | 3,664 | 24.54% |
| Sports | $86,764.16 | 3,367 |  25.42%  |

 Finding:  Books leads in total revenue, profit, and units sold. Sports has the highest profit margin, showing that the category with the strongest margin is not necessarily the largest contributor to total profit.

### 3. Regional Performance

| Region | Revenue | Profit | Units Sold | Revenue per Unit |
|---|---:|---:|---:|---:|
| West | $467,243.92 | $117,270.81 | 4,506 | $103.69 |
| South | $466,191.62 | $113,407.74 | 4,654 | $100.17 |
| North | $445,618.58 | $109,461.86 | 4,614 | $96.58 |
| East | $390,155.63 | $96,757.78 | 4,022 | $97.01 |

 Finding:  West generates the highest revenue and profit, despite selling fewer units than South and North. South sells the most units. West's higher revenue per unit helps explain why it leads in revenue despite its lower volume. East has the lowest total revenue and profit.

### 4. Category Performance Within Regions

| Region | Highest-Revenue Category | Highest-Profit Category | Highest-Margin Category |
|---|---|---|---|
| East | Home Goods | Home Goods | Electronics (25.56%) |
| North | Clothing | Clothing | Sports (27.26%) |
| South | Electronics | Clothing | Home Goods (25.15%) |
| West | Electronics | Sports | Clothing (25.75%) |

 Finding:  Product-category leaders vary by region. West–Sports produces the highest total profit of any category-region combination ( $25,356.76 ), while North–Sports has the highest margin ( 27.26% ). Regional decisions should therefore consider profit and margin, not revenue alone.

### 5. Monthly and Annual Performance

| Month | Revenue | Profit | Units Sold |
|---|---:|---:|---:|
| January | $128,858.31 | $32,795.25 | 1,340 |
| February | $132,215.38 | $32,180.03 | 1,423 |
| March | $145,321.15 | $36,004.65 | 1,353 |
| April | $138,161.05 | $33,989.94 | 1,316 |
| May | $150,775.02 | $39,130.00 | 1,565 |
| June | $152,605.82 | $39,042.66 | 1,570 |
| July | $162,111.14 | $40,208.95 | 1,536 |
| August | $148,020.40 | $34,675.58 | 1,489 |
| September | $153,094.72 | $37,796.79 | 1,598 |
| October | $151,272.32 | $36,019.35 | 1,569 |
| November | $146,795.62 | $36,344.07 | 1,461 |
| December | $159,978.82 | $38,710.92 | 1,576 |

 Finding:  July is the strongest month by revenue and profit. January has the lowest revenue; February has the lowest profit. September has the highest unit volume, and December records the second-highest revenue. The annual aggregation reconciles with the overall KPI totals.

### 6. Month-over-Month Revenue Growth

| Month | MoM Revenue Growth |
|---|---:|
| January | N/A |
| February | +2.61% |
| March |  +9.91%  |
| April | −4.93% |
| May | +9.13% |
| June | +1.21% |
| July | +6.23% |
| August |  −8.69%  |
| September | +3.43% |
| October | −1.19% |
| November | −2.96% |
| December | +8.98% |

 Finding:  March records the largest month-over-month increase (+9.91%), and August the largest decrease (−8.69%). Revenue grows in seven of eleven month-to-month comparisons. January is N/A because December 2022 data is not included.

### 7. Weekday Sales Performance

| Weekday | Days Represented | Average Daily Revenue |
|---|---:|---:|
| Monday | 52 | $4,825.71 |
| Tuesday | 52 | $4,794.42 |
| Wednesday | 52 |  $4,765.47  |
| Thursday | 52 | $4,810.91 |
| Friday | 52 |  $5,039.14  |
| Saturday | 52 | $4,833.15 |
| Sunday | 53 | $4,860.99 |

 Finding:  Friday has the highest average daily revenue; Wednesday has the lowest. Friday's average is about 5.74% higher than Wednesday's. Normalizing by the number of represented dates avoids misleading comparisons when weekday counts differ.

## Business Recommendations

These are hypotheses and possible actions based on descriptive results, not proven causal relationships:

1.  Protect the Books category's contribution:  Review stock availability and customer demand because Books leads total sales and profit.
2.  Investigate Sports profitability:  Examine why Sports has the highest category margin, particularly in North, before expanding inventory or promotions.
3.  Use region-specific assortment analysis:  Compare product mix, selling prices, and costs in West versus South to understand the higher revenue per unit in West.
4.  Investigate monthly volatility:  Examine campaigns, holidays, pricing, and stockouts around March, July, August, and December before attributing changes to seasonality.
5.  Test weekday interventions:  Consider controlled promotional or staffing experiments on lower-revenue weekdays rather than assuming Friday's advantage will repeat.
6.  Improve upstream data quality:  Investigate records with missing dimensions or invalid financial fields and preserve traceability to source records.

## Representative SQL Techniques

### Revenue Share by Category

SELECT
    category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(
        SUM(sales) * 100.0 /
        NULLIF(SUM(SUM(sales)) OVER (), 0),
        2
    ) AS revenue_share_pct
FROM retail.retail_sales_valid
GROUP BY category
ORDER BY total_sales DESC;

### Month-over-Month Revenue Growth


WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', sale_date)::date AS sales_month,
        SUM(sales) AS total_sales
    FROM retail.retail_sales_valid
    GROUP BY DATE_TRUNC('month', sale_date)
), monthly_comparison AS (
    SELECT
        sales_month,
        total_sales,
        LAG(total_sales) OVER (ORDER BY sales_month) AS previous_month_sales
    FROM monthly_sales
)
SELECT
    sales_month,
    ROUND(total_sales, 2) AS total_sales,
    ROUND(previous_month_sales, 2) AS previous_month_sales,
    ROUND(
        (total_sales - previous_month_sales) /
        NULLIF(previous_month_sales, 0) * 100,
        2
    ) AS month_over_month_growth_pct
FROM monthly_comparison
ORDER BY sales_month;

## Repository Structure


retail-sales-postgresql-analysis/
├── README.md
├── data/
│   └── retail_sales.csv
├── sql/
│   ├── 01_create_schema_and_raw_table.sql
│   ├── 02_data_profiling.sql
│   ├── 03_data_cleaning_validation.sql
│   └── 04_Exploratory_Analysis.sql
└── Results/
    ├── Profiling-screenshots.xlsx
    └── EDA Results - Screenshots.xlsx

## How to Reproduce

1. Install PostgreSQL and use a SQL client such as pgAdmin.
2. Create a database for the project.
3. Run `sql/01_create_schema_and_raw_table.sql` to create the `retail` schema and the raw table, then import `data/retail_sales.csv` following the pgAdmin Import/Export steps documented in that script (expected: 1,825 rows).
4. Run `sql/02_data_profiling.sql`, then `sql/03_data_cleaning_validation.sql` to build the cleaned `retail.retail_sales_upd` table with data-quality flags.
5. Run `sql/04_Exploratory_Analysis.sql` — Check 4 creates the `retail.retail_sales_valid` reporting view (1,762 records) used by the analysis queries that follow.
6. Execute the analysis queries and compare the KPI totals with the results documented above.

## Assumptions and Limitations

- The data covers  one calendar year (2023) ; results do not establish recurring seasonality or year-over-year growth.
- Financial results exclude records outside the validated reporting view; excluded records may contain real transactions that require correction or separate reporting.
- `Unknown` categories and regions were preserved rather than imputed without supporting evidence.
- The reporting view excludes negative profits by definition. This is a project-specific selection rule,  not  a universal business rule: legitimate losses should be included in comprehensive profitability reporting.
- Profit is taken from the supplied `profit` field. The data does not establish whether it represents gross profit, operating profit, or net profit.
- Revenue per unit is a weighted aggregate, not proof of a particular pricing or product-mix cause.
- The dataset does not establish that one record equals one customer order, so average sales per record should not be labeled average order value.
- Descriptive findings support further investigation but do not prove why performance changed.

## What This Project Demonstrates

- Building a reproducible SQL pipeline from raw data to a reporting view.
- Applying explicit quality rules without silently inventing missing information.
- Reconciling aggregate financial metrics across different levels of analysis.
- Using PostgreSQL aggregations, window functions, and CTEs for business analysis.
- Translating query outputs into clear findings, recommendations, and limitations.

---

 Project status:  SQL cleaning, validation, and exploratory analysis completed based on the documented results. Repository packaging and final file-path verification are the remaining publication steps.
