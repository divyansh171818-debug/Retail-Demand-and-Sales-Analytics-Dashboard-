-- ============================================================
-- Retail Demand and Sales Analytics Dashboard
-- 03_analytical_queries.sql — KPI & exploration queries
-- ============================================================

USE retail_analytics;

-- ------------------------------------------------------------
-- Monthly sales trend
-- ------------------------------------------------------------
SELECT d.year, d.month_name, SUM(f.total_revenue) AS monthly_revenue,
       SUM(f.gross_profit) AS monthly_profit
FROM fact_sales f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

-- ------------------------------------------------------------
-- Product performance ranking
-- ------------------------------------------------------------
SELECT p.product_name, p.category,
       SUM(f.quantity_sold) AS units_sold,
       SUM(f.total_revenue) AS total_revenue,
       SUM(f.gross_profit)  AS total_profit
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_profit DESC;

-- ------------------------------------------------------------
-- Customer behavior: average order value & repeat purchase rate
-- ------------------------------------------------------------
SELECT
    COUNT(DISTINCT f.customer_id) AS distinct_customers,
    COUNT(DISTINCT f.transaction_id) AS total_orders,
    SUM(f.total_revenue) / COUNT(DISTINCT f.transaction_id) AS avg_order_value
FROM fact_sales f;

SELECT
    COUNT(*) AS repeat_customers
FROM (
    SELECT customer_id
    FROM fact_sales
    GROUP BY customer_id
    HAVING COUNT(DISTINCT transaction_id) > 1
) repeat_buyers;

-- ------------------------------------------------------------
-- Sales by region / store type
-- ------------------------------------------------------------
SELECT s.region, s.store_type,
       SUM(f.total_revenue) AS revenue,
       SUM(f.quantity_sold) AS units
FROM fact_sales f
JOIN dim_store s ON f.store_id = s.store_id
GROUP BY s.region, s.store_type
ORDER BY revenue DESC;

-- ------------------------------------------------------------
-- Sales velocity per product (units sold per active day)
-- Feeds the demand segmentation logic in 04_demand_segmentation.sql
-- ------------------------------------------------------------
SELECT p.product_id, p.product_name,
       SUM(f.quantity_sold) AS total_units,
       COUNT(DISTINCT f.date_id) AS active_days,
       SUM(f.quantity_sold) / COUNT(DISTINCT f.date_id) AS avg_daily_velocity
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY avg_daily_velocity DESC;
