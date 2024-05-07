# A simple dbt experiment

*Date:* 2024-01-18  
*Author:* MvS  
*keywords:* data engineering, dbt, data build tool

## Description

## General tool setup

## Simple Example

1. Set up a docker container with a postgres container instance, admin role credentials and connection string should used
to connect to any DB admin tool of choice, e.g., [DBeaver](https://dbeaver.io/).

2. Create **source** schema on local instance and populate it with a table and some data, see [script](./scripts/00_source.sql).

3. Create a repository or project folder to host all data engineering and use this directory.

4. Run `dbt init`and fill out the required info on DB connectivity, specify **project name** and **target** schema which dbt will work on, pulling
data from the **source**. A project environment will created in the directory and a `~/.dbt/profile.yml` will store the connectivity information.
Both will be linked via a `dbt_project.yml` file in the project root.

5. Run `cd <project_name> && dbt debug` to verify that the connection to the postgres instance is working.

6. Observe the nested configuration between `*.yml` files where more general options can
be overwritten by more nested options within the model layers.

7. Run  `dbt run --select "models/example/my_first_dbt_model.sql"` for a "hello world" experience.

## A more elaborate example

1. Switch directory to the `jaffle_shop-dev` model

## Helpers

1. Install the command completion for dbt as specified, [here](https://github.com/dbt-labs/dbt-completion.bash).

    ```bash
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

- [Pre-commit](https://pre-commit.com/) hooks to check for fundamental issues with the code base before adding them to git,

  - Invoked manually via, `pre-commit run --all-files`.

- Automatic code reformatting following PEP8 using [black](https://black.readthedocs.io/en/stable/index.html),

  - Invoked manually via,`black .`

- Linting using [flake8](https://github.com/PyCQA/flake8),

  - Flake8 linter integrated in aforementioned git hooks (and configured in *setup.cfg*)

- Using a linter like *sqlfluff* will boost the code quality especially given the lack of enforced standardization
and evolving SQL habits within a dev team:

  - Start with package installation

    ```bash
    source <dbt-env>
    pip install sqlfluff sqlfluff-templater-dbt
    ```

  - Add a `.sqlfluff` config file to the project root, see, `jaffle_shop-dev`:

    ```bash
    [sqlfluff]
    dialect = postgres
    templater = dbt
    runaway_limit = 10
    max_line_length = 80
    indent_unit = space

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

  - Add a `.sqlfluffingnore` config file to the project root, see, `jaffle_shop-dev`:

    ```bash
    dbt_packages/
    target/
    ```

  - From the dbt project root, either invole `sqlfluff lint` to list the code quality issues in the
  current version of the SQL code or run `sqlfluff fix` to auto-correct the issues on the fly.
  Note, that some issues need to be fixed manually.

## References

- [SQL commands](https://docs.getdbt.com/sql-reference) in dbt
- [time-related macros for dbt](https://hub.getdbt.com/calogica/dbt_date/latest/)
- [dbt jaffle-shop example](https://github.com/dbt-labs/jaffle-shop)
