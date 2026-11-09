
-- loading the 9 olist csvs into postgres
-- run this in psql, the \copy lines dont work in the pgadmin query tool

-- you will need to edit this yourself
\cd '/path/to/olist'

-- raw data stays in its own schema, cleaning happens later in views
DROP SCHEMA IF EXISTS raw CASCADE;
CREATE SCHEMA raw;
SET search_path TO raw;

-- no primary or foreign keys yet, some would fail on duplicates like review_id
-- zip prefixes are text to keep the leading zeros

CREATE TABLE customers (
    customer_id              text,
    customer_unique_id       text,
    customer_zip_code_prefix text,
    customer_city            text,
    customer_state           text
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix text,
    geolocation_lat             numeric,
    geolocation_lng             numeric,
    geolocation_city            text,
    geolocation_state           text
);

CREATE TABLE orders (
    order_id                      text,
    customer_id                   text,
    order_status                  text,
    order_purchase_timestamp      timestamp,
    order_approved_at             timestamp,
    order_delivered_carrier_date  timestamp,
    order_delivered_customer_date timestamp,
    order_estimated_delivery_date timestamp
);

CREATE TABLE order_items (
    order_id            text,
    order_item_id       int,
    product_id          text,
    seller_id           text,
    shipping_limit_date timestamp,
    price               numeric(10,2),
    freight_value       numeric(10,2)
);

CREATE TABLE order_payments (
    order_id             text,
    payment_sequential   int,
    payment_type         text,
    payment_installments int,
    payment_value        numeric(10,2)
);

CREATE TABLE order_reviews (
    review_id               text,
    order_id                text,
    review_score            int,
    review_comment_title    text,
    review_comment_message  text,
    review_creation_date    timestamp,
    review_answer_timestamp timestamp
);

-- "lenght" is how olist spells it in the csv, keeping it so the columns match
CREATE TABLE products (
    product_id                 text,
    product_category_name      text,
    product_name_lenght        int,
    product_description_lenght int,
    product_photos_qty         int,
    product_weight_g           int,
    product_length_cm          int,
    product_height_cm          int,
    product_width_cm           int
);

CREATE TABLE sellers (
    seller_id              text,
    seller_zip_code_prefix text,
    seller_city            text,
    seller_state           text
);

CREATE TABLE category_translation (
    product_category_name         text,
    product_category_name_english text
);


-- loading the data, each \copy has to stay on one line

\copy customers            FROM 'olist_customers_dataset.csv'            WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy geolocation          FROM 'olist_geolocation_dataset.csv'          WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy orders               FROM 'olist_orders_dataset.csv'               WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy order_items          FROM 'olist_order_items_dataset.csv'          WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy order_payments       FROM 'olist_order_payments_dataset.csv'       WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy order_reviews        FROM 'olist_order_reviews_dataset.csv'        WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy products             FROM 'olist_products_dataset.csv'             WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy sellers              FROM 'olist_sellers_dataset.csv'              WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy category_translation FROM 'product_category_name_translation.csv'  WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')


-- checking the row counts
SELECT 'customers' AS table_name, count(*) AS row_count FROM customers
UNION ALL SELECT 'geolocation',          count(*) FROM geolocation
UNION ALL SELECT 'orders',               count(*) FROM orders
UNION ALL SELECT 'order_items',          count(*) FROM order_items
UNION ALL SELECT 'order_payments',       count(*) FROM order_payments
UNION ALL SELECT 'order_reviews',        count(*) FROM order_reviews
UNION ALL SELECT 'products',             count(*) FROM products
UNION ALL SELECT 'sellers',              count(*) FROM sellers
UNION ALL SELECT 'category_translation', count(*) FROM category_translation
ORDER BY table_name;
