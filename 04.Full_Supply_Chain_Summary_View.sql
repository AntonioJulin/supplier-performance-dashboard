/*
Here i generate a full denormalised supply chain summary view
and a couple queries on top of it to group by location and supplier
to be able to observe performance from a more general point of view
Used to have a denormalised table from which to better observe and identify issues by aggregate, 
like supplier issues, issues by location. Can also be expanded to observe potential issues in 
supply routes, lead times, or other factors.
*/

--If deleting views is desirable
DROP VIEW IF EXISTS summary_by_location;
DROP VIEW IF EXISTS summary_by_supplier;
DROP VIEW IF EXISTS supply_chain_summary;

--First we create a denormalised view that includes every column
CREATE VIEW supply_chain_summary AS
    SELECT
        products.sku,
        products.product_type,
        products.price,
        products.revenue_generated,
        products.number_of_products_sold,

        suppliers.supplier_id,
        suppliers.supplier_name,

        inventory.location,
        inventory.stock_levels,
        inventory.order_lead_time_days,
        inventory.supplier_lead_time_days,

        manufacturing.manufacturing_costs,
        manufacturing.manufacturing_lead_time,
        manufacturing.defect_rates,
        manufacturing.inspection_results,

        shipping.shipping_carrier,
        shipping.shipping_costs,
        shipping.shipping_time,
        shipping.transportation_mode,
        shipping.route
    FROM
        products
        JOIN inventory      ON inventory.sku = products.sku
        JOIN manufacturing  ON manufacturing.sku = products.sku
        JOIN shipping       ON shipping.sku = products.sku
        JOIN suppliers      ON suppliers.supplier_id = products.supplier_id;

-- Next we make a table aggregating by location
CREATE VIEW summary_by_location AS
    SELECT
        location,
        COUNT(DISTINCT sku)                 AS total_skus,
        ROUND(AVG(defect_rates), 2)         AS avg_defect_rate,
        ROUND(AVG(manufacturing_costs), 2)  AS avg_manufacturing_costs,
        ROUND(AVG(shipping_costs), 2)       AS avg_shipping_costs,
        ROUND(AVG(stock_levels), 2)         AS avg_stock_levels
    FROM
        supply_chain_summary
    GROUP BY
        location;

--Finally Aggregate by supplier
CREATE VIEW summary_by_supplier AS
SELECT
    supplier_id,
    supplier_name,
    COUNT(DISTINCT sku)                    AS total_skus,
    ROUND(AVG(defect_rates), 2)            AS avg_defect_rate,
    ROUND(AVG(manufacturing_costs), 2)     AS avg_manufacturing_cost,
    ROUND(AVG(shipping_costs), 2)          AS avg_shipping_cost,
    ROUND(SUM(revenue_generated), 2)       AS total_revenue
FROM
    supply_chain_summary
GROUP BY
    supplier_id, supplier_name
ORDER BY
    avg_defect_rate;


--Then we have a search function to present either of the aggregate views we've made
SELECT*
FROM supply_chain_summary
