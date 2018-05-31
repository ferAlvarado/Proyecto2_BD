--Para empezar, si se quiere probar en la misma maquina deben haber 2 instancias de la BD corriendo. Lo definimos de esta manera:
-- Creacion:
-- initdb -D /path/to/datadb1
-- initdb -D /path/to/datadb2
--
-- Inicializacion en puertos 5433 y 5434:
-- pg_ctl -D /path/to/datadb1 -o "-p 5433" -l /path/to/logdb1 start
-- pg_ctl -D /path/to/datadb2 -o "-p 5434" -l /path/to/logdb2 start
--
-- Conexion:
-- psql -p 5433 -d [nombre de bd]
-- psql -p 5434 -d [nombre de bd]

==================EN DB FUENTE
CREATE ROLE replicator REPLICATION LOGIN PASSWORD '1234';

CREATE PUBLICATION bpub FOR TABLE actor,address,category,city,country,customer,film,film_actor,film_category,inventory,language,payment,rental,staff,store;

GRANT ALL ON actor,address,category,city,country,customer,film,film_actor,film_category,inventory,language,payment,rental,staff,store TO replicator;


==================EN DB DESTINO

CREATE SUBSCRIPTION bsub
CONNECTION 'dbname=peliculas host=localhost
port=5433 user=replicator
password=1234'
PUBLICATION bpub;