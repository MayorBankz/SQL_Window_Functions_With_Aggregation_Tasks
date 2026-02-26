# SQL_Window_Functions_With_Aggregation_Tasks
## This document demonstrates practical use of window functions with aggregation while preserving row-level details
---
🔹 COUNT() Window Function Tasks
✅ Question 1: Total Number of Orders (With Order Details)
Goal:
Find the total number of orders while still displaying orderid and orderdate.

```sql
SELECT 
    orderid,
    orderdate,
    COUNT(*) OVER() AS total_orders
FROM orders;
```

Explanation 
* `COUNT()` - Counts all rows
* `OVER()` - Applies the count across the entire result set.
* `No PARTITION BY` Counts all orders
* If the table has 500 rows, every row will display 500.

---

✅ Question 2: Total Orders Per Customer
Goal:
Count how many orders each customer has made.

```sql
SELECT 
    customerid, 
    COUNT(*) OVER(PARTITION BY customerid) AS total_orders_by_customer
FROM orders;
```

Explanation
* `PARTITION BY customerid` - Restarts the count per customer.
* Each customer's total repeats for their rows

---

✅ Question 3: Total Number of Customers (With Full Details)
```sql
SELECT 
    *,
    COUNT(*) OVER() AS total_customers
FROM customers;
```

Explanation

* WHY `COUNT(*)` Instead of `COUNT(customerid)` ?
* Does not depend on column nullability
* Guarantees accuracy
* Counts all rows.

---

✅ Question 4: Total Scores Across All Customers

```sql
SELECT 
    customerid,
    SUM(score) OVER() AS total_scores
FROM customers;
```

---

✅ Question 5: Detect Duplicate Orders
Goal: Check whether orders table contains duplicate orderid.

```sql
SELECT *
FROM (
    SELECT *,
           COUNT(*) OVER(PARTITION BY orderid) AS duplicate_count
    FROM orders
) t
WHERE duplicate_count > 1;
-- If result is empty, no duplicates.
```

### Explanation 
How it works
* `COUNT(*) OVER(PARTITION BY orderid)` - Counts how many times each orderid appears.
* No `GROUP BY` - Row level details are preserved.
* `WHERE duplicate_count > 1` - Filters duplicates.

---

🔹 SUM() Window Function Tasks
---

✅ Question 6: Total Sales Across All Orders & Per Product

```sql
SELECT 
    orderid, 
    orderdate, 
    productid,
    SUM(sales) OVER() AS total_sales,
    SUM(sales) OVER(PARTITION BY productid) AS total_sales_by_product
FROM orders;
```

### How it Works 
* `SUM(sales) OVER()` - Total sales across entire table.
* `SUM(sales) OVER(PARTITION BY productid)` - Total sales per product.
* Row-level details preserved `(orderid, orderdate)`.

---

✅ Question 7: Percentage Contribution of Each Product
### FORMULA
`( Product Total / Overall Total ) * 100`

```sql
SELECT 
    productid,
    sales,
    SUM(sales) OVER() AS total_sales_all_products,
    SUM(sales) OVER(PARTITION BY productid) AS total_sales_per_product,
    ROUND(
        100.0 * SUM(sales) OVER(PARTITION BY productid) 
        / SUM(sales) OVER(), 
    2) AS percentage_contribution
FROM orders;
```

---
🔹 AVG() Window Function Tasks
---

✅ Question 1: Average Sales (Overall & Per Product)
```sql
SELECT 
    orderid,
    orderdate,
    productid,
    ROUND(AVG(sales) OVER(), 2) AS avg_sales_across_all_orders,
    ROUND(AVG(sales) OVER(PARTITION BY productid), 2) AS avg_sales_per_product
FROM orders;
```

---

✅ Question 2: Average Customer Score

```sql
SELECT 
    customerid, 
    COALESCE(lastname, firstname) AS lastname,
    ROUND(AVG(score) OVER(), 2) AS avg_score
FROM customers;
```

---

✅ Question 3: Orders Above Overall Average

### Why Subquery?
Window functions cannot be used directly in WHERE.

```sql
SELECT *
FROM (
    SELECT 
        orderid,
        sales,
        ROUND(AVG(sales) OVER(), 2) AS avg_sales_across_all_orders
    FROM orders
) t
WHERE sales > avg_sales_across_all_orders;
```

---

🔹 MIN() & MAX() Window Function Tasks

---

✅ Question 4: Highest & Lowest Sales (Overall & Per Product)
```sql
SELECT 
    orderid,
    orderdate,
    productid,
    sales,
    MAX(sales) OVER() AS highest_sales_across_all_orders,
    MIN(sales) OVER() AS lowest_sales_across_all_orders,
    MAX(sales) OVER(PARTITION BY productid) AS highest_sales_per_product,
    MIN(sales) OVER(PARTITION BY productid) AS lowest_sales_per_product
FROM orders;
```

---
🔹 Moving Average Tasks
---

✅ Question 5: 3-Row Moving Average Per Product

```sql
SELECT 
    orderid, 
    orderdate,
    productid,
    sales,
    ROUND(
        AVG(sales) OVER(
            PARTITION BY productid 
            ORDER BY orderdate 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 
    2) AS moving_avg
FROM orders
ORDER BY productid, orderdate;
```

### Explanation
* `PARTITION BY productid` - Separate calculation per product.
* `ORDER BY orderdate` - Chronological order
* `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` - 3-row window.

---

✅ Question 6: Employees With Highest Sales + Deviation
```sql
SELECT *
FROM (
    SELECT 
        salespersonid,
        orderid,
        sales,
        MAX(sales) OVER() AS max_sales,
        MIN(sales) OVER() AS min_sales,
        sales - MIN(sales) OVER() AS deviation_from_min,
        MAX(sales) OVER() - sales AS deviation_from_max
    FROM orders
) t
WHERE sales = max_sales;
```

### Logic
* Get `max(sales)` and `min(sales)`
* Calculate deviation
* Filter highest sales

---

✅ Question 7: Forward-Looking Moving Average (Current + Next Order)

```sql
SELECT 
    productid,
    sales,
    orderdate,
    ROUND(
        AVG(sales) OVER(
            PARTITION BY productid 
            ORDER BY orderdate 
            ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING
        ), 
    2) AS moving_avg
FROM orders;
```

### Explanation
* `CURRENT ROW AND 1 FOLLOWING` - Averages current order and next order.

---

🎯 Key Takeaways
✔ Window functions preserve row-level details
✔ `OVER()` defines how aggregation behaves
✔ `PARTITION BY` resets calculations per group
✔ `ORDER BY` enables ranking & time-based calculations
✔ `ROWS BETWEEN` controls moving window behavior
