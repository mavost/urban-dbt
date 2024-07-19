# A customizable dbt working environment

*Date:* 2024-05-07  
*Author:* MvS  
*keywords:* data engineering, dbt, data build tool, data warehouse, linter, code style

## Description

An enhanced working environment to develop and deploy dbt models using code quality tooling
for its various moving parts.

The description from the [project website](https://docs.getdbt.com/docs/introduction) sums it up perfectly:

> dbt is a transformation workflow that helps you get more work done while producing higher quality results. You can use dbt to modularize and centralize your analytics code, while also providing your data team with guardrails typically found in software engineering workflows. Collaborate on data models, version them, and test and document your queries before safely deploying them to production, with monitoring and visibility.
>
> dbt compiles and runs your analytics code against your data platform, enabling you and your team to collaborate on a single source of truth for metrics, insights, and business definitions. This single source of truth, combined with the ability to define tests for your data, reduces errors when logic changes, and alerts you when issues arise.

## Prerequisites

This project was created for:

- Ubuntu linux but should be fairly easily portable to other OS'es.
- It uses Python version 3.10 in a separate [Python environment](https://docs.python.org/3/library/venv.html) which also supports [Jupyter notebooks](https://code.visualstudio.com/docs/datascience/jupyter-notebooks).
- [Node installation](https://bluevps.com/blog/how-to-install-nodejs-on-ubuntu-2204) v.18.18 or greater, see `nvm ls`,
- It also uses Gnu [make](https://www.gnu.org/software/make/) v. 4.3.

## General environment setup

- In the developer's home directory a [dbt connection file](https://docs.getdbt.com/docs/core/connect-data-platform/profiles.yml), called `profile.yml` will have to be set up.
- We assume that either the `~/.dbt/profile.yml` will point to a pre-existing relational DB/lake-/warehouse data storage or the developer is familiar with setting up, e.g., a [Docker](https://docs.docker.com/) container with a [postgreSQL](https://www.docker.com/blog/how-to-use-the-postgres-docker-official-image/) instance on his laptop.
- We advise to use admin role credentials on a dev DB instance for fast prototyping and reduce this to minimal CRUD permissions specifically to the AOI on a production system.
- We encourage to connect to any DB admin tool of choice, in parallel of the ongoing dbt coding, e.g., [DBeaver](https://dbeaver.io/). This can be used to test/filter new model components.
- The Makefile in the repository's root is designed to help set up and manage the development environment. It includes tasks for setting up the Python/Node environment and testing the executables for running linters, formatting code, and cleaning up:

  - `make setup_env`  
    Install local Python/Node environment with dbt, linters, etc. This Makefile target installs all necessary dependencies listed in `requirements-dbt.txt` and `package.json`.
  - `make verify_install`  
    Check environment installation and command versions.
  - `make clean`  
    Clean up environment files - removes the Python virtual environment and Node modules.

### Usage

Run `make <target>` to execute the desired target. For example, use `make setup_env` to set up the environment.

### Additional notes

- The environment variable `DBT_PROJECT_NAME` does not need to be changed here as each
dbt project contains its own Makefile for specific use with the Python/Node environment.

- This approach was chosen to allow an individual customization of `dbt run` / `dbt test` for each dbt project's data modelling layer structure.

## List of available dbt projects in this repository

### Simple example from initial configuration (pg_source)

This example follows the first steps to set up a new project and adds another transformation
using dbt macros, see, `./models/loading`. It does not contain another Makefile for the sake
of illustrating the main commands and simplicity.

1. Consider that the dbt environment has been set up correctly and a database connection has been established to a database with sufficient permissions to create schemas/tables/views.

2. Using your DB admin tool, manually create a `source` schema on the database instance in database *pg_source* and populate it with a table containing some data, see [script](./sql-scripts/00_source.sql).

3. (Skipable): Creating a new dbt project:

    - Create a project folder *<project_name>* to host all dbt data engineering and use this directory.
    - Run `dbt init`and fill out the required info on DB connectivity, specify *<project_name>* and **target** schema which dbt will work on, pulling data from the **source**. A project environment will created in the directory and a `~/.dbt/profile.yml` will store the connectivity information. Both will be linked via a `dbt_project.yml` file in the project root.

4. Run `cd pg_source && dbt debug` to verify that the connection to the postgres instance is working.

5. Observe the fine-grained, recursive configuration options within each `*.yml` file which can be overwritten by more deeply-nested model layers definitions.

6. Run  `dbt run --select "models/example/my_first_dbt_model.sql"` for a "hello world" experience.

7. After a run has concluded it would be appropriate to use a testing workflow to verify the integrity
of the layers and tables generated, e.g., `dbt test --select "models/example/my_first_dbt_model.sql"` invoking generic tests on certain fields of a table. The testing criteria are specified in the `schema.yml` of the respective data model component. There are options for singular test cases, generic test cases,
and unit tests.

8. Run `dbt deps` to install additional modules, specified in `packages.yml` which provide advanced
functionality beyond the scope of `dbt-core`, e.g. timestamp functions of the `dbt_date` package.
In this way another model can be run using `dbt run --select "models/loading/my_first_transformation.sql"`

### A more elaborate example from dbt's website (jaffle_shop)

This project has been taken from dbt's [Github](https://github.com/clrcrl/jaffle_shop) page and slightly extended:

1. Note, as mentioned before, that for most commands a target database has to be specified, e.g., `dbt run --target dev`. In the `~/.dbt/profiles.yml` we can define connections `[local, dev, prod]` and default targets that would usually point to `dev` or `local` instances.  
One should deploy new model code to production systems after rigorous testing, only.

2. Switch directory to the dbt model and confirm that the connection is working:
`cd jaffle_shop && dbt debug`

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

7. Quickly, also mentioning the `Makefile` in this project which carries more weight in larger dbt projects:

    - Running `make dbt_run_refresh` will fully seed, recreate, test each individual model stage, here, they are called
    *marts* and *staging* one after the other and stopping the build process upon failure.
    - Running `make dbt_run` will recreate and test the models only by their increment, which carries no weight in 
    this configuration. See [incremental loading](https://next.docs.getdbt.com/docs/build/incremental-models-overview) for further details.
    - All the code quality features found under `make help` are also available.

### Transactional data normalization and de-normalization (dbt_norm_table)

The data set used here contains transactional data from a retail store covering:

- Consists of 12 months of transactions, approx. 500k rows,
- It covers orders and partial cancellations/returns of orders,
- Approximately 4000 product items for home furnishings and decorations,
- Recurring orders by approx. 4000 customers from 30 countries.

It was kindly provided through the [Kaggle community](https://www.kaggle.com/datasets/ishanshrivastava28/tata-online-retail-dataset). It turned out that the data also contains
stock management information, when items were lost/destroyed/damaged.

To properly make use of these data it became apparent that a certain level data cleaning is required during
dbt's loading process.
The result of an explorative data analysis and wrangling can be found in `analyses/2024-07-17_preparing_seeds.ipynb`.
The seed files provided in `seeds/*csv` can be re-created using this notebook plus some feature engineering by LLMs.

In this project most things run out of the box, but some initial setup is required still:

1. The Kaggle data needs to be manually imported to the DB using a DB Admin tool and a scripted approach.
One can opt to either use the 500k rows of data as a whole or split them into packages defined by a time interval.
There is a [script](./sql-scripts/2024-07-08_dbt_norm_table---prep_source_data.sql) provided to facilitate that task.

2. Once the data is "manually" ingested it can be processed by pointing the `models/sources_properties.yml` to the proper
tables and selecting the respective references in `staging/0101_transactional_data.sql` and `staging/0102_transactional_nulls.sql`.
*We strongly advise to replicate the initial setup before making individual customizations*.

3. Similar to the previous project example there are `Makefile` targets to simplify a structurally consistent deployment:

    - Running `make dbt_run_refresh` will fully seed, recreate, test each individual model stage:  
    *stage*, *core*, *mart* and *stats* point to respective schemas in the DB instances database.
    The build process stops upon failure.
    - Running `make dbt_incremental` will add any data to realized models of that [flavor](https://next.docs.getdbt.com/docs/build/incremental-models-overview).
    The common scenario is that a new batch of ingest data only contains a few lines and does not require a full rebuild of the data model.
    We can either simulate this be adding a new set of data to the source table by SQL `INSERT` or by simulating a
    incremental condition, e.g. `make dbt_incremental REFRESH="--vars 'overlap_interval: \"2 Days\"'"` as this
    parameter has been coded into the incremental models for this show case.

4. All the code quality features found under `make help` are also available. We advise to employ `make sqlfluff_lint` and `make prettier_reformat`
ahead of a pull/merge request in order to bring consistency to the SQL/YAML code base.

## Additional helper functions

1. Install the command completion for dbt as specified, [here](https://github.com/dbt-labs/dbt-completion.bash).

    ```shell
    cd ~
    curl https://raw.githubusercontent.com/fishtown-analytics/dbt-completion.bash/master/dbt-completion.bash > ~/.dbt-completion.bash
    echo 'source ~/.dbt-completion.bash' >> ~/.bash_profile
    ```

2. When using VScode we recommend to install the dbt extension [Power User for dbt Core](https://marketplace.visualstudio.com/items?itemName=innoverio.vscode-dbt-power-user) to gain:

    - Code completion, function hinting, model references, etc.
    - Ability to run dbt model queries inside of VS code out of their respective `model.sql` file by <kbd>Ctrl</kbd> + <kbd>Return</kbd>.
    - Display of data lineage.
    - ...

3. Install a dbt packages like [dbt-utils](https://github.com/dbt-labs/dbt-utils) by adding a `packages.yml` or `dependencies.yml` to the dbt project root and pull it into the project by running `dbt deps`.
Shortly afterwards, the [Jinja templating](https://jinja.palletsprojects.com/en/3.1.x/) engine will offer the respective macro functionalities.

## Note on convenience features for happier coding

Convenience features included in this repo are:

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
- [notes on auto-increment](https://discourse.getdbt.com/t/can-i-create-an-auto-incrementing-id-in-dbt/579/2)
