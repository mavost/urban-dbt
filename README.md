# A simple dbt working environment

*Date:* 2024-05-07  
*Author:* MvS  
*keywords:* data engineering, dbt, data build tool, linter

## Description

An enhanced working environment to develop and deploy dbt models using code quality tooling
for its various moving parts.

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

## Simple Example

1. Either use a pre-existing database connection or set up a docker container, e.g.,
with a postgreSQL instance, admin role credentials and connection string should used
to connect to any DB admin tool of choice, e.g., [DBeaver](https://dbeaver.io/).

2. (Optional): Creating a new dbt project:
    - For *dbt_toy_model*, create **source** schema on database instance and populate it
    with a table containing some data, see [script](./scripts/00_source.sql).

    - Create a project folder *<project_name>* to host all dbt data engineering and use this directory.

    - Run `dbt init`and fill out the required info on DB connectivity, specify *<project_name>* and **target** schema which dbt will work on, pulling data from the **source**. A project environment will created in the directory and a `~/.dbt/profile.yml` will store the connectivity information. Both will be linked via a `dbt_project.yml` file in the project root.

3. Run `cd <project_name> && dbt debug` to verify that the connection to the postgres instance is working.

4. Observe the nested configuration between `*.yml` files where more general options can
be overwritten by more nested options within the model layers.

5. Run  `dbt run --select "models/example/my_first_dbt_model.sql"` for a "hello world" experience.

## A more elaborate example

1. Switch directory to the `jaffle_shop-dev` model

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

- Automatic code reformatting following PEP8 using [black](https://black.readthedocs.io/en/stable/index.html),

  - Invoked manually via,`black .`

- Linting using [flake8](https://github.com/PyCQA/flake8),

  - Flake8 linter integrated in aforementioned git hooks (and configured in *setup.cfg*)

- Using [sqlfluff](https://docs.sqlfluff.com/en/stable/) as a linter will boost the dbt
code quality especially given the lack of enforced standardization and evolving SQL habits
within a dev team:

  - Start with package installation

    ```shell
    source <dbt-env>
    pip install sqlfluff sqlfluff-templater-dbt
    ```

  - Add a `.sqlfluff` config file to the project root:

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

- [Pre-commit](https://pre-commit.com/) hooks to check for fundamental issues with the code base
  before adding them to git,

  - Invoked manually via, `pre-commit run --all-files`.

## References

- [SQL commands](https://docs.getdbt.com/sql-reference) in dbt
- [time-related macros for dbt](https://hub.getdbt.com/calogica/dbt_date/latest/)
- [dbt jaffle-shop example](https://github.com/dbt-labs/jaffle-shop)
