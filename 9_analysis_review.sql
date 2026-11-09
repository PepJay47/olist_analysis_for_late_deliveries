CREATE SCHEMA IF NOT EXISTS analysis;

CREATE OR REPLACE VIEW analysis.delivered_orders AS

WITH items as (

	SELECT
		order_id,
		count(*) as number_of_items,
		SUM(price) as item_cost,
		SUM(freight_value) as freight_cost,
		MAX(shipping_limit_date) as ship_limit
	FROM raw.order_items
	GROUP BY order_id

),
reviews AS (

	SELECT order_id, avg(review_score) as avg_review_score
	FROM raw.order_reviews
	GROUP BY order_id
)

SELECT
	o.order_id,
	c.customer_unique_id,
	c.customer_state,
	o.order_purchase_timestamp::date as date_purchased,
	o.order_estimated_delivery_date::date - o.order_purchase_timestamp::date as days_promised,
	o.order_delivered_customer_date::date - o.order_purchase_timestamp::date as actual_days,
	o.order_delivered_customer_date::date - o.order_delivered_carrier_date::date as courier_days,
	o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date as number_of_days_late,
	(o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date) as order_is_late,
	(o.order_delivered_carrier_date::date > it.ship_limit::date) as seller_handed_over_late,
	it.number_of_items,
	it.item_cost,
	it.freight_cost,
	rv.avg_review_score
FROM raw.orders o
JOIN raw.customers c USING (customer_id)
LEFT JOIN items it USING (order_id)
LEFT JOIN reviews rv USING (order_id)
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL