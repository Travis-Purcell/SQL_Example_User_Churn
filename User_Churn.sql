#Calculates user churn for a given month
#Define months
WITH months AS 
(SELECT 
	'2017-01-01' as first_day,
	'2017-01-31' as last_day
	UNION
	SELECT
	'2017-02-01' as first_day,
	'2017-02-28' as last_day
	UNION
  SELECT
	'2017-03-01' as first_day,
	'2017-03-30' as last_day
),

#This combines the given table with our temporary months table, making the table more fluid
cross_join AS
(SELECT * FROM subscriptions CROSS JOIN months
),

#This defines whether a subscription is active or not for a given month for 2 segments (87 and 30 (AB testing))
###This is also where hard coding can be avoided for cases of large numbers of segments, instead of having segment=87, 30, 
###etc, this can be removed and instead
###just determine whether they're active or cancelled, and add the column 'segment' so that we can see what segment the 
###status is in.
status AS
(SELECT 
 id, 
 first_day AS month, 
 CASE 
 	WHEN (subscription_start < first_day) 
  AND (subscription_end > first_day OR subscription_end IS NULL) 
 	AND (segment = 87) THEN 1
 	ELSE 0
END AS is_active_87,
CASE 
 	WHEN (subscription_start < first_day) 
  AND (subscription_end > first_day OR subscription_end IS NULL) 
 	AND (segment = 30) THEN 1
 	ELSE 0
END AS is_active_30, 
CASE
 WHEN (subscription_end BETWEEN first_day AND   last_day)
 AND (segment = 87) THEN 1
 ELSE 0
END AS is_cancelled_87,
CASE
 WHEN (subscription_end BETWEEN first_day AND   last_day)
 AND (segment = 30) THEN 1
 ELSE 0
END AS is_cancelled_30
FROM cross_join
), 

#Adds number of active and cancelled from previous temp table.
status_aggregate AS 
(SELECT month,
 SUM(is_active_87) AS sum_active_87,
 SUM(is_active_30) AS sum_active_30,
 SUM(is_cancelled_87) AS sum_cancelled_87,
 SUM(is_cancelled_30) AS sum_cancelled_30 
FROM status
###For the avoid hard coding example, this would be grouped by month and segment
GROUP BY month
) 

#Calculates churn for each month.
SELECT month, 1.0*sum_cancelled_87/sum_active_87 AS churn_rate_87, 1.0*sum_cancelled_30/sum_active_30 AS churn_rate_30 
FROM status_aggregate;