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
	SELECT extract(DAY FROM rental_date), extract(MONTH FROM rental_date), extract(YEAR FROM rental_date) 
	FROM RENTAL
	GROUP BY  extract(YEAR FROM renta_date), extract(MONTH FROM renta_date), extract(DAY FROM renta_date)
	
INSERT INTO DIMENSION_lUGAR
	SELECT CITY.city, COUNTRY.country, STORE.store_id
	FROM RENTAL r INNER JOIN STAFF s ON r.staff_id=s.staff_id
		 INNER JOIN STORE st ON s.store_id=st.store_id
		 INNER JOIN ADDRESS a ON st.address_id=a.address_id
		 INNER JOIN CITY c  ON a.city_id=c.city_id
		 INNER JOIN COUNTRY co ON co.country_id=c.country_id
	GROUP BY CITY.city, COUNTRY.country, STORE.store_id
