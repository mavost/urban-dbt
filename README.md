# A simple dbt working environment

*Date:* 2024-05-07  
*Author:* MvS  
*keywords:* data engineering, dbt, data build tool, linter

## Description

An enhanced working environment to develop and deploy dbt models using code quality tooling
for its various moving parts.

The description from the [project website](https://docs.getdbt.com/docs/introduction) sums it up perfectly:

> dbt is a transformation workflow that helps you get more work done while producing higher quality results. You can use dbt to modularize and centralize your analytics code, while also providing your data team with guardrails typically found in software engineering workflows. Collaborate on data models, version them, and test and document your queries before safely deploying them to production, with monitoring and visibility.
>
> dbt compiles and runs your analytics code against your data platform, enabling you and your team to collaborate on a single source of truth for metrics, insights, and business definitions. This single source of truth, combined with the ability to define tests for your data, reduces errors when logic changes, and alerts you when issues arise.

## Prerequisites

- This project was created on Ubuntu flavor linux,
- using Python version 3.10,
- a Node installation v.18.18 or greater, see `nvm ls`,
- and Gnu make.
- We assume that either the `~/.dbt/profile.yml` will point to a working data
storage or the developer is familiar with setting up, e.g., a docker container with a postgreSQL
instance on his laptop.

## General tool setup

- Run `make help` to get an overview of various helper functions.
- Run `make setup-env` to install a python environment into the git project which will
include the relevant dependencies.
- Run `make dbt_debug` to check the configuration of the default showcase dbt project.

## Simple Example (pg_source)

1. Either use a pre-existing database connection or set up a docker container, e.g.,
with a postgreSQL instance, admin role credentials and connection string should used
to connect to any DB admin tool of choice, e.g., [DBeaver](https://dbeaver.io/).

2. (Optional): Creating a new dbt project:
    - For *dbt_toy_model*, create **source** schema on database instance and populate it
    with a table containing some data, see [script](./scripts/00_source.sql).

    - Create a project folder *<project_name>* to host all dbt data engineering and use this directory.

    - Run `dbt init`and fill out the required info on DB connectivity, specify *<project_name>* and **target** schema which dbt will work on, pulling data from the **source**. A project environment will created in the directory and a `~/.dbt/profile.yml` will store the connectivity information. Both will be linked via a `dbt_project.yml` file in the project root.

3. Run `cd pg_source && dbt debug` to verify that the connection to the postgres instance is working.

4. Observe the fine-grained configuration options within each `*.yml` file which can overwrite more nested options
within the more genral model layers definitions.

5. Run  `dbt run --select "models/example/my_first_dbt_model.sql"` for a "hello world" experience.

6. After a run has concluded it would be appropriate to use a testing workflow to verify the integrity
of the layers and tables generated, e.g., `dbt test --select "models/example/my_first_dbt_model.sql"` invoking
generic tests on certain fields of a table. The testing criteria are specified in the `schema.yml` of the respective data model component. There are options for singular test cases, generic test cases,
and unit tests.

7. Run `dbt deps` to install additional modules, specified in `packages.yml` which provide advanced
functionality beyond the scope of `dbt-core`, e.g. timestamp functions of the `dbt_date` package.

## A more elaborate example (jaffle_shop-dev)

This project has been taken from dbt's [Github](https://github.com/clrcrl/jaffle_shop) page and slightly extended:

1. Switch directory to the dbt model and confirm that the connection is working:
`cd jaffle_shop-dev && dbt debug`

2. Note that for most commands a target woudatabase has to be specified, e.g., `dbt run --target dev`.
In the `~/.dbt/profiles.yml` we can define connections `[local, dev, prod]` and default targets that would
usually point to `dev` or `local` instances.  
We would deploy to production after rigorous testing, only.

3. To source a simple start schema data mart we upload, or *seed*, a set of `*.csv` data files
found in the `./seeds` folder to the database using `dbt seed`. This simulates the landing stage
of the data lake/warehouse.

4. We build the full data model by calling `dbt run` which will try to create all subsequent tables and views
based on the specification found in `./models` consisting of `*.sql`, `*.yaml` definitions and jinja templating
configuration. We can use a command like `dbt run --select staging` to construct only parts of the model up to a certain level or to re-create a particular table.

5. We can do a dry-run of the `dbt run`, e.g., by calling `dbt show --select "model_name.sql"` which
will run the query against the database but not write to the database. We can also run ad-hoc queries
against the DB `dbt show --inline "select * from {{ ref('raw_customers') }}"`.

6. A powerful feature of dbt is the automatic generation of structured documentation for each *model
realization* based on the technology used. In this way the documentation for the production database
will differ from the development instance, e.g., postgreSQL (dev) and snowflake (prod).
Use `dbt docs generate --target dev` to generate/update the files.
You can even run `dbt docs serve --target dev` to create a local [website](http://localhost:8080/#!/overview)
to be displayed in the web browser. Noteworthy files are:

    - `manifest.json`: Containing a full representation of your dbt project's resources (models, tests, macros, etc).

    - `catalog.json`: Serves information about the tables and views produced and defined by the resources in your project.

## Helpers

1. Install the command completion for dbt as specified, [here](https://github.com/dbt-labs/dbt-completion.bash).

    ```shell
    cd ~
    curl https://raw.githubusercontent.com/fishtown-analytics/dbt-completion.bash/master/dbt-completion.bash > ~/.dbt-completion.bash
    echo 'source ~/.dbt-completion.bash' >> ~/.bash_profile
    ```

2. When using VScode install the extension [Power User for dbt Core](https://marketplace.visualstudio.com/items?itemName=innoverio.vscode-dbt-power-user) or something similar.

3. Install a package by adding a `packages.yml` to the dbt project root and pull it into the project by running `dbt deps`.
The template engine will now offer the respective macro functionality.

## Observations

- [notes on auto-increment](https://discourse.getdbt.com/t/can-i-create-an-auto-incrementing-id-in-dbt/579/2)

## Features

Convenience features included were:

- A [Makefile](https://www.gnu.org/software/make/manual/) to set up the environments and call the features below.

- Automatic Python code reformatting following PEP8 using [black](https://black.readthedocs.io/en/stable/index.html),

  - Invoked and applied manually via, `black .` and as a dry run using `black --check .`

- Python code linting using [flake8](https://github.com/PyCQA/flake8),

  - Flake8 linter integrated in aforementioned git hooks (and configured in *setup.cfg*)

- Using [sqlfluff](https://docs.sqlfluff.com/en/stable/) as a linter will boost the dbt
code quality especially given the lack of enforced standardization and evolving SQL habits
within a dev team:

  - Start with package installation

    ```shell
    source <dbt-env>
    pip install sqlfluff sqlfluff-templater-dbt
    ```

  - Add a `.sqlfluff` config file to the project root. Note: the SQL dialect and the project dir need to match the technologies used in the backend. ToDo: use jinja templating to add flexibility:

    ```yaml
    [sqlfluff]
    dialect = postgres
    templater = dbt
    runaway_limit = 10
    max_line_length = 80
    indent_unit = space

    [sqlfluff:templater:dbt]
    project_dir = <dbt_project-dir>

    [sqlfluff:indentation]
    tab_space_size = 4

    [sqlfluff:layout:type:comma]
    spacing_before = touch
    line_position = trailing

    [sqlfluff:rules:capitalisation.keywords] 
    capitalisation_policy = lower

    [sqlfluff:rules:aliasing.table]
    aliasing = explicit

    [sqlfluff:rules:aliasing.column]
    aliasing = explicit

    [sqlfluff:rules:aliasing.expression]
    allow_scalar = False

    [sqlfluff:rules:capitalisation.identifiers]
    extended_capitalisation_policy = lower

    [sqlfluff:rules:capitalisation.functions]
    capitalisation_policy = lower

    [sqlfluff:rules:capitalisation.literals]
    capitalisation_policy = lower

    [sqlfluff:rules:ambiguous.column_references]  # Number in group by
    group_by_and_order_by_style = explicit
    ```

  - Add a `.sqlfluffingnore` config file to the project root:

    ```ignore
    **/dbt_packages/
    **/target/
    <python_env>/
    ```

  - From the git project root, either invoke `sqlfluff lint` to list the code quality issues in the
  current SQL code or run `sqlfluff fix` to auto-correct the issues on the fly.
  Note, that some quality issues will still have to be fixed manually but the linter will usually
  point to the right direction.

- [Prettier](https://prettier.io/) formatting of all `*.yaml` configuration files. Prettier's own configuration
is specified within the `.prettierrc` file.

  - A dry-run invoked manually via, `npx prettier . --check` and executed using `npx prettier . --write`.

- [Pre-commit](https://pre-commit.com/) hooks to check for fundamental issues with the code base
  before adding them to git,

  - Invoked manually via, `pre-commit run --all-files`.

## Further references

- [SQL commands](https://docs.getdbt.com/sql-reference) in dbt
- [time-related macros for dbt](https://hub.getdbt.com/calogica/dbt_date/latest/)
