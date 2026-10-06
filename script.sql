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

 
-- enunciado 10
SELECT MIN(transaction_date) AS menor_data, MAX(transaction_date) AS maior_data 
FROM staging.cafe_sales;

DROP TABLE IF EXISTS dw.dim_date CASCADE;
CREATE TABLE dw.dim_date (
    date_sk INTEGER PRIMARY KEY,
    full_date DATE NOT NULL,
    day INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    quarter INTEGER NOT NULL,
    year INTEGER NOT NULL,
    day_of_week VARCHAR(20) NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

INSERT INTO dw.dim_date (
    date_sk,
    full_date,
    day,
    month,
    month_name,
    quarter,
    year,
    day_of_week,
    is_weekend
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER AS date_sk,
    d::DATE AS full_date,
    EXTRACT(DAY FROM d)::INTEGER AS day,
    EXTRACT(MONTH FROM d)::INTEGER AS month,
    TO_CHAR(d, 'TMMonth') AS month_name,
    EXTRACT(QUARTER FROM d)::INTEGER AS quarter,
    EXTRACT(YEAR FROM d)::INTEGER AS year,
    TO_CHAR(d, 'TMDay') AS day_of_week,
    CASE WHEN EXTRACT(ISODOW FROM d) IN (6, 7) THEN TRUE ELSE FALSE END AS is_weekend
FROM generate_series(
    (SELECT DATE_TRUNC('year', MIN(transaction_date)) FROM staging.cafe_sales),
    (SELECT (DATE_TRUNC('year', MAX(transaction_date)) + INTERVAL '1 year - 1 day')::DATE FROM staging.cafe_sales),
    INTERVAL '1 day'
) AS d;

SELECT * FROM dw.dim_date;
SELECT COUNT(*) AS total_dias_dim_date FROM dw.dim_date;

-- enunciado 11

DROP TABLE IF EXISTS dw.dim_item CASCADE;
CREATE TABLE dw.dim_item (
    item_sk SERIAL PRIMARY KEY,
    item VARCHAR(20) UNIQUE NOT NULL,
    category VARCHAR(10) NOT NULL
);

DROP TABLE IF EXISTS dw.dim_payment CASCADE;
CREATE TABLE dw.dim_payment (
    payment_sk SERIAL PRIMARY KEY,
    payment VARCHAR(20) UNIQUE NOT NULL
);

DROP TABLE IF EXISTS dw.dim_location CASCADE;
CREATE TABLE dw.dim_location (
    location_sk SERIAL PRIMARY KEY,
    location VARCHAR(20) UNIQUE NOT NULL
);

-- cargas nas dimensoes
-- dim_item
INSERT INTO dw.dim_item (item, category)
	SELECT DISTINCT s.item, c.category
	FROM staging.cafe_sales s
	JOIN staging.cardapio c ON c.item = s.item
ORDER BY s.item;

-- Carga dim_payment
INSERT INTO dw.dim_payment (payment)
	SELECT DISTINCT payment_method
	FROM staging.cafe_sales
ORDER BY payment_method;

-- Carga dim_location
INSERT INTO dw.dim_location (location)
	SELECT DISTINCT location
	FROM staging.cafe_sales
ORDER BY location;

-- Consulta de conferência das 3 dimensões (UNION ALL)
SELECT 'dim_item' AS dimensao, COUNT(*) AS quantidade FROM dw.dim_item
UNION ALL
SELECT 'dim_payment' AS dimensao, COUNT(*) AS quantidade FROM dw.dim_payment
UNION ALL
SELECT 'dim_location' AS dimensao, COUNT(*) AS quantidade FROM dw.dim_location;





-- enunciado 12 (quase final da fase 6)
DROP TABLE IF EXISTS dw.fact_sales CASCADE;

CREATE TABLE dw.fact_sales (
    transaction_nk VARCHAR(20) PRIMARY KEY,
    date_sk INTEGER NOT NULL REFERENCES dw.dim_date(date_sk),
    item_sk INTEGER NOT NULL REFERENCES dw.dim_item(item_sk),
    payment_sk INTEGER NOT NULL REFERENCES dw.dim_payment(payment_sk),
    location_sk INTEGER NOT NULL REFERENCES dw.dim_location(location_sk),
    quantity INTEGER NOT NULL,
    price_per_unit NUMERIC(6,2) NOT NULL,
    total_spent NUMERIC(8,2) NOT NULL
);

-- o index acelera na hora de fazer as consultas
CREATE INDEX idx_fact_date ON dw.fact_sales(date_sk);
CREATE INDEX idx_fact_item ON dw.fact_sales(item_sk);
CREATE INDEX idx_fact_payment ON dw.fact_sales(payment_sk);
CREATE INDEX idx_fact_location ON dw.fact_sales(location_sk);

TRUNCATE TABLE dw.fact_sales;

INSERT INTO dw.fact_sales (
    transaction_nk,
    date_sk,
    item_sk,
    payment_sk,
    location_sk,
    quantity,
    price_per_unit,
    total_spent
)
SELECT
    s.transaction_id AS transaction_nk,
    TO_CHAR(s.transaction_date, 'YYYYMMDD')::INTEGER AS date_sk,
    di.item_sk,
    dp.payment_sk,
    dl.location_sk,
    s.quantity,
    s.price_per_unit,
    s.total_spent
FROM staging.cafe_sales s
JOIN dw.dim_item di ON di.item = s.item
JOIN dw.dim_payment dp ON dp.payment = s.payment_method
JOIN dw.dim_location dl ON dl.location = s.location;

-- conferindo se esta tudo certinho
SELECT
    'staging.cafe_sales' AS origem,
    COUNT(*) AS total_linhas,
    SUM(total_spent) AS soma_total_spent
FROM staging.cafe_sales
UNION ALL
SELECT
    'dw.fact_sales' AS origem,
    COUNT(*) AS total_linhas,
    SUM(total_spent) AS soma_total_spent
FROM dw.fact_sales;


-- enunciado 13
-- a x
-- b x
-- c x
-- d x
-- e x
DO $$
DECLARE

	cur_ranking REFCURSOR;

	-- dimensoes
	v_dimensoes TEXT[] := ARRAY['item', 'payment', 'location'];
	v_dim_atual TEXT;

	-- texto sql
	v_sql TEXT;

	-- receita
	v_receita_total_fato NUMERIC(12,2);
	v_valor TEXT;
	v_vendas INTEGER;
	v_receita NUMERIC(12,2);
	v_percentual NUMERIC(5,2);

	-- contadores
	v_posicao INTEGER;
	v_linhas_dimensao INTEGER;
	v_linhas_totais INTEGER := 0;

BEGIN
	SELECT SUM(total_spent) INTO v_receita_total_fato FROM dw.fact_sales;

	FOREACH v_dim_atual IN ARRAY v_dimensoes LOOP
		v_posicao := 0;
		v_linhas_dimensao := 0;

		v_sql := '
			SELECT d.' || v_dim_atual || ',
				COUNT(*) AS vendas,
				SUM(f.total_spent) AS receita ' ||
			'FROM dw.fact_sales f ' ||
			'JOIN dw.dim_' || v_dim_atual || ' d ON d.' || v_dim_atual || '_sk = f.' || v_dim_atual || '_sk ' ||
			'GROUP BY d.' || v_dim_atual || ' ' || 
			'ORDER BY receita DESC';

		OPEN cur_ranking FOR EXECUTE v_sql;

			LOOP
				FETCH cur_ranking INTO v_valor, v_vendas, v_receita;
				EXIT WHEN NOT FOUND;

				v_posicao := v_posicao + 1;
				v_linhas_dimensao := v_linhas_dimensao + 1;
				v_percentual := ROUND((v_receita / v_receita_total_fato) * 100, 2);
				RAISE NOTICE '% | % - %: % vendas, receita % (% %% do total)', v_dim_atual, v_posicao, v_valor, v_vendas, v_receita, v_percentual;
			END LOOP;

		CLOSE cur_ranking;

		RAISE NOTICE 'Total de linhas lidas na dimensão %: %', v_dim_atual, v_linhas_dimensao;
		v_linhas_totais := v_linhas_totais + v_linhas_dimensao;

	END LOOP;
	RAISE NOTICE 'Total geral de linhas lidas nas três dimensões: %', v_linhas_totais;

END $$;


-- 14 - de meses cronologia

SELECT
    dd.year,
    dd.month,
    dd.month_name,
    COUNT(*) AS qtd_vendas,
    SUM(f.total_spent) AS receita,
    ROUND(AVG(f.total_spent), 2) AS ticket_medio
FROM dw.fact_sales f
JOIN dw.dim_date dd ON dd.date_sk = f.date_sk
GROUP BY dd.year, dd.month, dd.month_name
ORDER BY dd.year, dd.month;

-- 15 - ranking de items
SELECT
    di.category,
    di.item,
    SUM(f.quantity) AS total_unidades_vendidas,
    SUM(f.total_spent) AS receita
FROM dw.fact_sales f
JOIN dw.dim_item di ON di.item_sk = f.item_sk
GROUP BY di.category, di.item
ORDER BY receita DESC;

-- 16 - vendas por dia da semana

SELECT
    dd.day_of_week,
    dd.is_weekend,
    COUNT(*) AS qtd_vendas,
    SUM(f.total_spent) AS receita
FROM dw.fact_sales f
JOIN dw.dim_date dd ON dd.date_sk = f.date_sk
GROUP BY dd.day_of_week, dd.is_weekend
ORDER BY receita DESC;

