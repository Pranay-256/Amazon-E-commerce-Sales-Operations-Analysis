# Used to build fact and dimension tables based on the amazon_db postgre sql database.

import pandas as pd
from sqlalchemy import create_engine, inspect

pg_engine = create_engine("postgresql+psycopg2://<username>:<password>@<server>:<port>/amazon_db")
pg_engine2 = create_engine("postgresql+psycopg2://<username>:<password>@<server>:<port>/amazon_fact&dim_db")

inspector = inspect(pg_engine)
table_names = inspector.get_table_names(schema='public')

# Top 5 rows of every table in the database
for n, table in enumerate(table_names, start=1):
    print(f"{n}). top 5 rows of {table} table: ")
    print(pd.read_sql(f'SELECT * FROM "{table}" LIMIT 5;', pg_engine))
    print()

# Converting database tables into pandas dataframes

categories = pd.read_sql('SELECT * FROM category', pg_engine)
customers = pd.read_sql('SELECT * FROM customers', pg_engine)
inventory = pd.read_sql('SELECT * FROM inventory', pg_engine)
orders = pd.read_sql('SELECT * FROM orders', pg_engine)
order_items = pd.read_sql('SELECT * FROM order_items', pg_engine)
payments = pd.read_sql('SELECT * FROM payments', pg_engine)
products = pd.read_sql('SELECT * FROM products', pg_engine)
sellers = pd.read_sql('SELECT * FROM sellers', pg_engine)
shipping = pd.read_sql('SELECT * FROM shipping', pg_engine)

# Creating dim and fact tables

dim_products = products.merge(categories, on='category_id', how='left')
print(dim_products.head())

dim_customers = customers.rename(columns={"Customer ID": "customer_id"})
print(dim_customers.head())

dim_sellers = sellers.copy()
print(dim_sellers.head())

dim_warehouse = pd.DataFrame({"warehouse_id": inventory["warehouse_id"].drop_duplicates().sort_values()})
print(dim_warehouse.head())

# Fixing the date column datatypes in the inventory, orders, shipping and payments tables

inventory["last_stock_date"] = pd.to_datetime(inventory["last_stock_date"], format="%Y-%m-%d", errors="coerce")
orders["order_date"] = pd.to_datetime(orders["order_date"], format="%Y-%m-%d", errors="coerce")
shipping["shipping_date"] = pd.to_datetime(shipping["shipping_date"], format="%Y-%m-%d", errors="coerce")
shipping["return_date"] = pd.to_datetime(shipping["return_date"], format="%Y-%m-%d", errors="coerce")
payments["payment_date"] = pd.to_datetime(payments["payment_date"], format="%Y-%m-%d", errors="coerce")

print(inventory["last_stock_date"])
print(orders["order_date"])
print(shipping["shipping_date"])
print(shipping[shipping["return_date"].notna()])
print(payments["payment_date"])

print(payments.head())

print(orders.columns)
print()
print(order_items.columns)

fact_sales = orders.merge(
    order_items[["order_id", "product_id", "quantity", "price_per_unit"]],
    on="order_id", how="left"
)

print(payments.columns)

fact_sales = fact_sales.merge(
    payments[['order_id', 'payment_date', 'payment_status']],
    on="order_id", how="left"
)

print(shipping.columns)

fact_sales = fact_sales.merge(
    shipping[["order_id", "shipping_date", "return_date", "shipping_provider", "delivery_status"]],
    on="order_id", how="left"
)

fact_sales = fact_sales[[
    "order_id", "order_date", "customer_id", "product_id", "quantity", "price_per_unit",
    "payment_date", "payment_status", "seller_id", "shipping_provider", "shipping_date",
    "return_date", "order_status", "delivery_status"
]]
print(fact_sales.head())
print("\n")
print(f"the fact_sales table has {fact_sales.shape[0]} rows and {fact_sales.shape[1]} columns")
print("\n")

''' Note: To get the complete overview of the sales process and maintain the
 star schema structure for Power BI, no separate dimension tables were
 created for the orders, order_items, payments and shipping tables.
 Instead they have all been combined using the common order_id column.'''

print(fact_sales.isnull().sum())
print("\n")

orders_unique = orders["order_id"].nunique()
order_items_unique = order_items["order_id"].nunique()
print(orders_unique - order_items_unique)

''' Note: The 231 null values in the product_id, quantity and price_per_unit
 columns exist because these orders are present in the orders table but
 were not recorded in the order_items table. These columns in fact_sales
 are derived from order_items via a left join with orders.'''

print(fact_sales[(fact_sales["delivery_status"] != 'Returned') & (fact_sales["return_date"].notna())])

''' Note: This confirms the null values in the return_date column are because
 those orders were not returned (i.e. delivered, cancelled, or still in
 the process of being delivered) — not caused by any join error.'''

fact_inventory = inventory.copy()
print(fact_inventory)

all_dates = pd.concat([
    fact_sales["order_date"], fact_sales["payment_date"], fact_sales["shipping_date"],
    fact_sales["return_date"], fact_inventory["last_stock_date"]
])
all_dates = pd.to_datetime(all_dates, errors="coerce").dropna().drop_duplicates()
print(all_dates)
dim_date = pd.DataFrame({"date": pd.date_range(all_dates.min(), all_dates.max(), freq="D")})
dim_date["year"] = dim_date["date"].dt.year
dim_date["month"] = dim_date["date"].dt.month
dim_date["day"] = dim_date["date"].dt.day

print(dim_date)

# Writing fact and dimension tables back into another PostgreSQL database amazon_fact&dim_db

star_schema_tables = {
    "dim_date": dim_date,
    "dim_products": dim_products,
    "dim_customers": dim_customers,
    "dim_sellers": dim_sellers,
    "dim_warehouse": dim_warehouse,
    "fact_sales": fact_sales,
    "fact_inventory": fact_inventory
}

for table_name, df in star_schema_tables.items():
    df.to_sql(table_name, con=pg_engine2, if_exists='replace', index=False)
    print(f"{table_name}: {len(df):,} rows inserted to amazon_fact&dim_db")

print("\n\nFact and dimension tables created successfully in amazon_fact&dim_db.")