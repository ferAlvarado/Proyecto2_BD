-- No sé como se llama la tabla jaja
CREATE OR REPLACE FUNCTION DIMENSION_PELICULA
    RETURNS void
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$

 BEGIN
 INSERT INTO DIMENSION_PELICULA 
	SELECT category.name  film.title
	FROM CATEGORY c INNER JOIN FILM_CATEGORY fc ON c.category_id=fc.category_id
		 INNER JOIN FILM f ON f.film_id=fc.film_id
		 INNER JOIN INVENTORY i ON i.film_id=f.film_id
		 INNER JOIN RENTAL r ON i.inventory_id=r.inventory_id
		GROUP BY ROLLUP category.name  film.title
	
END;
$BODY$;

 INSERT INTO DIMENSION_FECHA
	SELECT extract(YEAR FROM rental_date) AS YEAR, extract(MONTH FROM rental_date) AS MONTH , extract(DAY FROM rental_date) AS DAY
	FROM RENTAL
	GROUP BY (YEAR, MONTH, DAY)
	ORDER BY YEAR, MONTH, DAY;

	
INSERT INTO DIMENSION_lUGAR
	SELECT c.city, co.country, st.store_id
	FROM RENTAL r INNER JOIN STAFF s ON r.staff_id=s.staff_id
		 INNER JOIN STORE st ON s.store_id=st.store_id
		 INNER JOIN ADDRESS a ON st.address_id=a.address_id
		 INNER JOIN CITY c  ON a.city_id=c.city_id
		 INNER JOIN COUNTRY co ON co.country_id=c.country_id
	GROUP BY  ( c.city, co.country, st.store_id)
	
INSERT INTO DIMENSION_LENGUAJE
	SELECT LANGUAGE.name
	FROM LANGUAGE
	
INSERT INTO DIMENSION_DURACION
	select extract(DAY FROM (RENTAL.return_date - RENTAL.rental_date)) AS DAY from rental
	group by DAY
	ORDER BY DAY;
	
INSERT INTO HECHOS_ALQUILER
	SELECT 	DIMENSION_PELICULA.id, DIMENSION_lUGAR.id, DIMENSION_LENGUAJE.id, DIMENSION_FECHA.id, count(*), SUM(PAYMENT.amount)
	FROM RENTAL r, STAFF s, STORE st,ADDRESS a, CITY c, COUNTRY co
	WHERE r.staff_id=s.staff_id AND s.store_id=st.store_id AND st.address_id=a.address_id AND a.city_id=c.city_id AND co.country_id=c.country_id
		 
		 
	INNER JOIN payment p ON r.rental_id = p.rental_id
	INNER JOIN payment p ON r.rental_id = p.rental_id
	INNER JOIN payment p ON r.rental_id = p.rental_id
	INNER JOIN payment p ON r.rental_id = p.rental_id
	INNER JOIN payment p ON r.rental_id = p.rental_id
	INNER JOIN payment p ON r.rental_id = p.rental_id
	INNER JOIN payment p ON r.rental_id = p.rental_id
	INNER JOIN payment p ON r.rental_id = p.rental_id
	INNER JOIN payment p ON r.rental_id = p.rental_id
	INNER JOIN payment p ON r.rental_id = p.rental_id
	
	
	
	
	
	
	