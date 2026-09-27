-- ============================================================
-- Retail Demand and Sales Analytics Dashboard
-- 01_schema.sql — Star schema table definitions
-- ============================================================

CREATE DATABASE IF NOT EXISTS retail_analytics;
USE retail_analytics;

DROP TABLE IF EXISTS fact_inventory_snapshot;
DROP TABLE IF EXISTS fact_sales;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_store;
DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date (
    date_id       INT PRIMARY KEY,
    full_date     DATE NOT NULL,
    day           INT,
    month         INT,
    month_name    VARCHAR(15),
    quarter       INT,
    year          INT,
    is_weekend    BOOLEAN
);

CREATE TABLE dim_product (
    product_id      INT PRIMARY KEY AUTO_INCREMENT,
    product_name    VARCHAR(150),
    category        VARCHAR(80),
    sub_category    VARCHAR(80),
    unit_cost       DECIMAL(10,2),
    unit_price      DECIMAL(10,2),
    avg_lead_time_days INT DEFAULT 7,
    demand_segment  VARCHAR(20)   -- populated by 04_demand_segmentation.sql
);

CREATE TABLE dim_customer (
    customer_id   INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(150),
    segment       VARCHAR(50),   -- e.g. Retail, Wholesale, Online
    region        VARCHAR(80),
    city          VARCHAR(80)
);

CREATE TABLE dim_store (
    store_id      INT PRIMARY KEY AUTO_INCREMENT,
    store_name    VARCHAR(120),
    region        VARCHAR(80),
    store_type    VARCHAR(50)
);

CREATE TABLE fact_sales (
    transaction_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    date_id        INT,
    product_id     INT,
    customer_id    INT,
    store_id       INT,
    quantity_sold  INT,
    unit_price     DECIMAL(10,2),
    total_revenue  DECIMAL(12,2),
    total_cost     DECIMAL(12,2),
    gross_profit   DECIMAL(12,2),
    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (store_id) REFERENCES dim_store(store_id)
);

CREATE INDEX idx_fact_date ON fact_sales(date_id);
CREATE INDEX idx_fact_product ON fact_sales(product_id);
CREATE INDEX idx_fact_customer ON fact_sales(customer_id);
CREATE INDEX idx_fact_store ON fact_sales(store_id);

-- Optional attributes populated by the demand/inventory workflow.
-- Keep these as nullable because they are derived metrics, not source facts.
ALTER TABLE dim_product
    ADD COLUMN IF NOT EXISTS reorder_point DECIMAL(12,2) NULL,
    ADD COLUMN IF NOT EXISTS safety_stock DECIMAL(12,2) NULL;


CREATE TABLE fact_inventory_snapshot (
    snapshot_date_id INT NOT NULL,
    product_id INT NOT NULL,
    store_id INT NOT NULL,
    current_stock INT NOT NULL,
    units_received INT DEFAULT 0,
    units_sold INT DEFAULT 0,
    PRIMARY KEY (snapshot_date_id, product_id, store_id),
    FOREIGN KEY (snapshot_date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (store_id) REFERENCES dim_store(store_id)
);
