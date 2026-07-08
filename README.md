# Supplier & Supply Chain Performance Dashboard (PostgreSQL)

A SQL project analyzing supplier performance, inventory risk, and product-level
quality across a simulated supply chain dataset. Built entirely in PostgreSQL
using layered views, CTEs, window functions, and both normalized and
denormalized reporting patterns.

## Tech Stack

SQL

## Techniques Demonstrated

- Multi-table `INNER JOIN`s (up to 5 tables in one query)
- `GROUP BY` with multiple simultaneous aggregates
- Window functions: `RANK() OVER (ORDER BY ...)` for supplier rankings
- Common Table Expressions (`WITH`) for readable, staged logic
- Layered views for maintainable, reusable reporting pipelines
- Conditional aggregation via `FILTER (WHERE ...)` (fail rate calculation)
- Correlated subqueries (comparing a row's value against a table-wide average)
- Weighted composite scoring across multiple normalized business metrics
- Deliberate denormalization of a normalized schema for reporting purposes

## Overview

This project answers three practical supply chain questions:

1. **Which suppliers are performing well or poorly**, and by how much, across
   defect rate, cost, and speed?
2. **Which SKUs are at risk of stocking out**, based on current inventory
   levels relative to demand and lead time?
3. **Which individual products have unusually high defect rates**, and how far
   above average are they?

A fourth component builds a fully denormalized reporting view across all five
source tables, then rolls it up by location and by supplier — deliberately
reversing the normalized schema to demonstrate why (and when) denormalization
is useful for reporting.

## Sample Insights

- **Supplier 4 shows compounding cost and quality issues.**
  A supplier score 12% worse than the next-worst supplier, driven by manufacturing costs 38% above the next costliest supplier, plus a 66% inspection fail rate (next-highest supplier doesn't break 40%). Other metrics are in line with peers, suggesting this is a supplier-specific problem rather than a broader pattern; worth flagging for a dedicated improvement plan or audit in real world scenario.
- **11 SKUs have insufficient stock levels to fulfill demand over lead time.**
  In real world scenario overhauling order policies/safety stock etc. would be necessary as multiple SKUs can't even fill 25% of demand over lead time (worst one is under 4% fulfillment)
- **Defect rates seem to be unrelated to supplier.**
  A single supplier doesn't have noticeably more SKUs with an above average defect rate, but some SKUs have a defect rate over twice as high as average. Merits process improvement on a per-SKU basis

## Data Model

The database consists of five normalized tables, each representing a distinct
entity:

| Table | Grain | Key Columns |
|---|---|---|
| `suppliers` | one row per supplier | `supplier_id`, `supplier_name` |
| `products`  | one row per SKU     | `sku`, `product_type`, `price`, `revenue_generated`, `number_of_products_sold`, `supplier_id` |
| `manufacturing` | one row per SKU | `defect_rates`, `manufacturing_costs`, `manufacturing_lead_time`, `inspection_results` |
| `shipping` | one row per SKU | `shipping_costs`, `shipping_time`, `shipping_carrier`, `route` |
| `inventory` | one row per SKU | `stock_levels`, `order_lead_time_days`, `supplier_lead_time_days`, `location` |

**Important structural note:** `manufacturing`, `shipping`, and `inventory`
are all keyed by `sku`, not by supplier. The only link back to a supplier is
`products.supplier_id`. This means every supplier-level metric in this project
(defect rate, cost, lead time, etc.) is **derived** by aggregating all SKUs
tied to that supplier. It is not a directly measured supplier statistic. This
distinction matters for interpretation and is discussed further in
Limitations below.

## Project Structure

```
sql_project/
├── 01_create_database.sql                -- creates the database
├── 02_create_tables.sql                  -- schema: 5 tables, PK/FK constraints
├── 03_modify_tables.sql                  -- loads data from CSV via COPY
├── 01_Supplier_Scorecard.sql             -- supplier ranking + weighted scoring
├── 02_Inventory_Risk_Report.sql          -- stockout risk by SKU
├── 03_SKU_High_Defect_Rates.sql          -- above-average defect rate SKUs
├── 04_Full_Supply_Chain_Summary_View.sql -- denormalized report + rollups
└── /data                                 -- source CSVs
```

## How to Run

Run the setup scripts in order first, then any of the four analysis files
independently (each is self-contained and drops/recreates its own views):

```
01_create_database.sql
02_create_tables.sql
03_modify_tables.sql   -- update the CSV file paths for your machine first
```

Then run any of `01`–`04` in any order, since none of them depend on each
other's views.

## Key Design Decisions & Assumptions

- **`weighted_assessment` combines defect rate, manufacturing cost, shipping
  cost, and total lead time using arbitrary weights (30/25/15/30).** In a real
  business setting these weights would reflect actual company priorities. For
  this score, **lower is better**, this is called out explicitly in the SQL
  comments since it's the opposite convention of most "score" metrics.
- **`number_of_products_sold` has no stated timeframe** in the source data.
  `02_Inventory_Risk_Report.sql` assumes this represents a 12-month
  total (dividing by 365 to get a daily rate)
- **Supplier-level metrics are aggregations, not direct measurements** (see
  Data Model note above), every "supplier defect rate" is really "the average
  defect rate of all SKUs sourced from that supplier."
- **The weighted score is unnormalized.** Defect rate, cost, and lead time are
  on very different numeric scales, so metrics with larger raw magnitudes
  (e.g., lead time in days vs. defect rate as a small percentage) have more
  practical influence on the final score than the stated weight alone would
  suggest. A min-max normalization step (rescaling each metric to 0–100 before
  weighting) would make the weights behave as intended.

## Limitations

- **Location-level rollups likely reflect supplier mix, not a true location effect.**     
  `summary_by_location` groups defect rate and manufacturing cost by
  warehouse location, but these are properties of how a product was made,
  not where it's stored. Any pattern by location is more likely explained by
  which suppliers happen to ship to that location, rather than something about
  the location itself. Shipping cost is the one metric in this rollup that is
  more directly tied to location, since it reflects the actual cost of
  supplying that warehouse.
- **`number_of_products_sold` timeframe is assumed, not confirmed** (see
  above).
- **The weighted supplier score is unnormalized** and sensitive to the
  relative scale of its inputs (see above).

