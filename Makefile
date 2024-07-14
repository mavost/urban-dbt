include .env
export

MAKEFLAGS += --warn-undefined-variables
.SHELLFLAGS := -eu -o pipefail -c

all: help

.PHONY: all help setup_env black_dry black_reformat flake8_lint\
 sqlfluff_dry sqlfluff_lint prettier_dry prettier_reformat\
 pre-commit-full pre-commit-full clean\
 dbt_debug

# Use bash for inline if-statements
SHELL:=bash
REQUIREMENTS = requirements-dbt.txt

VENV_NAME ?= _dbt_env
DBT_PROJECT_NAME ?= pg_source


PYTHON = $(VENV_NAME)/bin/python
# absolute path as we are calling dbt from its project dir
DBT = $(VENV_NAME)/bin/dbt
FLAKE8 = $(VENV_NAME)/bin/flake8
BLACK = $(VENV_NAME)/bin/black
SQLFLUFF = $(VENV_NAME)/bin/sqlfluff
PRECOMMIT = $(VENV_NAME)/bin/pre-commit
PRETTIER = npx prettier

##@ Helpers
help: ## display this help
	@echo "Setup environment for dbt repo"
	@echo "=============================="
	@awk 'BEGIN {FS = ":.*##"; printf "\033[36m\033[0m"} /^[a-zA-Z0-9\(\)\$$_%\.\-\\]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@printf "\n"

##@ Preparation
setup_env: $(PYTHON) $(DBT) $(FLAKE8) $(BLACK) $(SQLFLUFF) $(PRECOMMIT) $(PRETTIER) ## install local python environment with dbt, linters, etc.
	@echo "Installing python env..."

$(PYTHON) $(DBT) $(FLAKE8) $(BLACK) $(SQLFLUFF) $(PRECOMMIT): $(REQUIREMENTS)
	python3 -m venv $(VENV_NAME)
	$(VENV_NAME)/bin/pip install -r $<

$(PRETTIER): #- install prettier yaml reformatter using node package manager
	npm install --save-dev --save-exact prettier

##@ Operations

generate_sqlfluff_config: #- Generate/update .sqlfluff from template
	@sed 's/{{DBT_PROJECT_NAME}}/$(DBT_PROJECT_NAME)/' .sqlfluff.template > .sqlfluff

verify_install: generate_sqlfluff_config ## check environment installation/command version
	@echo "Testing python env..."
	@echo -e "\n***************************\npython version:"&&\
	$(PYTHON) --version &&\
	echo -e "\n***************************\nblack version:"&&\
	$(BLACK) --version &&\
	echo -e "\n***************************\nflake8 version:"&&\
	$(FLAKE8) --version &&\
	echo -e "\n***************************\nsqlfluff version:"&&\
	$(SQLFLUFF) --version &&\
	echo -e "\n***************************\nprettier version:"&&\
	$(PRETTIER) --version &&\
	echo -e "\n***************************\npre-commit version:"&&\
	$(PRECOMMIT) --version &&\
	echo -e "\n***************************\ndbt version:"&&\
	$(DBT) --version

##@ Tear-down

clean: ## clean up environment files
	@echo "Removing python env..."
	rm -rf node_modules
	rm -rf _dbt_env
