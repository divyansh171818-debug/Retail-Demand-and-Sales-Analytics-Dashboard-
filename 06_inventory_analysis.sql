-- ============================================================
-- 06_inventory_analysis.sql
-- Inventory analysis using reorder-point outputs
-- ============================================================
USE retail_analytics;

-- The inventory snapshot table stores observed stock, not calculated demand.
-- Derived metrics remain separate from source inventory facts.

WITH daily_demand AS (
    SELECT
        product_id,
        date_id,
        SUM(quantity_sold) AS daily_units
    FROM fact_sales
    GROUP BY product_id, date_id
),
demand_stats AS (
    SELECT
        product_id,
        AVG(daily_units) AS avg_daily_demand,
        STDDEV_SAMP(daily_units) AS stddev_daily_demand
    FROM daily_demand
    GROUP BY product_id
),
reorder_points AS (
    SELECT
        p.product_id,
        ROUND(
            1.65 * COALESCE(ds.stddev_daily_demand, 0)
            * SQRT(p.avg_lead_time_days), 2
        ) AS calculated_safety_stock,
        ROUND(
            ds.avg_daily_demand * p.avg_lead_time_days
            + 1.65 * COALESCE(ds.stddev_daily_demand, 0)
            * SQRT(p.avg_lead_time_days), 2
        ) AS calculated_reorder_point
    FROM dim_product p
    JOIN demand_stats ds
      ON p.product_id = ds.product_id
)
SELECT
    p.product_id,
    p.product_name,
    p.demand_segment,
    p.avg_lead_time_days,
    ds.avg_daily_demand,
    ds.stddev_daily_demand,
    r.calculated_safety_stock AS safety_stock,
    r.calculated_reorder_point AS reorder_point
FROM dim_product p
JOIN demand_stats ds
  ON p.product_id = ds.product_id
JOIN reorder_points r
  ON p.product_id = r.product_id
ORDER BY reorder_point DESC;

-- Populate derived product attributes for Power BI if desired.
-- Run this only after validating the calculations.
UPDATE dim_product p
JOIN (
    SELECT
        p2.product_id,
        ROUND(
            1.65 * COALESCE(ds.stddev_daily_demand, 0)
            * SQRT(p2.avg_lead_time_days), 2
        ) AS safety_stock_value,
        ROUND(
            ds.avg_daily_demand * p2.avg_lead_time_days
            + 1.65 * COALESCE(ds.stddev_daily_demand, 0)
            * SQRT(p2.avg_lead_time_days), 2
        ) AS reorder_point_value
    FROM dim_product p2
    JOIN (
        SELECT
            product_id,
            AVG(daily_units) AS avg_daily_demand,
            STDDEV_SAMP(daily_units) AS stddev_daily_demand
        FROM (
            SELECT product_id, date_id, SUM(quantity_sold) AS daily_units
            FROM fact_sales
            GROUP BY product_id, date_id
        ) d
        GROUP BY product_id
    ) ds
      ON p2.product_id = ds.product_id
) x
ON p.product_id = x.product_id
SET p.safety_stock = x.safety_stock_value,
    p.reorder_point = x.reorder_point_value;

-- Compare observed stock with calculated reorder point.
SELECT
    i.snapshot_date_id,
    i.product_id,
    p.product_name,
    i.store_id,
    i.current_stock,
    p.safety_stock,
    p.reorder_point,
    CASE
        WHEN i.current_stock < p.reorder_point THEN 'At Risk'
        ELSE 'OK'
    END AS stockout_risk
FROM fact_inventory_snapshot i
JOIN dim_product p
  ON i.product_id = p.product_id
ORDER BY stockout_risk DESC, i.current_stock ASC;
