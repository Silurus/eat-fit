-- Перед выполнением скрипта необходимо создать директории для табличных пространств и выдать на них права пользователю postgres:
-- # mkdir -p /data/ef/common
-- # mkdir -p /data/ef/orders
-- # mkdir -p /data/ef/indexes
-- # chown -R postgres:postgres /data

-- Для выполнения следующих команд подключаемся к БД postgres:
-- # psql -U postgres -W postgres

-- SELECT pg_terminate_backend(pg_stat_activity.pid)
-- FROM pg_stat_activity
-- WHERE pg_stat_activity.datname = 'eatfit'
--   AND pid <> pg_backend_pid();

-- DROP DATABASE IF EXISTS eatfit;
CREATE DATABASE eatfit ENCODING = 'UTF8';

-- DROP TABLESPACE IF EXISTS ef_commonspace;
-- DROP TABLESPACE IF EXISTS ef_orderspace;
-- DROP TABLESPACE IF EXISTS ef_indexspace;
-- DROP ROLE IF EXISTS ef_analytics, ef_user, ef_admin, ef_gr;
CREATE ROLE ef_gr; -- группа ролей, относящихся к БД EatFit
CREATE USER ef_admin WITH PASSWORD 'admin'; -- укажите свой пароль для ef_admin
CREATE USER ef_user WITH PASSWORD 'user'; -- укажите свой пароль для ef_user
CREATE USER ef_analytics WITH PASSWORD 'analytics'; -- укажите свой пароль для ef_analytics

CREATE TABLESPACE ef_commonspace OWNER ef_admin LOCATION '/data/ef/common'; -- табличное пространство по-умолчанию
CREATE TABLESPACE ef_orderspace OWNER ef_admin LOCATION '/data/ef/orders'; -- табличное пространство для таблицы с заказами
CREATE TABLESPACE ef_indexspace OWNER ef_admin LOCATION '/data/ef/indexes'; -- табличное пространство для индексов

ALTER DATABASE eatfit OWNER TO ef_admin; -- устанавливаем ef_admin владельцем БД (получает все привилегии)

-- Для выполнения следующих команд необходимо подключиться к БД eatfit:
-- # \c eatfit ef_admin

CREATE SCHEMA IF NOT EXISTS ef AUTHORIZATION ef_admin; -- схема по-умолчанию, владелец ef_admin
ALTER DATABASE eatfit SET search_path TO ef, public; -- устанавливаем схему по-умолчанию для БД

GRANT SELECT ON ALL TABLES IN SCHEMA ef TO ef_gr; -- выдаем группе ef_gr доступ к команде SELECT на все таблицы схемы ef
GRANT ef_gr to ef_admin, ef_user, ef_analytics; -- назначаем всех пользователей на группу ef_gr

GRANT SELECT, UPDATE, INSERT, DELETE ON ALL TABLES IN SCHEMA ef to ef_user; -- выдаем ef_user права на операции SELECT/INSERT/UPDATE/DELETE для схемы ef

-- Создаем таблицы

CREATE TABLE IF NOT EXISTS ef.city (
	id BIGSERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL
)   TABLESPACE ef_commonspace;

CREATE TABLE IF NOT EXISTS ef.address (
	id BIGSERIAL PRIMARY KEY,
	street VARCHAR(100) NOT NULL,
	building VARCHAR(20) NOT NULL,
	entrance VARCHAR(20) NULL,
	floor VARCHAR(20) NULL,
	flat VARCHAR(20) NULL,
	comment VARCHAR(500) NULL,
	cityid BIGINT NOT NULL,
	CONSTRAINT fk_address_city
		FOREIGN KEY(cityid)
			REFERENCES ef.city(id)
			ON DELETE RESTRICT
			ON UPDATE RESTRICT
)   TABLESPACE ef_commonspace;

CREATE TABLE IF NOT EXISTS ef.customer (
	id BIGSERIAL PRIMARY KEY,
	firstname VARCHAR(100) NOT NULL,
	lastname VARCHAR(100) NOT NULL,
	phone VARCHAR(20) NOT NULL,
	addressid BIGINT NULL,
	cityid BIGINT NOT NULL,
	CONSTRAINT fk_customer_city
		FOREIGN KEY(cityid)
			REFERENCES ef.city(id)
			ON DELETE RESTRICT
			ON UPDATE RESTRICT,
	CONSTRAINT fk_customer_address
		FOREIGN KEY(addressid)
			REFERENCES ef.address(id)
			ON DELETE RESTRICT
			ON UPDATE RESTRICT
)   TABLESPACE ef_commonspace;

-- Создадим домен под тип "процент"
CREATE DOMAIN percent AS NUMERIC
	DEFAULT 0
	NOT NULL
	CHECK (VALUE >= 0 AND VALUE <= 1);

-- Создадим домен под тип "цена"
CREATE DOMAIN price AS NUMERIC
	DEFAULT 0
	NOT NULL
	CHECK (VALUE >= 0);

CREATE TABLE IF NOT EXISTS ef.order (
	id BIGSERIAL PRIMARY KEY,
	createdat TIMESTAMP NOT NULL,
	iscompleted BOOLEAN NOT NULL,
	iscancelled BOOLEAN NOT NULL,
	customerid BIGINT NOT NULL,
	addressid BIGINT NOT NULL,
	desiredtime TIMESTAMP NULL,
	comment VARCHAR(3000) NULL,
	totalprice price,
	totaldiscount percent,
	CONSTRAINT fk_order_customer
		FOREIGN KEY(customerid)
			REFERENCES ef.customer(id)
			ON DELETE RESTRICT
			ON UPDATE RESTRICT,
	CONSTRAINT fk_order_address
		FOREIGN KEY(addressid)
			REFERENCES ef.address(id)
			ON DELETE RESTRICT
			ON UPDATE RESTRICT
)   TABLESPACE ef_orderspace;

CREATE TABLE IF NOT EXISTS ef.payment (
	orderid BIGINT PRIMARY KEY,
	paymentstatus INT NOT NULL,
	recipe JSONB NULL,
	date TIMESTAMP NULL,
	CONSTRAINT fk_payment_order
		FOREIGN KEY(orderid)
			REFERENCES ef.order(id)
			ON DELETE RESTRICT
			ON UPDATE RESTRICT
)   TABLESPACE ef_orderspace;

CREATE TABLE IF NOT EXISTS ef.feedback (
	orderid BIGINT PRIMARY KEY,
	orderrating INT NOT NULL,
	courierrating INT NOT NULL,
	text VARCHAR(300) NULL,
	CONSTRAINT fk_feedback_order
		FOREIGN KEY(orderid)
			REFERENCES ef.order(id)
			ON DELETE RESTRICT
			ON UPDATE RESTRICT
)   TABLESPACE ef_orderspace;

CREATE TABLE IF NOT EXISTS ef.courier (
	id BIGSERIAL PRIMARY KEY,
	firstname VARCHAR(100) NOT NULL,
	lastname VARCHAR(100) NOT NULL,
	phone VARCHAR(20) NOT NULL,
	ratingavg REAL NOT NULL,
	cityid BIGINT NOT NULL,
	CONSTRAINT fk_courier_city
		FOREIGN KEY(cityid)
			REFERENCES ef.city(id)
			ON DELETE RESTRICT
			ON UPDATE RESTRICT
)   TABLESPACE ef_commonspace;

CREATE TABLE IF NOT EXISTS ef.orderqueue (
	orderid BIGINT PRIMARY KEY,
	estimatedtime TIMESTAMP NOT NULL,
	orderstatus INT NOT NULL,
	courierid BIGINT NULL,
	CONSTRAINT fk_orderqueue_order
		FOREIGN KEY(orderid)
			REFERENCES ef.order(id)
			ON DELETE RESTRICT
			ON UPDATE RESTRICT,
	CONSTRAINT fk_orderqueue_courier
		FOREIGN KEY(courierid)
			REFERENCES ef.courier(id)
			ON DELETE RESTRICT
			ON UPDATE RESTRICT
)   TABLESPACE ef_orderspace;

CREATE TABLE IF NOT EXISTS ef.meal (
	id BIGSERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	price price,
	description VARCHAR(3000) NULL,
	ingredients VARCHAR(3000) NULL,
	volume VARCHAR(50) NULL,
	fats REAL NULL,
	carbs REAL NULL,
	protein REAL NULL,
	calories REAL NULL
)   TABLESPACE ef_commonspace;

CREATE TABLE IF NOT EXISTS ef.basket (
	orderid BIGINT NOT NULL,
	mealid BIGINT NOT NULL,
	quantity INT NOT NULL,
	positionprice price,
	PRIMARY KEY(orderid, mealid),
	CONSTRAINT fk_basket_order
		FOREIGN KEY(orderid)
			REFERENCES ef.order(id)
			ON DELETE RESTRICT
			ON UPDATE RESTRICT,
	CONSTRAINT fk_basket_meal
		FOREIGN KEY(mealid)
			REFERENCES ef.meal(id)
			ON DELETE RESTRICT
			ON UPDATE RESTRICT
)   TABLESPACE ef_orderspace;

CREATE TABLE IF NOT EXISTS ef.promocode (
	id BIGSERIAL PRIMARY KEY,
	code VARCHAR(50) NOT NULL,
	discount percent,
	isactive BOOLEAN NOT NULL,
	rules JSONB NULL,
	validfrom timestamp NULL,
	validuntil timestamp NULL,
	description VARCHAR(3000) NULL
)   TABLESPACE ef_commonspace;

CREATE TABLE IF NOT EXISTS ef.appliedpromocode (
	orderid BIGINT NOT NULL,
	promocodeid BIGINT NOT NULL,
	PRIMARY KEY(orderid, promocodeid),
	CONSTRAINT fk_appliedpromocode_order
		FOREIGN KEY(orderid)
			REFERENCES ef.order(id)
			ON DELETE RESTRICT
			ON UPDATE RESTRICT,
	CONSTRAINT fk_appliedpromocode_promocode
		FOREIGN KEY(promocodeid)
			REFERENCES ef.promocode(id)
			ON DELETE RESTRICT
			ON UPDATE RESTRICT
)   TABLESPACE ef_orderspace;

-- Создаем индексы

CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS uq_city_name
	ON ef.city(name)
	TABLESPACE ef_indexspace;

CREATE INDEX CONCURRENTLY IF NOT EXISTS ix_city_name_fulltext
	ON ef.city USING GIN (to_tsvector('russian', name))
	TABLESPACE ef_indexspace;

CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS uq_customer_phone
	ON ef.customer(phone)
	TABLESPACE ef_indexspace;

CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS uq_courier_phone
	ON ef.courier(phone)
	TABLESPACE ef_indexspace;
	
CREATE INDEX CONCURRENTLY IF NOT EXISTS ix_order_customerid_createdat
	ON ef.order(customerid, createdat)
	TABLESPACE ef_indexspace;

CREATE INDEX CONCURRENTLY IF NOT EXISTS ix_meal_name_fulltext
	ON ef.meal USING GIN (to_tsvector('russian', name))
	TABLESPACE ef_indexspace;

CREATE INDEX CONCURRENTLY IF NOT EXISTS ix_promocode_code
	ON ef.promocode(code)
	TABLESPACE ef_indexspace;

-- Создаем автоматические проверки (check constraints)

ALTER TABLE ef.basket
	ADD CONSTRAINT ck_basket_quantity_nonnegative
	CHECK (
			quantity >= 0
	);

ALTER TABLE ef.feedback
	ADD CONSTRAINT ck_feedback_courierrating_nonnegative
	CHECK (
			courierrating >= 0
	);

ALTER TABLE ef.feedback
	ADD CONSTRAINT ck_feedback_orderrating_nonnegative
	CHECK (
			orderrating >= 0
	);

ALTER TABLE ef.meal
	ADD CONSTRAINT ck_meal_calories_nonnegative
	CHECK (
			calories >= 0
	);

ALTER TABLE ef.meal
	ADD CONSTRAINT ck_meal_carbs_nonnegative
	CHECK (
			carbs >= 0
	);

ALTER TABLE ef.meal
	ADD CONSTRAINT ck_meal_fats_nonnegative
	CHECK (
			fats >= 0
	);

ALTER TABLE ef.meal
	ADD CONSTRAINT ck_meal_protein_nonnegative
	CHECK (
			protein >= 0
	);
