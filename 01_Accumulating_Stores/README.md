# Custom Weekly Store Cumulative Stores

**Business Problem:** 
The business launched a specific promotional campaign starting on January 15th, 2025. Leadership needed to track sales by custom "Campaign Weeks" rather than standard calendar weeks. 

Specifically, they requested a dashboard feed showing:
1. How many **new stores** started selling the product each week (Store Activation).
2. A **running total** of all activated stores since the campaign launch.
3. Total active stores and total units sold for that specific week.

> 🚀 **[Click here to run this query interactively in DB Fiddle!]**(https://www.db-fiddle.com/f/dx5yr4BNqNoQfk6zYRjcNB/1)

**SQL Techniques Highlighted:**
- **Custom Date Math:** Dynamically calculating custom week intervals from a specific launch date.
- **Nested Window Functions & Aggregations:** Using a `SUM(COUNT(DISTINCT...)) OVER(...)` to generate a cumulative running total of a grouped metric.
- **Cohort Flags:** Using a rolling `SUM() OVER(PARTITION BY...)` to identify the exact week a store made its very first sale.

---

### 1. Mock Schema and Data 
*Note: This data is mocked to demonstrate the logic of the query while respecting non-disclosure agreements and protecting proprietary information.*

```sql
-- Create the base sales table
CREATE TABLE store_custom_weekly_sales (
    store_id VARCHAR(10),
    custom_week VARCHAR(10),
    custom_week_number INT,
    total_units_sold INT
);

-- Insert realistic fake data over a 3-week period
INSERT INTO store_custom_weekly_sales VALUES
-- Week 1: Stores A and B start selling
('Store_A', 'Week 1', 1, 50),
('Store_B', 'Week 1', 1, 30),

-- Week 2: Stores A and B continue, Store C makes its FIRST sale
('Store_A', 'Week 2', 2, 45),
('Store_B', 'Week 2', 2, 25),
('Store_C', 'Week 2', 2, 60),

-- Week 3: Store D suddenly makes a sale, B drops off
('Store_A', 'Week 3', 3, 40),
('Store_C', 'Week 3', 3, 55),
('Store_D', 'Week 3', 3, 100);

WITH cumulative_sales AS (
    SELECT 
        store_id,
        custom_week,
        custom_week_number,
        total_units_sold,
        -- Window function to count how many weeks this store has sold > 0 units so far
        SUM(CASE WHEN total_units_sold > 0 THEN 1 ELSE 0 END) OVER (
            PARTITION BY store_id 
            ORDER BY custom_week_number 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_sales_flag
    FROM store_custom_weekly_sales
)

SELECT 
    custom_week,
    custom_week_number,
    
    -- 1. New stores activated exactly THIS week
    COUNT(DISTINCT CASE WHEN cumulative_sales_flag = 1 THEN store_id END) AS newly_activated_this_week,
    
    -- 2. Running total of ALL activated stores over time
    SUM(COUNT(DISTINCT CASE WHEN cumulative_sales_flag = 1 THEN store_id END)) OVER (
        ORDER BY custom_week_number
    ) AS cumulative_total_activated_stores,
    
    -- 3. Count of stores that sold anything THIS week
    COUNT(DISTINCT CASE WHEN total_units_sold > 0 THEN store_id END) AS active_stores_this_week,
    
    -- 4. Total volume for THIS week
    SUM(total_units_sold) AS total_units_this_week,

    -- 5. Cumulative total volume over the whole campaign
    SUM(SUM(total_units_sold)) OVER (
        ORDER BY custom_week_number
    ) AS cumulative_total_units
    
FROM cumulative_sales
GROUP BY 
    custom_week, 
    custom_week_number
ORDER BY 
    custom_week_number;
