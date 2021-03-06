# Eat-Fit - сервис доставки здоровой еды

**Содержание**
1. [Предметная область](#предметная-область)
2. [Схема БД](#схема-бд)
    - [Описание таблиц](#описание-таблиц)
    - [Индексы](#индексы)
    - [Aвтоматические проверки (Check Constraints)](#автоматические-проверки-check-constraints)
3. [Установка СУБД](#установка-субд)
    - [PostgreSQL](#postgresql)


## Предметная область
Сервис доставки здоровой еды через мобильное приложение.

**Целевая аудитория**: люди в возрасте от 20 до 50 лет, следящие за своим питанием и желающие разнообразить свой рацион, не выходя за рамки диеты.

## Схема БД

БД ориентирована на оформление заказов из мобильного приложения, где клиенты могут отслеживать статус заказа и ориентировочное время доставки.

По каждому выполненному заказу клиенту предлагается оценить заказ и работу курьера.
На основе этих данных курьерам выставляется средний рейтинг и дорабатывается рецептура блюд.

![image](https://user-images.githubusercontent.com/19695435/149655747-6915ac21-1329-4c73-bc95-326989b08662.png)


### Описание таблиц

- **Customer** - таблица с данными о клиентах
- **City** - таблица-справочник с городами/населенными пунктами для адресов
- **Address** - таблица с адресами доставки заказов. Также используется для хранения адресов клиентов по-умолчанию
- **Order** - таблица с данными о заказах
- **Feedback** - таблица с отзывами пользователей о заказах. Используется для формирования рейтинга курьеров
- **Payment** - таблица с данными об оплате заказа
- **Basket** - таблица с данными о корзине заказа, содержит информацию о количестве блюд и цене блюда на момент заказа
- **Promocode** - таблица с данными о промокодах, содержит информацию о размере скидки (в процентах, вещественное число от 0 до 1), правилах применения (в виде json), датах действия, а также флаг включен/выключен
- **AppliedPromocode** - таблица с данными о промокодах, примененных к заказам
- **Meal** - таблица с данными о блюдах. Здесь хранится описание, размер порции, состав, КБЖУ, а также цена блюда
- **OrderQueue** - таблица-очередь заказов. Здесь хранится статус заказа, ожидаемое время доставки, а также назначенный на заказ курьер
- **Courier** - таблица с курьерами. У каждого курьера есть средний рейтинг, который складывается из рейтинга всех доставленных заказов


### Индексы

- **UQ_City_Name** - уникальный индекс для таблицы City по полю Name,
- **IX_City_Name_Fulltext** - функциональный индекс для таблицы City по полю Name, необходим для полнотекстового поиска по названию города/населенного пункта
- **UQ_Customer_Phone** - уникальный индекс для таблицы Customer по полю Phone, необходим для быстрого поиска клиента по номеру телефона, проверяет чтобы номера телефонов не повторялись
- **UQ_Courier_Phone** - уникальный индекс для таблицы Courier по полю Phone, необходим для быстрого поиска курьера по номеру телефона в таблице, проверяет чтобы номера телефонов не повторялись. Индекс включает в себя поля FirstName и RatingAvg для быстрого отображения имени рейтинга курьера в приложении
- **IX_Order_CustomerId_CreatedAt** - композитный индекс для таблицы Order по полям CustomerId и CreatedAt, используется в запросах для сбора статистики заказов по клиенту. Индекс включает в себя поле TotalPrice для подсчета общей суммы заказов по клиенту за конкретный период времени
- **IX_Meal_Name_Fulltext** - функциональный индекс для таблицы Meal по полю Name, необходим для полнотекстового поиска по названию блюда
- **IX_Promocode_Code** - индекс для таблицы Promocode по полю Code, используется для поиска промокодов

### Автоматические проверки (Check Constraints)

- **CK_Basket_Quantity_NonNegative** - проверка для таблицы Basket,  
поле Quantity должно быть неотрицательным числом (>= 0)
- **CK_Feedback_CourierRating_NonNegative** - проверка для таблицы Feedback,  
поле CourierRating должно быть неотрицательным числом (>= 0)
- **CK_Feedback_OrderRating_NonNegative** - проверка для таблицы Feedback,  
поле OrderRating должно быть неотрицательным числом (>= 0)
- **CK_Meal_Calories_NonNegative** - проверка для таблицы Meal,  
поле Calories должно быть неотрицательным числом (>= 0)
- **CK_Meal_Carbs_NonNegative** - проверка для таблицы Meal,  
поле Carbs должно быть неотрицательным числом (>= 0)
- **CK_Meal_Fats_NonNegative** - проверка для таблицы Meal,  
поле Fats должно быть неотрицательным числом (>= 0)
- **CK_Meal_Protein_NonNegative** - проверка для таблицы Meal,  
поле Protein должно быть неотрицательным числом (>= 0)

Для полей **Order.TotalDiscount** и **Promocode.Discount** был создан домен **percent**, который имеет тип **DECIMAL** и применяет следующие ограничения:
- не может быть **NULL**
- значение по-умолчанию: **0**
- значение должно быть в интервале **[0; 1]**

Для полей **Order.TotalPrice**, **Meal.Price**, **Basket.PositionPrice** был создан домен **price**, который имеет тип **DECIMAL** и применяет следующие ограничения:
- не может быть **NULL**
- значение по-умолчанию: **0**
- значение должно быть **>= 0**

## Установка СУБД

### PostgreSQL

#### Установка docker-образа PostgreSQL

Для установки PostgreSQL необходимо скачать docker-образ с помощью команды `docker pull postgres`.  
После того, как образ скачался, запускаем контейнер для PostgreSQL:
```
docker run --name postgres14 –e POSTGRES_PASSWORD="****" –d –p 5432:5432 postgres
```

Проверить запущенные контейнеры можно с помощью команды `docker ps`:

![image](https://user-images.githubusercontent.com/19695435/147001369-1d0de65f-edbf-4b57-a4d5-737ff44df935.png)

#### Подключение к БД через командную строку

Подключимся к БД по-умолчанию **postgres** через командную строку:
```
docker exec -it postgres14 bash
psql -U postgres -W
> password: <вводим_пароль>
```
![image](https://user-images.githubusercontent.com/19695435/147001678-c022eb0b-ca76-467e-9f6b-6c08f703d276.png)

Посмотреть список БД можно с помощью команды `\l`:

![image](https://user-images.githubusercontent.com/19695435/147003409-39f004c7-9858-4c40-a1a6-5cdc83680e21.png)

Создадим новую БД с именем **otus** и затем подключимся к ней:
```
CREATE DATABASE otus;
\c otus postgres
```
![image](https://user-images.githubusercontent.com/19695435/147003849-397733f6-58b5-4b21-9631-79a6f01ecd3f.png)

#### Установка клиента pgAdmin

Для удобной работы с БД можно скачать docker-образ клиента pgAdmin `docker pull dpage/pgadmin4`.

Запускаем контейнер для pgAdmin, который будет доступен по адресу http://localhost:5555 :
```
docker run --name pgadmin4 -p 5555:80 -e PGADMIN_DEFAULT_EMAIL="user@email.com" -e PGADMIN_DEFAULT_PASSWORD="****" -e PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION=True -d dpage/pgadmin4
```

После того как контейнер запустился, в браузере переходим по адресу http://localhost:5555 и вводим указанные в предыдущей команде логин/пароль:

![image](https://user-images.githubusercontent.com/19695435/147004580-cb947b2e-4865-43ae-b39e-7f1aef0a395e.png)

Далее жмем правой кнопкой на **Servers -> Create -> Server...**, указываем имя (например, localhost).  
Переходим на вкладку **Connection**, указываем адрес хоста (в моем случае это **host.docker.internal**, т.к. Postgres и pgAdmin оба развернуты внутри docker-контейнеров) и порт 5432 (по-умолчанию).

![pgadmin connection](https://user-images.githubusercontent.com/19695435/147005143-b72f3d91-0e32-4384-97aa-4ee67b4c7df8.png)

Жмем **Save**.

Если выбрать сервер **localhost** и перейти на вкладку **Dashboard**, то внизу мы увидим список подключений, в котором есть три подключения:
- два подключения к базам **otus** и **postgres** из клиента pgAdmin
- одно подключение к базе **otus** из командной строки psql

![image](https://user-images.githubusercontent.com/19695435/147005523-b3badd2e-e37b-4001-9377-be09fbe3edf9.png)
