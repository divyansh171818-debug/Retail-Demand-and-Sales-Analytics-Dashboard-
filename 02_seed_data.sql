-- ============================================================
-- Retail Demand and Sales Analytics Dashboard
-- 02_seed_data.sql — Populate dim_date and load transaction data
-- ============================================================

USE retail_analytics;

-- ------------------------------------------------------------
-- 1. Populate dim_date for a date range (adjust as needed)
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS populate_dim_date;

DELIMITER $$
CREATE PROCEDURE populate_dim_date(IN start_date DATE, IN end_date DATE)
BEGIN
    DECLARE cur_date DATE;
    SET cur_date = start_date;

    WHILE cur_date <= end_date DO
        INSERT INTO dim_date (
            date_id, full_date, day, month, month_name, quarter, year, is_weekend
        )
        VALUES (
            CAST(DATE_FORMAT(cur_date, '%Y%m%d') AS UNSIGNED),
            cur_date,
            DAY(cur_date),
            MONTH(cur_date),
            MONTHNAME(cur_date),
            QUARTER(cur_date),
            YEAR(cur_date),
            DAYOFWEEK(cur_date) IN (1, 7)
        );
        SET cur_date = DATE_ADD(cur_date, INTERVAL 1 DAY);
    END WHILE;
END$$
DELIMITER ;

CALL populate_dim_date('2024-01-01', '2026-12-31');

-- ------------------------------------------------------------
-- 2. Load dimension + fact data
-- ------------------------------------------------------------
-- Option A: Import CSVs directly (adjust paths to your environment)
-- LOAD DATA INFILE '/path/to/data/products.csv'
-- INTO TABLE dim_product
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS
-- (product_name, category, sub_category, unit_cost, unit_price, avg_lead_time_days);

-- LOAD DATA INFILE '/path/to/data/customers.csv'
-- INTO TABLE dim_customer
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS
-- (customer_name, segment, region, city);

-- LOAD DATA INFILE '/path/to/data/stores.csv'
-- INTO TABLE dim_store
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS
-- (store_name, region, store_type);

-- LOAD DATA INFILE '/path/to/data/raw_transactions.csv'
-- INTO TABLE fact_sales
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS
-- (date_id, product_id, customer_id, store_id, quantity_sold, unit_price,
--  total_revenue, total_cost, gross_profit);

-- Option B: If your MySQL server has --secure-file-priv restrictions,
-- use a client-side tool (MySQL Workbench Table Data Import Wizard,
-- or `mysqlimport`) instead of LOAD DATA INFILE.

-- ------------------------------------------------------------
-- 3. Sanity checks after loading
-- ------------------------------------------------------------
SELECT COUNT(*) AS total_transactions FROM fact_sales;
SELECT COUNT(*) AS total_products FROM dim_product;
SELECT MIN(full_date) AS earliest_date, MAX(full_date) AS latest_date FROM dim_date;
