\set previous_version 'v1.13.0-ee'
\set next_version 'v1.14.0-ee'
SELECT openreplay_version()                       AS current_version,
       openreplay_version() = :'previous_version' AS valid_previous,
       openreplay_version() = :'next_version'     AS is_next
\gset

\if :valid_previous
\echo valid previous DB version :'previous_version', starting DB upgrade to :'next_version'
BEGIN;
SELECT format($fn_def$
CREATE OR REPLACE FUNCTION openreplay_version()
    RETURNS text AS
$$
SELECT '%1$s'
$$ LANGUAGE sql IMMUTABLE;
$fn_def$, :'next_version')
\gexec

--

CREATE TABLE IF NOT EXISTS public.feature_flags
(
    feature_flag_id integer generated BY DEFAULT AS IDENTITY PRIMARY KEY,
    project_id      integer                     NOT NULL REFERENCES projects (project_id) ON DELETE CASCADE,
    name            text                        NOT NULL,
    flag_key        text                        NOT NULL,
    description     text                        NOT NULL,
    flag_type       text                        NOT NULL,
    is_persist      boolean                     NOT NULL DEFAULT FALSE,
    is_active       boolean                     NOT NULL DEFAULT FALSE,
    created_by      integer                     REFERENCES users (user_id) ON DELETE SET NULL,
    updated_by      integer                     REFERENCES users (user_id) ON DELETE SET NULL,
    created_at      timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at      timestamp without time zone NOT NULL DEFAULT timezone('utc'::text, now()),
    deleted_at      timestamp without time zone NULL     DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_feature_flags_project_id ON public.feature_flags (project_id);

CREATE TABLE IF NOT EXISTS public.feature_flags_conditions
(
    condition_id       integer generated BY DEFAULT AS IDENTITY PRIMARY KEY,
    feature_flag_id    integer NOT NULL REFERENCES feature_flags (feature_flag_id) ON DELETE CASCADE,
    name               text    NOT NULL,
    rollout_percentage integer NOT NULL,
    filters            jsonb   NOT NULL DEFAULT '[]'::jsonb
);

CREATE TABLE IF NOT EXISTS public.sessions_feature_flags
(
    session_id      bigint  NOT NULL REFERENCES sessions (session_id) ON DELETE CASCADE,
    feature_flag_id integer NOT NULL REFERENCES feature_flags (feature_flag_id) ON DELETE CASCADE,
    condition_id    integer NULL REFERENCES feature_flags_conditions (condition_id) ON DELETE SET NULL
);

UPDATE public.roles
SET permissions = (SELECT array_agg(distinct e) FROM unnest(permissions || '{FEATURE_FLAGS}') AS e)
where not permissions @> '{FEATURE_FLAGS}';

COMMIT;

\elif :is_next
\echo new version detected :'next_version', nothing to do
\else
\warn skipping DB upgrade of :'next_version', expected previous version :'previous_version', found :'current_version'
\endif