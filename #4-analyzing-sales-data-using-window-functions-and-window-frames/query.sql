-- To analyze this data, the company would like a running total of how many 
-- users have filled in their street address over time. Write a query to produce these 
-- results
select 
customer_id,
street_address,
date_added::date,
count(
case when street_address is not null
	then customer_id
	else null end
)
over (order by date_added::date)
from customers
order by date_added;

-- alternate syntax --
select
customer_id,
street_address,
date_added::date,
count(
case when street_address is not null
	then customer_id
	else null end) over w as count_null_addresses
from customers
window w as (order by date_added::date)
order by date_added;

-- Gringo would like to promote salespeople at their regional dealerships to 
-- management and would like to consider tenure in their decision. Write a query that will 
-- rank the order of salesmen according to their hire date for each dealership:

select
salesperson_id,
concat_ws(' ', first_name,
last_name),
dealership_id,
rank() over w as rank
from salespeople
where termination_date is null
window w as (partition by dealership_id order by hire_date);

-- Find the employee with the second highest tenure in each dealership

select
salesperson_id,
hire_date,
concat_ws(' ', first_name, last_name) as full_name,
dealership_id,
nth_value(concat_ws(' ', first_name, last_name), 2) over w as runner_up
from salespeople
where termination_date is null
window w as (partition by dealership_id order by hire_date);

-- Calculate the 7-day rolling average of sales over time for Gringo.

with tt1 as (
select sales_transaction_date::DATE,
sum(sales_amount) as sales_per_day
from sales
group by 1
),

tt2 as (
select sales_transaction_date,
sales_per_day,
avg(sales_per_day) over (order by sales_transaction_date rows between 7 preceding and current row) as moving_average_7,
row_number() over (order by sales_transaction_date) as row_number
from tt1
order by 1
)

select sales_transaction_date,
case when row_number >= 7
then moving_average_7 else null end as moving_average_7
from tt2;

-- To help improve sales performance, the sales team has decided to give bonuses for all 
-- salespeople at the company every time they beat the figure for best daily total earnings 
-- achieved over the last 30 days. Write a query that produces the total sales in dollars 
-- for a given day and the target the salespeople have to beat for that day, starting from 
-- January 1, 2019:
with tt1 as (
select
sales_transaction_date::date,
sum(sales_amount) as sales_per_day
from sales
group by 1
),

tt2 as (
select
sales_transaction_date,
sales_per_day,
max(sales_per_day) over (order by sales_transaction_date
rows between 30 preceding and 1 preceding) as target_sales_30
from tt1
order by 1)
-- Notice the use of a window frame from 30 PRECEDING to 1 PRECEDING to remove the 
-- current row from the calculation.
select 
sales_transaction_date,
sales_per_day,
'$' || round(target_sales_30::numeric, 2) as target_sales_30
from tt2
where sales_transaction_date >= '2019-01-01';

-- It's the holidays, and it's time to give out Christmas bonuses at Gringo. Sales 
-- team want to see how the company has performed overall, as well as how individual 
-- dealerships have performed within the company. To achieve this, Gringo's head of 
-- Sales would like you to run an analysis for them:

-- 1. Open your favorite SQL client and connect to the sqlda database.
-- 2. Calculate the total sales amount by day for all of the days in the year 2018 (that is, 
--  before the date January 1, 2019).
select 
sales_transaction_date::date,
sum(sales_amount) as sales_per_day
from sales
where extract(year from sales_transaction_date) = 2018
group by 1;

--  3. Calculate the rolling 30-day average for the daily number of sales deals.
with tt1 as (
select 
sales_transaction_date::date,
count(*) as sales_deal_per_day
from sales
group by 1
),

tt2 as (
select 
sales_transaction_date,
sales_deal_per_day,
avg(sales_deal_per_day) over (order by sales_transaction_date 
rows between 30 preceding and current row) as rolling_avg_30,
row_number() over (order by sales_transaction_date) as row_number
from tt1
order by 1
)
select
sales_transaction_date,
case when row_number >= 30 then rolling_avg_30 else null end  
from tt2
where row_number > 30 and extract(year from sales_transaction_date) = 2018;
-- 4. Calculate what decile each dealership would be in compared to other dealerships 
--  based on their total sales amount

with tt1 as (
select 
dealership_id,
sum(sales_amount) as total_sales_amt
from sales
where extract(year from sales_transaction_date) = 2018
and channel = 'dealership'
group by 1
)

select
*,
ntile(10) over (order by total_sales_amt) as decile
from tt1;


