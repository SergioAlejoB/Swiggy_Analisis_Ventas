--ESTUDIO DE CASO: VENTAS DE LA APLICACION SWIGGY

CREATE DATABASE [Swiggy Database]
USE [Swiggy Database]

--INSERCION DE FUENTE DE DATOS (CV) A UNA TABLA (Import file CV) 
SELECT * FROM swiggy_data_1  

--VERIFICAR NULOS POR COLUMNA
SELECT 
	SUM(CASE WHEN State is NULL THEN 1 ELSE 0 END) AS null_STATE,
	SUM(CASE WHEN City is NULL THEN 1 ELSE 0 END) AS null_CITY,
	SUM(CASE WHEN Order_Date is NULL THEN 1 ELSE 0 END) AS null_order_date,
	SUM(CASE WHEN Restaurant_Name is NULL THEN 1 ELSE 0 END) AS null_restaurant,
	SUM(CASE WHEN Location is NULL THEN 1 ELSE 0 END) AS null_location,
	SUM(CASE WHEN Category is NULL THEN 1 ELSE 0 END) AS null_category,
	SUM(CASE WHEN Dish_Name is NULL THEN 1 ELSE 0 END) AS null_dish,
	SUM(CASE WHEN Price_INR is NULL THEN 1 ELSE 0 END) AS null_price,
	SUM(CASE WHEN Rating is NULL THEN 1 ELSE 0 END) AS null_rating,
	SUM(CASE WHEN Rating_Count is NULL THEN 1 ELSE 0 END) AS null_rating_count
FROM swiggy_data_1

--VERIFICAR CADENAS O DATOS EN BLANCO
SELECT *
FROM swiggy_data_1
WHERE State=' ' or City=' ' or Dish_Name=' ' or Restaurant_Name=' ' or Location=' ' or Category=' ' 

--VERIFICAR REGISTROS DUPLICADOS
SELECT State, City, Order_Date, Restaurant_Name, Location, Category, Dish_Name, Price_INR, Rating, Rating_Count, COUNT (1) AS CNT
FROM swiggy_data_1
GROUP BY State, City, Order_Date, Restaurant_Name, Location, Category, Dish_Name, Price_INR, Rating, Rating_Count
HAVING COUNT(1) > 1

--ELIMINAR DUPLICADOS

WITH Duplicados AS (
	SELECT 
		*,ROW_NUMBER() OVER(PARTITION BY State, City, Order_Date, Restaurant_Name, Location, Category, 
		Dish_Name, Price_INR, Rating, Rating_Count
		ORDER BY (SELECT null)) AS RN
	FROM swiggy_data_1
) 
DELETE FROM Duplicados
WHERE RN>1

--MODELADO DIMENSIONAL (5 ESTRELLAS)

--CREANDO LAS DIMENSIONES (TABLAS)

--Date Table
CREATE TABLE dim_date(
   date_id int primary key identity(1,1),
   Full_Date date,
   Year int,
   Month varchar(20),
   Month_Name varchar(20),
   Quarter int,
   Day int,
   Week int 
)
SELECT * FROM dim_date

--dim_location
CREATE TABLE dim_location(
   location_id int primary key identity(1,1),
   State varchar(100),
   City varchar(100),
   Location varchar(200)
)
SELECT * FROM dim_location

--dim_restaurant
CREATE TABLE dim_restaurant(
   restaurant_id int primary key identity(1,1),
   Restaurant_name varchar(200)
)
SELECT * FROM dim_restaurant

--dim_category
CREATE TABLE dim_category(
   category_id int primary key identity(1,1),
   Category varchar(200)
)
SELECT*FROM dim_category

--dim_dish
CREATE TABLE dim_dish(
   dish_id int primary key identity(1,1),
   Dish_Name varchar(200)
)
SELECT*FROM dim_dish

select * from swiggy_data_1

--FACT TABLE
CREATE table fact_swiggy_orders(
    order_id int primary key identity(1,1),
	Price_INR decimal(10,2),
	Rating decimal(4,2),
	Rating_Count INT,
	
	location_id int,
	date_id int,
	restaurant_id int,
	category_id int,
	dish_id int

	FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
	FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
	FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),
	FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
	FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id),
)

SELECT * FROM fact_swiggy_orders

select * from swiggy_data_1

--INSERCIÓN DE DATOS EN LAS DIMENSIONES Y TABLA DE HECHOS

--dimension date
INSERT INTO dim_date(Full_Date, Year, Month, Month_Name, Quarter, Day, Week)
SELECT DISTINCT
	Order_Date,
	YEAR(Order_Date),
	MONTH(Order_Date),
	DATENAME(Month,Order_Date),
	DATEPART(QUARTER,Order_Date),
	DAY(Order_Date),
	DATEPART(WEEK, Order_Date)
FROM swiggy_data_1
WHERE Order_Date IS NOT NULL

select * from dim_date

--dimension location

INSERT INTO dim_location(State, City, Location)
SELECT DISTINCT
	State,
	City,
	Location
FROM swiggy_data_1

select * from dim_location

--dimension restaurant

INSERT INTO dim_restaurant(Restaurant_name)
SELECT DISTINCT
	Restaurant_Name
FROM swiggy_data_1

select * from dim_restaurant


--dimension category
INSERT INTO dim_category(Category)
SELECT DISTINCT
	Category
FROM swiggy_data_1

select * from dim_category

--dimension dish
INSERT INTO dim_dish(Dish_Name)
SELECT DISTINCT
	Dish_Name
FROM swiggy_data_1

select * from dim_dish

--fact table
INSERT INTO fact_swiggy_orders(Price_INR, Rating, Rating_Count, location_id, date_id, restaurant_id, category_id, dish_id)
SELECT
    S.Price_INR,
	S.Rating,
	S.Rating_Count,
	L.location_id,
	d.date_id,
	r.restaurant_id,
	c.category_id,
	dh.dish_id
FROM swiggy_data_1 S JOIN dim_location L on S.Location=L.Location AND S.City=L.City AND S.State=L.State 
JOIN dim_date d on s.Order_Date=d.Full_Date
JOIN dim_restaurant r on s.Restaurant_Name=r.Restaurant_name
JOIN dim_category c on s.Category=c.Category
JOIN dim_dish dh on s.Dish_Name=dh.Dish_Name

select * from fact_swiggy_orders

--Verificar igualdad de IDs uniendo DIMENSIONES + T.HECHOS
SELECT * FROM fact_swiggy_orders f
JOIN dim_date d on f.date_id=d.date_id
JOIN dim_category c on f.category_id=c.category_id
JOIN dim_dish dh on f.dish_id=dh.dish_id
JOIN dim_location l on l.location_id=f.location_id
JOIN dim_restaurant r on f.restaurant_id=r.restaurant_id

--CREACION Y MANEJO DE KPIs

--Total de Ordenes
SELECT COUNT(1) AS Total_Orders
FROM fact_swiggy_orders

--Total Ganancias (INR MILLION)
SELECT FORMAT(CONVERT(float, SUM(Price_INR))/1000000, 'N2') + ' INR MILLION'  AS TOTAL_REVENUE 
FROM fact_swiggy_orders

--Precio promedio de Platos
SELECT FORMAT(CONVERT(float, AVG(price_inr)), 'N2') + ' INR' AS AVERAGE_PRICE_PLATES
FROM fact_swiggy_orders

--Promedio Puntaje de Calificacion 
SELECT AVG(Rating) as AVG_Rating
FROM fact_swiggy_orders


select * from fact_swiggy_orders 

--ANÁLISIS PROFUNDO DE DATOS

--Tendencias mensuales de ordenes
SELECT d.Month, D.Year, D.Month_Name, COUNT(1) AS Trend_Order_Monthly
FROM fact_swiggy_orders F JOIN dim_date D ON F.date_id=D.date_id
GROUP BY D. Year, D.Month_Name, D.Month
ORDER BY  4 DESC

--Tendencias mensuales de precio de platos (MILES)
SELECT d.Month, D.Year, D.Month_Name, FORMAT(SUM(F.Price_INR)/1000, 'N2') + ' K' AS Total_Revenue
FROM fact_swiggy_orders F JOIN dim_date D ON F.date_id=D.date_id
GROUP BY D. Year, D.Month_Name, D.Month
ORDER BY  4 DESC

--Tendencias de ordenes por TRIMESTRE
SELECT D.Year, D.Quarter, COUNT(1) AS Total_Orders
FROM fact_swiggy_orders F JOIN dim_date D ON F.date_id=D.date_id
GROUP BY D.Year, D.Quarter 
ORDER BY 3 DESC

--Tendencias  de ordenes por AÑO
SELECT D.Year, COUNT(*) AS Total_Orders
FROM fact_swiggy_orders F JOIN dim_date D ON F.date_id=D.date_id
GROUP BY D.Year

--Ordenes por dia de la semana 
SELECT DATENAME(WEEKDAY, D.Full_Date) AS DAY, COUNT(*) AS DayOfWeek_TREND
FROM fact_swiggy_orders F JOIN dim_date D ON F.date_id=D.date_id
GROUP BY DATENAME(WEEKDAY, D.Full_Date), DATEPART(WEEKDAY, D.Full_Date)
ORDER BY 2 DESC

--# Ordenes por ciudad (TOP 10 mayores)
SELECT TOP 10 
	L.City , COUNT(*) AS City_Orders
FROM fact_swiggy_orders F JOIN dim_location L ON F.location_id=L.location_id
GROUP BY L.City
ORDER BY 2 DESC

--Total Ganancias (Price_INR) por ciudad (TOP 10 mayores)
SELECT TOP 10 L.City, SUM(F.Price_INR) AS Total_Revenue
FROM fact_swiggy_orders F JOIN dim_location L ON F.location_id=L.location_id
GROUP BY L.City
ORDER BY 2 DESC

--Contribuacion de ganancias por estado
SELECT L.State, SUM(F.Price_INR) AS State_Contribution
FROM fact_swiggy_orders F JOIN dim_location L ON F.location_id=L.location_id
GROUP BY L.State
ORDER BY 2 

--Ordenes por estado 
SELECT L.State, COUNT(*) AS Orders
FROM fact_swiggy_orders F JOIN dim_location L ON F.location_id=L.location_id
GROUP BY L.State
ORDER BY 2 ASC

--Ordenes por restaurante (top 10)
SELECT TOP 10 R.Restaurant_name, COUNT(*) AS ORDERS 
FROM fact_swiggy_orders F JOIN dim_restaurant R ON F.restaurant_id=R.restaurant_id
GROUP BY R.Restaurant_name
ORDER BY 2 DESC

--Ganancias por restaurante
SELECT R.Restaurant_name, SUM(F.Price_INR) AS REVENUE
FROM fact_swiggy_orders F JOIN dim_restaurant R ON F.restaurant_id=R.restaurant_id
GROUP BY R.Restaurant_name
ORDER BY 2 DESC

--Ordenes por Categoria
SELECT C.Category, COUNT(*) AS ORDERS
FROM fact_swiggy_orders F JOIN dim_category C ON F.category_id=C.category_id
GROUP BY C.Category
ORDER BY 2 DESC

--Platos mas ordenados
SELECT D.Dish_Name, COUNT(*) AS ORDERS
FROM fact_swiggy_orders F JOIN dim_dish D ON F.dish_id=D.dish_id
GROUP BY D.Dish_Name
ORDER BY 2 DESC

--Ordenes y puntaje promedio por Categoria
SELECT C.Category, COUNT(*) ORDERS, FORMAT(AVG(F.Rating), 'N2') AS Rating_Prom
FROM fact_swiggy_orders F JOIN dim_category C ON F.category_id=C.category_id
GROUP BY c.Category
ORDER BY 2 DESC

select * from fact_swiggy_orders 

--Distribucion por rangos de ordenes de los precios de platos 
--1RA MANERA
SELECT 
	CASE
		WHEN Price_INR<100 THEN 'Under 100'
		WHEN Price_INR BETWEEN 100 AND 199 THEN '100 - 199'
		WHEN Price_INR BETWEEN 200 AND 299 THEN '200 - 299'
		WHEN Price_INR BETWEEN 300 AND 499 THEN '300 - 499'
		ELSE '+500'
	END AS RANGES_PRICE
	, COUNT(*) AS TOTAL_ORDERS
FROM fact_swiggy_orders
GROUP BY CASE
			WHEN Price_INR<100 THEN 'Under 100'
			WHEN Price_INR BETWEEN 100 AND 199 THEN '100 - 199'
			WHEN Price_INR BETWEEN 200 AND 299 THEN '200 - 299'
			WHEN Price_INR BETWEEN 300 AND 499 THEN '300 - 499'
			ELSE '+500'
		END
ORDER BY 2 DESC

--2DA MANERA
WITH CTE AS (
		SELECT 
			CASE
				WHEN Price_INR<100 THEN 'Under 100'
				WHEN Price_INR BETWEEN 100 AND 199 THEN '100 - 199'
				WHEN Price_INR BETWEEN 200 AND 299 THEN '200 - 299'
				WHEN Price_INR BETWEEN 300 AND 499 THEN '300 - 499'
				ELSE '+500'
			END AS RANGES_PRICE
			, Price_INR, order_id
		FROM fact_swiggy_orders
)
SELECT RANGES_PRICE, COUNT(*) AS ORDERS
FROM CTE
GROUP BY RANGES_PRICE
ORDER BY 1 DESC


--DISTRIBUCION DE CONTEO DE califiaciones de los platos
SELECT Rating, COUNT(*) AS Count_Rating
FROM fact_swiggy_orders
GROUP BY Rating
order by 2 ASC --order by Rating DESC 

