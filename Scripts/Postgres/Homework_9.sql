-- 1. Напишите запрос по своей базе с регулярным выражением, добавьте пояснение, что вы хотите найти.

-- Данный запрос выводит список заказчиков, у которых фамилия не оканчивается на 'ов' или 'ова'
SELECT * FROM ef.customer
WHERE lastname NOT SIMILAR TO '%ова?';


-- 2. Напишите запрос по своей базе с использованием LEFT JOIN и INNER JOIN, как порядок соединений в FROM влияет на результат? Почему?

-- Данный запрос выводит отзывы по заказам и имена заказчиков, которые оставляли хотя бы один отзыв по заказу,
-- объединяя таблицы order, feedback и customer
SELECT firstname, lastname, orderid, orderrating, courierrating, text
FROM (ef.order INNER JOIN ef.feedback ON ef.order.id = feedback.orderid)
	LEFT JOIN ef.customer ON ef.customer.id = ef.order.customerid

-- Если мы поменяем порядок таблиц для соединения INNER JOIN, то результат не изменится,
-- т.к. порядок таблиц не влияет на результат пересечения множеств их строк
SELECT firstname, lastname, orderid, orderrating, courierrating, text
FROM (ef.feedback INNER JOIN ef.order ON ef.order.id = feedback.orderid)
	LEFT JOIN ef.customer
        ON ef.customer.id = ef.order.customerid

-- Но если же мы поменяем порядок таблиц для соединения LEFT JOIN, то в результаты будут включены
-- даже те заказчики, которые ни разу не оставляли отзывы, со значениями NULL в полях присоединяемой таблицы
-- (присоединяем все множество customer + подмножество записей объединенной таблицы order-feedback)
SELECT firstname, lastname, orderid, orderrating, courierrating, text
FROM ef.customer
    LEFT JOIN (ef.feedback INNER JOIN ef.order ON ef.order.id = feedback.orderid)
        ON ef.customer.id = ef.order.customerid


-- 3. Напишите запрос на добавление данных с выводом информации о добавленных строках.

-- Создадим временную таблицу и скопируем в нее данные из таблицы курьеров
SELECT firstname, lastname, phone
INTO TEMPORARY courier_temp
FROM ef.courier;

-- SELECT * FROM courier_temp;

-- Вставляем новые записи во временную таблицу и используем конструкцию RETURNING *,
-- чтобы в качестве результата вернуть все поля вставленных записей
INSERT INTO courier_temp(firstname, lastname, phone) VALUES
	('Василий', 'Пупкин', '12345'),
	('Степан', 'Ложкин', '54321')
	RETURNING *;


-- 4. Напишите запрос с обновлением данные используя UPDATE FROM.

-- Создадим временную таблицу и скопируем в нее данные из таблицы заказов
SELECT *
INTO TEMPORARY order_temp
FROM ef.order;

-- Добавим во временную таблицу колонку customer
ALTER TABLE order_temp ADD COLUMN customer VARCHAR(300);

-- SELECT * FROM order_temp;

-- Обновим поле customer в таблице order_temp, используя конкатенацию имени и фамилии из таблицы ef.customer.
-- Для этого используем инструкцию UPDATE ... FROM
UPDATE order_temp
SET customer = cus.firstname || ' ' || cus.lastname
    FROM ef.customer as cus
        WHERE order_temp.customerid = cus.id;

-- SELECT id, customer, createdat FROM order_temp;


-- 5. Напишите запрос для удаления данных с оператором DELETE используя join с другой таблицей с помощью using.

-- Удалим из временной таблицы с заказами все заказы, в которых курьеру выставили рейтинг ниже 5 баллов
DELETE FROM order_temp
    USING ef.feedback
        WHERE order_temp.id = ef.feedback.orderid AND courierrating < 5
	RETURNING *;

-- SELECT id, customer FROM order_temp;

-- 6. Приведите пример использования утилиты COPY (по желанию)

-- COPY можно использовать для копирования записей из таблицы в файл, либо для копирования записей из файла в таблицу.
-- Применение функции: импорт/экспорт данных между БД, экспорт/постобработка/анализ данных, csv-файлы, DWH и т.д.

-- Для начала создадим папку data и файл courier.copy, куда будем копировать данные из таблицы ef.courier.
-- Не забываем выдать права на папку и файл пользователю postgres.

-- # mkdir -p /data
-- # echo > /data/courier.copy
-- # chown -R postgres:postgres /data

COPY ef.courier TO '/data/courier.copy' (DELIMITER ',');

-- Посмотрим содержимое файла командой:
-- # cat /data/courier.copy

-- 1,Матвей,Чернышев,+79513518645,4.7,1
-- 2,Алексей,Корнеев,+71321846415,4.5,1
-- 3,Анна,Журавлева,+73523525157,4.9,1
-- 4,Степан,Мыскин,+71258498464,4.8,2
-- 5,Анастасия,Редькина,+74579741133,5,2
-- 6,Глеб,Самойлов,+71357982467,5,3
-- 7,Майя,Редькина,+71248678287,0,4
-- 8,Максим,Свистоплясов,+72872198750,4,5
-- 9,Марина,Редькина,+72481589745,0,6

-- Теперь создадим новую БД
CREATE DATABASE eatfit_temp;

-- Подключимся к новой БД
-- \с eatfit_temp

-- Создадим в новой БД таблицу с типами полей, аналогичными ef.courier
CREATE TABLE IF NOT EXISTS courier_temp (
	id BIGSERIAL PRIMARY KEY,
	firstname VARCHAR(100) NOT NULL,
	lastname VARCHAR(100) NOT NULL,
	phone VARCHAR(20) NOT NULL,
	ratingavg REAL NOT NULL,
	cityid BIGINT NOT NULL
);

-- Используем утилиту COPY для импорта данных из csv-файла в нашу новую таблицу
COPY courier_temp FROM '/data/courier.copy' WITH DELIMITER ',';

-- SELECT * FROM courier_temp;

-- SELECT pg_terminate_backend(pg_stat_activity.pid)
-- FROM pg_stat_activity
-- WHERE pg_stat_activity.datname = 'eatfit_temp'
--   AND pid <> pg_backend_pid();

-- DROP eatfit_temp;