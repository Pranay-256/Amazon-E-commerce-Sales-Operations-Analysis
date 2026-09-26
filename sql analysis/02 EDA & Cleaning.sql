-- EDA & Cleaning--

--1. Category Table
SELECT * FROM category;

UPDATE category 
SET category_name = TRIM(category_name);

SELECT * FROM category
WHERE category_id = NULL OR category_name = NULL;

--2. Customers Table
SELECT * FROM customers;

UPDATE customers SET
first_name = TRIM(first_name),
last_name = TRIM(last_name), 
state = TRIM(state);

SELECT * FROM customers WHERE customer_id IS NULL OR first_name IS NULL 
OR last_name IS NULL OR state IS NULL OR address IS NULL;

--3. Inventory Table
SELECT * FROM inventory;

SELECT * FROM inventory WHERE inventory_id IS NULL OR product_id IS NULL 
OR stock IS NULL OR warehouse_id IS NULL OR last_stock_date IS NULL

SELECT MIN(stock) AS min_stock, MAX(stock) AS max_stock, 
MIN(last_stock_date) AS min_date, MAX(last_stock_date) AS max_date
FROM inventory;

--4. Order_Items Table
SELECT * FROM order_items;

SELECT * FROM order_items WHERE order_item_id IS NULL OR order_id IS NULL OR product_id IS NULL 
OR quantity IS NULL OR price_per_unit IS NULL OR total_sales IS NULL

SELECT MIN(quantity) AS min_quantity, MAX(quantity) AS max_quantiy, 
MIN(price_per_unit) AS min_price, MAX(price_per_unit) AS max_price, 
MIN(total_sales) AS min_sales, MAX(total_sales) AS max_sales
FROM order_items;

--5. Orders Table
SELECT * FROM orders;
SELECT DISTINCT(order_status) FROM orders;

UPDATE orders SET
order_status = TRIM(order_status);

SELECT * FROM orders WHERE order_id IS NULL OR order_date IS NULL OR customer_id IS NULL 
OR seller_id IS NULL OR order_status IS NULL

SELECT MIN(order_date) AS min_date, MAX(order_date) AS max_date
FROM Orders;

--6. Payments Table
SELECT * FROM payments;
SELECT DISTINCT payment_status FROM payments;

UPDATE payments SET
payment_status = TRIM(payment_status);

SELECT * FROM payments WHERE payment_id IS NULL OR order_id IS NULL OR 
payment_date IS NULL OR payment_status IS NULL;

SELECT min(payment_date) AS min_date, MAX(payment_date) AS max_date
FROM payments;

--7. Products Table
SELECT * FROM products;
UPDATE products SET
product_name = TRIM(product_name);

SELECT * FROM products
ORDER BY product_id ASC;

SELECT MIN(price) AS min_price, MAX(price) AS max_price, MIN(cogs) AS min_cogs, MAX(cogs) AS max_cogs
FROM products; -- some of the products have 0 min_price and 0 min_cogs

SELECT * FROM products
WHERE price = 0; -- there are multipe product records where price is 0

SELECT * FROM order_items oi
   JOIN products p
      ON oi.product_id = p.product_id
   WHERE p.price = 0 

UPDATE products p SET
price = oi.price_per_unit
FROM order_items oi
WHERE p.product_id = oi.product_id AND p.price = 0; -- now no product has price 0

SELECT * FROM products 
   WHERE cogs = 0; 
/* Multiple products have a COGS of 0, which could be due to testing, sample, trial, 
or package-offer products. Since their actual cost is unknown, 
including them in profit analysis would be unfair to products that were actually purchased by the business.*/


--8. Sellers Table
SELECT * FROM sellers; -- some sellers have null values in their origin column, so we need to fill it with "Unknown".

UPDATE sellers SET
seller_name = TRIM(seller_name), 
origin = TRIM(origin);

SELECT * FROM sellers WHERE seller_id IS NULL OR seller_name IS NULL OR origin IS NULL;

UPDATE sellers
SET origin = 'Unknown'
WHERE origin IS NULL;

--9. Shipping Table
SELECT * FROM shipping; -- There are null values in return_date column
SELECT DISTINCT(delivery_status) FROM shipping;

UPDATE shipping SET
shipping_provider = TRIM(shipping_provider),
delivery_status  = TRIM(delivery_status);

SELECT * FROM shipping WHERE return_date IS NOT NULL AND delivery_status IN ('Delivered', 'Cancelled'); -- no records found
SELECT * FROM shipping WHERE return_date IS NOT NULL AND delivery_status IN ('In Transit'); -- no records found
SELECT * FROM shipping WHERE return_date IS NOT NULL AND delivery_status IN ('Returned'); -- there are 681 records where products are returned
/*This confirms that return_date is not null only for records where products are returned, 
for the rest of the delivery_status the value in return_date is null*/

--10. Checking for information consistency in orders, payments and delivery tables
SELECT o.order_id, o.order_status, pay.payment_status, s.delivery_status
FROM orders o
JOIN payments pay
ON o.order_id = pay.order_id
JOIN shipping s
ON o.order_id = s.order_id; 

SELECT  o.order_status, pay.payment_status, s.delivery_status, COUNT(pay.payment_status)
FROM orders o
JOIN payments pay
ON o.order_id = pay.order_id
JOIN shipping s
ON o.order_id = s.order_id
GROUP BY o.order_status, pay.payment_status, s.delivery_status;

/*Everything seems to be consistent*/
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------