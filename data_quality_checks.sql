-- customer_id looks like it is per order, customer_unique_id is the actual person
SELECT
	(SELECT COUNT(*) FROM raw.orders) as orders,
	COUNT(DISTINCT customer_id) as distinct_customer_id,
	COUNT(DISTINCT customer_unique_id) as distinct_people
FROM raw.customers;

-- order statuses that exist
SELECT
	order_status,
	COUNT(*) as orders,
	ROUND(100.0*COUNT(*) / SUM(COUNT(*)) OVER (),2) as pct
FROM raw.orders
GROUP BY 1
ORDER BY 2 DESC;

-- status and delivery date that disagree
SELECT
	COUNT(*) FILTER (WHERE order_status = 'delivered' AND order_delivered_customer_date IS NULL) as delivered_but_no_date,
	COUNT(*) FILTER (WHERE order_status <> 'delivered' AND order_delivered_customer_date IS NOT NULL) as not_delivered_but_has_date
FROM raw.orders;

-- timestamps in the wrong order, these should all be 0
SELECT
	COUNT(*) FILTER (WHERE order_approved_at < order_purchase_timestamp) as approved_before_purchase,
	COUNT(*) FILTER (WHERE order_delivered_carrier_date < order_approved_at) as carrier_before_approval,
	COUNT(*) FILTER (WHERE order_delivered_customer_date < order_delivered_carrier_date) as delivered_before_carrier,
	COUNT(*) FILTER (WHERE order_delivered_customer_date < order_purchase_timestamp) as delivered_before_purchase
FROM raw.orders;

-- first and last order
SELECT
	MIN(order_purchase_timestamp) as first_order,
	MAX(order_purchase_timestamp) as last_order
FROM raw.orders;

-- orders per month, looking for thin months at the start and end
SELECT
	TO_CHAR(DATE_TRUNC('month',order_purchase_timestamp),'YYYY-MM') as month,
	COUNT(*) as orders
FROM raw.orders
GROUP BY 1
ORDER BY 1;

-- review counts and orders with more than one review
WITH repeat_reviews AS (

	SELECT order_id
	FROM raw.order_reviews
	GROUP BY order_id
	HAVING COUNT(*) > 1
)

SELECT
	COUNT(*) as review_rows,
	COUNT(DISTINCT review_id) as distinct_review_ids,
	COUNT(DISTINCT order_id) as orders_with_a_review,
	(SELECT COUNT(*) FROM repeat_reviews) as orders_with_2plus_reviews
FROM raw.order_reviews;

-- reviews answered before the parcel arrived
SELECT
	COUNT(*) as reviews_answered_before_delivery
FROM raw.order_reviews r
JOIN raw.orders o USING (order_id)
WHERE r.review_answer_timestamp < o.order_delivered_customer_date;

-- items with no order, orders with no items or payment
WITH items_no_order AS (

	SELECT i.order_id
	FROM raw.order_items i
	WHERE NOT EXISTS (SELECT 1 FROM raw.orders o WHERE o.order_id = i.order_id)
),

orders_no_items AS (

	SELECT o.order_id
	FROM raw.orders o
	WHERE NOT EXISTS (SELECT 1 FROM raw.order_items i WHERE i.order_id = o.order_id)
),

orders_no_payment AS (

	SELECT o.order_id
	FROM raw.orders o
	WHERE NOT EXISTS (SELECT 1 FROM raw.order_payments p WHERE p.order_id = o.order_id)
)

SELECT
	(SELECT COUNT(*) FROM items_no_order) as items_without_order,
	(SELECT COUNT(*) FROM orders_no_items) as orders_without_items,
	(SELECT COUNT(*) FROM orders_no_payment) as orders_without_payment;

-- how many orders have more than one seller
-- we can only blame one seller for lateness if the order has one seller
WITH order_sellers AS (

	SELECT order_id,COUNT(DISTINCT seller_id) as sellers_in_order
	FROM raw.order_items
	GROUP BY 1
)

SELECT
	sellers_in_order,
	COUNT(*) as orders
FROM order_sellers
GROUP BY 1
ORDER BY 1;

-- products missing a category or weight, categories with no translation
WITH missing_translation AS (

	SELECT DISTINCT p.product_category_name
	FROM raw.products p
	WHERE p.product_category_name IS NOT NULL
		AND NOT EXISTS (SELECT 1 FROM raw.category_translation t WHERE t.product_category_name = p.product_category_name)
)

SELECT
	COUNT(*) FILTER (WHERE product_category_name IS NULL) as products_no_category,
	COUNT(*) FILTER (WHERE product_weight_g IS NULL) as products_no_weight,
	(SELECT COUNT(*) FROM missing_translation) as categories_missing_translation
FROM raw.products;

-- payment types
SELECT
	payment_type,
	COUNT(*) as payment_rows
FROM raw.order_payments
GROUP BY 1
ORDER BY 2 DESC;

-- zip prefixes repeat a lot in geolocation, joining it raw multiplies rows
SELECT
	COUNT(*) as geo_rows,
	COUNT(DISTINCT geolocation_zip_code_prefix) as distinct_prefixes,
	ROUND(COUNT(*)::numeric / COUNT(DISTINCT geolocation_zip_code_prefix),1) as avg_rows_per_prefix
FROM raw.geolocation;
