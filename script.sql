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

SELECT 'Item' AS Colina,
	(SELECT COUNT(*) FROM raw.cafe_sales WHERE item IS NULL) AS itemsNulos,
	(SELECT COUNT(*) FROM raw.cafe_sales WHERE item = 'UNKNOWN') AS itemsUnknown,
	(SELECT COUNT(*) FROM raw.cafe_sales WHERE item = 'ERROR') AS itemsErro

UNION ALL

SELECT 'payment_method' AS Colina,
	(SELECT COUNT(*) FROM raw.cafe_sales WHERE payment_method IS NULL) AS payment_methodsNulos,
	(SELECT COUNT(*) FROM raw.cafe_sales WHERE payment_method = 'UNKNOWN') AS payment_methodsUnknown,
	(SELECT COUNT(*) FROM raw.cafe_sales WHERE payment_method = 'ERROR') AS payment_methodsErro

UNION ALL

SELECT 'location' AS Colina,
	(SELECT COUNT(*) FROM raw.cafe_sales WHERE location IS NULL) AS locationsNulos,
	(SELECT COUNT(*) FROM raw.cafe_sales WHERE location = 'UNKNOWN') AS locationsUnknown,
	(SELECT COUNT(*) FROM raw.cafe_sales WHERE location = 'ERROR') AS locationsErro


-- enunciado 6

DROP TABLE IF EXISTS staging.cafe_tipada;
CREATE TABLE IF NOT EXISTS staging.cafe_tipada (
	transaction_id VARCHAR(20) PRIMARY KEY,
	item VARCHAR(20),
	quantity INTEGER,
	price_per_unit NUMERIC(6,2),
	total_spent NUMERIC(8,2),
	payment_method VARCHAR(20),
	location VARCHAR(20),
	transaction_date DATE
);

INSERT INTO staging.cafe_tipada (transaction_id)
SELECT TRIM(transaction_id)
FROM raw.cafe_sales;

SELECT * FROM staging.cafe_tipada;

TRUNCATE TABLE staging.cafe_tipada;

SELECT * FROM staging.cafe_tipada;


INSERT INTO staging.cafe_tipada (
	transaction_id,item, quantity, price_per_unit, total_spent, payment_method, location, transaction_date
)
SELECT
	TRIM(transaction_id),

	CASE
		WHEN TRIM(item) IN ('ERROR', 'UNKNOWN')
		THEN NULL ELSE TRIM(item)
	END,

	CAST (CASE
		WHEN TRIM(quantity) IN ('ERROR', 'UNKNOWN')
		THEN NULL ELSE TRIM(quantity)
	END AS INTEGER),

	CAST (CASE
		WHEN TRIM(price_per_unit) IN ('ERROR', 'UNKNOWN')
		THEN NULL ELSE TRIM(price_per_unit)
	END AS NUMERIC(6,2)),

	CAST (CASE
		WHEN TRIM(total_spent) IN ('ERROR', 'UNKNOWN')
		THEN NULL ELSE TRIM(total_spent)
	END AS NUMERIC(6,2)),

	CASE
		WHEN TRIM(payment_method) IN ('ERROR', 'UNKNOWN')
		THEN NULL ELSE TRIM(payment_method)
	END,

	CASE
		WHEN TRIM(location) IN ('ERROR', 'UNKNOWN')
		THEN NULL ELSE TRIM(location)
	END,

	TO_DATE (CASE
		WHEN TRIM(transaction_date) IN ('ERROR', 'UNKNOWN')
		THEN NULL ELSE TRIM(transaction_date)
	END, 'YYYY-MM-DD')

FROM raw.cafe_sales;

SELECT * FROM staging.cafe_tipada;

SELECT 
    COUNT(*) - COUNT(item) AS itemsNulos,
    COUNT(*) - COUNT(quantity) AS quantityNulos,
    COUNT(*) - COUNT(price_per_unit) AS price_per_unitNulos,
    COUNT(*) - COUNT(total_spent) AS total_spentNulos,
    COUNT(*) - COUNT(payment_method) AS payment_methodNulos,
    COUNT(*) - COUNT(location) AS locationNulos,
    COUNT(*) - COUNT(transaction_date) AS transaction_dateNulos
FROM staging.cafe_tipada;

