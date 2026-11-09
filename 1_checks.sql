--order statuses that exist
SELECT
	ORDER_STATUS,
	COUNT(*) AS ORDERS
FROM
	RAW.ORDERS
GROUP BY
	1
ORDER BY
	2 DESC;

-- orders that have been delivered but do not have a delivery date
SELECT
	COUNT(*) AS NO_DATE_BUT_DELIVERED
FROM
	RAW.ORDERS
WHERE
	ORDER_STATUS = 'delivered'
	AND ORDER_DELIVERED_CUSTOMER_DATE IS NULL;

-- orders that have more than review
SELECT
	COUNT(*) AS ORDERS_WITH_MORE_THAN_ONE_REVIEW
FROM
	(
		SELECT
			ORDER_ID
		FROM
			RAW.ORDER_REVIEWS
		GROUP BY
			ORDER_ID
		HAVING
			COUNT(*) > 1
	);
	-- products that have no category assigned to them
SELECT
	COUNT(*) AS NO_CATEGORY
FROM
	RAW.PRODUCTS
WHERE
	PRODUCT_CATEGORY_NAME IS NULL;

