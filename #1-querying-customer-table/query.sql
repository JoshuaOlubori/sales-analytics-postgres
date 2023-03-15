-- 1. Write a query that pulls all emails for Gringo customers in the state of Florida 
-- in alphabetical order.

select email from customers where state = 'FL'
order by email;

-- Gringo customers in New York City in the state of New York. They should be 
-- ordered alphabetically by the last name followed by the first name.

select first_name, last_name, email 
from customers
where state = 'NY' and city = 'New York City'
order by last_name, first_name;

-- 3. Write a query that returns all customers with a phone number ordered by the date 
-- the customer was added to the database.

select customer_id
from customers
where phone is not null
order by date_added;

-- 4. Create a new table called customers_nyc that pulls all rows from the customers
-- table where the customer lives in New York City in the state of New York. 

drop table if exists customers_nyc;
create table customers_nyc as (
select * from customers
where city = 'New York City' and state = 'NY'
);

-- Delete from the new table all customers in postal code 10014. Due to local laws, 
-- they will not be eligible for marketing.

delete from customers_nyc
where postal_code = '10014';

--  Add a new text column called event.

alter table customers_nyc
add column event text;

--  Set the value of the event to thank-you party

update customers_nyc
set event = 'thank-you party';

--You've told the manager that you've completed these steps. He tells the marketing 
-- operations team, who then uses the data to launch a marketing campaign. The 
-- marketing manager thanks you and then asks you to delete the customers_nyc
-- table.

drop table customers_nyc;

