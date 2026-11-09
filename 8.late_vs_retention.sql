WITH customer_orders as (


	SELECT
		c.customer_unique_id,
		o.order_delivered_customer_date,
		o.order_estimated_delivery_date,
		ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp) as order_number,
		COUNT(*) OVER (PARTITION BY c.customer_unique_id) as total_number_of_orders
	FROM raw.orders o
	JOIN raw.customers c USING (customer_id)
	WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
)


SELECT
	CASE
		WHEN order_delivered_customer_date::date > order_estimated_delivery_date THEN 'First order was late'
		ELSE 'First order was on time'
	END AS customer_first_order,
	COUNT(*) as number_of_customers,
	COUNT(*) FILTER (WHERE total_number_of_orders > 1) as customer_came_back,
	ROUND(100.0 *avg((total_number_of_orders >1)::int),2) as percentage_that_come_back
FROM customer_orders
WHERE order_number = 1
GROUP BY 1
ORDER BY 1