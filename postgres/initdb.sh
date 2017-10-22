psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE USER datastore WITH PASSWORD 'datastore';
    ALTER USER datastore WITH login;
    CREATE DATABASE datastore_default;
    GRANT ALL PRIVILEGES ON DATABASE datastore_default TO datastore;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" datastore_default <<-EOSQL
    REVOKE CREATE ON SCHEMA public FROM PUBLIC;
    REVOKE USAGE ON SCHEMA public FROM PUBLIC;

    GRANT CREATE ON SCHEMA public TO "ckan";
    GRANT USAGE ON SCHEMA public TO "ckan";

    GRANT CREATE ON SCHEMA public TO "ckan";
    GRANT USAGE ON SCHEMA public TO "ckan";

    REVOKE CONNECT ON DATABASE "ckan" FROM "datastore";

    GRANT CONNECT ON DATABASE "datastore_default" TO "datastore";
    GRANT USAGE ON SCHEMA public TO "datastore";

    GRANT SELECT ON ALL TABLES IN SCHEMA public TO "datastore";

    ALTER DEFAULT PRIVILEGES FOR USER "ckan" IN SCHEMA public
    GRANT SELECT ON TABLES TO "datastore";

    CREATE OR REPLACE VIEW "_table_metadata" AS
        SELECT DISTINCT
            substr(md5(dependee.relname || COALESCE(dependent.relname, '')), 0, 17) AS "_id",
            dependee.relname AS name,
            dependee.oid AS oid,
            dependent.relname AS alias_of
            -- dependent.oid AS oid
        FROM
            pg_class AS dependee
            LEFT OUTER JOIN pg_rewrite AS r ON r.ev_class = dependee.oid
            LEFT OUTER JOIN pg_depend AS d ON d.objid = r.oid
            LEFT OUTER JOIN pg_class AS dependent ON d.refobjid = dependent.oid
        WHERE
            (dependee.oid != dependent.oid OR dependent.oid IS NULL) AND
            (dependee.relname IN (SELECT tablename FROM pg_catalog.pg_tables)
                OR dependee.relname IN (SELECT viewname FROM pg_catalog.pg_views)) AND
            dependee.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname='public')
        ORDER BY dependee.oid DESC;
    ALTER VIEW "_table_metadata" OWNER TO "ckan";
    GRANT SELECT ON "_table_metadata" TO "datastore";
EOSQL