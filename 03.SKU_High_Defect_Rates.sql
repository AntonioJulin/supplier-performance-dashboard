/*
This query simply finds the individual SKUs with an above average defect rate,
and filters for them, showing defect rate, average defect rate, and SKUs defect rate as % of average defect rate.
Can be used to identify SKUs to focus manufacturing improvement processes on
*/
WITH defect_average AS
(
SELECT
    manufacturing.sku,
    defect_rates,
    suppliers.supplier_name,
    (SELECT ROUND(AVG(defect_rates), 2)FROM manufacturing)  AS avg_defect_rates 
FROM 
    manufacturing
    JOIN products ON manufacturing.sku = products.sku
    JOIN suppliers ON products.supplier_id = suppliers.supplier_id
WHERE
    defect_rates > (SELECT AVG(defect_rates) FROM manufacturing)
)
SELECT
    sku,
    defect_rates,
    avg_defect_rates,
    supplier_name,
    ROUND((defect_rates / avg_defect_rates) * 100, 2) AS pct_of_avg_defects
FROM
    defect_average
ORDER BY
    supplier_name;