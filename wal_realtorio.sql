GRANT CONNECT ON DATABASE pw TO postgres;
GRANT USAGE ON SCHEMA public TO postgres;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO postgres;

-- number of rows 

SELECT COUNT(*) FROM wal;

-- quantity of sales by payment method 

SELECT payment_method, 
  COUNT(*)
FROM wal
GROUP BY payment_method; 

-- quantity of branches 

SELECT 
	COUNT (DISTINCT branch) 
FROM wal;

-- MAX and MIN of quantity 

SELECT MAX(quantity) FROM wal;
SELECT MIN(quantity) FROM wal;

-- BUSINESS PROBLEMNS 

--Q1. Quantity of sales (transactions) and quanity of sold products by each payment method

SELECT payment_method,
  COUNT(*) as sales_number,
  SUM (quantity) as sold_products_number
FROM wal
GROUP BY payment_method;

--Q2. identifying the highest-rated category in each branch

WITH ranked_ratings AS (
SELECT 
	branch,
	category,
	AVG(rating) as avg_rating,
	RANK() OVER (PARTITION BY branch ORDER BY AVG(rating) DESC) as rank
FROM wal
GROUP BY branch, category
)
SELECT 
	branch,
	category,
	avg_rating
FROM ranked_ratings
WHERE rank=1;

--Q3. Identify the busiest day of the week for each branch based on the number of transactions (sales)

-- First we need to convert data type from str to datatype, using TO_DATE()

SELECT *
FROM
	(SELECT
		branch,
		TO_CHAR(TO_DATE(date, 'DD-MM-YY'), 'Day')  AS day_name,
		COUNT(*) AS number_transaction,
		RANK() OVER (PARTITION BY branch ORDER BY COUNT (*) DESC) as rank
	FROM wal
	GROUP BY 1,2)

WHERE rank =1




-- Q4. Calculate the total quantity of items sold per payment method.

SELECT 
	payment_method,
	COUNT (*) as qtd_methods
FROM Wal
GROUP BY payment_method;

	
--Q5. Avarege, minimum and maximum rating of category for each city. 

SELECT
	city,
	category,
	MIN(rating) as rating_min,
	MAX(rating) as rating_max,
	ROUND(AVG(rating)) as rating_avg
FROM wal
GROUP BY city,  category
ORDER BY city, category;

--Q6. Total profit of each category (unit_price * quantity * profit_margin)

SELECT
	category,
	ROUND(SUM (unit_price * quantity * profit_margin)) as total_profit 
FROM wal
GROUP BY 1
ORDER BY 2 DESC; 

--Q7. The most commun payment method for each branch 

WITH cte AS (
	SELECT 
		branch,
		payment_method,
		COUNT (*) as num_sales, -- esta coluna não é necessário, deixei ela aqui para ficar claro que o COUNT (*) abaixo faz parte do OVER mas representa uma coluna calculada, com o alias num_sales 
		ROW_NUMBER() OVER (PARTITION BY branch ORDER BY COUNT (*) DESC) as rank_column 
FROM wal
GROUP BY 1,2
ORDER BY 1
)

SELECT 
	branch,
	payment_method,
	num_sales,
	rank_column
FROM cte
WHERE rank_column =1; 

--Q8. Categorize sales into 3 group MORNING, AFTERNOON, EVENING 
-- Find out each of the shift and number of invoices

SELECT
    CASE
		WHEN EXTRACT(HOUR FROM time::time) >= 6 AND EXTRACT(HOUR FROM time::time) < 12 THEN 'morning'
        WHEN EXTRACT(HOUR FROM time::time) >= 12 AND EXTRACT(HOUR FROM time::time) < 18 THEN 'afternoon'
		ELSE 'evening'
	END as shift,
	COUNT (*)
FROM wal
GROUP BY 1
ORDER BY 2 DESC; 

--Q9. Identify 5 branch with the highest decrise ratio in revenue compare to last year (conta invertida por isso os resultados estão negativos)

WITH reveneu_year AS (
	SELECT 
	branch,
	SUM(CASE 
        WHEN EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2022 
        THEN total_price 
        ELSE 0 
    END) AS invoicing_2022,
	SUM(CASE 
        WHEN EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2023 
        THEN total_price 
        ELSE 0 
    END) AS invoicing_2023
FROM wal
GROUP BY branch
ORDER BY branch 
)

SELECT
	branch,
	(invoicing_2023 - invoicing_2022) as diference 
FROM reveneu_year;



-- Q9. Identify 5 branch with highest decrese ratio in revevenue compare to last year(current year 2023 and last year 2022)

--1st cte
WITH cte_22 AS (
	SELECT 
		branch,
		SUM(total_price) as colmn_rev_2022
	FROM wal
	WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2022
	GROUP BY 1
),
--2nd cte
cte_23 AS (
	SELECT 
		branch,
		SUM(total_price) as colmn_rev_2023
	FROM wal
	WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2023
	GROUP BY 1
)

SELECT -- cte alias l (last year 2022) c (curent year 2023)
	l.branch, 
	l.colmn_rev_2022,
	c.colmn_rev_2023,
	ROUND((l.colmn_rev_2022 - c.colmn_rev_2023) / l.colmn_rev_2022 * 100) as rev_dec_ratio 
FROM cte_22 as l
INNER JOIN cte_23 as c
ON l.branch = c.branch
WHERE l.colmn_rev_2022 > c.colmn_rev_2023
ORDER BY 4 DESC
LIMIT 5;
	


-- query por categoria específica 

SELECT 
	branch,
	SUM (total_price) as home_lifestyle_total_revenue
FROM wal 
WHERE category ='Home and lifestyle'
GROUP BY branch, category
ORDER BY branch; 

-- outro modo 

SELECT
    branch,
    SUM(CASE
		WHEN category = 'Home and lifestyle'
		THEN total_price  -- Explicitly state what to sum
		ELSE 0           -- Explicitly state 0 for other categories
   		END) AS home_lifestyle_total_revenue
FROM 
    wal
GROUP BY 
    branch  -- Only group by branch to get the total per branch
ORDER BY 
    branch;

-- qtd vendas por categoria 

SELECT category,
  SUM (quantity)
FROM wal
GROUP BY category;

-- qtd vendas por branch

SELECT branch,
  SUM (quantity)
FROM wal
GROUP BY branch
ORDER BY branch;

-- quantity of sales by category in each branch 

SELECT branch, category,
  SUM (quantity) as sales_total
FROM wal
GROUP BY branch, category
ORDER BY branch;

/*
Descobrir qual a categoria de produtos mais vendida em cada branch

1° passo: criação de uma CTE (apelidada de with query)

-- CTE quantity of sales by category in each branch 
-- it's not necessary the order by in the CTE because the CTE will not be displayed
-- CTE is an temporary virtual table 

2° passo: O próximo passo é ranquear as categorias dentro de cada filial e selecionar apenas a que está em primeiro lugar (com ROW_NUMBER()).
*/

WITH sales_by_category_and_branch AS (
    SELECT
        branch,
        category,
        SUM(quantity) AS sales_total
    FROM
        wal
    GROUP BY
        branch,
        category
)
SELECT
    branch,
    category,
    sales_total
FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY branch ORDER BY sales_total DESC) AS rank
    FROM
        sales_by_category_and_branch
) AS ranked_sales
WHERE
    rank = 1;


--qtd of branches
SELECT 
	DISTINCT(branch)
FROM wal;

-- qtd sales and profit by category

SELECT
	category,
	ROUND(SUM (rating)) as rating,
	COUNT (*) as qtd_sales,
	ROUND(SUM (total_price)) as profit
FROM wal
GROUP BY category
ORDER BY category;
