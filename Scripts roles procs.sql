
-- Creacion de roles

-- Role: "EMP"
-- DROP ROLE "EMP";

CREATE ROLE "EMP" WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION;
  
-- Role: "ADMIN"
-- DROP ROLE "ADMIN";

CREATE ROLE "ADMIN" WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION;

GRANT "EMP" TO "ADMIN";

-- USER: video
-- DROP USER video;

CREATE USER video WITH
  NOLOGIN
  NOSUPERUSER
  INHERIT
  CREATEDB
  CREATEROLE
  NOREPLICATION;
  
-- User: empleado1
-- DROP USER empleado1;

CREATE USER empleado1 WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  PASSWORD '1234';

GRANT "EMP" TO empleado1;

-- User: administrador1
-- DROP USER administrador1;

CREATE USER administrador1 WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  PASSWORD '1234';

GRANT "ADMIN" TO administrador1;


-- FUNCTION: public.insert_customer(smallint, character varying, character varying, character varying, smallint, integer)

-- DROP FUNCTION public.insert_customer(smallint, character varying, character varying, character varying, smallint, integer);

CREATE OR REPLACE FUNCTION public.insert_customer(
	store_ids smallint,
	first_names character varying,
	last_names character varying,
	emails character varying,
	actives integer,
	address01 character varying(50),
    address02 character varying(50),
    districts character varying(20),
    city_ids smallint,
    postal_codes character varying(10),
    phones character varying(20))
    RETURNS void
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$

 BEGIN
 INSERT INTO public.address(address, address2, district, city_id, postal_code, phone)
	VALUES (address01, address02, districts, city_ids, postal_codes, phones);
 INSERT INTO public.customer(store_id, first_name, last_name, email,address_id,active)
	VALUES (store_ids, first_names, last_names, emails, (SELECT address_id FROM ADDRESS ORDER By address_id DESC LIMIT 1),actives);
END;
$BODY$;

-- FUNCTION: public.insert_rental(integer, smallint, smallint)

-- DROP FUNCTION public.insert_rental(integer, smallint, smallint);

--FALTA VERIFICAR QUE EL CODIGO DE LA PELOCULA QUE SE VA A RENTAR NO ESTE RENTADA
CREATE OR REPLACE FUNCTION public.insert_rental(
	inventory_ids integer,
	customer_ids smallint,
	staff_ids smallint)
    RETURNS void
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$

 BEGIN
INSERT INTO public.rental(rental_date, inventory_id, customer_id, staff_id)
	VALUES (now():: timestamp without time zone, inventory_ids, customer_ids, staff_ids);
END;

$BODY$;

-- FUNCTION: public.register_return(character varying, character varying)

-- DROP FUNCTION public.register_return(character varying, character varying);

CREATE OR REPLACE FUNCTION public.register_return(
	first_names character varying,
	last_names character varying,
	inventory_ids integer)
	
    RETURNS void
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$

 BEGIN
UPDATE public.rental
	SET return_date=now():: timestamp without time zone,last_update=now():: timestamp without time zone
	WHERE rental.customer_id=(SELECT customer_id FROM CUSTOMER 
							WHERE CUSTOMER.first_name=first_names AND CUSTOMER.last_name=last_names)
							AND rental.inventory_id=inventory_ids;
END;

$BODY$;

CREATE OR REPLACE FUNCTION public.insert_movie(
	movie character varying(255),
    descriptions text,
    release_years year,
    language  character varying(20),
    rental_durations smallint,
    rental_rates numeric(4,2),
    lengths smallint,
    replacement_costs numeric(5,2),
    ratings mpaa_rating,
    specials_features text[],
    fulltexts tsvector,
	copies_number integer,
	store_ids integer)

    RETURNS void
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$


BEGIN
 IF (rental_durations=0 AND rental_rates=0 AND replacement_costs=0 AND ratings=''::mpaa_rating) THEN
	INSERT INTO public.film(title, description, release_year,language_id, length,special_features, fulltext)
	VALUES (movie, descriptions, release_years, (SELECT language_id 
					  FROM LANGUAGE 
					  WHERE language=name), lengths, specials_features, fulltext);
 ELSIF (rental_rates=0 AND replacement_costs=0 AND ratings=''::mpaa_rating) THEN
	INSERT INTO public.film(title, description, release_year,language_id,rental_duration, length,special_features, fulltext)
	VALUES (movie, descriptions, release_years, (SELECT language_id 
					  FROM LANGUAGE 
					  WHERE language=name),rental_durations, lengths, specials_features, fulltext);
ELSIF (rental_durations=0  AND replacement_costs=0 AND ratings=''::mpaa_rating) THEN
	INSERT INTO public.film(title, description, release_year,language_id,rental_rate, length,special_features, fulltext)
	VALUES (movie, descriptions, release_years, (SELECT language_id 
					  FROM LANGUAGE 
					  WHERE language=name),rental_rates, lengths, specials_features, fulltext);
 ELSIF (rental_durations=0 AND rental_rates=0 AND ratings=''::mpaa_rating) THEN
	INSERT INTO public.film(title, description, release_year,language_id, length,replacement_cost,special_features, fulltext)
	VALUES (movie, descriptions, release_years, (SELECT language_id 
					  FROM LANGUAGE 
					  WHERE language=name), lengths,replacement_costs, specials_features, fulltext);
 ELSIF (rental_durations=0 AND rental_rates=0 AND replacement_costs=0) THEN
	INSERT INTO public.film(title, description, release_year,language_id, length,rating,special_features, fulltext)
	VALUES (movie, descriptions, release_years, (SELECT language_id 
					  FROM LANGUAGE 
					  WHERE language=name), lengths,ratings, specials_features, fulltext);
 ELSIF (replacement_costs=0 AND ratings=''::mpaa_rating) THEN
	INSERT INTO public.film(title, description, release_year,language_id,rental_duration,rental_rate, length,special_features, fulltext)
	VALUES (movie, descriptions, release_years, (SELECT language_id 
					  FROM LANGUAGE 
					  WHERE language=name),rental_durations,rental_rates, lengths, specials_features, fulltext);
 ELSIF (rental_rates=0 AND ratings=''::mpaa_rating) THEN
	INSERT INTO public.film(title, description, release_year,language_id,rental_duration, length,replacement_cost,special_features, fulltext)
	VALUES (movie, descriptions, release_years, (SELECT language_id 
					  FROM LANGUAGE 
					  WHERE language=name),rental_durations, lengths,replacement_costs, specials_features, fulltext);
 ELSIF (rental_rates=0 AND replacement_costs=0) THEN
	INSERT INTO public.film(title, description, release_year,language_id,rental_duration, length,rating,special_features, fulltext)
	VALUES (movie, descriptions, release_years, (SELECT language_id 
					  FROM LANGUAGE 
					  WHERE language=name),rental_durations, lengths,ratings, specials_features, fulltext);
 ELSIF (rental_durations=0 AND ratings=''::mpaa_rating) THEN
	INSERT INTO public.film(title, description, release_year,language_id,rental_rate, length,replacement_cost,special_features, fulltext)
	VALUES (movie, descriptions, release_years, (SELECT language_id 
					  FROM LANGUAGE 
					  WHERE language=name),rental_rates, lengths,replacement_costs, specials_features, fulltext);
 ELSIF (rental_durations=0 AND replacement_costs=0) THEN
	INSERT INTO public.film(title, description, release_year,language_id,rental_rate, length,rating,special_features, fulltext)
	VALUES (movie, descriptions, release_years, (SELECT language_id 
					  FROM LANGUAGE 
					  WHERE language=name),rental_rates, lengths,ratings, specials_features, fulltext);
 ELSIF (rental_durations=0 AND rental_rates=0) THEN
	INSERT INTO public.film(title, description, release_year,language_id, length,replacement_cost,rating,special_features, fulltext)
	VALUES (movie, descriptions, release_years, (SELECT language_id 
					  FROM LANGUAGE 
					  WHERE language=name),lengths,replacement_costs,ratings, specials_features, fulltext);
 ELSIF (rental_durations=0 ) THEN
	INSERT INTO public.film(title, description, release_year,language_id,rental_rate, length,replacement_cost,rating,special_features, fulltext)
	VALUES (movie, descriptions, release_years, (SELECT language_id 
					  FROM LANGUAGE 
					  WHERE language=name),rental_rates,lengths,replacement_costs,ratings, specials_features, fulltext);
 ELSIF (rental_rates=0 ) THEN
	INSERT INTO public.film(title, description, release_year,language_id,rental_duration, length,replacement_cost,rating,special_features, fulltext)
	VALUES (movie, descriptions, release_years, (SELECT language_id 
					  FROM LANGUAGE 
					  WHERE language=name),rental_durations,lengths,replacement_costs,ratings, specials_features, fulltext);
 ELSIF (replacement_costs=0 ) THEN
	INSERT INTO public.film(title, description, release_year,language_id,rental_duration,rental_rate, length,rating,special_features, fulltext)
	VALUES (movie, descriptions, release_years, (SELECT language_id 
					  FROM LANGUAGE 
					  WHERE language=name),rental_durations,rental_rates,lengths,ratings, specials_features, fulltext);
 ELSIF (ratings=''::mpaa_rating) THEN
	INSERT INTO public.film(title, description, release_year,language_id,rental_duration,rental_rate, length,replacement_cost,special_features, fulltext)
	VALUES (movie, descriptions, release_years, (SELECT language_id 
					  FROM LANGUAGE 
					  WHERE language=name),rental_durations,rental_rates,lengths,replacement_costs, specials_features, fulltext);
 ELSE
	INSERT INTO public.film(title, description, release_year,language_id,rental_duration,rental_rate, length,replacement_cost,rating,special_features, fulltext)
	VALUES (movie, descriptions, release_years, (SELECT language_id 
					  FROM LANGUAGE 
					  WHERE language=name),rental_durations,rental_rates,lengths,replacement_costs,ratings, specials_features, fulltext);
 END IF;	
 FOR i IN 1..copies_number LOOP
	INSERT INTO public.inventory(film_id, store_id)
	VALUES ((SELECT film_id
			 FROM FILM 
			WHERE movie=title), store_ids);
	
 END LOOP;
END;
$BODY$;



-- FUNCTION: public.insert_inventory(integer, smallint, smallint, timestamp without time zone)

-- DROP FUNCTION public.insert_inventory(integer, smallint, smallint, timestamp without time zone);

CREATE OR REPLACE FUNCTION public.insert_inventory(
	inventory_id integer,
	film_id smallint,
	store_id smallint,
	last_update timestamp without time zone)
    RETURNS void
    LANGUAGE 'sql'

    COST 100
    VOLATILE 
AS $BODY$

INSERT INTO public.inventory(
	inventory_id, film_id, store_id, last_update)
	VALUES (inventory_id, film_id, store_id, last_update);

$BODY$;

ALTER FUNCTION public.insert_inventory(integer, smallint, smallint, timestamp without time zone)
    OWNER TO video;

-- Asignacion de permisos 
GRANT EXECUTE ON FUNCTION insert_customer,insert_rental,register_return,film_in_stock TO "EMP";
GRANT EXECUTE ON FUNCTION insert_customer,insert_movie,insert_inventory TO "ADMIN";

--asignacion de dueño 

ALTER TABLE actor OWNER TO video; 
ALTER TABLE address OWNER TO video; 
ALTER TABLE category OWNER TO video; 
ALTER TABLE city OWNER TO video; 
ALTER TABLE country OWNER TO video; 
ALTER TABLE customer OWNER TO video; 
ALTER TABLE film OWNER TO video; 
ALTER TABLE film_actor OWNER TO video; 
ALTER TABLE film_category OWNER TO video; 
ALTER TABLE inventory OWNER TO video; 
ALTER TABLE language OWNER TO video; 
ALTER TABLE payment OWNER TO video; 
ALTER TABLE rental OWNER TO video; 
ALTER TABLE staff OWNER TO video; 
ALTER TABLE store OWNER TO video; 

ALTER FUNCTION _group_concat OWNER TO video;
ALTER FUNCTION film_in_stock OWNER TO video;
ALTER FUNCTION film_not_in_stock OWNER TO video;
ALTER FUNCTION get_customer_balance OWNER TO video;
ALTER FUNCTION insert_customer OWNER TO video;
ALTER FUNCTION insert_movie OWNER TO video;
ALTER FUNCTION insert_inventory OWNER TO video;
ALTER FUNCTION insert_rental OWNER TO video;
ALTER FUNCTION inventory_held_by_customer OWNER TO video;
ALTER FUNCTION inventory_in_stock OWNER TO video;
ALTER FUNCTION last_day OWNER TO video;
ALTER FUNCTION register_return OWNER TO video;
ALTER FUNCTION rewards_report OWNER TO video;

