--sellers which are causing the lateness
-- we are using sellers with enough orders to make a judgement

WITH order_sellers AS (

	SELECT DISTINCT order_id,seller_id
	FROM raw.order_items
)

SELECT
	os.seller_id,
	s.seller_state,
	COUNT(*) orders,
	COUNT(*) FILTER (WHERE o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date) as late_orders,
	ROUND(100.0*avg((o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date)::int),1) as late_percentage
FROM order_sellers os
JOIN raw.orders o USING (order_id)
JOIN raw.sellers s USING (seller_id)
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
GROUP BY 1,2
HAVING COUNT(*) >= 50
ORDER BY 5 DESC
LIMIT 20;