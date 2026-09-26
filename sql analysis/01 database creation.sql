--CREATING PARENT TABLES--

-- category Table

CREATE TABLE category(
category_id	INT PRIMARY KEY,
category_name VARCHAR(20)
);

--customers Table

CREATE TABLE customers(
customer_id	INT PRIMARY KEY,
first_name VARCHAR(20),
last_name VARCHAR(20),
state VARCHAR(20),
address VARCHAR(5) DEFAULT ('xxxx')
);

--sellers Table

CREATE TABLE sellers(
seller_id INT PRIMARY KEY,
seller_name	VARCHAR(30),
origin VARCHAR(20)
);

--CREATING CHILD TABLES--

--products table

CREATE TABLE products(
product_id	INT PRIMARY KEY,
product_name VARCHAR(175),
price FLOAT,
cogs FLOAT,	
category_id INT, --FK from category table
CONSTRAINT product_fk_category 
FOREIGN KEY (category_id) REFERENCES category(category_id)
);

--NOTE: """The products.csv file has some invalid values (text and null) in the price and cogs columns which is needed to be cleaned before importing into the products table using excel or python."""

--orders Table

CREATE TABLE orders(
order_id INT PRIMARY KEY,
order_date DATE,
customer_id	INT, --FK from customers table
seller_id INT, --FK from sellers table	
order_status VARCHAR(15),
CONSTRAINT customer_fk_orders
FOREIGN KEY (customer_id) REFERENCES customers(customer_id),

CONSTRAINT seller_fk_orders
FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);

--order_items Table

CREATE TABLE order_items(
order_item_id INT PRIMARY KEY,
order_id INT, --FK from orders table
product_id INT, --FK from products table
quantity INT,
price_per_unit FLOAT,
CONSTRAINT orders_fk_order_items
FOREIGN KEY (order_id) REFERENCES orders(order_id),

CONSTRAINT products_fk_order_items
FOREIGN KEY (product_id) REFERENCES products(product_id)
);

--NOTE: """some of the product_ids are not present in the products table which are present in order_items.csv file. This will cause an error because of one to many relationship caused by primary and foreign key relationship, so this should be fixed before importing the data to the table using python or excel"""

--payment table

CREATE TABLE payments(
payment_id INT PRIMARY KEY,
order_id INT, --FK from orders table
payment_date DATE,	
payment_status VARCHAR(25),

CONSTRAINT orders_fk_payments
FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

--shipping Table

CREATE TABLE shipping(
shipping_id INT PRIMARY KEY,
order_id INT, --FK from orders table	
shipping_date DATE,
return_date	DATE,
shipping_provider VARCHAR(15),
delivery_status VARCHAR(15),

CONSTRAINT orders_fk_shipping
FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

--inventory table

CREATE TABLE inventory(
inventory_id INT PRIMARY KEY,
product_id	INT, --FK from products table
stock INT,
warehouse_id INT,
last_stock_date DATE,

CONSTRAINT products_fk_inventory
FOREIGN KEY (product_id) REFERENCES products(product_id)
)

--NOTE: """some of the product_ids are not present in the products table which are present in inventory.csv file. This will cause an error because of one to many relationship caused by primary and foreign key relationship, so this should be fixed before importing the data to the table using python or excel"""


---END OF SCHEMA---