-- we need to see whose fault it is, in terms of orders being late
-- this could be the seller or it could be the carrier


WITH deadlines_for_orders AS (

	SELECT 
		order_id, 
		MAX(shipping_limit_date) as ship_limit
	FROM raw.order_items
	GROUP BY 1

)


SELECT
	CASE
		WHEN o.order_delivered_carrier_date::date > od.ship_limit::date THEN 'Item handed in late by seller'
		ELSE 'Item handed in on time by seller'
	END AS sellers_handover,
	COUNT(*) as number_of_orders,
	COUNT(*) FILTER (WHERE o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date) as late_orders,
	ROUND(100.0*avg((o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date)::int),1) as late_percentage
FROM raw.orders o
JOIN deadlines_for_orders od USING (order_id)
WHERE o.order_status ='delivered' AND o.order_delivered_customer_date IS NOT NULL AND o.order_delivered_carrier_date IS NOT NULL
GROUP BY sellers_handover
ORDER BY sellers_handover;
	