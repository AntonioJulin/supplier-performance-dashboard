-- dropping tables if they exist
DROP TABLE IF EXISTS shipping;
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS manufacturing;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS suppliers;


-- Creating table for suppliers with primary key
CREATE TABLE suppliers 
(
    supplier_id     INTEGER PRIMARY KEY,
    supplier_name   TEXT
);

-- Creating table for products with primary key and foreign key
CREATE TABLE products 
(
    sku                         TEXT PRIMARY KEY,
    product_type                TEXT,
    price                       NUMERIC(10,2),
    availability                INTEGER,
    number_of_products_sold     INTEGER,
    revenue_generated           NUMERIC(12,2),
    customer_demographics       TEXT,
    supplier_id                 INTEGER REFERENCES suppliers(supplier_id)
);

--Creating table for manufacturing with primary key
CREATE TABLE manufacturing
(
    sku                       TEXT PRIMARY KEY REFERENCES products(sku),
    production_volumes        INTEGER,
    manufacturing_lead_time  INTEGER,
    manufacturing_costs       NUMERIC(10,2),
    inspection_results        TEXT,
    defect_rates              NUMERIC(6,4)
);

--Creating table for inventory with primary key
CREATE TABLE inventory
(
    sku                       TEXT PRIMARY KEY REFERENCES products(sku),
    stock_levels              INTEGER,
    order_lead_time_days      INTEGER,
    order_quantities          INTEGER,
    supplier_lead_time_days  INTEGER,
    location                  TEXT
);

--Creating table for shipping with primary key
CREATE TABLE shipping
(
    sku                      TEXT PRIMARY KEY REFERENCES products(sku),
    shipping_time           INTEGER,
    shipping_carrier        TEXT,
    shipping_costs           NUMERIC(10,2),
    transportation_mode      TEXT,
    route                    TEXT,
    costs                    NUMERIC(10,2)
);

--Setting ownership of the tables to the current user
ALTER TABLE suppliers OWNER TO current_user;
ALTER TABLE products OWNER TO current_user;
ALTER TABLE manufacturing OWNER TO current_user;
ALTER TABLE inventory OWNER TO current_user;
ALTER TABLE shipping OWNER TO current_user;