-- ----------------------------------------------------------------------------
-- setup template database
CREATE EXTENSION IF NOT EXISTS unaccent;
ALTER TEXT SEARCH DICTIONARY unaccent (RULES='translit');
CREATE EXTENSION IF NOT EXISTS ltree;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_buffercache;

CREATE OR REPLACE LANGUAGE plpgsql;
CREATE OR REPLACE LANGUAGE plperl;
