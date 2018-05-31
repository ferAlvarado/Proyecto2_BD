-- No sé como se llama la tabla jaja
CREATE OR REPLACE FUNCTION MODELO_ESTRELLA
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
		GROUP BY category.name  film.title
		
INSERT INTO DIMENSION_FECHA
	SELECT extract(YEAR FROM rental_date) AS YEAR, extract(MONTH FROM rental_date) AS MONTH , extract(DAY FROM rental_date) AS DAY
	FROM RENTAL
	GROUP BY (YEAR, MONTH, DAY)
	ORDER BY YEAR, MONTH, DAY;

	
INSERT INTO DIMENSION_LUGAR
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
		 
END;
$BODY$;

 
	
--CREAR MODELO ESTRELLA
CREATE TABLE DIMENSION_PELICULA 
(
    pelicula_id integer NOT NULL DEFAULT nextval('DIMENSION_PELICULA_pelicula_id_seq'::regclass),
    categoria character varying(25) NOT NULL,
    pelicula character varying(255) NOT NULL,
    CONSTRAINT pelicula_pkey PRIMARY KEY (pelicula_id)
)

CREATE TABLE DIMENSION_FECHA 
(
    fecha_id integer NOT NULL DEFAULT nextval('DIMENSION_FECHA_fecha_id_seq'::regclass),
	anno date NOT NULL,  -
	mes date NOT NULL,
	dia date NOT NULL,
    CONSTRAINT fecha_pkey PRIMARY KEY (fecha_id)
)

CREATE TABLE DIMENSION_LUGAR 
(
    lugar_id integer NOT NULL DEFAULT nextval('DIMENSION_LUGAR_lugar_id_seq'::regclass),
    pais character varying(50) NOT NULL,
    ciudad character varying(50) NOT NULL,
	tienda integer NOT NULL,
    CONSTRAINT lugar_pkey PRIMARY KEY (lugar_id)
)

CREATE TABLE DIMENSION_LENGUAJE 
(
    lenguaje_id integer NOT NULL DEFAULT nextval('DIMENSION_LENGUAJE_lenguaje_id_seq'::regclass),
	lenguaje character(20) NOT NULL,  
    CONSTRAINT fecha_pkey PRIMARY KEY (fecha_id)
)

CREATE TABLE DIMENSION_DURACION
(
    duracion_id integer NOT NULL DEFAULT nextval('DIMENSION_LUGAR_lugar_id_seq'::regclass),
    cantidad integer NOT NULL,
    CONSTRAINT duracion_pkey PRIMARY KEY (duracion_id)
)

CREATE TABLE HECHOS_ALQUILER 
(
	pelicula_id integer NOT NULL,
	fecha_id integer NOT NULL,
	lugar_id integer NOT NULL,
    lenguaje_id integer NOT NULL,
	duracion_id integer NOT NULL,
	numeroAlquileres integer NOT NULL,
	montoAlquileres numeric(5,2) NOT NULL
	CONSTRAINT pelicula_id_fkey FOREIGN KEY (pelicula_id)
        REFERENCES DIMENSION_PELICULA (pelicula_id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
	CONSTRAINT fecha_id_fkey FOREIGN KEY (fecha_id)
        REFERENCES DIMENSION_FECHA (fecha_id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
	CONSTRAINT lugar_id_fkey FOREIGN KEY (lugar_id)
        REFERENCES DIMENSION_LUGAR (lugar_id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
	CONSTRAINT lenguaje_id_fkey FOREIGN KEY (lenguaje_id)
        REFERENCES DIMENSION_LENGUAJE (lenguaje_id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
	CONSTRAINT duracion_id_fkey FOREIGN KEY (duracion_id)
        REFERENCES DIMENSION_DURACION (duracion_id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE RESTRICT
)


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
  SELECT h.numeroAlquileres 
  FROM HECHOS_ALQUILER h INNER JOIN DIMENSION_PELICULA p  ON h.pelicula_id=p.pelicula_id 
  WHERE p.categoria=categoria 
  GROUP BY p.categoria INTO ret;
RETURN ret;
END;
$BODY$ 
LANGUAGE plpgsql;


LANGUAGE plpgsql VOLATILE 

	
	
	
	
	
	
	