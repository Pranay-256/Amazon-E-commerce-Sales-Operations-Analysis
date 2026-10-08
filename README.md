# Amazon E-commerce Sales & Operations Analytics Pipeline

An end-to-end e-commerce analytics project covering **SQL analysis, data cleaning, Python/Pandas ETL, dimensional modeling and an interactive Power BI dashboard**.

 **Project Status:** Completed ✅
 
 **Part 1:** SQL + ETL + Power BI-ready data\
 **Part 2:** Power BI data model, DAX measures and 4-page interactive dashboard

 📄 A full write-up is available in [`Project_Report.pdf`](Project_Report.pdf) (business requirements, database & data model, SQL insights and dashboard analysis).

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Business Requirements](#business-requirements)
3. [Tech Stack](#tech-stack)
4. [Database Design & EDA](#1-database-design--eda)
5. [SQL Business Analysis & Key Insights](#2-sql-business-analysis--key-insights)
6. [Advanced SQL](#3-advanced-sql)
7. [Python ETL & Dimensional Modeling](#4-python-etl--dimensional-modeling)
8. [Power BI Data Model](#5-power-bi-data-model)
9. [Power BI Dashboard](#6-power-bi-dashboard)
10. [Repository Structure](#7-repository-structure)
11. [Complete Pipeline / How to Update the Project](#8-complete-pipeline--how-to-update-the-project)
12. [Skills Demonstrated](#skills-demonstrated)

---

## Project Overview

The business operates an Amazon-style online marketplace where customers place orders for products sold by many different sellers. Orders are paid for, shipped through delivery providers and fulfilled from several warehouses. This project studies that data, answers key business questions with SQL and presents the results in an interactive Power BI dashboard to support decisions on **sales, customers, sellers, shipping and inventory**.

The dataset contains **9 related tables**:

`categories` • `customers` • `products` • `sellers` • `orders` • `order_items` • `payments` • `shipping` • `inventory`

The project follows this pipeline:

```text
Raw CSV Data
     ↓
PostgreSQL Database (amazon_db)
     ↓
Relationships + EDA + Data Cleaning
     ↓
SQL Business Analysis (20 questions + stored procedure)
     ↓
Python + Pandas ETL
     ↓
Fact & Dimension Tables (star schema)
     ↓
Power BI-ready CSVs / PostgreSQL (amazon_fact&dim_db)
     ↓
Power BI Data Model + DAX Measures
     ↓
Interactive 4-Page Power BI Dashboard
```

---

## Business Requirements

**SQL analysis:** answer 20 business questions and build an automated inventory-update stored procedure.

**Power BI dashboard requirements:**

- **Four report pages:** Executive Sales Overview, Customers & Sellers Insights, Shipping & Delivery Performance, Inventory Health Analysis
- **Filters:** Category, Year and Month slicers on every page
- **Sales KPIs:** total revenue, current revenue, YoY and MoM revenue growth, total orders, average order value, profit margin
- **Customer & seller KPIs:** total customers, returning customers, active sellers, average revenue per seller / customer
- **Shipping KPIs:** delivery, in-transit, cancel and return rates, average days in shipping
- **Inventory KPIs:** total stock in hand, products below threshold, total inventory value, total warehouses

---

## Tech Stack

| Technology | Purpose |
|---|---|
| **PostgreSQL / SQL** | Database creation, EDA, data cleaning and business analysis |
| **Python** | ETL and data transformation |
| **Pandas** | Data cleaning, merging, date handling and dimensional modeling |
| **SQLAlchemy** | Python-to-database connectivity |
| **Power BI & DAX** | Data modeling, measures, KPIs and interactive dashboard |

---

## 1. Database Design & EDA

The original dataset was structured into **9 relational tables** (3 parent tables and 6 child tables), each with a primary key and foreign-key relationships between them.

The SQL stage included:

- Database and table creation
- Relationship / foreign-key validation
- Null and duplicate checks
- Date-range validation
- Text cleaning using `TRIM()`
- Missing-value handling
- Status-value validation
- Product price / COGS checks
- Cross-table consistency checks
- Referential-integrity validation

**Data preparation notes** (cleaned with Python/Excel before import, because of PK/FK constraints):

- The products file had invalid values (text and null) in the `price` and `cogs` columns.
- Some `product_id`s in `order_items` were not present in `products`.
- Some `product_id`s in `inventory` were not present in `products`.

The database schema ER diagram (`amazon_db`):

![SQL Database Schema](schemas/sql_database_schema.png)

---

## 2. SQL Business Analysis & Key Insights

I answered **20 business questions** using SQL techniques such as **multi-table joins, aggregations, `GROUP BY`, `HAVING`, `CASE`, CTEs, subqueries, window functions, ranking, date calculations and conditional aggregation**.

### Sales & Product Analysis

1. **Top 10 selling products** based on non-cancelled/non-returned orders, including category, orders, quantity sold and sales value.
2. **Revenue by product category**, including each category's sales contribution.
3. **Average Order Value (AOV)** for customers with at least 15 orders.
4. **Month-by-month sales trend**, comparing current-month sales with the previous month.
5. **Customers registered but with no orders.**
6. **Top 3 best-selling categories in each state**, including sales value.
7. **Least-selling category in each state**, including sales value.
8. **Customer lifetime order value**, including total orders, total sales and customer ranking.
9. **Low-stock products** below a threshold of 10 units, along with warehouse sales analysis.
10. **Orders with shipping delays of more than 5 days**, including customer, order and shipping details.

### Payments, Sellers & Profitability

11. **Payment-status contribution percentage** across all orders.
12. **Top 5 sellers by sales**, including successful/failed orders, success rate, and the top products of the highest-ranked seller.
13. **Gross profit and profit margin by product**, including product ranking.
14. **Top 10 most-returned products**, including returned quantity and return rate.
15. **Sellers with no sales in the last 6 months**, including their latest sale date and total sales.
16. **Customer return activity** for customers with at least 10 orders in the last 2 years, including return rate and return-frequency classification.
17. **Top 5 customers in each state** based on number of orders and their total sales.
18. **Running total sales by year**, along with yearly sales.

### Operations & Growth

19. **Shipping-provider performance**, including revenue, orders handled, average delivery time and order contribution.
20. **Year-over-Year revenue growth percentage** for each recorded year.

---

## 3. Advanced SQL

The analysis demonstrates practical use of:

```text
JOINs
GROUP BY / HAVING
Aggregate Functions
CASE Statements
CTEs
Subqueries
Window Functions
DENSE_RANK()
ROW_NUMBER()
LAG()
Conditional Aggregation
Date / Interval Calculations
Stored Procedures
```

### Stored Procedure

A PostgreSQL stored procedure named `add_sales` automates inventory updates when a new sale is added. It:

1. Checks the product and its price.
2. Checks inventory availability.
3. Inserts the new order.
4. Inserts the order item.
5. Calculates total sales.
6. Decreases inventory stock.
7. Displays a status message when the product is unavailable.

---

## 4. Python ETL & Dimensional Modeling

After the SQL analysis, a Python script (`pandas` + `SQLAlchemy`) converts the 9 database tables into an analytics-ready **star schema**.

### ETL Script

```text
python script/
├── fact_dim_creation.py
└── requirements.txt
```

### What the script does

1. Reads all 9 tables from `amazon_db` into pandas dataframes and checks the top 5 rows of each.
2. Builds the dimension and fact tables listed below.
3. Fixes date columns (`last_stock_date`, `order_date`, `shipping_date`, `return_date`, `payment_date`) to a proper date data type.
4. Writes all 7 resulting tables to a second PostgreSQL database (`amazon_fact&dim_db`) and exports Power BI-ready CSVs.

### Generated Tables

| Table | Type | Built From |
|---|---|---|
| `dim_products` | Dimension | `products` joined with `category` on `category_id` |
| `dim_customers` | Dimension | `customers` table |
| `dim_sellers` | Dimension | `sellers` table |
| `dim_warehouse` | Dimension | Unique `warehouse_id` values from `inventory` |
| `dim_date` | Dimension | Continuous daily calendar from the earliest to the latest date across orders, payments, shipping, returns and inventory, with year, month and day columns |
| `fact_sales` | Fact | `orders` combined with `order_items`, `payments` and `shipping` on `order_id` |
| `fact_inventory` | Fact | Copy of the `inventory` table |

To keep the star schema simple, no separate dimensions were created for orders, order items, payments and shipping. They are all combined into `fact_sales` through `order_id`.

### Data Checks in the Script

- **Orders without item data:** 231 orders exist in `orders` but not in `order_items`. They have null `product_id`, `quantity` and `price_per_unit` in `fact_sales`, and are flagged using a new `has_item_data` (Yes/No) column.
- **Null return dates:** confirmed to be genuine (orders were delivered, cancelled or still in transit), not a join error.

---

## 5. Power BI Data Model

The dimension and fact tables are loaded into Power BI as a **star schema**, with one-to-many relationships from each dimension to the fact tables:

- `dim_sellers` → `fact_sales` through `seller_id`
- `dim_customers` → `fact_sales` through `customer_id`
- `dim_products` → `fact_sales` and `fact_inventory` through `product_id`
- `dim_warehouse` → `fact_inventory` through `warehouse_id`
- `dim_date` → date columns of the fact tables (one **active** relationship, the others are **inactive** and used through DAX)

Calculated columns such as `customer_name`, `days_in_shipping` and month names were added in Power BI.

![Power BI Data Model](schemas/powerbi%20data%20model.png)

---

## 6. Power BI Dashboard

The dashboard is built on the star schema above and has **four pages**. Every page has **Category, Year and Month slicers** at the top, followed by a row of KPI cards, charts and tables. The screenshots below show each page with Category = *All*, Year = *2023* and Month = *January*.

📁 Dashboard file: [`powerbi dashboard/amazon dashboard.pbix`](powerbi%20dashboard/amazon%20dashboard.pbix)

### 6.1 Executive Sales Overview

![Executive Sales Overview](powerbi%20dashboard/images/01%20Executive%20Sales%20Overview.png)

- **KPIs:** Total Revenue **$25.80M**, Current Revenue **$576.67K**, YoY Growth **−3.40%**, MoM Growth **25.02%**, Total Orders **427**, AOV **$1.45K**, Profit Margin **54.37%**.
- **Revenue trend:** starts near $580K, dips to its lowest (~$380K) in April, then recovers to its peak (~$670K) in December.
- **Revenue by category:** Electronics leads with **$443K**, far ahead of Home & Kitchen ($75K), Sports & Outdoors ($21K), Toys & Games ($15K), Clothing ($13K) and Pet Supplies ($10K).
- **Top 10 products:** all electronics, led by the Samsung Portable product ($29.5K), JBL Wi-Fi Router ($27.1K) and Dell Wireless Mouse ($20.0K).
- **State-wise revenue:** California, Ohio and Florida have the highest revenue.

### 6.2 Customers & Sellers Insights

![Customers & Sellers Insights](powerbi%20dashboard/images/02%20Customers%20%26%20Seller%20Insights.png)

- **KPIs:** **900** customers, **331** returning customers, **54** active sellers, **$10.68K** average revenue per seller, **$640.75** average revenue per customer.
- **Customers by state:** California (71), Texas (57), Florida (55) and Ohio (45) lead.
- **Top customers:** Janet Thomas ($22,583.05, 3.92%), Megan Diaz ($21,968.28, 3.81%) and Jacqueline Davis ($21,050.95, 3.65%). Most top customers generate revenue from only 1–3 orders.
- **Return frequency:** customers such as Deborah Ramirez, Dennis Sanders and Jerry Gray are segmented as "High Frequency" returners (50%–100% return rate).
- **Seller origin:** USA has the largest share, followed by China and Japan.
- **Seller performance:** Roborock earns the highest revenue ($50,279.91) with only 10 orders, followed by Yeti Coolers ($30,509.11) and Amazonbasics ($29,582.63).

### 6.3 Shipping & Delivery Performance

![Shipping & Delivery Performance](powerbi%20dashboard/images/03%20Shipping%20%26%20Delivery%20Performance.png)

- **KPIs:** 427 orders, **236 delivered**; Delivery Rate **55.27%**, In-Transit Rate **36.30%**, Cancel Rate **4.68%**, Return Rate **3.75%**, Avg Days in Shipping **2**.
- **Order & payment status:** Delivered/Payment Successful 236, In Transit/Payment Pending 155, Cancelled/Payment Failed 20, Returned/Refunded 16.
- **Shipping providers:** FedEx handles the most orders (178), followed by DHL (79), Bluedart (66), UPS (61) and USPS (43). DHL has the highest delivery rate (59.49%); USPS has the lowest (51.16%) and the highest in-transit rate (44.19%). Bluedart has the highest return rate (6.06%) and DHL the highest cancel rate (6.33%).
- **Returns by category:** Electronics (5), Sports & Outdoors (4), Pet Supplies (3), Clothing and Toys & Games (2 each).
- **Monthly return trend:** peaks in May (~18), lowest in July (~10), rises again in August (~17) and declines towards December (~11).

### 6.4 Inventory Health Analysis

![Inventory Health Analysis](powerbi%20dashboard/images/04%20Inventory%20Health%20Analysis.png)

- **KPIs:** **39K** units in stock across **5** warehouses, total inventory value **$13.67M**, **42** products below the stock threshold.
- **Stock by warehouse:** Warehouse 1 holds the most stock (14.5K), followed by Warehouse 2 (8.3K), Warehouse 3 (6.3K), Warehouse 4 (5.6K) and Warehouse 5 (4.7K).
- **Orders by warehouse:** Warehouse 1 also handles the most orders (146), so it needs close monitoring and frequent replenishment.
- **Product stock status:** products such as the Asus External SSD 1TB, Cuisinart Electric Kettle and a Hasbro Building Bricks Set have only 5 units in stock.
- **Stock vs sales velocity:** a few fast-selling products reach $20K–$27K in sales with low-to-moderate stock, making them the first candidates for restocking.

### Business Recommendations

- **Replenish Warehouse 1 more often**: it has the highest demand and the most low-stock products.
- **Promote high-margin products** (176+ products with margin above 60%).
- **Investigate the 2022 revenue decline** (−6.77%) and prevent a repeat.
- **Follow up on high-return customers and products** with sellers and customers to reduce returns.
- **Reduce pending payments** (about 36% of orders) to avoid processing delays.
- **Diversify beyond Electronics**, which makes up about 77% of sales.

---

## 7. Repository Structure

```text
Amazon-E-commerce-Sales-Operations-Analysis/
│
├── data/
│   ├── original datasets/
│   │   ├── categories.csv
│   │   ├── customers.csv
│   │   ├── inventory.csv
│   │   ├── order_items.csv
│   │   ├── orders.csv
│   │   ├── payments.csv
│   │   ├── products.csv
│   │   ├── sellers.csv
│   │   └── shipping.csv
│   │
│   └── powerbi datasets/
│       ├── dim_customers.csv
│       ├── dim_date.csv
│       ├── dim_products.csv
│       ├── dim_sellers.csv
│       ├── dim_warehouse.csv
│       ├── fact_inventory.csv
│       └── fact_sales.csv
│
├── powerbi dashboard/
│   ├── amazon dashboard.pbix
│   └── images/
│       ├── 01 Executive Sales Overview.png
│       ├── 02 Customers & Seller Insights.png
│       ├── 03 Shipping & Delivery Performance.png
│       └── 04 Inventory Health Analysis.png
│
├── python script/
│   ├── fact_dim_creation.py
│   └── requirements.txt
│
├── schemas/
│   ├── powerbi data model.png
│   └── sql_database_schema.png
│
├── sql analysis/
│   ├── 01 database creation.sql
│   ├── 02 EDA & Cleaning.sql
│   └── 03 business questions.sql
│
├── Project_Report.pdf
└── README.md
```

---

## 8. Complete Pipeline / How to Update the Project

The project follows a **full-refresh workflow**. Whenever the source database/data changes:

### Step 1 — Rebuild the analytical model

Run:

```text
fact_dim_creation.py
```

This regenerates the fact and dimension tables and overwrites the Power BI-ready files with the latest data.

### Step 2 — Refresh Power BI

Open `amazon dashboard.pbix` and click **Refresh**. Power BI reads the updated data and refreshes every dashboard page.

### Complete Workflow

```text
Change Source Data
       ↓
fact_dim_creation.py
       ↓
Updated Fact/Dimension Tables
       ↓
Power BI Refresh
       ↓
Updated Dashboard & Insights
```

This makes the project reproducible: **data changes → ETL → refreshed analytical model → refreshed BI output.**

---

## Skills Demonstrated

**SQL • PostgreSQL • Python • Pandas • ETL • Data Cleaning • EDA • Relational Database Design • Star Schema • Fact & Dimension Modeling • Window Functions • CTEs • Subqueries • Stored Procedures • SQLAlchemy • Power BI • DAX • Data Modeling • Dashboard Design • Business Insights & Storytelling**

---

## Project Status

### Part 1 — Data & Analytics Engineering

- [x] Database design & relationships
- [x] EDA & data cleaning
- [x] 20 SQL business questions
- [x] Advanced SQL analysis
- [x] Stored procedure
- [x] Python/Pandas ETL
- [x] Fact & dimension modeling
- [x] Power BI-ready datasets

### Part 2 — Business Intelligence

- [x] Power BI data model
- [x] DAX measures
- [x] Dashboard development
- [x] Interactive analysis
- [x] Final insights & documentation

## Author

**Pranay Jha**

Data Analytics & Business Intelligence
