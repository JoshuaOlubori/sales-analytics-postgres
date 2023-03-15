-- List the model, base_msrp (MSRP stands for manufacturer's -- suggested retail 
-- price), and production_start_date fields within the product table for product types matching scooter
select 
model,
base_msrp,
production_start_date
from products
where product_type = 'scooter'
order by base_msrp desc;

-- Extract the model name and product IDs for the scooters available within the 
-- database. We will need this information to reconcile the product information with 
-- the available sales information:
select model, product_id from products 
where product_type='scooter';

-- Insert the results of this query into a new table called product_names:
select model, product_id into product_names from products 
where product_type='scooter';

-- With the preliminary 
-- information at hand, we can use it to extract the Bat Scooter sales records and discover 
-- what is actually going on. We have a table, product_names, that contains both the 
-- model names and product IDs. We will need to combine this information with the 
-- sales records and extract only those for the Bat Scooter:
select model, customer_id,
sales_transaction_date, sales_amount,
channel, dealership_id into products_sales
from sales inner join product_names
on sales.product_id = product_names.product_id;

-- look at the first 5 rows of the new table
select * from products_sales limit 5;

-- Select all the information from the product_sales table that is available for the 
-- Bat Scooter and order the sales information by sales_transaction_date in 
-- ascending order. By selecting the data in this way, we can look at the first few days 
-- of the sales records in detail:
select * from products_sales where model='Bat' order by sales_transaction_date;

-- The model count for the 'Bat' model is as follows:
select count(*) from products_sales
where model = 'Bat';
-- so, we have 7328 sales, beginning on October 10, 2016. Check the date of the final 
-- sales record by performing the next step.

select max(sales_transaction_date::date) from products_sales where 
model='Bat';

--          max
---------------------
-- 2019-05-31 22:15:30
-- (1 row)
-- This shows last sale occurred 31st May, 2019
 
-- Create a new table `bat_sales` to confirm the information provided by the sales team stating that 
-- sales dropped by 20% after the first 2 weeks:
select * into bat_sales
from products_sales 
where model='Bat' 
order by sales_transaction_date;

-- Remove the time-related information to allow tracking of sales by date, since, at 
-- this stage, we are not interested in the time each sale occurred. To do so, run the 
-- following query:
update bat_sales
set sales_transaction_date = DATE(sales_transaction_date);

-- Check out the new table
 select * from bat_sales order by sales_transaction_date limit 
5;

-- Create a new table (bat_sales_daily) containing the sales transaction dates and 
-- a daily count of total sales:
select sales_transaction_date,
count(sales_transaction_date) 
into bat_sales_daily from bat_sales
group by sales_transaction_date 
order by sales_transaction_date;

-- Examine the first 22 records which is a little over 3 weeks, as sales were reported to have 
-- dropped after approximately the first 2 weeks:
select * from bat_sales_daily limit 22;


-- sales_transaction_date | count
------------------------+-------
-- 2016-10-10 00:00:00    |     9
-- 2016-10-11 00:00:00    |     6
-- 2016-10-12 00:00:00    |    10
-- 2016-10-13 00:00:00    |    10
-- 2016-10-14 00:00:00    |     5
-- 2016-10-15 00:00:00    |    10
-- 2016-10-16 00:00:00    |    14
-- 2016-10-17 00:00:00    |     9
-- 2016-10-18 00:00:00    |    11
-- 2016-10-19 00:00:00    |    12
-- 2016-10-20 00:00:00    |    10
-- 2016-10-21 00:00:00    |     6
-- 2016-10-22 00:00:00    |     2
-- 2016-10-23 00:00:00    |     5
-- 2016-10-24 00:00:00    |     6
-- 2016-10-25 00:00:00    |     9
-- 2016-10-26 00:00:00    |     2
-- 2016-10-27 00:00:00    |     4
-- 2016-10-28 00:00:00    |     7
-- 2016-10-29 00:00:00    |     5
-- 2016-10-30 00:00:00    |     5
-- 2016-10-31 00:00:00    |     3
-- (22 rows)

-- We can affirm a drop in sales after 11 days, with sales dropping from double digits
-- to sigle digits after 11 days of sales on the 20th of October, 2016

-- B. QUANTIFYING THE SALES DROP

-- Using the OVER and ORDER BY statements, compute the daily cumulative sum of 
-- sales. This provides us with a discrete count of sales over a period of time on a daily 
-- basis. Insert the results into a new table called bat_sales_growth
select *,
sum(count) over (order by sales_transaction_date) as cum_sales
into bat_sales_growth
from bat_sales_daily;

-- Compute a 7-day lag function of the sum column and insert all the columns of bat_
-- sales_daily and the new lag column into a new table, bat_sales_daily_delay. This 
-- lag column indicates what the sales were like 1 week before the given record:
select *,
lag(cum_sales, 7) over (order by sales_transaction_date)
into bat_sales_daily_delay
from bat_sales_growth;

-- Inspect the new table
select * from bat_sales_daily_delay;

-- Compute the sales growth as a percentage, comparing the current sales volume 
-- to that of 1 week prior. Insert the resulting table into a new table called bat_sales_
-- delay_vol:
select *,
round(((cum_sales - lag) / lag) * 100,2) as growth_pct
into bat_sales_delay_vol
from bat_sales_daily_delay;

-- Inspecting the table
select * from bat_sales_delay_vol;


-- STRATEGY
-- Because I am looking for drops in sales growth
-- over the first couple of weeks, I compare the daily sum of 
-- sales to the same values 7 days earlier (the lag).
-- By subtracting the sum and lag values 
-- and dividing by the lag, we obtain the volume value and can -- determine sales growth 
-- compared to the previous week. As time 
-- passes, this relative difference begins to decrease dramatically.
-- Hence, it is confirmed that sales experienced a drop in growth

-- C. HYPOTHESIS TESTING
-- To explain the cause of the sales drop, I am testing the hypothesis that the timing of the scooter launch attributed to the 
-- reduction in sales.

select * from products;
-- product_id |         model         | year | product_type | base_msrp | production_start_date | production_end_date
------------+-----------------------+------+--------------+-----------+-----------------------+---------------------
--          1 | Lemon                 | 2010 | scooter      |    399.99 | 2010-03-03 00:00:00   | 2012-06-08 00:00:00
--         2 | Lemon Limited Edition | 2011 | scooter      |    799.99 | 2011-01-03 00:00:00   | 2011-03-30 00:00:00
--          3 | Lemon                 | 2013 | scooter      |    499.99 | 2013-05-01 00:00:00   | 2018-12-28 00:00:00
--          5 | Blade                 | 2014 | scooter      |    699.99 | 2014-06-23 00:00:00   | 2015-01-27 00:00:00
--          7 | Bat                   | 2016 | scooter      |    599.99 | 2016-10-10 00:00:00   |
--          8 | Bat Limited Edition   | 2017 | scooter      |    699.99 | 2017-02-15 00:00:00   |
--         12 | Lemon Zester          | 2019 | scooter      |    349.99 | 2019-02-04 00:00:00   |
--          4 | Model Chi             | 2014 | automobile   | 115000.00 | 2014-06-23 00:00:00   | 2018-12-28 00:00:00
--          6 | Model Sigma           | 2015 | automobile   |  65500.00 | 2015-04-15 00:00:00   | 2018-10-01 00:00:00
--          9 | Model Epsilon         | 2017 | automobile   |  35000.00 | 2017-02-15 00:00:00   |
--         10 | Model Gamma           | 2017 | automobile   |  85750.00 | 2017-02-15 00:00:00   |
--         11 | Model Chi             | 2019 | automobile   |  95000.00 | 2019-02-04 00:00:00   |
-- (12 rows)

-- Note that all the other products launched before July, compared to the Bat Scooter, which 
-- launched in October.

-- store information about the sales of the Bat Limited Edition scooter 
-- in a table called bat_ltd_sales,
-- ordered by date from the earliest sale to the latest sale
select products.model, sales.sales_transaction_date
into bat_ltd_sales 
from sales inner join 
products on sales.product_id=products.product_id 
where sales.product_id=8 
order by sales.sales_transaction_date

-- compare the total number of sales for the Bat Limited Edition and the 
-- original Bat model
select count(*) from bat_ltd_sales
union
select count(*) from bat_sales;

-- the query shows that the bat model sold more
-- Discard the time information
alter table bat_ltd_sales 
alter column sales_transaction_date 
type date;

-- Create a table for count of sales on a daily basis, the cumulative sum of this
-- count, a 1 week lag and then for a growth percentage, just like I did for
-- the original Bat model

select sales_transaction_date,
count(sales_transaction_date)
into bat_ltd_sales_count -- count table
from bat_ltd_sales
group by sales_transaction_date 
order by sales_transaction_date;

select *, 
sum(count) over(order by sales_transaction_date) as cum_sales 
into bat_ltd_sales_growth -- cumulative sum table
from bat_ltd_sales_count;

-- Display the first 22 days of sales records from bat_ltd_sales_growth
select * from bat_ltd_sales_growth limit 22;

-- compare that with the original Bat model
select * from bat_sales_growth limit 22;

-- The Bat Limited Edition sold 64 fewer units (160 - 96) over the first 22 days
-- Compute 7 day lag
select *,
lag(cum_sales, 7) over (order by sales_transaction_date)
into bat_ltd_sales_daily_delay
from bat_ltd_sales_growth;

-- compute the sales growth as a % and store in a table
select *,
round(((cum_sales - lag) / lag) * 100,2) as growth_pct
into bat_ltd_sales_delay_vol
from bat_ltd_sales_daily_delay;

-- Inspect the table
select * from bat_ltd_sales_delay_vol limit 22;

-- After 22 days of sales, the sales growth of the Limited Edition 
-- scooter is 65% compared to the previous week, as compared with the 28% growth

-- At this stage, we have collected data from two similar products that were launched at 
-- different time periods and found some differences in the trajectory of the sales growth 
-- over the first 3 weeks of sales. 

-- While we have shown there to be a difference in sales between the two Bat Scooters, 
-- we also cannot rule out the fact that the sales differences can be attributed to the 
-- difference in the sales price of the two scooters, with the limited edition scooter being 
-- $100 more expensive. In the next activity, we will compare the sales of the Bat Scooter 
-- to the 2013 Lemon, which is $100 cheaper, was launched 3 years prior, is no longer in 
-- production, and started production in the first half of the calendar year

-- D.ANALYZING THE DIFFERENCE IN THE SALES PRICE HYPOTHESIS
-- Select the sales_transaction_date column from the 2013 Lemon sales and insert the 
-- column into a table called lemon_sales:

select sales_transaction_date 
into lemon_sales 
from sales 
where product_id=3;


-- Count the sales records available for the 2013 Lemon by running the following 
-- query:
select count(sales_transaction_date) from lemon_sales;

-- This indicates that the company has made 16558 sales of the product

-- Use the max function to check the latest sales_transaction_date column
 select max(sales_transaction_date) from lemon_sales;
 
-- Convert the sales_transaction_date column to a date type using the following 
-- query:
alter table lemon_sales
alter column sales_transaction_date
type date;

-- Count the number of sales per day within the lemon_sales table and insert this 
-- figure into a table called lemon_sales_count:
select *, 
count(sales_transaction_date) 
into lemon_sales_count 
from lemon_sales 
group by sales_transaction_date
order by sales_transaction_date;

-- Calculate the cumulative sum of sales and insert the corresponding table into a 
-- new table labeled lemon_sales_sum:
select *, 
sum(count) over (order by sales_transaction_date) 
into lemon_sales_sum from lemon_sales_count;

-- Compute the 7-day lag function on the sum column and save the result to lemon_
-- sales_delay
select *, 
lag(sum, 7) over (order by sales_transaction_date) 
into lemon_sales_delay 
from lemon_sales_sum;
 
-- Calculate the growth rate using the data from lemon_sales_delay and store the 
-- resulting table in lemon_sales_growth. Label the growth rate column as growth_pct:
select *, 
(round(((sum - lag) / lag) * 100, 2)) as growth_pct 
into lemon_sales_growth 
from lemon_sales_delay;
 
-- Inspect the first 22 records of the lemon_sales_growth table by examining the 
-- growth_pct data:
select * from lemon_sales_growth limit 22;

-- E. CONCLUSION

-- Looking at the sales growth of the three different scooters, we can also make a few 
-- different observations:
--		• The original Bat Scooter, which launched in October at a price of $599.99, 
--		experienced a 700% sales growth in its second week of production and finished the 
--		first 22 days with 28% growth and a sales figure of 160 units.

--		• The Bat Limited Edition Scooter, which launched in February at a price of $699.99, 
--		experienced 450% growth at the start of its second week of production and 
--		finished with 96 sales and 66% growth over the first 22 days.

--		• The 2013 Lemon Scooter, which launched in May at a price of $499.99, experienced 
--		830% growth in the second week of production and ended its first 22 days with 141 
--		sales and 55% growth.

-- Based on this information, we can make some conclusions:
--		• The initial growth rate starting in the second week of sales correlates to the cost of 
--		the scooter. As the cost increased to $699.99, the initial growth rate dropped from 
--		830% to 450%.

--		• The number of units sold in the first 22 days does not directly correlate to the 
--		cost. The $599.99 Bat Scooter sold more than the 2013 Lemon Scooter in that first 
--		period, despite the price difference.

--		• There is some evidence to suggest that the reduction in sales can be attributed	
--		to seasonal variations, given the significant reduction in growth and the fact that 
--		the original Bat Scooter is the only one released in October. So far, the evidence 
--		suggests that the drop can be attributed to the difference in launch timing.

-- F. HYPOTHESIS: a decrease in the rate of opening emails impacted the 
-- Bat Scooter sales rate,

-- Inspecting the email table
select * from emails limit 5;

-- To investigate our hypothesis, we need to know whether an email was opened, 
-- when it was opened, as well as who the customer was who opened the email and 
-- whether that customer purchased a scooter. If the email marketing campaign was 
-- successful in maintaining the sales growth rate, we would expect a customer to 
-- open an email soon before a scooter was purchased.
-- The period in which the emails were sent, as well as the ID of customers who 
-- received and opened an email, can help us determine whether a customer who 
-- made a sale may have been encouraged to do so following the receipt of an email.

-- To determine this hypothesis, we need to collect the customer_id column from 
-- both the emails table and the bat_sales table for the Bat Scooter, the opened, 
-- sent_date, opened_date, and email_subject columns from the emails table, 
-- as well as the sales_transaction_date column from the bat_sales table. 
-- Since we only want the email records of customers who purchased a Bat Scooter, 
-- we will join the customer_id column in both tables. Then, we'll insert the results 
-- into a new table – bat_emails:

select 
emails.email_subject, 
emails.customer_id, 
emails.opened, 
emails.sent_date, 
emails.opened_date, 
bat_sales.sales_transaction_date 
into bat_emails 
from emails inner join bat_sales on 
bat_sales.customer_id = emails.customer_id 
order by 
bat_sales.sales_transaction_date;

--  Select the first 10 rows of the bat_emails table, ordering the results by sales_
-- transaction_date:
select * from bat_emails limit 10;

-- Select all rows where the sent_date email predates the sales_transaction_date column, order by customer_id, and limit the output to the first 22 rows. 
-- This will help us find out which emails were sent to each customer before they 
-- purchased their scooter.
select * from bat_emails 
where sent_date < sales_transaction_date 
order by customer_id 
limit 22;

-- Delete the rows of the bat_emails table where emails were sent more than 6 
-- months prior to production. As we can see, there are some emails that were sent 
-- years before the transaction date. That is before the Bat Scooter was in production
-- as they are irrelevant to the analysis. In the 
-- products table, the production start date for the Bat Scooter is October 10, 2016:
delete from emails where sent_date < '2016-04-10';

-- Delete the rows where the sent date is after the purchase date since they are not 
-- relevant to the sales:
delete from bat_emails 
where sent_date > sales_transaction_date;

-- Delete those rows where the difference between the transaction date and the 
-- sent date exceeds 30 since we also only want those emails that were sent shortly 
-- before the scooter purchase. An email 1 year beforehand is probably unlikely to 
-- influence a purchasing decision, but one that is closer to the purchase date may 
-- have influenced the sales decision. We will set a limit of 1 month (30 days) before 
-- the purchase.
 delete from bat_emails 
 where (sales_transaction_date-sent_date) > '30 days';

-- Inspecting the new table
select * from bat_emails 
order by customer_id limit 22;

-- At this stage, we have reasonably filtered the available data based on the dates the 
-- email was sent and opened. Looking at the preceding email_subject column, it 
-- also appears that there are a few emails unrelated to the Bat Scooter (for example, 
-- 25% of all EVs. It's a Christmas Miracle! and Black Friday. Green 
-- Cars). These emails seem more related to electric car production than scooters, so 
-- we can remove them from our analysis.
-- Inspecting ...
select distinct(email_subject) from bat_emails;

-- Delete all the records that have Black Friday in the email subject. These emails 
-- do not appear to be relevant to the sale of the Bat Scooter:
delete from bat_emails
where position('Black Friday' in email_subject) > 0;

--  Delete all rows where 25% off all EVs. It's a Christmas Miracle! and A 
-- New Year, And Some New EVs can be found in the email_subject column:
delete from bat_emails
where position('25% off all EV' in email_subject)>0;

delete from bat_emails
where position('Some New EV' in email_subject)>0;

-- At this stage, we have our final dataset of emails that were sent to customers. Count 
-- the number of rows that are left in the sample by writing the following query:
select count(sales_transaction_date) from bat_emails;
-- 401 rows

-- Computing the percentage of emails that were opened relative to sales. 
-- Count the emails that were opened by writing the following query
select count(opened) from bat_emails where opened='t';
-- 98 rows

-- Count the customers who received emails and made a purchase. We will determine 
--  this by counting the number of unique (or distinct) customers that are in the bat_
-- emails table:
select count(distinct(customer_id)) from bat_emails;
-- 396 customers

-- Count the unique (or distinct) customers who made a purchase by
-- writing the following query:
select count(distinct(customer_id)) from bat_sales;
-- 6659 customers

-- Calculate the percentage of customers who purchased a Bat Scooter 
-- after receiving an email:
select round((396.0/6659.0) * 100, 2) as email_rate;
-- 5.95%

-- limit the scope of our data to all sales prior to November 1, 2016, and put the data 
-- in a new table called bat_emails_threewks. So far, we have examined the email 
-- opening rate throughout all the available data for the Bat Scooter. Check the rate 
-- throughout for the first 3 weeks, where we saw a reduction in sales:
select * into bat_emails_threewks 
from bat_emails 
where sales_transaction_date < '2016-11-01';

-- count the number of emails that were sent during this period:
select count(*) from bat_emails_threewks;
-- 82 sent emails

-- Now, count the number of emails that were opened in the first 3 weeks:
select count(opened) 
from bat_emails_threewks 
where opened='t';
-- 15 opened emails

-- Calculate the percentage of customers who opened emails pertaining to the Bat 
-- Scooter and then made a purchase in the first 3 weeks using the following query:
select round((15.0/82.0) * 100, 2) as sale_rate;
-- 18.29%
-- I added decimals to prevent integer division which is Postgres' default
-- Approximately 18% of customers who received an email about the Bat Scooter 
-- made a purchase in the first 3 weeks. This is consistent with the rate for all the 
-- available data for the Bat Scooter.

-- ANALYZING THE PERFORMANCE OF THE EMAIL MARKETING CAMPAIGN
-- In this exercise, we will investigate the performance of the email -- marketing campaign 
-- for the Lemon Scooter to allow for a comparison with the Bat -- Scooter. Our hypothesis 
-- is that if the email marketing campaign's performance of the Bat -- Scooter is consistent 
-- with another, such as the 2013 Lemon, then the reduction in sales -- cannot be attributed 
-- to differences in the email campaigns.

-- Drop the existing lemon_sales table:
drop table lemon_sales;

-- The 2013 Lemon Scooter is product_id = 3. Select customer_id and 
-- sales_transaction_date from the sales table for the 2013 Lemon 
--  Scooter. Insert this information into a table called lemon_sales:
select customer_id, sales_transaction_date 
into lemon_sales 
from sales where product_id=3;

-- Select all the information from the emails database for customers 
-- who purchased a 2013 Lemon Scooter. Place this information in a 
-- new table called lemon_emails:
select emails.customer_id, emails.email_subject, emails.opened, emails.sent_date, emails.opened_date, lemon_sales.sales_transaction_date 
into lemon_emails 
from emails inner join lemon_sales 
on emails.customer_id=lemon_sales.customer_id;

-- Remove all the emails that were sent before the start of the 
-- production of the 2013 
-- Lemon Scooter. For this, we require the date when production started:
select production_start_date 
from products 
Where product_id=3;

-- Now, delete the emails that were sent before the start of 
-- production of the 2013 Lemon Scooter:
delete from lemon_emails where sent_date < '2013-05-01';

-- Remove all the rows where the sent date occurred after the 
-- sales_transaction_date column:
delete from lemon_emails 
where sent_date > sales_transaction_date;

-- Remove all the rows where the sent date occurred more than 30 days
-- before the sales_transaction_date column
delete from lemon_emails 
where (sales_transaction_date - sent_date) > '30 days';

-- Remove all the rows from lemon_emails where the email subject is 
-- not related to 
-- a Lemon Scooter. Before doing this, we will search for all 
-- distinct emails:
select distinct(email_subject) from lemon_emails;


-- Delete the email subjects not related to the Lemon Scooter using 
-- the DELETE command:
delete from lemon_emails where position('25% off all EVs.' in 
email_subject)>0;

delete from lemon_emails where position('Like a Bat out of 
Heaven' in email_subject)>0;

delete from lemon_emails where position('Save the Planet' in 
email_subject)>0;

delete from lemon_emails where position('An Electric Car' in 
email_subject)>0;

delete from lemon_emails where position('We cut you a deal' in 
email_subject)>0;

delete from lemon_emails where position('Black Friday. Green Cars.' in email_subject)>0;

delete from lemon_emails where position('Zoom' in email_subject)>0;

-- check how many emails for the lemon_scooter customers were opened:
select count(opened) from lemon_emails where opened='t';
-- 157 emails were opened:

-- List the number of customers who received emails and made a purchase:
select count(distinct(customer_id)) from lemon_emails;
-- 626 rows

-- Calculate the percentage of customers who opened the received emails and 
-- made a purchase:
select round((157.0/626.0) * 100, 2) as email_rate;
-- 25% of customers who opened their emails made a purchase

-- Calculate the number of unique customers who made a purchase:
select count(distinct(customer_id)) from lemon_sales;
-- 13854 customers made a purchase:

-- Calculate the percentage of customers who made a purchase having 
-- received an email. This will enable a comparison with the
-- corresponding figure for the Bat Scooter:
select round((506.0/13854.0) * 100, 2) as email_sales;

-- Select all records from lemon_emails where a sale occurred within the first 
-- 3 weeks of the start of production. Store the results in a new table, 
-- lemon_emails_threewks:
select * into lemon_emails_threewks from lemon_emails 
where sales_transaction_date < '2013-06-01';

-- Count the number of emails that were made for Lemon Scooters in the 
-- first 3 weeks:
select count(sales_transaction_date) from lemon_emails_threewks;
-- 0 emails

-- We can see that 25% of customers 
-- who opened an email made a purchase, which is a lot higher than the 18% figure 
-- for the Bat Scooter. We have also calculated that just over 3.6% of customers who 
-- purchased a Lemon Scooter were sent an email, which is much lower than almost 
-- 6% of Bat Scooter customers. The final interesting piece of information we can see 
-- is that none of the Lemon Scooter customers received an email during the first 
-- 3 weeks of product launch compared with the 82 Bat Scooter customers, which is 
-- approximately 50% of all customers in the first 3 weeks.

-- CONCLUSIONS
-- Now that we have collected a range of information about the timing of the product 
-- launches, the sales prices of the products, and the marketing campaigns, we can make 
-- some conclusions regarding our hypotheses:
--		• I gathered some evidence to suggest 
--		that launch timing could be related to the reduction in sales after the first 2 weeks, 
--		although this cannot be proven.

--		• There is a correlation between the initial sales rate and the sales price of the 
--		scooter, with a reduced sales price trending with a high sales rate

--		• The number of units sold in the first 3 weeks does not directly correlate to 
-- 		the sale price of the product 

--		• There is evidence to suggest that a successful marketing campaign could increase 
--		the initial sales rate, with an increased email opening rate trending with an 
--		increased sales rate Similarly, there's an increase in the number of customers receiving email 
--		trends with increased sales 

--		• The Bat Scooter sold more units in the first 3 weeks than the Lemon or Bat Limited 
--		Scooters 