-- ============================================================
-- 05_advanced_interview_queries.sql
-- Interview-focused SQL patterns
-- ============================================================
USE retail_analytics;

-- 1. Top 3 products by revenue within each category
WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(f.total_revenue) AS revenue
    FROM fact_sales f
    JOIN dim_product p ON f.product_id = p.product_id
    GROUP BY p.product_id, p.product_name, p.category
), ranked AS (
    SELECT *,
           DENSE_RANK() OVER (
               PARTITION BY category
               ORDER BY revenue DESC
           ) AS category_rank
    FROM product_sales
)
SELECT *
FROM ranked
WHERE category_rank <= 3
ORDER BY category, category_rank;

-- 2. Month-over-month revenue growth
WITH monthly_sales AS (
    SELECT
        d.year,
        d.month,
        STR_TO_DATE(CONCAT(d.year, '-', LPAD(d.month, 2, '0'), '-01'), '%Y-%m-%d') AS month_start,
        SUM(f.total_revenue) AS revenue
    FROM fact_sales f
    JOIN dim_date d ON f.date_id = d.date_id
    GROUP BY d.year, d.month
), with_previous AS (
    SELECT *,
           LAG(revenue) OVER (ORDER BY month_start) AS previous_month_revenue
    FROM monthly_sales
)
SELECT
    year,
    month,
    revenue,
    previous_month_revenue,
    ROUND(
        100 * (revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0), 2
    ) AS mom_growth_pct
FROM with_previous
ORDER BY month_start;

-- 3. Product revenue contribution to total revenue
WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        SUM(f.total_revenue) AS revenue
    FROM fact_sales f
    JOIN dim_product p ON f.product_id = p.product_id
    GROUP BY p.product_id, p.product_name
)
SELECT
    product_name,
    revenue,
    ROUND(100 * revenue / NULLIF(SUM(revenue) OVER (), 0), 2) AS revenue_share_pct
FROM product_sales
ORDER BY revenue DESC;

-- 4. Rank customers by revenue within each region
WITH customer_region_sales AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.region,
        SUM(f.total_revenue) AS revenue
    FROM fact_sales f
    JOIN dim_customer c ON f.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_name, c.region
)
SELECT *,
       DENSE_RANK() OVER (
           PARTITION BY region
           ORDER BY revenue DESC
       ) AS regional_rank
FROM customer_region_sales
ORDER BY region, regional_rank;

-- 5. Repeat customers and their order counts
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT f.transaction_id) AS order_count,
    SUM(f.total_revenue) AS customer_revenue
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT f.transaction_id) > 1
ORDER BY customer_revenue DESC;

-- 6. Revenue by category with category rank
WITH category_sales AS (
    SELECT
        p.category,
        SUM(f.total_revenue) AS revenue,
        SUM(f.gross_profit) AS profit
    FROM fact_sales f
    JOIN dim_product p ON f.product_id = p.product_id
    GROUP BY p.category
)
SELECT *,
       RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM category_sales
ORDER BY revenue_rank;

-- 7. Seven-day rolling revenue by date
WITH daily_sales AS (
    SELECT
        d.full_date,
        SUM(f.total_revenue) AS daily_revenue
    FROM fact_sales f
    JOIN dim_date d ON f.date_id = d.date_id
    GROUP BY d.full_date
)
SELECT
    full_date,
    daily_revenue,
    SUM(daily_revenue) OVER (
        ORDER BY full_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7_day_revenue
FROM daily_sales
ORDER BY full_date;

-- 8. Products with revenue above the average product revenue
WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        SUM(f.total_revenue) AS revenue
    FROM fact_sales f
    JOIN dim_product p ON f.product_id = p.product_id
    GROUP BY p.product_id, p.product_name
)
SELECT *
FROM product_sales
WHERE revenue > (SELECT AVG(revenue) FROM product_sales)
ORDER BY revenue DESC;
