-- 1. Создать индекс к какой-либо из таблиц вашей БД

-- Индекс не будет работать на таблице с малым количеством строк.
-- Предварительно заполним таблицу ef.city данными из файла cities.csv

-- Скопируем файл cities.csv в docker-контейнер, где развернута БД Postgres:
-- # docker cp cities.csv postgres14:/data/cities.csv

-- Затем, с помощью утилиты COPY заполним таблицу ef.city данными из файла cities.csv
-- COPY ef.city(name) FROM '/data/cities.csv';

-- Создадим уникальный индекс по названию города
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS uq_city_name
	ON ef.city(name, id)
	TABLESPACE ef_indexspace;

-- 2. Прислать текстом результат команды explain, в которой используется данный индекс

-- set random_page_cost = 1.25;
-- analyze ef.city;

-- Выведем id города 'г Орёл'

explain SELECT id
FROM ef.city
WHERE name = 'г Орёл'

-- Результат команды explain (на первой строчке указано, что поиск был проведен Index Only поиск по индексу uq_city_name,
-- т.к. поле id также входит в индекс 

-- "Index Only Scan using uq_city_name on city  (cost=0.28..14.29 rows=1 width=8) (actual time=0.042..0.045 rows=1 loops=1)"
-- "  Index Cond: (name = 'г Орёл'::text)"
-- "  Heap Fetches: 0"
-- "Planning Time: 0.134 ms"
-- "Execution Time: 0.074 ms"

-- 3. Реализовать индекс для полнотекстового поиска

-- Добавим возможность полнотекстового поиска по названию города.
-- В таблицу ef.city добавим поле name_lexeme и обновим его значениями,
-- оптимизированными под полнотекстовый поиск по названию города
ALTER TABLE ef.city ADD COLUMN name_lexeme TSVECTOR;
UPDATE ef.city
SET name_lexeme = to_tsvector(ef.city.name);

-- Создадим индекс
CREATE INDEX CONCURRENTLY IF NOT EXISTS ix_city_name_fulltext
	ON ef.city USING GIN (name_lexeme)
	TABLESPACE ef_indexspace;

-- Теперь найдем в таблице все области и края
explain SELECT id, name
FROM ef.city
WHERE name_lexeme @@ to_tsquery('обл | край' );

-- "Bitmap Heap Scan on city  (cost=76.05..311.40 rows=748 width=60)"
-- "  Recheck Cond: (name_lexeme @@ to_tsquery('обл | край'::text))"
-- "  ->  Bitmap Index Scan on ix_city_name_fulltext  (cost=0.00..75.86 rows=748 width=0)"
-- "        Index Cond: (name_lexeme @@ to_tsquery('обл | край'::text))"

-- 4. Реализовать индекс на часть таблицы или индекс на поле с функцией

-- Добавим индекс на полное имя заказчиков (имя и фамилия с большой буквы) в таблице ef.customer
CREATE INDEX CONCURRENTLY IF NOT EXISTS ix_customer_fullname
	ON ef.customer (initcap(ef.customer.firstname || ef.customer.lastname));

-- Добавим индекс на таблицу ef.order для заказов в очереди в статусе 'Готовится' (orderstatus = 1) и для которых еще не назначен курьер
CREATE INDEX CONCURRENTLY IF NOT EXISTS ix_orderqueue_orderid_ready_to_assign
	ON ef.orderqueue (orderid)
	WHERE orderstatus = 1 AND courierid IS NULL;

-- 5. Создать индекс на несколько полей

-- Создадим индекс, который будет оптимизировать поиск заказов по customerid заказчика
CREATE INDEX CONCURRENTLY IF NOT EXISTS ix_order_customerid_id
	ON ef.order (customerid, id);
	
-- 6. Написать комментарии к каждому из индексов

-- Сделано!

-- 7. Описать что и как делали и с какими проблемами столкнулись

-- Столкнулся с проблемой, что из-за небольшого набора тестовых данных в таблицах
-- Postgres не хотел использовать поиск по индексу, а просто шел последовательным перебором.
-- Мне пришлось найти в интернете csv с полным списком городов России и импортировать данные в таблицу ef.city,
-- чтобы команда explain показала использование индекса.

-- Т.к. моя БД еще не использовалась на практике и пока не понятен реальный объем данных в таблицах,
-- а также сложно представить часто используемые запросы с бэкенда, то заранее сложно понять, какие индексы реально могут пригодиться.
-- Поэтому те индексы, которые я создавал в домашнем задании, построены на гипотезах о возможном объеме
-- данных и возможных запросах, и носят скорее теоретический характер.