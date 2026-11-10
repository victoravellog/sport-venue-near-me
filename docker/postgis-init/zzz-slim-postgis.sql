-- The postgis/postgis image enables postgis_topology, fuzzystrmatch and
-- postgis_tiger_geocoder on the default database. This app only needs core
-- PostGIS (geometry + ST_* functions), so drop the extras on fresh init to
-- keep the schema (and structure.sql) lean.
--
-- Runs after the image's own init scripts (filename sorts last).

DROP EXTENSION IF EXISTS postgis_tiger_geocoder CASCADE;
DROP EXTENSION IF EXISTS postgis_topology CASCADE;
DROP EXTENSION IF EXISTS fuzzystrmatch CASCADE;

DROP SCHEMA IF EXISTS tiger CASCADE;
DROP SCHEMA IF EXISTS tiger_data CASCADE;
DROP SCHEMA IF EXISTS topology CASCADE;

-- The image also set the database search_path to include topology/tiger; reset it
-- so structure.sql does not reference dropped schemas.
DO $do$
BEGIN
  EXECUTE format('ALTER DATABASE %I SET search_path TO %s', current_database(), '"$user", public');
END
$do$;
