-- ============================================================
-- Retail Demand and Sales Analytics Dashboard
-- 04_demand_segmentation.sql — Fast/Medium/Slow mover classification
-- and reorder point support
-- ============================================================

USE retail_analytics;

-- ------------------------------------------------------------
-- 1. Classify products into demand segments using velocity quintiles
--    (Fast-Moving = top 20%, Slow-Moving = bottom 20%)
-- ------------------------------------------------------------
UPDATE dim_product p
JOIN (
    SELECT product_id,
           NTILE(5) OVER (ORDER BY avg_daily_velocity DESC) AS velocity_bucket
    FROM (
        SELECT f.product_id,
               SUM(f.quantity_sold) / COUNT(DISTINCT f.date_id) AS avg_daily_velocity
        FROM fact_sales f
        GROUP BY f.product_id
    ) v
) b ON p.product_id = b.product_id
SET p.demand_segment = CASE
    WHEN b.velocity_bucket = 1 THEN 'Fast-Moving'
    WHEN b.velocity_bucket = 5 THEN 'Slow-Moving'
    ELSE 'Medium-Moving'
END;

-- Check the distribution
SELECT demand_segment, COUNT(*) AS product_count
FROM dim_product
GROUP BY demand_segment;

-- ------------------------------------------------------------
-- 2. Reorder point calculation
--    Reorder Point = (Avg Daily Demand * Lead Time) + Safety Stock
--    Safety Stock   = Z * StdDev(Daily Demand) * SQRT(Lead Time)
--    Z = 1.65 for ~95% service level (adjust as needed)
-- ------------------------------------------------------------
WITH daily_demand AS (
    SELECT f.product_id, f.date_id, SUM(f.quantity_sold) AS daily_units
    FROM fact_sales f
    GROUP BY f.product_id, f.date_id
),
demand_stats AS (
    SELECT product_id,
           AVG(daily_units) AS avg_daily_demand,
           STDDEV_SAMP(daily_units) AS stddev_daily_demand
    FROM daily_demand
    GROUP BY product_id
)
SELECT
    p.product_id,
    p.product_name,
    p.demand_segment,
    p.avg_lead_time_days,
    ds.avg_daily_demand,
    ds.stddev_daily_demand,
    ROUND(1.65 * ds.stddev_daily_demand * SQRT(p.avg_lead_time_days), 2) AS safety_stock,
    ROUND(
        (ds.avg_daily_demand * p.avg_lead_time_days)
        + (1.65 * ds.stddev_daily_demand * SQRT(p.avg_lead_time_days)), 2
    ) AS reorder_point
FROM dim_product p
JOIN demand_stats ds ON p.product_id = ds.product_id
ORDER BY p.demand_segment, reorder_point DESC;

-- ------------------------------------------------------------
-- 3. Stockout risk flag (requires a current_stock column/table —
--    add one to dim_product or join an inventory table if you have one)
-- ------------------------------------------------------------
-- ALTER TABLE dim_product ADD COLUMN current_stock INT DEFAULT 0;
--
-- SELECT product_name, current_stock, reorder_point,
--        CASE WHEN current_stock < reorder_point THEN 'At Risk' ELSE 'OK' END AS stockout_risk
-- FROM ( ...join the reorder_point query above... ) t;
