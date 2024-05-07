MAKEFLAGS += --warn-undefined-variables
.SHELLFLAGS := -eu -o pipefail -c

all: help
.PHONY: all, help, setup_env, black_dry, black_reformat, flake8_lint,\
sqlfluff_dry, sqlfluff_lint, prettier_dry, prettier_reformat,\
pre-commit-full, pre-commit-full, clean,\
dbt_debug

# Use bash for inline if-statements
SHELL:=bash
REQUIREMENTS = requirements-dbt.txt

VENV_NAME ?= dbt_env
DBT_PROJECT_NAME ?= jaffle_shop-dev

PYTHON = $(VENV_NAME)/bin/python
# absolute path as we are calling dbt from its project dir
DBT = cd $(DBT_PROJECT_NAME) && $(shell pwd)/$(VENV_NAME)/bin/dbt
FLAKE8 = $(VENV_NAME)/bin/flake8
BLACK = $(VENV_NAME)/bin/black
SQLFLUFF = $(VENV_NAME)/bin/sqlfluff
PRECOMMIT = $(VENV_NAME)/bin/pre-commit
PRETTIER = npx prettier

##@ Helpers
help: ## display this help
	@echo "Some dbt Showcase"
	@echo "======================="
	@awk 'BEGIN {FS = ":.*##"; printf "\033[36m\033[0m"} /^[a-zA-Z0-9\(\)\$$_%\.\-\\]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@printf "\n"

##@ Preparation
setup_env: $(PYTHON) $(DBT) $(FLAKE8) $(BLACK) $(SQLFLUFF) $(PRECOMMIT) $(PRETTIER) ## install local dbt environment

$(PYTHON): $(REQUIREMENTS) ## install local python environment
	python3 -m venv $(VENV_NAME)
	$(VENV_NAME)/bin/pip install -r $<

$(DBT): $(REQUIREMENTS) ## install dbt executable in dev environment
	python3 -m venv $(VENV_NAME)
	$(VENV_NAME)/bin/pip install -r $<

$(FLAKE8): $(REQUIREMENTS) ## install linter in local dev environment
	python3 -m venv $(VENV_NAME)
	$(VENV_NAME)/bin/pip install -r $<

$(BLACK): $(REQUIREMENTS) ## install reformatter in local dev environment
	python3 -m venv $(VENV_NAME)
	$(VENV_NAME)/bin/pip install -r $<

$(SQLFLUFF): $(REQUIREMENTS) ## install sql-fluff in local dev environment
	python3 -m venv $(VENV_NAME)
	$(VENV_NAME)/bin/pip install -r $<

$(PRECOMMIT): $(REQUIREMENTS) ## install pre-commit in local dev environment
	python3 -m venv $(VENV_NAME)
	$(VENV_NAME)/bin/pip install -r $<

$(PRETTIER): ## install prettier yaml reformatter using node package manager
	npm install --save-dev --save-exact prettier

##@ Operations

dbt_debug: ## check dbt version and project settings
	$(DBT) --version
	$(DBT) debug 

black_dry: ## format your python code using black - dry run
	$(BLACK) --version
# black throws exit code=1 for detected formatting issues
	$(BLACK) --check . || true

black_reformat: ## format your python code using black - applied (see, pyproject.toml)
	$(BLACK) --version
	$(BLACK) .

flake8_lint: ## run flake8 linter - (see, setup.cfg)
	$(FLAKE8) --version
	$(FLAKE8)

sqlfluff_dry: ## format your sql using sqlfluff - dry run
	$(SQLFLUFF) --version
	$(SQLFLUFF) lint

sqlfluff_lint: ## format your sql using sqlfluff - applied (see, .sqlfluff)
	$(SQLFLUFF) --version
	$(SQLFLUFF) fix

prettier_dry: ## format your yaml using prettier - dry run
	$(PRETTIER) --version
	$(PRETTIER) . --check

prettier_reformat: ## format your yaml using prettier - applied (see, .prettierrc)
	$(PRETTIER) --version
	$(PRETTIER) . --write

pre-commit-full: ## run pre commit checks (see, .pre-commit-config.yaml)
	$(PRECOMMIT) --version
	$(PRECOMMIT) run --all-files

##@ Tear-down
clean: ## clean up temp files
	rm -rf node_modules
	rm -rf dbt_env
