# Data Warehouse Analytics Project

## Overview

This project demonstrates an end-to-end SQL-based analytics workflow using a dimensional data warehouse model. The analysis focuses on understanding sales trends, customer behavior, product performance, and business segmentation in order to derive actionable business insights.

The project simulates a real-world analytics environment where transactional sales data is analyzed using SQL to support data-driven decision making.

---

## Objectives

The main objectives of this project are:

- Analyze business performance over time
- Identify high-performing and low-performing products
- Understand product contribution to total revenue
- Segment customers based on purchasing behavior
- Build reusable reporting views for analytics and dashboards

---

## Repository Structure
data-warehouse-analytics
│
├── README.md
│
├── sql
│ └── data_warehouse_analytics.sql
│
├── documentation
│ └── Data_Warehouse_Analytics_Report.pdf
│
└── images
├── sales_trend.png
├── segmentation.png
├── product_analysis.png

---

## Data Model

The project uses a **Star Schema Data Warehouse model**.

### Fact Table

- `gold.fact_sales`  
Contains transactional sales data.

### Dimension Tables

- `gold.dim_customers`  
Contains customer demographic information.

- `gold.dim_products`  
Contains product information including category and cost.

---

## Analysis Performed

### 1. Changes Over Time Analysis

Analyzes yearly trends in:

- total sales
- number of customers
- quantity sold

This helps understand business growth and demand trends.

---

### 2. Cumulative Sales Analysis

Calculates:

- running total sales
- moving average price

This helps track revenue accumulation and pricing trends over time.

---

### 3. Product Performance Analysis

Evaluates product-level metrics including:

- total orders
- total sales
- total customers
- product lifecycle
- revenue efficiency

Products are also segmented into:

- High Performer
- Mid Range
- Low Performer

---

### 4. Part-To-Whole Analysis

Determines category contribution to overall business.

Metrics analyzed:

- revenue contribution by category
- customer distribution across categories

---

### 5. Data Segmentation

Segments both products and customers.

#### Product Segmentation
Products grouped by cost ranges:

- Below 100
- 100–500
- 500–1000
- Above 1000

#### Customer Segmentation

Customers classified as:

- VIP
- Regular
- New

based on spending and customer lifespan.

---

### 6. Customer Reporting View

A reusable analytical view was created:

This view includes:

- customer demographics
- total orders
- total sales
- recency
- customer lifespan
- average order value
- monthly spending

This dataset can be directly used for dashboards.

---

### 7. Product Reporting View

A second analytical view was created:


This view provides:

- product sales metrics
- customer reach
- product lifecycle metrics
- product performance segmentation

---

## Key Business Insights

Some of the key insights derived from the analysis include:

- Revenue is heavily concentrated in the **Bikes category**
- Accessories attract the largest number of customers
- VIP customers represent a smaller segment but contribute significant revenue
- Most products fall within lower price ranges
- Cross-selling opportunities exist between bikes and accessories

---

## Technologies Used

- SQL Server
- T-SQL
- Data Warehouse Modeling
- Analytical SQL
- GitHub

---

## Repository Structure

This view provides:

- product sales metrics
- customer reach
- product lifecycle metrics
- product performance segmentation

---

## Key Business Insights

Some of the key insights derived from the analysis include:

- Revenue is heavily concentrated in the **Bikes category**
- Accessories attract the largest number of customers
- VIP customers represent a smaller segment but contribute significant revenue
- Most products fall within lower price ranges
- Cross-selling opportunities exist between bikes and accessories

---

## Technologies Used

- SQL Server
- T-SQL
- Data Warehouse Modeling
- Analytical SQL
- GitHub

---

---

## Author

**Eniyan D**

Aspiring Data Analyst | SQL | Data Warehousing | Business Analytics

LinkedIn :🔗 www.linkedin.com/in/tamil-eniyan-a7116a171

GitHub :🔗 https://github.com/ENIYAND

