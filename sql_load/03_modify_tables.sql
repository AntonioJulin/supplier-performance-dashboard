--Inserting data from CSV files into the tables
\copy suppliers     FROM './data/suppliers.csv'     DELIMITER ',' CSV HEADER;
\copy products      FROM './data/products.csv'      DELIMITER ',' CSV HEADER;
\copy manufacturing FROM './data/manufacturing.csv' DELIMITER ',' CSV HEADER;
\copy inventory     FROM './data/inventory.csv'     DELIMITER ',' CSV HEADER;
\copy shipping      FROM './data/shipping.csv'      DELIMITER ',' CSV HEADER;