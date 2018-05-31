--CREAR MODELO ESTRELLA
CREATE TABLE DIMENSION_PELICULA 
(
    pelicula_id SERIAL NOT NULL PRIMARY KEY,
    categoria character varying(25) NOT NULL,
    pelicula character varying(255) NOT NULL
);

CREATE TABLE DIMENSION_FECHA 
(
    fecha_id SERIAL NOT NULL PRIMARY KEY,
	anno int NOT NULL,  
	mes int NOT NULL,
	dia int NOT NULL
);

CREATE TABLE DIMENSION_LUGAR 
(
    lugar_id SERIAL NOT NULL PRIMARY KEY,
    pais character varying(50) NOT NULL,
    ciudad character varying(50) NOT NULL,
	tienda integer NOT NULL
);

CREATE TABLE DIMENSION_LENGUAJE 
(
    lenguaje_id SERIAL NOT NULL PRIMARY KEY,
	lenguaje character(20) NOT NULL
);

CREATE TABLE DIMENSION_DURACION
(
    duracion_id SERIAL NOT NULL PRIMARY KEY,
    cantidad integer NOT NULL
);

CREATE TABLE HECHOS_ALQUILER 
(
	pelicula_id integer NOT NULL REFERENCES DIMENSION_PELICULA(pelicula_id),
	fecha_id integer NOT NULL REFERENCES DIMENSION_FECHA(fecha_id),
	lugar_id integer NOT NULL REFERENCES DIMENSION_LUGAR(lugar_id),
    lenguaje_id integer NOT NULL REFERENCES DIMENSION_LENGUAJE(lenguaje_id),
	duracion_id integer NOT NULL REFERENCES DIMENSION_DURACION(duracion_id),
	numeroAlquileres integer NOT NULL,
	montoAlquileres numeric(5,2) 
);
-- No sé como se llama la tabla jaja
CREATE OR REPLACE FUNCTION MODELO_ESTRELLA()
    RETURNS void
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$

 BEGIN
 INSERT INTO DIMENSION_PELICULA (categoria, pelicula)
	SELECT c.name, f.title
	FROM CATEGORY c INNER JOIN FILM_CATEGORY fc ON c.category_id=fc.category_id
		 INNER JOIN FILM f ON f.film_id=fc.film_id
		 INNER JOIN INVENTORY i ON i.film_id=f.film_id
		 INNER JOIN RENTAL r ON i.inventory_id=r.inventory_id
		GROUP BY c.name, f.title;
		
INSERT INTO DIMENSION_FECHA (anno, mes, dia)
SELECT extract(YEAR FROM rental_date) AS YEAR, extract(MONTH FROM rental_date) AS MONTH , extract(DAY FROM rental_date) AS DAY
	FROM RENTAL
	GROUP BY (YEAR, MONTH, DAY)
	ORDER BY YEAR, MONTH, DAY;
	
	
INSERT INTO DIMENSION_LUGAR (pais, ciudad, tienda)
	SELECT co.country, c.city, st.store_id
	FROM RENTAL r INNER JOIN STAFF s ON r.staff_id=s.staff_id
		 INNER JOIN STORE st ON s.store_id=st.store_id
		 INNER JOIN ADDRESS a ON st.address_id=a.address_id
		 INNER JOIN CITY c  ON a.city_id=c.city_id
		 INNER JOIN COUNTRY co ON co.country_id=c.country_id
	GROUP BY  ( c.city, co.country, st.store_id);
	

INSERT INTO DIMENSION_LENGUAJE (lenguaje)
	SELECT LANGUAGE.name
	FROM LANGUAGE;
	
INSERT INTO DIMENSION_DURACION (cantidad)
	select (date_part ('day',  return_date - rental_date )) +
        ceiling(date_part ('hour', return_date - rental_date ) /24) AS DAY from rental
	where return_date is not null
	group by DAY
	ORDER BY DAY;
	
INSERT INTO HECHOS_ALQUILER
	SELECT 	DIMENSION_PELICULA.pelicula_id, DIMENSION_FECHA.fecha_id, DIMENSION_lUGAR.lugar_id, DIMENSION_LENGUAJE.lenguaje_id, DIMENSION_DURACION.duracion_id, count(*), SUM(P.amount)
	FROM RENTAL r 
	FULL JOIN PAYMENT P
	ON r.rental_id = P.rental_id
	INNER JOIN inventory I
	ON r.inventory_id = I.inventory_id 
	INNER JOIN FILM F
	ON I.film_id = F.film_id
	INNER JOIN language L
	ON F.language_id = L.language_id
	INNER JOIN film_category fc
	ON fc.film_id = F.film_id
	INNER JOIN category cat
	on fc.category_id = cat.category_id
	INNER JOIN STAFF s   
	ON r.staff_id=s.staff_id 
	INNER JOIN STORE st
	ON s.store_id=st.store_id 
	INNER JOIN ADDRESS a
	ON st.address_id=a.address_id 
	INNER JOIN CITY c
	ON a.city_id=c.city_id 
	INNER JOIN COUNTRY co
	ON co.country_id=c.country_id, DIMENSION_lUGAR, DIMENSION_LENGUAJE, DIMENSION_PELICULA, DIMENSION_FECHA, DIMENSION_DURACION
	WHERE DIMENSION_LUGAR.pais = co.country 
	AND DIMENSION_LUGAR.ciudad = c.city 
	AND DIMENSION_LUGAR.tienda = st.store_id
	AND L.name = DIMENSION_LENGUAJE.lenguaje
	AND DIMENSION_PELICULA.pelicula = F.title
	AND DIMENSION_PELICULA.categoria = cat.name
	AND DIMENSION_FECHA.anno = extract(YEAR FROM r.rental_date)
	AND DIMENSION_FECHA.mes = extract(MONTH FROM r.rental_date)
	AND DIMENSION_FECHA.dia = extract(DAY FROM r.rental_date)
	AND DIMENSION_DURACION.cantidad = (date_part ('day',  r.return_date - r.rental_date )) + ceiling(date_part ('hour', r.return_date - r.rental_date ) /24)
	GROUP BY DIMENSION_PELICULA.pelicula_id, DIMENSION_FECHA.fecha_id, DIMENSION_lUGAR.lugar_id, DIMENSION_LENGUAJE.lenguaje_id, DIMENSION_DURACION.duracion_id;


	  
END;
$BODY$;



--CONSULTAS DEL MODELO
CREATE FUNCTION obtener_num_alquileres_categoria(
mes date,
categoria character varying(25)
)
RETURNS RECORD AS 
$BODY$
DECLARE 
  ret RECORD;
BEGIN
  SELECT h.numeroAlquileres,p.categoria 
  FROM HECHOS_ALQUILER h INNER JOIN DIMENSION_PELICULA p  ON h.pelicula_id=p.pelicula_id 
  WHERE p.categoria=categoria 
  GROUP BY p.categoria,h.numeroAlquileres INTO ret;
RETURN ret;
END;
$BODY$ 
LANGUAGE plpgsql;


LANGUAGE plpgsql VOLATILE 

CREATE FUNCTION obtener_num_alquileres_duracion()
RETURNS RECORD AS 
$BODY$
DECLARE 
  ret RECORD;
BEGIN
  SELECT h.numeroAlquileres,h.montoAlquileres,d.cantidad
  FROM HECHOS_ALQUILER h INNER JOIN DIMENSION_DURACION d  ON h.duracion_id=d.duracion_id 
  GROUP BY d.cantidad,h.numeroAlquileres,h.montoAlquileres INTO ret;
RETURN ret;
END;
$BODY$ 
LANGUAGE plpgsql;


LANGUAGE plpgsql VOLATILE 

CREATE FUNCTION rollup_anno_mes()
RETURNS RECORD AS 
$BODY$
DECLARE 
  ret RECORD;
BEGIN
  SELECT h.montoAlquileres,f.anno,f.mes
  FROM HECHOS_ALQUILER h INNER JOIN DIMENSION_FECHA f  ON h.fecha_id=f.fecha_id 
  GROUP BY ROLLUP (f.anno,f.mes,h.montoAlquileres) INTO ret;
RETURN ret;
END;
$BODY$ 
LANGUAGE plpgsql;

CREATE FUNCTION cubo_anno_categoria()
RETURNS RECORD AS 
$BODY$
DECLARE 
  ret RECORD;
BEGIN
  SELECT h.numeroAlquileres,h.montoAlquileres,f.anno,p.categoria
  FROM HECHOS_ALQUILER h,DIMENSION_FECHA f, DIMENSION_PELICULA p
  WHERE h.fecha_id=f.fecha_id AND h.pelicula_id=p.pelicula_id
  GROUP BY ROLLUP (f.anno,p.categoria,h.numeroAlquileres,h.montoAlquileres) INTO ret;
RETURN ret;
END;
$BODY$ 
LANGUAGE plpgsql;


LANGUAGE plpgsql VOLATILE 

	
	
	
	
	
	
	