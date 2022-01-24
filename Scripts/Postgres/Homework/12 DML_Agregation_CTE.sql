-- CREATE DATABASE Homework_12;

-- \c Homework_12

-- 1. Создайте таблицу и наполните ее данными

CREATE TABLE statistic(
	player_name VARCHAR(100) NOT NULL,
	player_id INT NOT NULL,
	year_game SMALLINT NOT NULL CHECK (year_game > 0),
	points DECIMAL(12,2) CHECK (points >= 0), 
	PRIMARY KEY (player_name,year_game));

-- 2. заполнить данными

INSERT INTO statistic(player_name, player_id, year_game, points) VALUES
	('Mike',1,2018,18),
	('Jack',2,2018,14),
	('Jackie',3,2018,30),
	('Jet',4,2018,30),
	('Luke',1,2019,16),
	('Mike',2,2019,14),
	('Jack',3,2019,15),
	('Jackie',4,2019,28),
	('Jet',5,2019,25),
	('Luke',1,2020,19),
	('Mike',2,2020,17),
	('Jack',3,2020,18),
	('Jackie',4,2020,29),
	('Jet',5,2020,27);

-- 3. написать запрос суммы очков с группировкой и сортировкой по годам

SELECT year_game, SUM(points)
FROM statistic
GROUP BY year_game
ORDER BY year_game;

-- 4. написать cte показывающее тоже самое

WITH points_by_year AS (
	SELECT year_game, SUM(points) as total_points
	FROM statistic
	GROUP BY year_game
	ORDER BY year_game
)
SELECT year_game, total_points
FROM points_by_year;

-- 5. используя функцию LAG вывести кол-во очков по всем игрокам за текущий код и за предыдущий.

WITH points_by_year AS (
	SELECT year_game, SUM(points) as total_points
	FROM statistic
	GROUP BY year_game
	ORDER BY year_game
)
SELECT year_game, total_points,
	LAG(year_game) OVER (ORDER BY year_game) as prev_year,
	LAG(total_points) OVER (ORDER BY year_game) as prev_total
FROM points_by_year;

-- DROP DATABASE Homework_12;