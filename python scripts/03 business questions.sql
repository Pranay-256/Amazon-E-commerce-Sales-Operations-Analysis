-- Q1. Top 10 Selling Products based on orders that were not cancelled or returned (include category, product name, total_orders, quantity sold and sales value)

--step 1: 
SELECT * FROM order_items;

ALTER TABLE order_items 
   ADD COLUMN total_sales DECIMAL;

UPDATE order_items
   SET total_sales = quantity * price_per_unit;

--step 2:
SELECT 
   c.category_name AS category, p.product_name AS product,
   COUNT(oi.order_id) AS total_orders, SUM(oi.quantity) AS quantity, SUM(oi.total_sales) AS sales
FROM products p
   JOIN category c
      ON c.category_id = p.category_id
   JOIN order_items oi
      ON oi.product_id = p.product_id
   JOIN orders o
      ON o.order_id = oi.order_id
   JOIN payments pay
      ON o.order_id = pay.order_id
   WHERE o.order_status NOT IN ('Cancelled', 'Returned') AND pay.payment_status NOT IN ('Payment Failed', 'Refunded')	  
   GROUP BY c.category_name, p.product_name, oi.price_per_unit
   ORDER BY SUM(oi.total_sales) DESC
   LIMIT 10;                      
   
/*insight: the product "Google Mechanical Keyboard" is the top seller and 
  all these top 10 products by sales come from the category "electronics". 
  Indicating high demand for electronic devices*/



-- Q2. Revenue by each product category

--step 1:
WITH revenue_by_category AS (
   SELECT 
      p.category_id, c.category_name AS category, 
      SUM(oi.total_sales) AS sales,
	  ROUND(SUM(oi.total_sales):: numeric/(SELECT SUM(oi.total_sales) FROM order_items oi
	     JOIN orders o
		    ON o.order_id = oi.order_id
		 JOIN payments pay
		    ON oi.order_id = pay.order_id
	  WHERE o.order_status NOT IN ('Cancelled', 'Returned') AND pay.payment_status NOT IN ('Payment Failed', 'Refunded')):: numeric * 100, 2) AS sales_contribution
   FROM products p
      JOIN category c
         ON c.category_id = p.category_id
      JOIN order_items oi
         ON oi.product_id = p.product_id
      JOIN orders o
	     ON oi.order_id = o.order_id
      JOIN payments pay
	     ON oi.order_id = pay.order_id
      WHERE o.order_status NOT IN ('Cancelled', 'Returned') AND pay.payment_status NOT IN ('Payment Failed', 'Refunded')
      GROUP BY p.category_id, c.category_name
)

--step 2:
SELECT * FROM revenue_by_category
  ORDER BY sales DESC;
   
/*insight: the category "electronics" has the highest sales of "19803860.87$" 
  among all the categories, with the total contribution of "76.75%" in total sales.*/



/*Q3. Average Order Value (AOV) for customers having atleast 15 orders.*/

SELECT c.customer_id, CONCAT_WS(' ', c.first_name, c.last_name) AS customer_name, COUNT(o.order_id) AS total_orders, ROUND(SUM(oi.total_sales)/ COUNT(o.order_id), 2 ) AS avg_order_value
   FROM orders o
      JOIN customers c
	     ON o.customer_id = c.customer_id
      JOIN order_items oi
	     ON o.order_id = oi.order_id
	  GROUP BY c.customer_id, customer_name
	  HAVING COUNT(o.order_id) >= 15   ---> filtering customers by number of orders
	  ORDER BY avg_order_value DESC;

/*insight: there are more than 11 customers who have the average order value more that 30000 
  while having total number of orders >= 15.*/



/* Q4. Determine the month-by-month sales trend starting from the same date last year 
      (assuming current year is 2023) up to the latest, showing sales for the current and previous months.*/
	  
SELECT year, month, total_sales AS current_month_sales,
       LAG(total_sales, 1) OVER(ORDER BY year, month) AS prev_month_sales
FROM (
   SELECT 
         EXTRACT(YEAR FROM o.order_date) AS year,
   	  EXTRACT(MONTH FROM o.order_date) AS month,
   	  ROUND(SUM(oi.total_sales), 2) AS total_sales
      FROM orders o
         JOIN order_items oi
            ON o.order_id = oi.order_id
	     JOIN payments pay
		    ON o.order_id = pay.order_id
      WHERE order_date >= ((CURRENT_DATE - INTERVAL '3 year') - INTERVAL '1 year') AND --> CURRENT_DATE - INTERVAL '3 year' will take us to the same current date in 2023 and (CURRENT_DATE - INTERVAL '3 year') - INTERVAL '1 year' will filter the records based on the same date in the year 2022
         o.order_status NOT IN ('Cancelled', 'Returned') AND pay.payment_status NOT IN ('Payment Failed', 'Refunded')
	  GROUP BY 1, 2
      ORDER BY 1, 2
   ) AS table_1;


/* Q5. Find the customers which are registered but have not placed any order yet */

--solution 1:
SELECT * FROM customers
   WHERE customer_id NOT IN(
      SELECT DISTINCT(customer_id)
	  FROM orders
   );

--solution 2:
SELECT * FROM customers
   LEFT JOIN orders
      ON customers.customer_id = orders.customer_id
   WHERE orders.customer_id IS NULL;

/*insight: There are no customers which are registered and have not placed any order*/



/* Q6. Find the top-3 best-selling product categories in each state including their sales value.*/

--step 1:
WITH state_category_sales AS (
SELECT c.state, cat.category_id, cat.category_name, ROUND(SUM(oi.total_sales), 2) AS sales
   FROM customers c
      JOIN orders o
         ON c.customer_id = o.customer_id
      JOIN order_items oi
         ON o.order_id = oi.order_id
      JOIN products p
         ON oi.product_id = p.product_id
      JOIN category cat
         ON p.category_id = cat.category_id
	  JOIN payments pay
	     ON o.order_id = pay.order_id
   WHERE o.order_status NOT IN ('Cancelled', 'Returned') AND pay.payment_status NOT IN ('Payment Failed', 'Refunded')		 
GROUP BY 1, 2, 3
ORDER BY state
),

--step 2:
category_sales_rank AS(
   SELECT state, category_name, sales,
      DENSE_RANK() OVER(PARTITION BY state ORDER BY sales DESC) AS sales_rank
      FROM state_category_sales
)

--step 3:
SELECT * FROM category_sales_rank
   WHERE sales_rank <= 3
   ORDER BY state, sales_rank;

/*insight: The categories "electronics" and "home & kitchen" appears at the rank 1 and rank 2 respectively 
  in terms of sales in every state, this describes a constant high demand for these categories 
  across all the states*/



/* Q7. Find the least-selling product category in each state including it's sales value.*/

--step 1:
WITH state_category_sales AS (
SELECT c.state, cat.category_id, cat.category_name, ROUND(SUM(oi.total_sales), 2) AS sales
   FROM customers c
      JOIN orders o
         ON c.customer_id = o.customer_id
      JOIN order_items oi
         ON o.order_id = oi.order_id
      JOIN products p
         ON oi.product_id = p.product_id
      JOIN category cat
         ON p.category_id = cat.category_id
	  JOIN payments pay
	     ON o.order_id = pay.order_id
   WHERE o.order_status NOT IN ('Cancelled', 'Returned') AND pay.payment_status NOT IN ('Payment Failed', 'Refunded')	 
GROUP BY 1, 2, 3
),

--step 2:
category_sales_rank AS(
   SELECT state, category_name, sales,
      DENSE_RANK() OVER(PARTITION BY state ORDER BY sales ASC) AS sales_rank
      FROM state_category_sales
)

--step 3:
SELECT * FROM category_sales_rank
   WHERE sales_rank = 1
   ORDER BY state, sales_rank;

/*insight: The category "pet supplies" appears as the least selling product category in most
of the states. Showcasing it's least demand among many states  which is justified 
because not everyone owns a pet*/   



/* Q8: Calculate the total value of orders placed by each customer over their recorded lifetime 
       and also rank them based on the order value*/  

SELECT customer_id, customer_name, total_orders, total_sales,
DENSE_RANK() OVER(ORDER BY total_sales DESC) AS order_value_rank
   FROM(
      SELECT c.customer_id, CONCAT_WS(' ', c.first_name, c.last_name) AS customer_name, 
             COUNT(DISTINCT(o.order_id)) AS total_orders, SUM(oi.total_sales) total_sales
         FROM customers c
            JOIN orders o
               ON c.customer_id = o.customer_id
            JOIN order_items oi
               ON o.order_id = oi.order_id
			JOIN payments pay
	     ON o.order_id = pay.order_id
   WHERE o.order_status NOT IN ('Cancelled', 'Returned') AND pay.payment_status NOT IN ('Payment Failed', 'Refunded')   
         GROUP BY c.customer_id, customer_name
         ORDER BY total_sales DESC
) AS customer_order_value;   



/* Q9: Find products with stock levels below a certain threshold (for eg: 10 units) in the inventory, 
       to give a low stock alert*/

-- step 1:
WITH stock_left AS(
SELECT i.inventory_id, p.product_id, p.product_name, i.warehouse_id, i.last_stock_date , SUM(i.stock) AS current_stock
   FROM inventory i
      JOIN products p
         ON i.product_id = p.product_id
   GROUP BY i.inventory_id, p.product_id, p.product_name, warehouse_id
)

SELECT inventory_id, product_name, last_stock_date, current_stock, warehouse_id 
   FROM stock_left
      WHERE current_stock <= 10
         ORDER BY warehouse_id ASC, current_stock ASC;

-- step 2:
SELECT i.warehouse_id, SUM(oi.total_sales) as total_sales
   FROM orders o
      JOIN order_items oi
         ON o.order_id = oi.order_id
      JOIN inventory i
         ON i.product_id = oi.product_id
	  JOIN payments pay
	     ON o.order_id = pay.order_id
   WHERE o.order_status NOT IN ('Cancelled', 'Returned') AND pay.payment_status NOT IN ('Payment Failed', 'Refunded')		 
      GROUP BY i.warehouse_id	
      ORDER BY total_sales DESC

/*insight: Many products that have stock levels below 10 are from Warehouse 1. 
  Warehouse 1 also shows the highest sales volume among all the warehouses which can be confirmed from step 2. 
  This shows the low stock levels in Warehouse 1 are likely caused by high product demand since items there 
  are selling very quickly. To stop stockouts it is necessary to monitor inventory and to replenish 
  stock more often. */ 




/* Q10: Identify orders where shipping delay is more than 5 days since the order has placed. 
        Including customer deltails, order details and shipping provider*/

SELECT c.customer_id, CONCAT_WS(' ', c.first_name, c.last_name) AS customer_name, o.order_id, o.order_date, 
       s.shipping_id, s.shipping_date, s.delivery_status, s.shipping_provider
       FROM orders o
	      JOIN customers c
	         ON c.customer_id = o.customer_id
	      JOIN shipping s
	         ON o.order_id = s.order_id
	      WHERE s.delivery_status != 'Cancelled' AND s.shipping_date >= (o.order_date + INTERVAL '5 day')

/*insight: There are no non-cancelled orders that were delayed in shipping by more than 5 days from the order date, 
  this indicates that, in the recorded dataset, orders were generally shipped within 5 days of being placed.*/



/* Q11: Calculate the percentage of each payment type across all orders, 
        Including all the different payment status*/  

SELECT p.payment_status, COUNT(*) AS total_count,
       ROUND(COUNT(*)/ (SELECT COUNT(*) FROM payments)::NUMERIC * 100, 2) AS contribution_rate
	   FROM orders o
	      JOIN payments p
		     ON o.order_id = p.order_id
	   GROUP BY p.payment_status
	   ORDER BY contribution_rate DESC;

/* insight: "54.36%" of payments came out to be successful, while "35.42%" are still pending. 
   This means that a large number of payments have not yet been completed, 
   which could lead to delays in orders processing.*/	   



/* Q12: Identify the top 5 sellers by sales, 
        Including their count of sucessfull orders and count of failed orders with their success rate
		(I'm considering Delivered orders as successful and Cancelled and Returned orders as failed) and find the top 5 
		products sold by the top seller based on their total sales*/


--step 1:
WITH seller_order_status AS(
   SELECT s.seller_id, s.seller_name, o.order_status, 
          COUNT(o.order_id) AS orders_count
      FROM sellers s
         JOIN orders o
            ON s.seller_id = o.seller_id		 
      GROUP BY 1, 2, 3
),

seller_order_status_2 AS(
   SELECT seller_id, seller_name, 
   	      SUM(orders_count) AS total_orders,
          SUM(CASE WHEN order_status = 'Delivered' THEN orders_count ELSE 0 END) AS successful_orders,
   	      SUM(CASE WHEN order_status IN ('Cancelled', 'Returned') THEN orders_count ELSE 0 END) AS failed_orders
      FROM seller_order_status
      GROUP BY seller_id, seller_name
),

seller_sales AS(
   SELECT o.seller_id, ROUND(SUM(oi.total_sales), 2) AS total_sales
      FROM orders o
         JOIN order_items oi
            ON o.order_id = oi.order_id
         JOIN payments pay
            ON o.order_id = pay.order_id
      WHERE o.order_status NOT IN ('Cancelled', 'Returned') AND pay.payment_status NOT IN ('Payment Failed', 'Refunded')
      GROUP BY o.seller_id
),

seller_order_status_3 AS(
   SELECT sos2.seller_id, sos2.seller_name, sos2.total_orders, 
          sos2.successful_orders, sos2.failed_orders,
          ROUND((successful_orders)::numeric/(total_orders)::numeric * 100, 2) AS succesful_order_rate,
          ss.total_sales
      FROM seller_order_status_2 sos2
         JOIN seller_sales ss
            ON sos2.seller_id = ss.seller_id
),

seller_order_status_4 AS(
   SELECT *, DENSE_RANK() OVER(ORDER BY total_sales DESC) AS sales_rank
      FROM seller_order_status_3
)

SELECT * 
   FROM seller_order_status_4
   WHERE sales_rank <= 5
   ORDER BY sales_rank;

--step 2:
SELECT s.seller_id, s.seller_name, p.product_name, SUM(oi.total_sales) AS total_sales
   FROM orders o
      JOIN sellers s
	     ON o.seller_id = s.seller_id
	  JOIN order_items oi
	     ON o.order_id = oi.order_id
	  JOIN products p 
	     ON oi.product_id = p.product_id
	  JOIN payments pay
	     ON o.order_id = pay.order_id
   WHERE s.seller_id = 23 AND 
      o.order_status NOT IN ('Cancelled', 'Returned') AND pay.payment_status NOT IN ('Payment Failed', 'Refunded')
   GROUP BY 1, 2, 3
   ORDER BY SUM(oi.total_sales) DESC
   LIMIT  5



/* Q13: Calculate the gross profit and profit margin for each product and Rank products by their profit margin, 
        whlie also showing product category, product name, purchase price, selling price, quantity sold and  
		total sales */

WITH CTE1 AS(
   SELECT p.product_id, p.product_name, c.category_name AS category, p.cogs AS purchase_price, oi.quantity, (p.cogs*oi.quantity) AS total_cost, oi.price_per_unit AS selling_price, oi.total_sales,
   (oi.total_sales - (p.cogs*oi.quantity)) AS total_profit
      FROM orders o
         JOIN order_items oi
            ON oi.order_id = o.order_id
		 JOIN products p
		    ON p.product_id = oi.product_id
		 JOIN payments pay
		    ON pay.order_id = o.order_id
		 JOIN category c
		    ON c.category_id = p.category_id
	WHERE o.order_status NOT IN ('Cancelled', 'Returned') AND 
	pay.payment_status NOT IN ('Payment Failed', 'Refunded') AND p.cogs != 0 -- Filtering for testing, sample, trial, or package-offer products.
),		

CTE2 AS(
   SELECT product_id, product_name, category, purchase_price, selling_price, 
   SUM(quantity) AS total_quantity, ROUND(SUM(total_cost):: numeric, 2) AS total_cost, 
   ROUND(SUM(total_sales):: numeric, 2) AS total_sales, ROUND(SUM(total_profit):: numeric, 2) AS gross_profit,
   ROUND((SUM(total_profit):: numeric/ SUM(total_sales):: numeric) * 100, 2) AS profit_margin
      FROM CTE1
	  GROUP BY product_id, product_name, category, purchase_price, selling_price
)

SELECT *, DENSE_RANK() OVER (ORDER BY profit_margin DESC) AS profit_rank
   FROM CTE2;

/* insight: There are more than 176 products which have a profit margin higher than 60%, a planned marketing campaign 
and promotion strategy to increase their sales can significantly improve the overall profit of the business*/



/* Q14: Identify the top 10 most returned products and 
        determine what percentage of their ordered units was returned.*/

SELECT p.product_id, p.product_name, 
       SUM(CASE WHEN o.order_status != 'Cancelled' THEN oi.quantity ELSE 0 END) AS total_quantity,
       SUM(CASE WHEN o.order_status = 'Returned' THEN oi.quantity ELSE 0 END) AS returned_quantity,
	   ROUND(SUM(CASE WHEN o.order_status = 'Returned' THEN oi.quantity ELSE 0 END):: numeric/
	   NULLIF(SUM(CASE WHEN o.order_status != 'Cancelled' THEN oi.quantity ELSE 0 END), 0):: numeric*100, 2) AS returned_quantity_rate
   FROM order_items oi
      JOIN products p
	     ON oi.product_id = p.product_id
	  JOIN orders o
	     ON oi.order_id = o.order_id
   GROUP BY 1, 2
   ORDER BY returned_quantity DESC
   LIMIT 10;

/* insight: The total return rate for all 10 products exceeds 10%, indicating that a significant number of 
   these items are being returned. The business should pay attention to customer reviews and discuss the 
   potential reasons for these returns with the sellers to identify ways to reduce the return rate.*/	



/* Q15: Identify sellers who have not made any sales in the last 6 months, and also provide details regarding 
        the date of their most recent sale and their total sales.*/

WITH cte1 AS(
   SELECT s.seller_id, s.seller_name, MAX(o.order_date) AS last_order_date, SUM(oi.total_sales) AS total_sales
      FROM sellers s
         LEFT JOIN orders o
   	     ON o.seller_id = s.seller_id
         JOIN order_items oi
   	     ON o.order_id = oi.order_id
   	  JOIN payments pay
   	     ON o.order_id = pay.order_id
      WHERE o.order_status NOT IN ('Cancelled', 'Returned') AND 
      pay.payment_status NOT IN ('Payment Failed', 'Refunded')
	  GROUP BY s.seller_id, s.seller_name
),

cte2 AS(
   SELECT * FROM cte1
      WHERE last_order_date < (SELECT MAX(last_order_date) FROM cte1) - INTERVAL '6 months'
)

SELECT * FROM cte2;

/* insight: There are no sellers who have been inactive during the last 6 months based on the latest recorded 
sale date, indicating that all sellers have contributed to sales during this period.*/



/* Q16: Analyze the return activity of customers who placed at least 10 orders in the last 2 years. 
        Calculate their total orders, returned orders, and return rate, and classify customers 
		with a return rate of 40% or higher as "High Return Frequency" and others as "Normal Return Frequency".*/

WITH cte1 AS(
   SELECT *,
      ROUND((returned_orders::numeric / NULLIF(delivered_orders, 0)) * 100, 2) AS return_rate
      FROM(
      SELECT c.customer_id, CONCAT_WS(' ', c.first_name, c.last_name) AS customer_name,
             COUNT(o.order_id) AS total_orders,
             COUNT(CASE WHEN o.order_status = 'Delivered' THEN o.order_status ELSE NULL END) AS delivered_orders,
             COUNT(CASE WHEN o.order_status = 'Returned' THEN o.order_status ELSE NULL END) AS returned_orders
      	      FROM orders o
      		     JOIN customers c
      			    ON o.customer_id = c.customer_id
      		  WHERE o.order_date >= (SELECT MAX(order_date) FROM orders) - INTERVAL '2 years'				
      		  GROUP BY 1, 2	
      		     HAVING COUNT(o.order_id) >= 10
      		  ORDER BY returned_orders DESC
) AS t1 
),

cte2 AS(
   SELECT *, 
   CASE
      WHEN return_rate >= 40
	  THEN 'High Return Frequency'
	  ELSE 'Normal Return Frequency'
   END AS return_frequency	  
   FROM cte1
)

SELECT *
   FROM cte2
   WHERE returned_orders > 0
   ORDER BY return_rate DESC;

SELECT return_frequency, COUNT(return_frequency)
   FROM cte2
	  WHERE returned_orders > 0
	  GROUP BY return_frequency;

/* insight: There are 19 customers which have high return frequency. The team should contact them and  
   analyze what is the reason behind their high return frequency, As it could also affect the other future 
   customers in that same residencial area*/	

   

/* Q17: Identify the top 5 customers in each state based on the number of orders placed, 
        and provide their total orders and total sales generated.*/

WITH cte1 AS(
SELECT c.customer_id, CONCAT_WS(' ', c.first_name, c.last_name) AS customer_name, c.state, 
       COUNT(DISTINCT(o.order_id)) AS total_orders, SUM(oi.total_sales) AS total_sales
       FROM orders o
	      JOIN order_items oi
		      ON o.order_id = oi.order_id
		  JOIN customers c
		      ON o.customer_id = c.customer_id
		  JOIN payments pay
		      ON o.order_id = pay.order_id
		  WHERE o.order_status NOT IN ('Cancelled', 'Returned') AND 
	      pay.payment_status NOT IN ('Payment Failed', 'Refunded')
	   GROUP BY 1, 2, 3	  
),

cte2 AS(
SELECT *, 
   ROW_NUMBER() OVER(PARTITION BY state ORDER BY total_orders DESC) AS orders_rank
      FROM cte1
)

SELECT * FROM cte2
   WHERE orders_rank <= 5;



/* Q18: Calculate the running total sales for each year and also display the sales generated in each year.*/

SELECT *, SUM(total_sales) OVER(ORDER BY year) AS running_total_sales
   FROM (SELECT EXTRACT(YEAR FROM o.order_date) AS year, SUM(oi.total_sales) AS total_sales
      FROM orders o
         JOIN order_items oi
	        ON o.order_id = oi.order_id
		 JOIN payments pay
		    ON o.order_id = pay.order_id
	   WHERE o.order_status NOT IN ('Cancelled', 'Returned') AND 
	   pay.payment_status NOT IN ('Payment Failed', 'Refunded')		
      GROUP BY 1) AS t1;	 



/* Q19: Analyze the performance of each shipping provider by calculating total revenue, 
        the number of orders handled, and the average shipping time.*/

WITH cte1 AS(
SELECT s.shipping_provider, 
       COUNT(DISTINCT(o.order_id)) AS total_orders, ROUND(SUM(oi.total_sales), 2) AS total_sales,
	   ROUND(AVG(s.shipping_date - o.order_date), 2) AS average_delivery_days
   FROM orders o
      JOIN order_items oi
	      ON o.order_id = oi.order_id
	  JOIN shipping s 
	      ON o.order_id = s.order_id
	  JOIN payments pay
	      ON o.order_id = pay.order_id
   	  WHERE o.order_status NOT IN ('Cancelled', 'Returned') AND 
	  pay.payment_status NOT IN ('Payment Failed', 'Refunded')
   GROUP BY 1
   ORDER BY total_orders DESC	  
),

cte2 AS(
   SELECT *, ROUND(total_orders* 100/ (SELECT SUM(total_orders) FROM cte1), 2) AS order_contribution_pct
   FROM cte1
)

SELECT * FROM cte2;

/* insight: The average delivery time for each shipping provider is approximately two days. Among all the 
   providers, fedex handles the highest volume of orders (45.23% of the total) and generates the most sales. 
   This indicates that fedex manages a significant portion of our orders while maintaining consistent 
   delivery times, resulting in superior sales performance.*/



/* Q20: FInd the Year Over Year revenue growth percentage for each recorded year*/

SELECT *, ROUND((cy_revenue - py_revenue) * 100/ py_revenue, 2) AS yoy_growth_pct
FROM(
   SELECT *, LAG(cy_revenue) OVER(ORDER BY year) AS py_revenue 
      FROM(
         SELECT EXTRACT(YEAR FROM o.order_date) AS year, SUM(oi.total_sales) AS cy_revenue
            FROM orders o
               JOIN order_items oi
         	      ON o.order_id = oi.order_id
         	  JOIN payments pay
         	      ON o.order_id = pay.order_id
            WHERE o.order_status NOT IN ('Cancelled', 'Returned') AND 
            pay.payment_status NOT IN ('Payment Failed', 'Refunded')	
            GROUP BY 1
            ORDER BY 1
) AS t1
) AS t2   

/* insight: The business experienced a 3.38% growth in sales in 2021, but faced a 6.77% decline in 2022. 
   In 2023, sales started to recover, growing by 1.14%, although the growth was relatively small. 
   The team should investigate the reasons behind the decline in 2022 and develop strategies to 
   address those issues so that a similar decline can be avoided in the coming years.*/



/* Final Task: Implement an automated inventory update mechanism(stored procedure) that decreases the stock 
               quantity for the corresponding product whenever a new sales record is added.*/

--step 1:
SELECT * FROM products;  --1. Anker Smartphone Mini | stock - 65units
ORDER BY product_id;    --3. Apple Gaming Console | stock - 7units
SELECT * FROM inventory
ORDER BY product_id;
SELECT * FROM orders;
SELECT * FROM order_items;
SELECT * FROM products;

--required parameteres
order_id, 
order_date,
customer_id,
seller_id,
order_item_id,
product_id,
quantity

--step 2(execute this part only):
CREATE OR REPLACE PROCEDURE add_sales
(
p_order_id INT,
p_customer_id INT,
p_seller_id INT,
p_order_item_id INT,
p_product_id INT,
p_quantity INT
)
LANGUAGE plpgsql
AS $$

DECLARE
-- all variables
v_count INT;
v_price DECIMAL;
V_product_name VARCHAR(200);

BEGIN
-- fetching product name and product price based on the product_id entered
   SELECT price, product_name
      INTO v_price, v_product_name
      FROM products
	     WHERE product_id = p_product_id;


-- checking stock and product availability in inventory
   SELECT COUNT(*) INTO v_count
      FROM inventory
         WHERE product_id = p_product_id AND stock >= p_quantity;


      IF v_count> 0 THEN -- add into orders and order_items table and update the inventory	 

		 -- Inserting new order record to orders table
         INSERT INTO orders(order_id, order_date, customer_id, seller_id)
   	     VALUES(p_order_id, CURRENT_DATE, p_customer_id, p_seller_id);
			
         -- Inserting new order records into order_items table
   	     INSERT INTO order_items(order_item_id, order_id, product_id, quantity, price_per_unit, total_sales)
   	     VALUES(p_order_item_id, p_order_id, p_product_id, p_quantity, v_price, p_quantity*v_price);

		 --updating the inventory
         UPDATE inventory
		 SET stock = stock - p_quantity
		    WHERE product_id = p_product_id;

		 RAISE NOTICE 'Product: % has been added to the order and inventory is updated', v_product_name;
   	  
      ELSE 
	  
         RAISE NOTICE 'oops! The product: % is not available right now.', v_product_name;

	  END IF;
END;
$$

-- calling the procedure

CALL add_sales(25000, 2, 5, 25001, 1, 40)
	  