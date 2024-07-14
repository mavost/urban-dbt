-- dbt tutorial
-- https://medium.com/israeli-tech-radar/first-steps-with-dbt-over-postgres-db-f6b350bf4526
CREATE SCHEMA IF NOT EXISTS source;

CREATE TABLE source.users (
 id bpchar(36) NULL,
 user_name varchar(60) null,
 email varchar(60) null
);

INSERT INTO "source".users
(id, user_name, email)
VALUES('1', 'jon', 'jon@acme.com');
INSERT INTO "source".users
(id, user_name, email)
VALUES('1', 'jane', 'jane@acme.com');