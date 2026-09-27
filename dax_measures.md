# Power BI DAX Measures

Create a dedicated blank `Measures` table and keep the measures there.

## Sales KPIs

```dax
Total Revenue = SUM('fact_sales'[total_revenue])

Total Profit = SUM('fact_sales'[gross_profit])

Total Cost = SUM('fact_sales'[total_cost])

Total Units Sold = SUM('fact_sales'[quantity_sold])

Total Orders = DISTINCTCOUNT('fact_sales'[transaction_id])

Distinct Customers = DISTINCTCOUNT('fact_sales'[customer_id])

Profit Margin % = DIVIDE([Total Profit], [Total Revenue], 0)

Average Order Value = DIVIDE([Total Revenue], [Total Orders], 0)
```

## Time Analysis

```dax
Previous Month Revenue =
CALCULATE(
    [Total Revenue],
    DATEADD('dim_date'[full_date], -1, MONTH)
)

MoM Revenue Growth % =
DIVIDE(
    [Total Revenue] - [Previous Month Revenue],
    [Previous Month Revenue],
    0
)

YTD Revenue =
TOTALYTD(
    [Total Revenue],
    'dim_date'[full_date]
)
```

## Customer Analysis

```dax
Repeat Customers =
COUNTROWS(
    FILTER(
        VALUES('fact_sales'[customer_id]),
        CALCULATE(
            DISTINCTCOUNT('fact_sales'[transaction_id])
        ) > 1
    )
)

Repeat Customer Rate =
DIVIDE(
    [Repeat Customers],
    [Distinct Customers],
    0
)
```

## Product Analysis

```dax
Product Revenue Rank =
RANKX(
    ALL('dim_product'[product_name]),
    [Total Revenue],
    ,
    DESC,
    DENSE
)

Average Daily Velocity =
DIVIDE(
    [Total Units Sold],
    DISTINCTCOUNT('fact_sales'[date_id]),
    0
)

Fast Moving Units =
CALCULATE(
    [Total Units Sold],
    'dim_product'[demand_segment] = "Fast-Moving"
)

Slow Moving Units =
CALCULATE(
    [Total Units Sold],
    'dim_product'[demand_segment] = "Slow-Moving"
)
```

## Inventory Risk

If `fact_inventory_snapshot` is populated:

```dax
Current Stock =
SUM('fact_inventory_snapshot'[current_stock])

Stockout Risk Products =
COUNTROWS(
    FILTER(
        VALUES('dim_product'[product_id]),
        [Current Stock] < [Reorder Point]
    )
)
```

Reorder point and safety stock are stored as product-level derived attributes after the SQL validation step. Use filter-context-aware aggregation in measures.

```dax
Reorder Point =
MAX('dim_product'[reorder_point])

Stockout Risk Flag =
IF(
    [Current Stock] < [Reorder Point],
    "At Risk",
    "OK"
)
```

> `RELATED()` should not be used as a shortcut for retrieving a product attribute inside this measure. Use filter-context-aware aggregation such as `MAX()` when the model supports it.
