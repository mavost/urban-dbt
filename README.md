# A simple dbt experiment

*Date:* 2024-01-18  
*Author:* MvS  
*keywords:* data engineering, dbt, data build tool

## Description

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

## Helpers

- Install the command completion for dbt as specified, [here](https://github.com/dbt-labs/dbt-completion.bash).

    ```bash
    cd ~
    curl https://raw.githubusercontent.com/fishtown-analytics/dbt-completion.bash/master/dbt-completion.bash > ~/.dbt-completion.bash
    echo 'source ~/.dbt-completion.bash' >> ~/.bash_profile
    ```
