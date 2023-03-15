-- Search and Analysis
-- Set up a search materialized view and answer some business 
-- questions using what we have learned in the previous exercises. The head of sales at 
-- Gringo has identified a problem: there is no easy way for the sales team to search 
-- for a customer. You volunteered to create a proof-of-concept internal search engine 
-- that will make all customers searchable by their contact information and the products 
-- that they have purchased in the past.

-- Using the customer_sales table, create a searchable materialized view with one 
-- record per customer. This view should be keyed off of the customer_id column 
-- and searchable on everything related to that customer: name, email, phone, and 
-- purchased products. It is OK to include other fields as well
create materialized view customer_search as (
select
customer_json -> 'customer_id' as customer_id,
customer_json,
to_tsvector('english', customer_json) as search_vector
from customer_sales);

-- Create the GIN index on the view:
CREATE INDEX customer_search_gin_idx ON customer_search USING GIN(search_
vector);

-- A salesperson asks you if you can use your new search prototype to find a customer 
-- by the name of Danny who purchased the Bat scooter. Query your new searchable 
-- view using the Danny Bat keywords. How many rows did you get?
select customer_id, 
customer_json
from customer_search
where search_vector @@ plainto_tsquery('english', 'Danny Bat');

-- The sales team wants to know how common it is for someone to buy each scooter 
-- and automobile combination. To do that, join the product table to itself to get all 
-- distinct pairs of scooters and automobiles, filtering out limited edition products
SELECT DISTINCT
 p1.model,
 p2.model
FROM products p1
CROSS JOIN products p2
WHERE p1.product_type = 'scooter'
AND p2.product_type = 'automobile'
AND p1.model NOT ILIKE '%Limited Edition%';

--  Transform the output
SELECT DISTINCT
 plainto_tsquery('english', p1.model) &&
 plainto_tsquery('english', p2.model) as model_combo
FROM products p1
LEFT JOIN products p2 ON TRUE
WHERE p1.product_type = 'scooter'
AND p2.product_type = 'automobile'
AND p1.model NOT ILIKE '%Limited Edition%';

-- Count number of occurences of combinations
SELECT
 sub.query,
 (
 SELECT COUNT(1)
 FROM customer_search
 WHERE customer_search.search_vector @@ sub.query)
FROM (
 SELECT DISTINCT
 plainto_tsquery('english', p1.model) &&
 plainto_tsquery('english', p2.model) AS query
 FROM products p1
 LEFT JOIN products p2 ON TRUE
 WHERE p1.product_type = 'scooter'
 AND p2.product_type = 'automobile'
 AND p1.model NOT ILIKE '%Limited Edition%'
) sub
ORDER BY 2 DESC;
