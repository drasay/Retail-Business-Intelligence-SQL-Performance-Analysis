/* E-Commerce Business Intelligence & Sales Analysis
   Description: A series of SQL queries designed to extract actionable insights 
   from a retail database, including revenue trends, customer segmentation, 
   and growth metrics.
   
   Tech Stack: SQL (PostgreSQL/MySQL compatible)
*/

-- Analysis of daily sales volume (April - May 2024)
SELECT 
    cp.transaction_date,
    SUM(cp.quantity * p.unit_price) AS daily_sales
FROM 
    customer_purchase cp
INNER JOIN product p 
    ON cp.product_id = p.product_id
WHERE 
    cp.transaction_date BETWEEN '2024-04-01' AND '2024-05-31'
GROUP BY 
    cp.transaction_date 
ORDER BY 
    cp.transaction_date ASC;

-- Monthly revenue aggregation
SELECT 
    MONTH(cp.transaction_date) AS month,
    SUM(cp.quantity * p.unit_price) AS monthly_sales
FROM 
    customer_purchase cp
INNER JOIN product p 
    ON cp.product_id = p.product_id
WHERE 
    cp.transaction_date BETWEEN '2024-04-01' AND '2024-05-31'
GROUP BY 
    MONTH(cp.transaction_date)
ORDER BY 
    MONTH(cp.transaction_date) ASC;

-- Regional revenue analysis for May 2024
SELECT
    c.city,
    SUM(cp.quantity * p.unit_price) AS overall_sales_May_2024
FROM 
    customer_purchase cp
INNER JOIN product p 
    ON cp.product_id = p.product_id
INNER JOIN customer c 
    ON cp.customer_id = c.customer_id
WHERE 
    cp.transaction_date BETWEEN '2024-05-01' AND '2024-05-31'
GROUP BY 
    c.city
ORDER BY 
    overall_sales_May_2024 DESC;


-- Top 10 products by total revenue generation
SELECT
    p.product_name,
    SUM(cp.quantity * p.unit_price) AS total_sales
FROM 
    customer_purchase cp
INNER JOIN product p 
    ON cp.product_id = p.product_id
GROUP BY 
    p.product_name
ORDER BY 
    total_sales DESC 
LIMIT 10;

-- Top 10 customers by purchase volume
SELECT 
    cp.customer_id,
    c.first_name,
    c.last_name,
    SUM(cp.quantity) AS total_products_purchased
FROM 
    customer_purchase cp
INNER JOIN customer c 
    ON cp.customer_id = c.customer_id
GROUP BY 
    cp.customer_id
ORDER BY 
    total_products_purchased DESC, c.last_name ASC
LIMIT 10;

-- Comprehensive VIP customer analysis and category affinity
WITH customer_total_spend AS (
    SELECT 
        cp.customer_id,
        c.first_name,
        c.last_name,
        SUM(cp.quantity * p.unit_price) AS overall_spend
    FROM 
        customer_purchase cp
    INNER JOIN customer c 
        ON cp.customer_id = c.customer_id
    INNER JOIN product p 
        ON cp.product_id = p.product_id
    GROUP BY 
        cp.customer_id
),
customer_top_product AS (
    SELECT 
        cp.customer_id,
        cp.product_id,
        p.product_name,
        SUM(cp.quantity * p.unit_price) AS amount_spent_on_product
    FROM 
        customer_purchase cp
    INNER JOIN product p 
        ON cp.product_id = p.product_id
    GROUP BY 
        cp.customer_id, cp.product_id
),
customer_top_spend_with_product AS (
    SELECT 
        cts.customer_id,
        cts.first_name,
        cts.last_name,
        cts.overall_spend,
        ctp.product_name AS most_spent_product,
        ctp.amount_spent_on_product
    FROM 
        customer_total_spend cts
    INNER JOIN customer_top_product ctp 
        ON cts.customer_id = ctp.customer_id
    WHERE ctp.amount_spent_on_product = (
        SELECT 
            MAX(amount_spent_on_product)
        FROM 
            customer_top_product
        WHERE 
            customer_id = cts.customer_id
    )
)
SELECT 
    customer_id,
    first_name,
    last_name,
    overall_spend,
    most_spent_product,
    amount_spent_on_product
FROM 
    customer_top_spend_with_product
ORDER BY 
    overall_spend DESC, last_name ASC
LIMIT 10;


-- Intra-city product performance ranking using window functions

WITH city_product_sales AS (
    SELECT 
        c.city,
        p.product_name,
        SUM(cp.quantity * p.unit_price) AS overall_sales
    FROM 
        customer_purchase cp
    INNER JOIN product p 
        ON cp.product_id = p.product_id
    INNER JOIN customer c 
        ON cp.customer_id = c.customer_id
    GROUP BY 
        c.city, p.product_name
),
ranked_city_product_sales AS (
    SELECT 
        city,
        product_name,
        overall_sales,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY overall_sales DESC) AS product_rank
    FROM 
        city_product_sales
)
SELECT 
    city,
    product_name,
    overall_sales
FROM 
    ranked_city_product_sales
WHERE 
    product_rank <= 10
ORDER BY 
    city ASC,
    overall_sales DESC;

-- Delta analysis of unit sales (April vs. May)

WITH monthly_amount_of_items_sold AS
    (SELECT
        MONTH(transaction_date) as month,
        SUM(quantity) AS total_quantity
    FROM 
        customer_purchase
    WHERE 
        transaction_date BETWEEN '2024-04-01' AND '2024-05-31'
    GROUP BY 
        MONTH(transaction_date)
)
SELECT 
    (m2.total_quantity - m1.total_quantity) AS month_over_month_growth_april_to_may
FROM 
    monthly_amount_of_items_sold m1, monthly_amount_of_items_sold m2
WHERE
    m2.month = 5 AND m1.month = 4;
