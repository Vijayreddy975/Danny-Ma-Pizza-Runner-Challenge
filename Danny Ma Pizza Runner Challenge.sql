USE Dannys_Pizza;

/* ---------- A. Pizza Metrics --------------- */ 

/* 1.How many pizzas were ordered? */

SELECT Count(Order_id) as no_of_pizzas
FROM Customer_Orders;

/* 2. How many unique customer orders were made? */

SELECT COUNT(Distinct customer_id) AS UNIQUE_Customers
from Customer_Orders;

/* 3. How many successful orders were delivered by each runner? */

SELECT r.runner_id,Count(c.order_id) as successful
from Customer_orders c
LEFT JOIN Runner_orders r
on c.order_id = r.order_id
group by r.runner_id;

/*ALTERNATE SOLUTION */

select runner_id,Count(order_id) as successful
from Runner_orders
where distance not like '%null%'
group by runner_id ;

/* 4. How many of each type of pizza was delivered?? */

SELECT Count(C.pizza_id) as pizza,p.pizza_name
from Customer_orders C
JOIN Pizza_names p
ON C.pizza_id = p.pizza_id
group by p.pizza_name;

/* 5. How many Vegetarian and Meatlovers were ordered by each customer */

SELECT C.customer_id,count(p.pizza_id) as types,p.pizza_name
from Customer_orders C
left join Pizza_names p
on C.pizza_id = p.pizza_id
group by C.customer_id,p.pizza_name
order by customer_id asc,types desc;

/* 6. What was the maximum number of pizzas delivered in a single order? */

SELECT Count(order_id) as No_of_pizza_delivered,order_id
from Customer_orders
group by order_id
order by No_of_pizza_delivered desc
limit 1;

/* 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes? */

select customer_orders.customer_id, 
sum(case
  when (exclusions is not null and exclusions != 0) or (extras is not null and extras != 0) then 1
        else 0
        end )as AtleastOneChange,
sum(case 
  when (exclusions is null or exclusions = 0) and (extras is null or extras = 0) then 1
        else 0
        end ) as NoChange
from customer_orders
inner join runner_orders
on runner_orders.order_id = customer_orders.order_id
where runner_orders.distance != 0
group by customer_orders.customer_id;



/* 8. How many pizzas were delivered that had both exclusions and extras? */
With CTE as (  
SELECT order_id,
CASE WHEN exclusions is null or exclusions  = ' ' then 0 else 1 end as exclusions,
CASE WHEN extras is null or extras  = ' ' then 0 else 1 end as extras
from Customer_orders)

Select Count(order_id)
from CTE
where (exclusions + extras)>1 ;

/* 9. What was the total volume of pizzas ordered for each hour of the day? */

SELECT Hour(order_time) as Hour_of_the_day,Count(Order_id) as volume
from Customer_orders
group by Hour(order_time)
Order by volume DESC;

/* 10. What was the volume of orders for each day of the week? */

 
SELECT dayofweek(order_time) as Day_of_week,Count(Order_id) as volume
from Customer_orders
group by dayofweek(order_time)
Order by volume DESC;


/*---------B) RUNNER AND CUSTOMER EXPERIENCE-------------*/

/* 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01) */


SELECT WEEK(registration_date) as week,count(runner_id) as times FROM runners
group  by week(registration_date);



/* 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order? */

SELECT R.runner_id, Avg(Minute(C.order_time)-Minute(R.pickup_time)) as MINUTES
from customer_orders C
LEFT JOIN runner_orders R 
ON C.order_id = R.order_id
GROUP BY R.runner_id;  


/* 3. Is there any relationship between the number of pizzas and how long the order takes to prepare? */

WITH CTE AS (
SELECT C.order_id,C.order_time,R.pickup_time FROM customer_orders C
INNER JOIN runner_orders R
ON C.order_id = R.order_id),
CTE1 as (
SELECT Minute(order_time) as orderM,Minute(pickup_time) as pickm,Order_id 
from CTE)
SELECT Count(order_id) as orders,pickm-orderM as minutes
from CTE1
GROUP BY pickm-orderM ;


/* 4. What was the average distance travelled for each customer? */


Select c.customer_id,round(avg(r.distance),1) as travelled  from customer_orders c
join runner_orders r
on c.order_id = r.order_id
Group by c.customer_id ;

/* 5. What was the difference between the longest and shortest delivery times for all orders? */

SELECT MAX(r.duration)-Min(r.duration) as durations
from runner_orders r;


/* 6. What was the average speed for each runner for each delivery and do you notice any trend for these values? */


DROP TABLE IF exists clean_runner_orders;
CREATE temporary TABLE  clean_runner_orders (
SELECT order_id,runner_id,
NULLIF(REGEXP_REPLACE(distance, '[^0-9.]', ''), '') AS distance,
        NULLIF(REGEXP_REPLACE(duration, '[^0-9.]', ''), '')  AS duration,
CASE WHEN cancellation = 'null' then NULL
Else cancellation end as Cancels
from runner_orders);       


SELECT runner_id,order_id,AVG(speed) as avg_speed from (
SELECT runner_id,order_id,CAST((distance/duration *60) as float) as speed FROM clean_runner_orders ) A
Group by runner_id,order_id;


/* 7. What is the successful delivery percentage for each runner? */
SELECT 
     runner_id, 
     ROUND(100 * SUM(
       CASE WHEN distance is null THEN 0
       ELSE 1 END) / COUNT(*), 0) AS success_perc
   FROM clean_runner_orders
   
   GROUP BY runner_id
   order by runner_id;  

