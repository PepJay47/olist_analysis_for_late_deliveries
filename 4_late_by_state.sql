-- looking at where the lateness happens
-- also looking at orders greater than 100


SELECT
	c.customer_state,
	COUNT(*) as number_of_orders,
	COUNT(*) FILTER (WHERE o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date) as late_orders,
	ROUND(100.0*avg((o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date)::int),1) as late_percentage,
	ROUND(avg(o.order_delivered_customer_date::date - o.order_purchase_timestamp::date),1) as actual_avg_delivery_days,
	ROUND(avg(o.order_estimated_delivery_date::date - o.order_purchase_timestamp::date),1) as promised_days_avg
FROM raw.orders o
JOIN raw.customers c USING (customer_id)
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(*) >= 100
ORDER BY late_percentage DESC;