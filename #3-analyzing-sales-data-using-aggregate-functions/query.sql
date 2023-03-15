-- The CEO, COO, and CFO of Gringo would like to gain some insights on what might be driving sales. 
-- Now that the company feels they have a strong enough analytics team with your arrival. 
-- The task has been given to you:

-- 1. Open your favorite SQL client and connect to the sqlda database.
-- 2. Calculate the total number of unit sales the company has done.

    select count(*) total_unit_sales
	from sales;
	
-- 3. Calculate the total sales amount in dollars for each state.
	
	select round(sum(sales_amount)::numeric,2) as total_sales_amount
	from sales;
	
-- 4. Identify the top five best dealerships in terms of the most units sold (ignore 
-- internet sales).

	select dealership_id, sum(sales_amount)
	from sales 
	where channel <> 'internet'
	group by dealership_id
	order by 2
	limit 5;

-- 5. Calculate the average sales amount for each channel, as seen in the sales table, 
-- and look at the average sales amount first by channel sales, then by product_id, and 
-- then by both together.


SELECT s.channel, s.product_id, AVG(sales_amount) as avg_sales_amount
FROM sales s
GROUP BY 
GROUPING SETS(
(s.channel), (s.product_id),
(s.channel, s.product_id)
)
ORDER BY 1, 2

