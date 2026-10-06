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

SELECT 'Item' AS Coluna,
	(SELECT COUNT(*) FROM raw.cafe_sales WHERE item IS NULL) AS itemsNulos,
	(SELECT COUNT(*) FROM raw.cafe_sales WHERE item = 'UNKNOWN') AS itemsUnknown,
	(SELECT COUNT(*) FROM raw.cafe_sales WHERE item = 'ERROR') AS itemsErro

UNION ALL

SELECT 'payment_method' AS Coluna,
	(SELECT COUNT(*) FROM raw.cafe_sales WHERE payment_method IS NULL) AS payment_methodsNulos,
	(SELECT COUNT(*) FROM raw.cafe_sales WHERE payment_method = 'UNKNOWN') AS payment_methodsUnknown,
	(SELECT COUNT(*) FROM raw.cafe_sales WHERE payment_method = 'ERROR') AS payment_methodsErro

UNION ALL

SELECT 'location' AS Coluna,
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


-- 7

DROP TABLE IF EXISTS staging.cardapio CASCADE;

CREATE TABLE staging.cardapio (
    item VARCHAR(20) PRIMARY KEY,
    price NUMERIC(6,2) NOT NULL,
    category VARCHAR(10) NOT NULL
);

INSERT INTO staging.cardapio (item, price, category) VALUES
('Cookie', 1.00, 'Comida'),
('Tea', 1.50, 'Bebida'),
('Coffee', 2.00, 'Bebida'),
('Cake', 3.00, 'Comida'),
('Juice', 3.00, 'Bebida'),
('Sandwich', 4.00, 'Comida'),
('Smoothie', 4.00, 'Bebida'),
('Salad', 5.00, 'Comida');

SELECT * FROM staging.cardapio;


-- enunciado 8

-- R1 preço nulo e item conhecido preço ← preço do item no cardápio
UPDATE staging.cafe_tipada t
SET price_per_unit = (SELECT c.price FROM staging.cardapio c WHERE c.item = t.item)
WHERE t.price_per_unit IS NULL AND t.item IS NOT NULL;
-- WHERE t.price_per_unit IS NOT NULL AND t.item IS NULL

-- R2 preço nulo, quantidade e total conhecidos preço ← total ÷ quantidade
UPDATE staging.cafe_tipada
SET price_per_unit = total_spent / quantity
WHERE price_per_unit IS NULL AND quantity IS NOT NULL AND total_spent IS NOT NULL;


-- R3 quantidade nula, preço e total conhecidos quantidade ← total ÷ preço, arredondado para inteiro
-- TOTAL ÷ PREÇO
-- total_spent / price_per_unit

UPDATE staging.cafe_tipada
SET quantity = ROUND(total_spent / price_per_unit)::INTEGER
WHERE quantity IS NULL AND price_per_unit IS NOT NULL AND total_spent IS NOT NULL;



-- R4 total nulo, quantidade e preço conhecidos total ← quantidade × preço
-- TOTAL = QUANTIDADE X PREÇO DA UNIDADE
-- igual fizemos no pi
-- total_spent = quantity * price_per_unit
UPDATE staging.cafe_tipada
SET total_spent = quantity * price_per_unit
WHERE total_spent IS NULL AND quantity IS NOT NULL AND price_per_unit IS NOT NULL;


-- R5 item nulo e preço conhecido, pertencente a um único item do cardápio item ← item do cardápio com aquele preço
UPDATE staging.cafe_tipada t
SET item = (SELECT c.item FROM staging.cardapio c WHERE c.price = t.price_per_unit)
WHERE t.item IS NULL 
  AND t.price_per_unit IS NOT NULL 
   AND t.price_per_unit IN (
      SELECT price 
		FROM staging.cardapio 
		GROUP BY price 
      HAVING COUNT(*) = 1
);


-- R6 forma de pagamento ou local nulos substituir por 'Unknow
UPDATE staging.cafe_tipada
	SET payment_method = 'Unknown'
WHERE payment_method IS NULL;

UPDATE staging.cafe_tipada
	SET location = 'Unknown'
WHERE location IS NULL;


-- enunciado 09
-- agora é outro staging = staging.cafe_sales É DIFERNTE DE staging.cafe_tipada !!
DROP TABLE IF EXISTS staging.cafe_sales CASCADE;

CREATE TABLE staging.cafe_sales (
    transaction_id VARCHAR(20) PRIMARY KEY,
    item VARCHAR(20) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price_per_unit NUMERIC(6,2) NOT NULL CHECK (price_per_unit > 0),
    total_spent NUMERIC(8,2) NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    location VARCHAR(20) NOT NULL,
    transaction_date DATE NOT NULL
);

TRUNCATE TABLE staging.cafe_sales;

INSERT INTO staging.cafe_sales (
    transaction_id,
    item,
    quantity,
    price_per_unit,
    total_spent,
    payment_method,
    location,
    transaction_date
)
SELECT
    transaction_id,
    item,
    quantity,
    price_per_unit,
    total_spent,
    payment_method,
    location,
    transaction_date
FROM staging.cafe_tipada
WHERE item IS NOT NULL
  AND quantity IS NOT NULL
  AND price_per_unit IS NOT NULL
  AND total_spent IS NOT NULL
  AND payment_method IS NOT NULL
  AND location IS NOT NULL
  AND transaction_date IS NOT NULL;

-- Consulta de contagem e perda de linhas
SELECT
    (SELECT COUNT(*) FROM staging.cafe_tipada) AS linhas_tipada,
    (SELECT COUNT(*) FROM staging.cafe_sales) AS linhas_limpas,
    (SELECT COUNT(*) FROM staging.cafe_tipada) - (SELECT COUNT(*) FROM staging.cafe_sales) AS descartadas;

-- linhas_tipada 1000
--  linhas_limpas  9064
-- linhas descartadas 936

 