/* Window function with Aggregation Tasks *
Question 1: Find the total number of orders, additionally provide details such as orderid & orderdate
Explanation 
- COUNT(*) - Counts all rows
- OVER() - applies it across the entire set result set 
- No PARTITION BY - so it counts all orders
If the table has 500 rows, every row will display 500*/

select orderid,
orderdate,
count(*) over() as total_orders
from orders;

/* QUESTION 2: Find the total orders for each customers */

SELECT customerid, 
count(*) OVER(PARTITION by customerid) as total_orders_by_customers
FROM orders;

/* QUESTION 3: Find the toal number of customers, additionally provide all customer's details.
Explanation
- Why COUNT(*) is used instead of COUNT(customerid) is because it does not depend on column nullability
- It guarantees accuracy
- It counts all rows */

SELECT *,
count(*) over() as total_customers
FROM customers;

/* QUESTION 4: Find the total number of scores for the customers */

SELECT customerid,
sum(score) over() as total_scores
FROM customers;

/* QUESTION 5: Check whether the table 'Orders' contains any duplicate rows 
How it works
1. COUNT(*) OVER (PARTITION BY orderid)

Counts how many rows have the same orderid.

No GROUP BY needed because it’s a window function, so every row keeps its original details.

2. WHERE count > 1

Filters only rows where orderid appears more than once → duplicates.

3. Result:

Shows all rows that are duplicated (based on orderid).

If empty → no duplicates. */

select *
from (
select *,
count(*) over(partition by orderid) as duplicate_count
from orders)t
where count > 1
;

/* QUESTION 6: Find the total sales across all orders, and the total sales for each product. Additionally provide details such as orderid and orderdate.
HOW IT WORKS
1. SUM(sales) OVER()
- Computes total sales across all orders
- No PARTITION BY - The sum is for the entire table
2. SUM(sales) OVER(PARTITION BY productid)
- Computes total sales per product 
- Each product's total is repeated for all rows of that product
- Preserves row-level detail(orderid, orderdate)
3. Row-level details preserved
- You still see orderid and orderdate for every order
- Combined with global and per-product aggregates
*/


select orderid, orderdate, productid, 
sum(sales) over() as total_sales,
sum(sales) over(partition by productid) as total_sales_by_product
from orders;

/* QUESTION 7: Find the percentage contribution of each product's sales to the total sales 
WHY THIS WORKS
1. SUM(sales) OVER (PARTITION BY productid)
- Calculates total sales per product.
2. SUM(sales) OVER ()
- Calculates total sales across all products.
3. The Formula
- 100.0 * product_total / overall_total
*/

select 
productid,
sales,
sum(sales) over() as total_sales_all_products,
sum(sales) over(partition by productid) as total_sales_per_product,
round(100.0 * sum(sales) over(partition by productid)  / sum(sales) over(), 2) as percentage_contribution
from orders;

/* Average Function Tasks 
QUESTION 1: Find the average sales across all orders, and find the average sales for each product, additionally provide details such as orderid, orderdate */

select orderid,
orderdate,
productid,
round(avg(sales) over(), 2) as avg_sales_across_all_orders,
round(avg(sales) over(partition by productid), 2) as avg_sale_per_product 
from orders;

/* QUESTION 2: Find the average scores of customers. Additionally provide details such as customerid, and lastname */

select customerid, coalesce(lastname, firstname) as lastname, 
round(avg(score) over(), 2) as avg_score
from customers; 

/* QUESTION 3: Find all orders where sales are higher than the average sales across all orders 
How it works 
1. Avg(sales) over()
- Calculates the average sales across all orders
- Repeated for every row because it's a window function 
- Preserves row-level details (orderid, sales)
2. Round(---, 2)
- Makes the average readable with 2 decimal places
- Optional for precision/formatting
3. Subquery
- Needed because you cannot use a window function directly in a WHERE clause
- Creates a temporary table with the average pre-calculated
4. WHERE sales > avg_sales_across_all_orders
- Filters only orders that are higher than the overall average*/

select *
from (
select orderid, 
sales,
round(avg(sales) over(), 2) as avg_sales_across_all_orders
from orders) t
where sales > avg_sales_across_all_orders;

/* QUESTION 4: Find the highest & lowest sales across all orders, and the highest & lowest sales for each product. Additionally, provide details such as orderid and orderdate
Step by Step Explanation
1. max(sales) over()
- No partition by
- Treats the entire table as one group
- Returns the highest sales across all orders
- Same value repeated on every row 
2. min(sales) over(partition by productid)
- Divides the data into groups by productid
- Returns the highest sales for each product
- Each product has its own maximum values
3. max(sales) over(partition by productid)
- Divides the data into groups by productid
- Returns the highest sales for each product
- Each product has its own maximum value
4. min(sales) over(partition by productid)
- Same logic 
- Returns the lowest sales per product*/

select orderid,
orderdate,
productid,
sales,
max(sales) over() as highest_sales_across_all_orders,
min(sales) over() as lowest_sales_across_all_orders,
max(sales) over(partition by productid) as highest_sales_per_product,
min(sales) over(partition by productid) as lowest_sales_per_product
from orders;

/* QUESTION 5: Calculate moving average of sales for each product over time. 
Explanation
1. PARTITION BY productid
- Resets the moving average calculation for each product. So product A and Prodcut B are calculated separately
2. ORDER BY orderdate
- Ensures the calculation follows time order. Without this, moving average makes no sense.
3. ROWS BETWEEN 2 PRECEEDING AND CURRENT ROW
- This defines the moving window:
For each row, calculate the average of:
- Current row
- 2 previous rows
So it's a 3-row moving average*/

select orderid, 
orderdate,
productid,
sales,
round(avg(sales) over(partition by productid order by orderdate rows between 2 preceding and current row), 2) as moving_avg
from orders
order by productid, orderdate;

/* QUESTION 6: Show the employees who have the highest sales, calculates the deviation of each sale from both the minimum and maximum sales amounts. 
WHY THIS WORKS
- max(sales) over() - Gets the highest sale in the entire table
- min(sales) over() - Gets the lowest sale in the entire table. 
- sales - min(sales) - Shows how much higher the highest sale is compared to the minimum sale.
- max(sales) - sales - shows how far each sale is from the maximum. 
- where sales = max_sales - Filters to only show employee(s) who made the highest sale.
If multiple employees share the highest sale, all of them will be returned.*/

select *
from (select salespersonid,
orderid,
sales,
max(sales) over() as max_sales,
min(sales) over() as min_sales,
sales - min(sales) over() as deviation_from_min,
max(sales) over() - sales as deviation_from_max
from orders) t
where sales = max_sales;

/* QUESTION 7: Calculate the moving average of sales for each product over time, including only the next order
Explanation
1. PARTITION BY productid - calculates the moving average separately for each product.
2. ORDER BY orderdate - Ensures the calculation follows chronological order.
3. ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING 
- This defines a forward-looking window:
	For each row, it averages:
- The current order
- The next order
So it's a 2-row forward moving average */

select productid,
sales,
orderdate,
round(avg(sales) over(partition by productid order by orderdate rows between current row and 1 following), 2) as moving_avg
from orders;
