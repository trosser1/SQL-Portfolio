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
    
    -- 3. Count of stores that sold anything THIS week (regardless of when they first activated)
    COUNT(DISTINCT CASE WHEN total_units_sold > 0 THEN store_id END) AS active_stores_this_week,
    
    -- 4. Total volume for the week
    SUM(total_units_sold) AS total_units
FROM cumulative_sales
GROUP BY 
    custom_week, 
    custom_week_number
ORDER BY 
    custom_week_number;
