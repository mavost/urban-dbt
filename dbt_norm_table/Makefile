include .env
export

MAKEFLAGS += --warn-undefined-variables
.SHELLFLAGS := -eu -o pipefail -c

all: help

.PHONY: all help clean \
 	dbt_debug dbt_docs dbt_run_refresh dbt_incremental \
	run_seed run_stage run_core run_stats runinc_stage runinc_core \
	black_dry black_reformat flake8_lint \
 	sqlfluff_dry sqlfluff_lint prettier_dry prettier_reformat \
 	pre-commit-full pre-commit-full

# Use bash for inline if-statements
SHELL:=bash

VENV_NAME ?= _dbt_env
DBT_PROJECT_NAME ?= dbt_norm_table
DBT_TARGET ?= test
DBT_PORT ?= 8082
LAYER ?= null

PYTHON = $(VENV_NAME)/bin/python
DBT = ../$(VENV_NAME)/bin/dbt
FLAKE8 = $(VENV_NAME)/bin/flake8
BLACK = $(VENV_NAME)/bin/black
SQLFLUFF = $(VENV_NAME)/bin/sqlfluff
PRECOMMIT = $(VENV_NAME)/bin/pre-commit
PRETTIER = npx prettier

##@ Helpers
help: ## display this help
	@echo "dbt project $(DBT_PROJECT_NAME): Makefile commands"
	@echo "=================================================="
	@awk 'BEGIN {FS = ":.*##"; printf "\033[36m\033[0m"} /^[a-zA-Z0-9\(\)\$$_%\.\-\\]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@printf "\n"

##@ dbt Operations

dbt_debug: ## check dbt version and project settings
	$(DBT) --version &&\
	$(DBT) debug

dbt_docs: ## generate dbt model docs and start server
	@echo "Generation dbt model documentation and serving on http:\\localhost:$(DBT_PORT)"
	$(DBT) docs generate --target $(DBT_TARGET) &&\
	$(DBT) docs serve --target $(DBT_TARGET) --port $(DBT_PORT)

dbt_run_refresh: REFRESH=--full-refresh
dbt_run_refresh: run_seed run_stage run_core run_mart run_stats ## refresh dbt model and test: layer by layer

run_seed:
	@echo "Running dbt seed to raw layer"
	$(DBT) seed --target $(DBT_TARGET)

run_stage:
	$(eval LAYER=01_staging)
	$(RUNTEST_LAYER_TEMPLATE)

run_core:
	$(eval LAYER=02_core)
	$(RUNTEST_LAYER_TEMPLATE)

run_mart:
	$(eval LAYER=03_mart)
	$(RUNTEST_LAYER_TEMPLATE)

run_stats:
	$(eval LAYER=05_stats)
	$(RUN_LAYER_TEMPLATE)

# Example: make dbt_incremental REFRESH="--vars 'overlap_interval: \"2 Days\"'"
# 	will simulate an incremental load acrooss all models using this variable's time difference
#   Note: in this chow case the time line of the seeds (full) and ingestion (continuously) differs!
dbt_incremental: REFRESH=
dbt_incremental: runinc_stage runinc_core runinc_mart ## add data to dbt model - layer by layer (tbc)

runinc_stage:
	$(eval LAYER=01_staging)
	$(RUN_LAYER_TEMPLATE)

runinc_core:
	$(eval LAYER=02_core)
	$(RUN_LAYER_TEMPLATE)

runinc_mart:
	$(eval LAYER=03_mart)
	$(RUN_LAYER_TEMPLATE)

define RUN_LAYER_TEMPLATE
@echo "Running dbt $(LAYER) layer"
$(DBT) run --target $(DBT_TARGET) --select $(DBT_PROJECT_NAME).$(LAYER).* $(REFRESH)
endef

define RUNTEST_LAYER_TEMPLATE
@echo "Running/testing dbt $(LAYER) layer"
$(DBT) run --target $(DBT_TARGET) --select $(DBT_PROJECT_NAME).$(LAYER).* $(REFRESH) &&\
$(DBT) test --target $(DBT_TARGET) --select $(DBT_PROJECT_NAME).$(LAYER).*
endef

dbt_reset: ## clean dbt configuration
	@echo "Cleaning dbt environment and installing dependencies"
	dbt clean && dbt deps

##@ Linting Operations

generate_sqlfluff_config: ## Generate/update .sqlfluff from template
	@sed 's/{{DBT_PROJECT_NAME}}/$(DBT_PROJECT_NAME)/' ../.sqlfluff.template > ../.sqlfluff

black_dry: ## format your python code using black - dry run
# black throws exit code=1 for detected formatting issues
	cd .. && $(BLACK) --check . || true && cd -

black_reformat: ## format your python code using black - applied (see, pyproject.toml)
	cd .. && $(BLACK) . && cd -

flake8_lint: ## run flake8 linter - (see, setup.cfg)
	cd .. && $(FLAKE8) && cd -

sqlfluff_dry: generate_sqlfluff_config ## format your sql using sqlfluff - dry run
# sqlfluff throws exit code=1 for detected formatting issues
	cd .. && $(SQLFLUFF) lint || true && cd -

sqlfluff_lint: generate_sqlfluff_config ## format your sql using sqlfluff - applied (see, .sqlfluff)
	cd .. && $(SQLFLUFF) fix || true && cd -

prettier_dry: ## format your yaml using prettier - dry run
	cd .. && $(PRETTIER) . --check && cd -

prettier_reformat: ## format your yaml using prettier - applied (see, .prettierrc)
	cd .. && $(PRETTIER) . --write && cd -

pre-commit-full: ## run pre commit checks (see, .pre-commit-config.yaml)
	cd .. && $(PRECOMMIT) run --all-files && cd -

##@ Tear-down
clean: ## clean up temp files
	rm -rf dbt_packages
	rm -rf logs
	rm -rf target
