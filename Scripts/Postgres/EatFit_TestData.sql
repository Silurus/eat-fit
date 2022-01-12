-- Для выполнения следующих команд необходимо подключиться к БД eatfit:
-- # \c eatfit ef_admin

-- TRUNCATE ef.city RESTART IDENTITY CASCADE;
-- TRUNCATE ef.address RESTART IDENTITY CASCADE;
-- TRUNCATE ef.customer RESTART IDENTITY CASCADE;
-- TRUNCATE ef.order RESTART IDENTITY CASCADE;
-- TRUNCATE ef.payment RESTART IDENTITY CASCADE;
-- TRUNCATE ef.feedback RESTART IDENTITY CASCADE;
-- TRUNCATE ef.courier RESTART IDENTITY CASCADE;
-- TRUNCATE ef.orderqueue RESTART IDENTITY CASCADE;
-- TRUNCATE ef.meal RESTART IDENTITY CASCADE;
-- TRUNCATE ef.basket RESTART IDENTITY CASCADE;
-- TRUNCATE ef.promocode RESTART IDENTITY CASCADE;
-- TRUNCATE ef.appliedpromocode RESTART IDENTITY CASCADE;

-- TRUNCATE ef.city RESTART IDENTITY CASCADE;
INSERT INTO ef.city(name) VALUES
	('Москва'),
	('Санкт-Петербург'),
	('Нижний Новгород'),
	('Ярославль'),
	('Екатеринбург'),
	('Новосибирск');

-- TRUNCATE ef.address RESTART IDENTITY CASCADE;
INSERT INTO ef.address(cityid, street, building, entrance, floor, flat) VALUES
	(1, 'Ленина', '5', NULL, NULL, 22),
	(1, 'Пушкина', '6', '1', NULL, 15),
	(1, 'Ратная', '14', '3', '8', 48),
	(1, 'Аргуновская', '2', NULL, '8', NULL),
	(2, 'Ленина', '5 литера А', NULL, NULL, 24),
	(2, 'Пушкина', '6 литера Б', '3', NULL, 17),
	(2, 'Свободы', '15', '4', '9', 150),
	(3, 'Ленина', '7', NULL, NULL, 26),
	(3, 'Пушкина', '9', '5', NULL, 19),
	(4, 'Ленина', '12', NULL, NULL, 455),
	(4, 'Пушкина', '1', '10', NULL, 6),
	(5, 'Ленина', '18 к 1', NULL, NULL, 53),
	(6, 'Пушкина', '17', '9', NULL, 88);

-- TRUNCATE ef.customer RESTART IDENTITY CASCADE;
INSERT INTO ef.customer(firstname, lastname, phone, addressid, cityid) VALUES
	('Петр', 'Иванов', '+74817501172', NULL, 1),
	('Сергей', 'Кузнецов', '+74257821203', 2, 1),
	('Иван', 'Кожемякин', '+79721755429', NULL, 1),
	('Ирина', 'Громова', '+78768421742', NULL, 1),
	('Анна', 'Свиридова', '+77978241750', 5, 2),
	('Алексей', 'Нарышкин', '+74654812128', 6, 2),
	('Ксения', 'Темникова', '+79768418641', NULL, 2),
	('Игорь', 'Завьялов', '+71354168472', NULL, 3),
	('Илья', 'Сидоров', '+70212455644', NULL, 4),
	('Маргарита', 'Светлова', '+70214178774', 10, 4),
	('Евгения', 'Лапина', '+78946121487', NULL, 5),
	('Анатолий', 'Кудюхов', '+71325487871', 13, 6);

-- TRUNCATE ef.order RESTART IDENTITY CASCADE;
INSERT INTO ef.order(customerid, addressid, createdat, iscompleted, iscancelled, totalprice, totaldiscount) VALUES
	(12, 13, TIMESTAMP '2021-12-28 14:53', FALSE, TRUE, 380, NULL),
	(4, 1, TIMESTAMP '2021-12-29 12:01', FALSE, TRUE, 640, NULL),
	(9, 10, TIMESTAMP '2021-12-30 21:45', FALSE, TRUE, 400, NULL),
	(1, 2, TIMESTAMP '2021-12-31 09:22', FALSE, TRUE, 650, NULL),
	(1, 2, TIMESTAMP '2022-01-03 08:41', FALSE, TRUE, 810, 0.1),
	(1, 3, TIMESTAMP '2022-01-05 14:00', FALSE, TRUE, 650, NULL),
	(7, 7, TIMESTAMP '2022-01-05 15:25', FALSE, TRUE, 400, NULL),
	(7, 4, TIMESTAMP '2022-01-05 15:37', FALSE, TRUE, 570, 0.05);

--  Значения paymentstatus: -1 (ошибка), 0 (не оплачен), 1 (оплачен), 2 (обрабатывается), 3 (произведен возврат)
-- TRUNCATE ef.payment RESTART IDENTITY CASCADE;
INSERT INTO ef.payment(orderid, paymentstatus) VALUES
	(1, 1),
	(2, 1),
	(3, -1),
	(4, 1),
	(5, 2),
	(6, 1),
	(7, 3),
	(8, 0);

-- TRUNCATE ef.feedback RESTART IDENTITY CASCADE;
INSERT INTO ef.feedback(orderid, orderrating, courierrating, text) VALUES
	(1, 5, 5, 'Отлично!'),
	(2, 5, 4, NULL),
	(3, 3, 4, NULL),
	(4, 5, 1, 'Курьер отдал не тот заказ'),
	(5, 1, 4, 'Нашел кусок ветчины в веганском салате'),
	(6, 5, 5, NULL);

-- TRUNCATE ef.courier RESTART IDENTITY CASCADE;
INSERT INTO ef.courier(cityid, firstname, lastname, phone, ratingavg) VALUES
	(1, 'Матвей', 'Чернышев', '+79513518645', 4.7),
	(1, 'Алексей', 'Корнеев', '+71321846415', 4.5),
	(1, 'Анна', 'Журавлева', '+73523525157', 4.9),
	(2, 'Степан', 'Мыскин', '+71258498464', 4.8),
	(2, 'Анастасия', 'Редькина', '+74579741133', 5.0),
	(3, 'Глеб', 'Самойлов', '+71357982467', 5.0),
	(4, 'Майя', 'Редькина', '+71248678287', 0.0),
	(5, 'Максим', 'Свистоплясов', '+72872198750', 4.0),
	(6, 'Марина', 'Редькина', '+72481589745', 0.0);

-- --  Значения orderstatus: 0 (ожидает подтверждения), 1 (готовится), 2 (доставляется), 3 (выполнен), 4 (отменен)
-- TRUNCATE ef.orderqueue RESTART IDENTITY CASCADE;
INSERT INTO ef.orderqueue(orderid, courierid, orderstatus, estimatedtime) VALUES
	(5, 2, 4, TIMESTAMP '2022-01-03 11:00'),
	(6, 1, 3, TIMESTAMP '2022-01-05 16:00'),
	(7, 5, 1, TIMESTAMP '2022-01-05 18:00'),
	(8, 2, 2, TIMESTAMP '2022-01-05 18:30');

-- TRUNCATE ef.meal RESTART IDENTITY CASCADE;
INSERT INTO ef.meal(name, price, calories) VALUES
	('Курица с гарниром', 300, 250.0),
	('Грибной суп', 350, 300.0),
	('Фрикадельки из индейки', 300, 270.0),
	('Блинный торт', 200, 300.0),
	('Лимонад без сахара', 100, 80.0);

-- TRUNCATE ef.basket RESTART IDENTITY CASCADE;
INSERT INTO ef.basket(orderid, mealid, quantity, positionprice) VALUES
	(1, 3, 1, 280),
	(1, 5, 1, 100),
	(2, 2, 2, 320),
	(3, 4, 1, 200),
	(3, 5, 2, 100),
	(4, 1, 1, 300),
	(4, 2, 1, 350),
	(5, 3, 1, 300),
	(5, 4, 2, 200),
	(5, 5, 2, 100),
	(6, 2, 1, 350),
	(6, 3, 1, 300),
	(7, 1, 1, 300),
	(7, 5, 1, 100),
	(8, 3, 2, 300);

-- TRUNCATE ef.promocode RESTART IDENTITY CASCADE;
INSERT INTO ef.promocode(code, discount, isactive) VALUES
	('NEWYEAR10', '0.1', TRUE),
	('WINTER', '0.05', TRUE),
	('FALL', '0.05', FALSE);

-- TRUNCATE ef.appliedpromocode RESTART IDENTITY CASCADE;
INSERT INTO ef.appliedpromocode(orderid, promocodeid) VALUES
	(5, 1),
	(8, 2);