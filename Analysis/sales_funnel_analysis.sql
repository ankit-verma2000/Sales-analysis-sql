SELECT  * FROM `my-project-485806.rental_e_bike.user_events` LIMIT 1000;

-- Define sales funnel and the differnt stages:
WITH funnel_stages AS (
  SELECT 
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END ) AS stage_1_views,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END ) AS stage_2_cart,
    COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END ) AS stage_3_checkout,
    COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END ) AS stage_4_payment,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END ) AS stage_5_purchase
  FROM `rental_e_bike.user_events`
  WHERE event_date  >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))

)

SELECT * FROM funnel_stages;

-- Conversion rate:

WITH funnel_stages AS (
  SELECT 
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END ) AS stage_1_views,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END ) AS stage_2_cart,
    COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END ) AS stage_3_checkout,
    COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END ) AS stage_4_payment,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END ) AS stage_5_purchase
  FROM `rental_e_bike.user_events`
  WHERE event_date  >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))

)

SELECT  
  stage_1_views, stage_2_cart,
  ROUND(stage_1_views * 100/ stage_2_cart) AS view_to_cart_rate,
  stage_3_checkout,
  ROUND(stage_3_checkout * 100/ stage_2_cart) AS checkout_to_cart_rate,
  stage_4_payment,
  ROUND(stage_4_payment * 100/ stage_3_checkout) AS payment_to_checkout_rate,
  stage_5_purchase,
  ROUND(stage_5_purchase * 100/ stage_4_payment) AS purchase_to_payment_rate,
  ROUND(stage_5_purchase * 100/ stage_1_views) AS overall_conversion_rate
FROM funnel_stages;

-- Funnel by source:
WITH source_funnel AS (
  SELECT
    traffic_source, 
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END ) AS views,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END ) AS carts,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END ) AS purchases
  FROM `rental_e_bike.user_events`
  WHERE event_date  >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
  group by traffic_source
)

SELECT  
  traffic_source, views, carts, purchases, 
  ROUND(carts *100/ views) as carts_conversion_rate,
  ROUND(purchases *100/ views) as purchases_conversion_rate,
  ROUND(purchases *100/ carts) as carts_to_purchase_conversion_rate
FROM source_funnel
ORDER BY purchases DESC;

-- Time to conversion analysis:
WITH user_journey AS (
  SELECT
    user_id, 
    MIN(CASE WHEN event_type = 'page_view' THEN event_date END ) AS view_time,
    MIN(CASE WHEN event_type = 'add_to_cart' THEN event_date END ) AS cart_time,
    MIN(CASE WHEN event_type = 'purchase' THEN event_date END ) AS purchase_time
  FROM `rental_e_bike.user_events`
  WHERE event_date  >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
  group by user_id
  HAVING MIN(CASE WHEN event_type = 'purchase' THEN event_date END ) IS NOT NULL

)

SELECT  
  COUNT(*) AS converted_users, 
  ROUND(AVG(timestamp_diff(cart_time, view_time, MINUTE)),2) as avg_view_to_cart_minute,
  ROUND(AVG(timestamp_diff(purchase_time, view_time, MINUTE)),2) as avg_cart_to_purchase_minute,
  ROUND(AVG(timestamp_diff(purchase_time, view_time, MINUTE)),2) as avg_total_journey_minute
FROM user_journey;


-- Reveunue funnel analysis:

WITH funnel_revenue AS (
  SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN event_date END ) AS total_visitors,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN event_date END ) AS total_buyers,
    SUM(CASE WHEN event_type = 'purchase' THEN amount END ) AS total_revenue,
    COUNT(CASE WHEN event_type = 'purchase' THEN 1 END ) AS total_orders,
  FROM `rental_e_bike.user_events`
  WHERE event_date  >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))

)

SELECT  
  total_visitors, total_buyers, ROUND(total_revenue,2) total_revenue , total_orders,
  ROUND(total_revenue/ total_orders,2) as avg_order_value,
  ROUND(total_revenue/ total_buyers,2) as revenue_per_buyer,
  ROUND(total_revenue/ total_visitors,2) as revenue_per_visitors
FROM funnel_revenue;
