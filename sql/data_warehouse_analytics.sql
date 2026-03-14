
USE DataWarehouseAnalytics;

---------------------------------------------------------------------------------------------
--CUSTOMER REPORTS AND ANALYSIS
---------------------------------------------------------------------------------------------


--1.Changes Over Time Analysis
SELECT 
DATETRUNC(YEAR, order_date) AS order_year,
SUM(sales_amount) AS total_Sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(YEAR, order_date) 
ORDER BY DATETRUNC(YEAR, order_date) ;

--2. Cumulative Sales Analysis
SELECT
    order_date,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_date) AS running_total_sales,
    AVG(avg_price) OVER (ORDER BY order_date) AS moving_average_price
FROM
(
    SELECT
        DATETRUNC(year, order_date) AS order_date,
        SUM(sales_amount) AS total_sales,
        AVG(price) AS avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(year, order_date)
) AS subquery;

--3. Performance Analysis
WITH yearly_product_sales AS (
    SELECT
        YEAR(f.order_date) AS order_year,
        p.product_name,
        SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY 
        YEAR(f.order_date),
        p.product_name
)

SELECT
    order_year,
    product_name,
    current_sales,
    AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
    current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
    CASE 
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
        ELSE 'Avg'
    END AS avg_change,
--YoY Analysis
    COALESCE(LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year),0) AS py_sales,
    COALESCE(current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year),0) AS diff_py,
    CASE 
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS py_change
FROM yearly_product_sales
ORDER BY product_name, order_year;

--4. Part-To-Whole Analysis
---4.1 Based on Sales
WITH category_sales AS (
    SELECT
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
    GROUP BY p.category
)

SELECT
    category,
    total_sales,
    SUM(total_sales) OVER () AS overall_sales,
    CONCAT(
        ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ()) * 100, 2), 
        '%'
    ) AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;

---4.2 Based on Customers
WITH category_sales AS (
    SELECT
        p.category,
        COUNT(DISTINCT f.customer_key) AS total_customers
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
    GROUP BY p.category
)

SELECT
    category,
    total_customers,
    SUM(total_customers) OVER () AS overall_customers,
    CONCAT(
        ROUND((CAST(total_customers AS FLOAT) / SUM(total_customers) OVER ()) * 100, 2), 
        '%'
    ) AS percentage_of_total
FROM category_sales
ORDER BY total_customers DESC;

--5. Data Segmentation
---5.1 Based on Cost Range
WITH product_segments AS (
    SELECT
        product_key,
        product_name,
        cost,
        CASE 
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
            ELSE 'Above 1000'
        END AS cost_range
    FROM gold.dim_products
)

SELECT
    cost_range,
    COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;

---5.2 Based on Customer Spending behaviour
WITH customer_spending AS (
    SELECT
        c.customer_key,
        SUM(f.sales_amount) AS total_spending,
        MIN(f.order_date) AS first_order,
        MAX(f.order_date) AS last_order,
        DATEDIFF(month, MIN(f.order_date), MAX(f.order_date)) AS lifespan
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY c.customer_key
)

SELECT
    customer_segment,
    COUNT(customer_key) AS total_customers
FROM (
    SELECT
        customer_key,
        CASE 
            WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
            WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_segment
    FROM customer_spending
) t
GROUP BY customer_segment
ORDER BY total_customers DESC;

--6. Build Customer Reports
GO
CREATE VIEW gold.report_customers AS 
WITH base_query AS (
/* -------------------------------------------------------------------------
   1) Base Query: Retrieves core columns from tables
   ------------------------------------------------------------------------- */
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        -- Combine first and last name into a single column
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        -- Calculate current age based on birthdate and today's date
        DATEDIFF(year, c.birthdate, GETDATE()) AS age
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON c.customer_key = f.customer_key
    WHERE f.order_date IS NOT NULL
),

customer_aggregation AS(
/* -------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
------------------------------------------------------------------------- */
SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT product_key) AS total_products,
    MAX(order_date) AS last_order_date,
    DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
GROUP BY 
    customer_key,
    customer_number,
    customer_name,
    age)

SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    CASE 
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,
    CASE 
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,
    last_order_date,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    DATEDIFF(month,last_order_date,GETDATE()) AS recency,
    CASE WHEN total_sales = 0 THEN 0
         ELSE total_sales/total_orders
    END AS avg_order_value,
    CASE WHEN lifespan = 0 THEN total_sales
         ELSE total_sales/lifespan
    END AS avg_monthly_spend
FROM customer_aggregation;

SELECT * FROM gold.report_customers;

---------------------------------------------------------------------------------------------
-- PRODUCT REPORTS AND ANALYSIS
---------------------------------------------------------------------------------------------
/*
Purpose:
    This report consolidates key product-level sales metrics and behaviors.

Description:
    - Combines product attributes from the dimension table with sales
      transactions from the fact table.
    - Calculates performance metrics to evaluate product demand and revenue.

Key Metrics:
    - Total Orders
    - Total Sales
    - Total Quantity Sold
    - Total Unique Customers
    - Product Lifespan (in months)
    - Recency (months since last sale)
    - Average Order Revenue (AOR)
    - Average Monthly Revenue

Segmentation:
    Products are categorized into High Performer, Mid Range,
    or Low Performer based on total sales.

Source Tables:
    gold.dim_products
    gold.fact_sales
===============================================================================
*/

--1.Base Product Information

SELECT
    p.product_key,
    p.product_name,
    p.category,
    p.subcategory,
    p.cost
FROM gold.dim_products p

--2.Join with Sales Data
    -- Join product dimension with fact sales to combine product attributes
    -- with transaction-level sales data
SELECT
    p.product_key,
    p.product_name,
    p.category,
    p.subcategory,
    p.cost
FROM gold.dim_products p
LEFT JOIN gold.fact_sales s
ON p.product_key = s.product_key;

--3. Aggregate Sales Metrics
    -- Aggregate sales data at the product level
    -- This section calculates product performance metrics
SELECT
    p.product_key,
    p.product_name,
    p.category,
    p.subcategory,
    p.cost,
    -- Total number of unique orders containing the product
    COALESCE(COUNT(DISTINCT s.order_number),0) AS total_orders,

    -- Total revenue generated by the product
    COALESCE(SUM(s.sales_amount),0) AS total_sales,

    -- Total quantity of items sold
    COALESCE(SUM(s.quantity),0) AS total_quantity_sold,

    -- Number of unique customers who purchased the product
    COALESCE(COUNT(DISTINCT s.customer_key),0) AS total_customers,

        -- Product lifespan measured as months between first and last sale
    COALESCE(DATEDIFF(month, MIN(s.order_date), MAX(s.order_date)),0) AS lifespan_months,

    -- Recency measures how many months have passed since the last sale
    COALESCE(DATEDIFF(month, MAX(s.order_date), GETDATE()),0) AS recency_months,

    -- Average revenue per order (AOR)
    -- Helps evaluate how much revenue each order contributes
    COALESCE(SUM(s.sales_amount) * 1.0 / COUNT(DISTINCT s.order_number),0) AS avg_order_revenue,

    -- Average monthly revenue generated by the product
    -- NULLIF prevents divide-by-zero errors when lifespan is zero
    COALESCE(SUM(s.sales_amount) * 1.0 /
    NULLIF(DATEDIFF(month, MIN(s.order_date), MAX(s.order_date)),0),0)
    AS avg_monthly_revenue,
    -- Segment products based on total sales performance
    CASE
    WHEN SUM(s.sales_amount) > 50000 THEN 'High Performer'
    WHEN SUM(s.sales_amount) > 10000 THEN 'Mid Range'
    ELSE 'Low Performer'
    END AS product_segment

FROM gold.dim_products p
LEFT JOIN gold.fact_sales s
    ON p.product_key = s.product_key

GROUP BY
    p.product_key,
    p.product_name,
    p.category,
    p.subcategory,
    p.cost

ORDER BY total_sales DESC;


GO
CREATE VIEW gold.report_products AS

WITH base_query AS (
/* -------------------------------------------------------------------------
   1) Base Query: Retrieves core product and sales columns
------------------------------------------------------------------------- */
    SELECT
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,

        p.product_key,
        p.product_number,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost

    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key

    WHERE f.order_date IS NOT NULL
),

product_aggregation AS (
/* -------------------------------------------------------------------------
   2) Product Aggregations: Summarizes key metrics at the product level
------------------------------------------------------------------------- */

SELECT
    product_key,
    product_number,
    product_name,
    category,
    subcategory,
    cost,

    COUNT(DISTINCT order_number) AS total_orders,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT customer_key) AS total_customers,

    MIN(order_date) AS first_sale_date,
    MAX(order_date) AS last_sale_date,

    DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan

FROM base_query

GROUP BY
    product_key,
    product_number,
    product_name,
    category,
    subcategory,
    cost
)

SELECT
    product_key,
    product_number,
    product_name,
    category,
    subcategory,
    cost,

    total_orders,
    total_sales,
    total_quantity,
    total_customers,

    first_sale_date,
    last_sale_date,

    lifespan,

    /* Recency: months since last sale */
    DATEDIFF(month, last_sale_date, GETDATE()) AS recency,

    /* Average order revenue */
    CASE 
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_revenue,

    /* Average monthly revenue */
    CASE 
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_revenue,

    /* Product Performance Segmentation */
    CASE
        WHEN total_sales > 50000 THEN 'High Performer'
        WHEN total_sales > 10000 THEN 'Mid Range'
        ELSE 'Low Performer'
    END AS product_segment

FROM product_aggregation;