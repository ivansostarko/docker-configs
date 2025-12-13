-- Runs only on first init of an empty data dir.
-- Safe baseline extensions commonly used by GitLab.
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gist;
