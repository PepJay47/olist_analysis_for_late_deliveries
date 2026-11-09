-- we want to see if the carrier problem is a regional issue

WITH deadlines_for_orders AS (

	SELECT 
		order_id, 
		MAX(shipping_limit_date) as ship_limit
	FROM raw.order_items
	GROUP BY 1

)

SELECT
	c.customer_state,
	COUNT(*) as number_of_orders,
	ROUND(avg(o.order_delivered_customer_date::date - o.order_delivered_carrier_date::date),1) as average_courier_days,
	COUNT(*) FILTER (WHERE o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date) as late_orders,
	ROUND(100.0*avg((o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date)::int),1) as late_percentage
FROM raw.orders o
JOIN deadlines_for_orders od USING (order_id)
JOIN raw.customers c USING(customer_id)
WHERE o.order_status ='delivered' AND o.order_delivered_customer_date IS NOT NULL AND o.order_delivered_carrier_date IS NOT NULL AND o.order_delivered_carrier_date::date <= od.ship_limit::date
GROUP BY c.customer_state
HAVING COUNT(*) >= 100
ORDER BY 5 DESC
	
