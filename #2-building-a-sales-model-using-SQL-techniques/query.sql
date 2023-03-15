-- The data science team wants to build a new model to help predict which 
-- customers are the best prospects for remarketing. A new data scientist has joined their 
-- team and does not know the database well enough to pull a dataset for this new model. 
-- The responsibility has fallen to you to help the new data scientist prepare and build a 
-- dataset to be used to train a model. 
-- Write a query to assemble a dataset that will do the following:

-- return all columns from the customer table and products table. Also return the dealership_id column
-- from the sales table but fill in dealership_id in sales with -1 if it is null
-- Add a column called high-savings that returns 1 if the sales amount was 500 less 
--than base_msrp or lower. Otherwise, it returns 0

select c.*,
p.*, 
coalesce(s.dealership_id, -1), 
case when p.base_msrp - s.sales_amount > 500
then 1
else 0
end as high_savings
from customers c
inner join sales s on c.customer_id = s.customer_id
inner join products p on p.product_id = s.product_id
left join dealerships d on s.dealership_id = d.dealership_id;