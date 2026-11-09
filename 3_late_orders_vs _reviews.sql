
WITH reviews_per_order AS (

	SELECT 
		order_id,
		avg(review_score) AS review_score
	FROM raw.order_reviews
	GROUP BY order_id
),
delivered_orders as (

	SELECT
		order_id,
		order_delivered_customer_date::date - order_estimated_delivery_date::date as number_of_days_late
	FROM raw.orders
	WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL
) 

SELECT
	CASE
		WHEN dlvd.number_of_days_late <=0 THEN 'On time/early'
		WHEN dlvd.number_of_days_late <=3 THEN '1 to 3 days late'
		WHEN dlvd.number_of_days_late<=7 THEN '4 to 7 days late'
		WHEN dlvd.number_of_days_late<=14 THEN '8 to 14 days late'
		ELSE '15+ days late'
	END AS delivery_classes,
	COUNT(*) as number_of_orders,
	ROUND(avg(rpo.review_score),2) as avg_review_score,
	ROUND(100.0 * avg((rpo.review_score <=2)::int),1) as bad_review_percentage
FROM delivered_orders dlvd
JOIN reviews_per_order rpo USING(order_id)
GROUP BY delivery_classes
ORDER BY delivery_classes;