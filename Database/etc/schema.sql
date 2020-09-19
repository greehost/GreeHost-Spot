CREATE EXTENSION IF NOT EXISTS citext;

-- Session Table Removed - See https://metacpan.org/pod/Catalyst::Plugin::Session::Store::Cookie
-- for the new state.

CREATE TABLE person (
    id                          serial          PRIMARY KEY,
    name                        text            not null,
    email                       citext          not null unique,
    is_enabled                  boolean         not null default true,
    created_at                  timestamptz     not null default current_timestamp
);
--
-- Settings for a given user.  | Use with care, add things to the data model when you should.
-- 
create TABLE person_settings (
    id                          serial          PRIMARY KEY,
    person_id                   int             not null references person(id),
    name                        text            not null,
    value                       json            not null default '{}',
    created_at                  timestamptz     not null default current_timestamp,

    -- Allow ->find_or_new_related()
    CONSTRAINT unq_person_id_name UNIQUE(person_id, name)
);

CREATE TABLE auth_password (
    person_id                   int             not null unique references person(id),
    password                    text            not null,
    salt                        text            not null,
    updated_at                  timestamptz     not null default current_timestamp,
    created_at                  timestamptz     not null default current_timestamp
);

CREATE TABLE project (
    id                          serial          PRIMARY KEY,
    owner_id                    int             not null references person(id),
    name                        text            not null,
    description                 text            not null,
    repository                  text            not null,
    ssh_key                     text            ,
    password                    text            ,
    created_at                  timestamptz     not null default current_timestamp
);

--
-- Settings for a given project. | Use with care, add things to the data model when you should.
-- 
create TABLE project_settings (
    id                          serial          PRIMARY KEY,
    project_id                  int             not null references project(id),
    name                        text            not null,
    value                       json            not null default '{}',
    created_at                  timestamptz     not null default current_timestamp,

    -- Allow ->find_or_new_related()
    CONSTRAINT unq_project_id_name UNIQUE(project_id, name)
);

CREATE TABLE ssl_store_provider (
    id                          serial          PRIMARY KEY,
    name                        text            not null,
    created_at                  timestamptz     not null default current_timestamp
);    

CREATE TABLE ssl_store (
    id                          serial          PRIMARY KEY,
    owner_id                    int             not null references person(id),
    name                        text            not null,
    domains                     text[]          not null default '{}',
    provider_id                 int             not null references ssl_store_provider(id),
    credentials                 json            not null default '{}',
    created_at                  timestamptz     not null default current_timestamp
);

INSERT INTO ssl_store_provider (name) VALUES( 'linode');
