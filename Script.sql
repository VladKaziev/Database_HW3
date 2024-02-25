-- Создание таблицы customer
CREATE TABLE customer (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR,
    last_name VARCHAR,
    gender VARCHAR,
    DOB DATE,
    job_title VARCHAR,
    job_industry_category VARCHAR,
    wealth_segment VARCHAR,
    deceased_indicator VARCHAR,
    owns_car VARCHAR,
    address VARCHAR,
    postcode VARCHAR,
    state VARCHAR,
    country VARCHAR,
    property_valuation INT
);

-- Создание таблицы transaction
CREATE TABLE transaction (
    transaction_id INT PRIMARY KEY,
    product_id INT,
    customer_id INT,
    transaction_date DATE,
    online_order VARCHAR,
    order_status VARCHAR,
    brand VARCHAR,
    product_line VARCHAR,
    product_class VARCHAR,
    product_size VARCHAR,
    list_price FLOAT,
    standard_cost FLOAT
);


-- 1. Распределение клиентов по сферам деятельности
SELECT job_industry_category, COUNT(*) AS customer_count
FROM customer
GROUP BY job_industry_category
ORDER BY customer_count DESC;

-- 2. Сумма транзакций за каждый месяц по сферам деятельности
SELECT EXTRACT(MONTH FROM t.transaction_date) AS month,
       c.job_industry_category,
       SUM(t.list_price) AS total_transaction_amount
FROM transaction t
JOIN customer c ON t.customer_id = c.customer_id
GROUP BY month, c.job_industry_category
ORDER BY month, c.job_industry_category;

-- 3. Количество онлайн-заказов для всех брендов в рамках подтвержденных заказов клиентов из сферы IT
SELECT t.brand , COUNT(*) AS online_order_count
FROM transaction t
JOIN customer c ON t.customer_id  = c.customer_id
WHERE c.job_industry_category = 'IT' AND t.order_status = 'Approved' AND t.online_order = 'Yes'
GROUP BY t.brand;

-- 4. Сумма всех транзакций, максимум, минимум и количество транзакций для каждого клиента
-- 4.1 Используя GROUP BY
SELECT c.customer_id, 
       SUM(t.list_price) AS total_transaction_amount,
       MAX(t.list_price) AS max_transaction_amount,
       MIN(t.list_price) AS min_transaction_amount,
       COUNT(t.transaction_id) AS transaction_count
FROM customer c
JOIN transaction t ON c.customer_id = t.customer_id
GROUP BY c.customer_id
ORDER BY total_transaction_amount DESC, transaction_count DESC;

-- 4.2 Используя оконные функции
SELECT customer_id,
       SUM(list_price) OVER (PARTITION BY customer_id) AS total_transaction_amount,
       MAX(list_price) OVER (PARTITION BY customer_id) AS max_transaction_amount,
       MIN(list_price) OVER (PARTITION BY customer_id) AS min_transaction_amount,
       COUNT(transaction_id) OVER (PARTITION BY customer_id) AS transaction_count
FROM transaction
ORDER BY total_transaction_amount DESC, transaction_count DESC;

-- 5. Имена и фамилии клиентов с минимальной суммой транзакций
SELECT c.first_name, c.last_name
FROM customer c
JOIN (
    SELECT customer_id, SUM(list_price) AS total_transaction_amount
    FROM transaction
    GROUP BY customer_id
    ORDER BY total_transaction_amount ASC
    LIMIT 1
) t ON c.customer_id = t.customer_id;

-- 5. Имена и фамилии клиентов с максимальной суммой транзакций
SELECT c.first_name, c.last_name
FROM customer c
JOIN (
    SELECT customer_id, SUM(list_price) AS total_transaction_amount
    FROM transaction
    GROUP BY customer_id
    ORDER BY total_transaction_amount DESC
    LIMIT 1
) t ON c.customer_id = t.customer_id;

-- 6. Самые первые транзакции клиентов с использованием оконных функций
SELECT customer_id, transaction_id, transaction_date
FROM (
    SELECT customer_id, transaction_id, transaction_date,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY transaction_date) AS row_num
    FROM transaction
) first_transactions
WHERE row_num = 1;

-- 7. Имена, фамилии и профессии клиентов, между транзакциями которых был максимальный интервал
SELECT c.first_name, c.last_name, c.job_title
FROM customer c
JOIN (
    SELECT customer_id,
           MAX(transaction_date) - MIN(transaction_date) AS max_interval
    FROM transaction
    GROUP BY customer_id
    ORDER BY max_interval DESC
    LIMIT 1
) t ON c.customer_id = t.customer_id;
