-- Enunciado 1

DROP SCHEMA IF EXISTS raw CASCADE;
CREATE SCHEMA IF NOT EXISTS raw;

DROP SCHEMA IF EXISTS staging CASCADE;
CREATE SCHEMA IF NOT EXISTS staging;

DROP SCHEMA IF EXISTS dw CASCADE;
CREATE SCHEMA IF NOT EXISTS dw;

SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('raw', 'staging','dw');


-- Enunciado 2
DROP TABLE IF EXISTS raw.cafe_sales;
CREATE TABLE IF NOT EXISTS raw.cafe_sales (
	transaction_id TEXT,
	item TEXT,
	quantity TEXT,
	price_per_unit TEXT,
	total_spent TEXT,
	payment_method TEXT,
	location TEXT,
	transaction_date TEXT
);

SELECT * FROM raw.cafe_sales;

-- Enunciado 3

SELECT COUNT(transaction_id) FROM raw.cafe_sales;
-- 10000 foi o valor retornado

SELECT COUNT(DISTINCT transaction_id) FROM raw.cafe_sales;
-- 10000 foi o valor retornado novamente pois não há dados duplicados


-- Enunciado 4
-- Corrigir ORDER BY com UNION ALL
SELECT DISTINCT
	COUNT(item) AS "Items com erro",
	COUNT(payment_method) AS "Pagamentos com erro",
	COUNT(location) AS "Localizações com erro"
FROM raw.cafe_sales
WHERE
item IS NULL OR item = 'UNKNOWN' OR item = 'ERROR'
OR payment_method IS NULL OR payment_method = 'UNKNOWN' OR payment_method = 'ERROR'
OR location IS NULL OR location = 'UNKNOWN' OR location = 'ERROR';
-- ORDER BY COUNT(*);

-- Enunciado 5
-- SELECT item FROM raw.cafe_sales WHERE item IS NULL UNION SELECT location FROM raw.cafe_sales WHERE location = 'UNKNOWN';

SELECT 'Item' AS Linhas, COUNT(*) AS itemsNulos
FROM raw.cafe_sales 
WHERE item IS NULL

UNION ALL

SELECT 'Métodos de pagamento' AS Linhas, COUNT(*) AS itemsNulos 
FROM raw.cafe_sales 
WHERE payment_method IS NULL

UNION ALL

SELECT 'Localizações' AS Linhas, COUNT(*) AS itemsNulos 
FROM raw.cafe_sales 
WHERE location IS NULL




-- SELECT DISTINCT
-- 	COUNT(item) AS "Items com erro",
-- 	COUNT(payment_method) AS "Pagamentos com erro"
-- FROM raw.cafe_sales
-- WHERE
-- item IS NULL OR item = 'UNKNOWN' OR item = 'ERROR'
-- OR payment_method IS NULL OR payment_method = 'UNKNOWN' OR payment_method = 'ERROR';









 