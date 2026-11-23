--Exploratory analysis

------ Check 1: Investigating Unknown Categories ------

/*
Business Context:
The dataset is expected to contain 5 categories per day,
with one record for each category.

Objective:
Investigate Unknown category records and determine whether
missing categories can be reliably inferred.

No updates will be made to the dataset.
*/

-- Step 1: Check total records and distinct categories per date
Select sale_date,
count(*) as records,
Count(distinct category) as distinct_categories
from retail.retail_sales_upd 
group by sale_date
order by sale_date;

/* Observation: For 2023-01-04, the distinct category count differs from the total record count. */

-- Step 2: Inspect records for the affected date

select * from  retail.retail_sales_upd where sale_date = '2023-01-04';

/* Observation: Two records have an Unknown category on this date. */


-- Step 3: Identify all records with Unknown categories

SELECT *
FROM retail.retail_sales_upd
WHERE category = 'Unknown' order by sale_Date;
/*
Observation: 7 records have Unknown categories. */

-- Step 4: Display categories present on affected dates

SELECT
    sale_date,
    STRING_AGG(category, ', ' ORDER BY category)
        AS available_categories
FROM retail.retail_sales_upd
WHERE sale_date IN (
    SELECT sale_date
    FROM retail.retail_sales_upd
    WHERE category = 'Unknown'
)
GROUP BY sale_date;
/* Observation: Shows the categories recorded on dates where at least one category is Unknown. */

-- Step 5: Count Unknown records and distinct known categories

SELECT
    sale_date,
    COUNT(*) AS total_records,
    COUNT(DISTINCT category)
        FILTER (WHERE category <> 'Unknown')
        AS distinct_known_categories,
    COUNT(*)
        FILTER (WHERE category = 'Unknown')
        AS unknown_category_records
FROM retail.retail_sales_upd
GROUP BY sale_date
HAVING COUNT(*)
    FILTER (WHERE category = 'Unknown') > 0
ORDER BY sale_date;

/*
Observation:
Identifies how many Unknown category records exist on each affected date and how many distinct known categories are available.

Business Decision:
Although some missing categories may be inferred from the other categories recorded on a given date,the source values 
will not be modified. Unknown categories will remain as 'Unknown' to avoid
introducing assumptions into the dataset. */

-- Step 6: Investigate missing regions
SELECT *
FROM retail.retail_sales_upd
WHERE region = 'Unknown'
ORDER BY sale_date;

/* Business Decision: Missing regions cannot be reliably inferred from the available data.
They will remain classified as 'Unknown'*/

------check 2--Category contribution to sales-------

--Step 1 -- Finding which category contributes to higher sales

select category, Sum(sales) as Total_Sales from retail.retail_sales_upd
where data_quality_status = 'VALID'
group by category 
order by Total_sales desc ;

--Step 2 -- calculates how much revenue each category generates and what percentage of overall revenue comes from that category

WITH category_sales AS (
    SELECT
        category,
        SUM(sales) AS total_sales
    FROM retail.retail_sales_upd
    WHERE data_quality_status = 'VALID'
    GROUP BY category
)

SELECT
    category,
    ROUND(total_sales, 2) AS total_sales,
    ROUND(
        100.0 * total_sales
        / NULLIF(SUM(total_sales) OVER (), 0),
        2
    ) AS sales_percentage
FROM category_sales
ORDER BY total_sales DESC;

/*Business insight
This analysis calculates the percentage of total sales contributed by each product category.

It helps identify which categories generate the largest share of revenue and how sales are distributed across the categories.

Higher revenue contribution indicates a stronger share of overall sales, but does not necessarily mean higher
profitability.

Key findings 
- Books contributes the highest share of total revenue at 20.97%, followed by Electronics at 20.42%.
- Sports contributes the lowest share at 19.29%.
- The difference between the highest and lowest revenue contributions is only 1.68 percentage points,
indicating a relatively balanced revenue distribution across all five product categories.
- No single category dominates overall revenue, suggesting that sales are not heavily dependent on any one category.
*/


---check 3 --Checking the count of records for each data quality status 

select data_quality_status , count(*) as total_records
from retail.retail_sales_upd 
group by data_quality_status;
/*
"REVIEW"	63
"VALID"	1762
*/
-- check for bad data where valid category and region present but invalid fact columns
select * from retail.retail_sales_upd where data_quality_status = 'REVIEW' and category <> 'Unknown'  
and region <>'Unknown'
order by sale_date ;

-- 50 rows affected; mostly sale is 0 while profit and Quantity columns have teh value

select * from retail.retail_sales_upd where 
data_quality_status = 'REVIEW' and (category = 'Unknown'  
or region = 'Unknown')
order by sale_date ;
--13 rows

SELECT
    data_quality_status,
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE sales = 0
    ) AS zero_sales_records,
    COUNT(*) FILTER (
        WHERE sales = 0
          AND profit > 0
    ) AS zero_sales_positive_profit,
    ROUND(SUM(sales),2)
        AS total_sales
FROM retail.retail_sales_upd
GROUP BY data_quality_status;

/*Business Conclusion:
Out of 1825 total records, 1767 (96.82%) were marked as VALID, while 58 (3.18%) were flagged for REVIEW.

Among the 58 REVIEW records, 45 had valid category and region values but contained issues with financial
or quantity data, primarily zero sales despite positive profit and quantity values.

The remaining 13 records contained at least one 
Unknown category or region value.

These findings highlight data-quality issues that could affect the accuracy of sales and profitability
analysis. REVIEW records require further investigation and should be handled carefully in financial reporting.
*/


---check 4 -- 
/*Creating View to exclude recorfds that distort financial conclusion
(to consider only valid sales and quantity records)*/

	SELECT *
FROM retail.retail_sales_upd
WHERE data_quality_status = 'VALID'
  AND (
       sales <= 0
       OR quantity <= 0
       OR profit < 0
       OR sales IS NULL
       OR quantity IS NULL
       OR profit IS NULL
  );	   

CREATE OR REPLACE VIEW retail.retail_sales_valid AS
SELECT *
FROM retail.retail_sales_upd
WHERE data_quality_status = 'VALID'
  AND sales > 0
  AND quantity > 0
  AND profit >= 0;

select * from retail.retail_sales_Valid; --1762
select * from retail.retail_sales_upd WHERE data_quality_status = 'VALID'
and sales > 0 and quantity > 0 and profit >= 0

-- 1762
			
/*
Business Conclusion: Created a view to include only records meeting the defined data-quality and financial criteria.

The view contains 1,762 valid records, ensuring that subsequent sales, profit, and quantity analyses use a consistent dataset.

Records flagged for REVIEW are excluded from the reporting view to reduce the risk of
inaccurate financial conclusions.
*/		

---Check 5--Overall KPI's

Select round(Sum(Sales),2)  as Total_Sales,
Round(Sum(Profit),2) as Total_Profits,
Sum(quantity) as Total_units_sold,
Round(Sum(Profit)/NULLIF(Sum(Sales),0) *100,2) as Profit_Margin,
Round(Avg(Sales),2) as Avg_record_sales
from retail.retail_sales_Valid;

/*
Business Conclusion:
The business generated approximately $1.77 million in total revenue and $436,898 in profit from
17,796 units sold across 1,762 valid records.

The overall profit margin was 24.69%, indicating that approximately $24.69 in profit was generated
for every $100 in sales.

Average revenue per sales record was $1,004.09.

These KPIs establish a baseline for evaluating category performance, regional profitability,
and sales trends in subsequent analyses.
*/

--check 6 --- -- Performance by category 

Select category, 
Round(Sum(Sales),2)  as Total_Sales,
Round(Sum(Profit),2) as Total_Profits,
Sum(quantity) as units_sold,
Round(Sum(Profit)/NULLIF(Sum(Sales),0) *100,2) as Profit_Margin_pct
from retail.retail_sales_Valid 
group by category
order by total_sales desc;

/*
Business Conclusion: Analyzed revenue, profit, units sold, and profit margins across product categories to identify
the strongest-performing categories.

Revenue and profitability are evaluated separately, since the category generating the highest sales may not necessarily have 
the highest profit margin.

Key findings
- Books leads in total sales ($370,971.86), total profit ($90,909.63), and units sold (3,692).
- Sports has the highest profit margin (25.42%), despite generating the lowest total revenue and selling the fewest units.
- Electronics has the lowest profit margin (24.10%).
- Revenue is relatively evenly distributed across all five categories, with no single category dominating sales.

*/

--check 7 -- Performance by region 

Select region, round(Sum(Sales),2)  as Total_Sales,
Round(Sum(Profit),2) as Total_Profits,
Sum(quantity) as units_sold,
Round(Sum(Profit)/NULLIF(Sum(Sales),0) *100,2) as Profit_Margin_pct,
ROUND( SUM(sales) / NULLIF(SUM(quantity), 0), 2) AS revenue_per_unit
from retail.retail_sales_Valid 
group by region
order by total_sales desc;

/* West generates the highest revenue and total profit, while South sells the most units.
Key findings -
- West generates the highest revenue ($467,243.92) and profit ($117,270.81), despite selling fewer units than South and North.
- South sells the most units (4,654), but generates slightly less revenue and profit than West.
- West achieved higher revenue per unit ($103.69) compared with South's ($100.17)
- East records the lowest sales ($390,155.63) and total profit ($96,757.78).
- Profit margins are relatively similar across regions, ranging from approximately 24% to 25%.
- These findings suggest that differences in sales volume and revenue per unit contribute to regional
performance, with West leading in revenue and profit.
*/
---check 8 -- Performance by category, region 

Select region, 
category,
round(Sum(Sales),2)  as Total_Sales,
Round(Sum(Profit),2) as Total_Profits,
Sum(quantity) as units_sold,
Round(Sum(Profit)/NULLIF(Sum(Sales),0) *100,2) as Profit_Margin_pct
from retail.retail_sales_Valid 
group by region,category 
order by  region, total_Sales desc;

/* 
Category performance varies across regions 
- Home Goods leads in revenue and profit in East, while Clothing leads in both metrics in North.
- Electronics generates the highest revenue in South and West, but Clothing and Sports generate the highest profits 
in those regions, respectively.
- Sports in North has the highest profit margin (27.26%) among all category-region combinations.

These findings indicate that the highest-revenue category is different across regions, and the highest-revenue category 
is not always the most profitable.

Region-specific category performance can help identify opportunities for targeted inventory, pricing, and promotional strategies.

*/


-------Check 9 ---Monthly performance-------
SELECT
	DATE_TRUNC ('month', sale_date)::date as sales_month,
    ROUND(SUM(sales), 2) AS monthly_sales,
    ROUND(SUM(profit), 2) AS monthly_profit,
    SUM(quantity) AS units_sold
FROM retail.retail_sales_Valid
GROUP BY DATE_TRUNC('month', sale_date)
ORDER BY sales_month;


/*
Business Conclusion:
July recorded the highest revenue ($162,111.14) and profit ($40,208.95), making it the strongest
month in terms of financial performance.

January generated the lowest revenue ($128,858.31), while February recorded the lowest profit ($32,180.03).

September had the highest sales volume (1,598 units), indicating that the month with the most units sold
does not necessarily generate the highest revenue.

Revenue generally increased during the first half of the year, peaked in July, and fluctuated during
the remaining months, with December recording the second-highest revenue ($159,978.82).

These findings highlight variations in monthly performance that may help guide inventory and
sales planning. Additional years of data would be needed to confirm seasonal trends.
*/

-- yearly performance
SELECT
	Extract ('Year' from sale_date) as Year,
    ROUND(SUM(sales), 2) AS yearly_sales,
    ROUND(SUM(profit), 2) AS yearly_profit,
    SUM(quantity) AS units_sold
FROM retail.retail_sales_Valid
GROUP BY year
ORDER BY year;
/*
Business Conclusion — Yearly Performance:

In 2023, the business generated $1,769,209.75 in revenue and $436,898.19 in profit, with
17,796 units sold.

The annual totals match the overall KPIs calculated in Check 5, confirming consistency
between the yearly aggregation and overall financial summary.

Since the dataset contains only 2023 data, year-over-year growth cannot be evaluated.
*/

------Check 10--month over month sales growth

with monthly_sales as (
select DATE_TRUNC('month', sale_date)::DATE as sales_month,
SUM(Sales) as Total_sales
from retail.retail_sales_Valid
group by DATE_TRUNC('month', sale_date)
),

monthly_comparison as (
select sales_month,
total_Sales,
LAG(total_sales) over(order by sales_month)  as Previous_month_sales
from monthly_sales
)

Select sales_month, 
Round(total_Sales,2) as total_sales,
Round(Previous_month_sales,2) as Previous_month_sales,
Round((total_sales - Previous_month_sales)/NULLIF(Previous_month_sales,0)*100,2) 
as Month_over_month_growth_pct
from monthly_comparison order by sales_month;

/*
Business Conclusion:
March recorded the highest month-over-month sales growth at 9.91%, followed by May (9.13%) and
December (8.98%).

August experienced the largest sales decline at -8.69%, following July's peak revenue.

Sales increased in 7 out of 11 monthly comparisons, while 4 months recorded negative growth.

December showed a strong recovery of 8.98% after consecutive declines in October and November.

These fluctuations highlight changes in monthly revenue performance and can help identify periods
that warrant further investigation.

Additional years of data would be required to determine whether these patterns are seasonal.
*/

-----check 11 --- 

SELECT
    EXTRACT(ISODOW FROM sale_date) AS weekday_number,
    TRIM(TO_CHAR(sale_date, 'Day')) AS day_of_week,
    COUNT(DISTINCT sale_date) AS days_recorded,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(sales) / NULLIF(COUNT(DISTINCT sale_date), 0), 2) AS avg_daily_sales,
    ROUND(AVG(sales), 2) AS avg_record_sales
FROM retail.retail_sales_valid
GROUP BY
    EXTRACT(ISODOW FROM sale_date),
    TRIM(TO_CHAR(sale_date, 'Day'))
ORDER BY weekday_number;

/*
Business Conclusion:
Friday generated the highest total revenue
($262,035.18) and average daily sales ($5,039.14),
making it the strongest-performing weekday.

Wednesday recorded the lowest average daily sales
($4,765.47), approximately 5.74% below Friday.

Sunday had 53 recorded days compared with 52
for other weekdays, so average daily sales
provides a more consistent comparison than
total revenue alone.

Overall, sales performance was relatively
balanced across weekdays, with Friday
showing a modest advantage.

These findings may help inform daily staffing,
inventory planning, and promotional decisions.
*/