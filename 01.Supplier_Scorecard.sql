/*
Supplier performance board showing upon request:
1. supplier ranking based on defect rate
2. weighted supplier scores based on defect rates, shipping costs, and manufacturing costs,
Used to identify suppliers in need of performance improvement plans or similar.
*/ 

-- we start off with deleting views if they exist to avoid errors
DROP VIEW IF EXISTS weighted_assessment;
DROP VIEW IF EXISTS supplier_stats;
DROP VIEW IF EXISTS supplier_assessment;

--Creating a table from where we can more easily pull from for our queries
CREATE VIEW supplier_assessment AS
    SELECT
    suppliers.supplier_id,
    suppliers.supplier_name,

    products.sku,
    products.revenue_generated,
    products.number_of_products_sold,

    manufacturing.defect_rates,
    manufacturing.manufacturing_costs,
    manufacturing.manufacturing_lead_time,
    manufacturing.inspection_results,

    shipping.shipping_costs,
    shipping.shipping_time,

    inventory.stock_levels,
    inventory.supplier_lead_time_days
    FROM
        suppliers
        INNER JOIN products        ON products.supplier_id = suppliers.supplier_id
        INNER JOIN manufacturing   ON manufacturing.sku = products.sku
        INNER JOIN shipping        ON shipping.sku = products.sku
        INNER JOIN inventory       ON inventory.sku = products.sku;


--Concentrating the values from supplier_assessment into a per supplier average
CREATE VIEW supplier_stats AS
SELECT
    supplier_id,
    supplier_name,
    COUNT(DISTINCT sku)                                        AS total_sku_count,

    -- Quality
    ROUND(AVG(defect_rates), 2)                       AS avg_defect_rate,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE inspection_results = 'Fail') / COUNT(*), 2
    )                                                           AS fail_rate_pct,

    -- Cost
    ROUND(AVG(manufacturing_costs), 2)                AS avg_manufacturing_cost,
    ROUND(AVG(shipping_costs), 2)                     AS avg_shipping_cost,

    -- Speed
    ROUND(AVG(manufacturing_lead_time), 2)            AS avg_manufacturing_lead_time,
    ROUND(AVG(shipping_time), 2)                      AS avg_shipping_time,
    ROUND(AVG(supplier_lead_time_days), 2)            AS avg_supplier_lead_time,
    ROUND(
        AVG(manufacturing_lead_time + shipping_time + supplier_lead_time_days), 2
    )                                                           AS avg_total_lead_time,

    -- Business impact
    ROUND(SUM(revenue_generated), 2)                              AS total_revenue,
    SUM(number_of_products_sold)                                  AS total_units_sold,
    ROUND(SUM(revenue_generated)/SUM(number_of_products_sold), 2) AS revenue_per_unit,

    -- Rankings
    RANK() OVER (ORDER BY AVG(defect_rates) ASC)               AS defect_rank,
    RANK() OVER (ORDER BY SUM(revenue_generated) DESC)         AS revenue_rank
FROM
    supplier_assessment
GROUP BY
    supplier_id, supplier_name
ORDER BY
    avg_defect_rate ASC;


--This query is used to give suppliers a score based on a weighted average of supplier_stats 
--Weights for weighted average are arbitrary, and in a real world scenario would be based on firm needs
CREATE VIEW weighted_assessment AS
SELECT
    supplier_name,
    ROUND((
        (AVG(defect_rates) * 0.3) +
        (AVG(manufacturing_costs) * 0.25) +
        (AVG(shipping_costs) * 0.15) +
        (AVG(manufacturing_lead_time + shipping_time + supplier_lead_time_days)* 0.30))
    , 2)                                 AS supplier_score,
    ROUND(AVG(defect_rates), 2)          AS avg_defect_rate,
    ROUND(AVG(manufacturing_costs), 2)   AS avg_manufacturing_cost,
    ROUND(AVG(shipping_costs), 2)        AS avg_shipping_cost,
    ROUND(AVG(manufacturing_lead_time + shipping_time + supplier_lead_time_days), 2)
                                         AS avg_total_lead_time
FROM
    supplier_assessment
GROUP BY
    supplier_name
ORDER BY
    supplier_score;

/*Here is where you query the views we have created:
1. supplier_stats - aggregate stats for each supplier
2. weighted_assessment - holistic assessment of supplier based on supplier_stats
NOTE: for the supplier score lower is better
*/
SELECT*
FROM weighted_assessment