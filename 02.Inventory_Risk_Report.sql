/*
Inventory risk report to flag SKUs with low stock levels relative to 
no.of products sold, or high order lead time, to create a "stockout risk query"
Used to identify SKUs with insufficient inventory, to better design reorder and stocking policies
*/

WITH inventory_risk AS
(    
    SELECT
        products.sku,
        inventory.stock_levels,
        inventory.order_lead_time_days,
        products.number_of_products_sold,
-- I assume here that the no.of products sold is from the past 12 months, the actual timeframe is not stated anywhere in the dataset
        (products.number_of_products_sold / 365 * inventory.order_lead_time_days) AS demand_over_lead_time
    FROM
        products
        INNER JOIN inventory ON inventory.sku = products.sku
)
SELECT
    sku,
    stock_levels,
    demand_over_lead_time,
    ROUND((stock_levels:: NUMERIC / demand_over_lead_time) * 100, 2) AS pct_demand_filled
FROM
    inventory_risk
WHERE
    stock_levels < demand_over_lead_time
ORDER BY
    pct_demand_filled;