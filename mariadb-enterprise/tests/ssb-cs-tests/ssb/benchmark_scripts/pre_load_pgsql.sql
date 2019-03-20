createdb ssb;
psql -l
psql -U gpadmin ssb
DROP SCHEMA IF EXISTS orders CASCADE;
CREATE SCHEMA orders;
SET SEARCH_PATH TO orders, public, pg_catalog, gp_toolkit;
SHOW search_path;
ALTER ROLE gpadmin SET search_path TO orders, public, pg_catalog, gp_toolkit;
alter database ssb SET search_path TO orders, public, pg_catalog;

/*The default resource queue, pg_default, allows a maximum of 20 active queries and allocates the same amount of memory to each.*/
ALTER RESOURCE QUEUE pg_default WITH (ACTIVE_STATEMENTS=64);
