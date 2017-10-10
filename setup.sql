-- ----------------------------------------------------------------------------
-- setup template database
CREATE EXTENSION IF NOT EXISTS unaccent;
ALTER TEXT SEARCH DICTIONARY unaccent (RULES='translit');
CREATE EXTENSION IF NOT EXISTS ltree;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_buffercache;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

CREATE OR REPLACE LANGUAGE plpgsql;
-- CREATE OR REPLACE LANGUAGE plperl;

ALTER SYSTEM SET track_functions = 'all';
 
-- Register as template
UPDATE pg_database SET datistemplate = TRUE WHERE datname=current_database();
