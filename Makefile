MAKEFLAGS += --warn-undefined-variables
.SHELLFLAGS := -eu -o pipefail -c

all: help
.PHONY: all, help, setup_env, ci, black, lint, pre-commit-full, test, clean

# Use bash for inline if-statements
SHELL:=bash
REQUIREMENTS = requirements-dbt.txt

VENV_NAME ?= dbt_env

PYTHON = $(VENV_NAME)/bin/python
FLAKE8 = $(VENV_NAME)/bin/flake8
BLACK = $(VENV_NAME)/bin/black
PRECOMMIT = $(VENV_NAME)/bin/pre-commit

##@ Helpers
help: ## display this help
	@echo "Some dbt Showcase"
	@echo "======================="
	@awk 'BEGIN {FS = ":.*##"; printf "\033[36m\033[0m"} /^[a-zA-Z0-9\(\)\$$_%\.-\\]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@printf "\n"

##@ Preparation
setup_env: $(PYTHON) $(FLAKE8) $(BLACK) ## install local dev environment

$(PYTHON): $(REQUIREMENTS) ## install local python environment
	python3 -m venv $(VENV_NAME)
	$(VENV_NAME)/bin/pip install -r $<

$(FLAKE8): $(REQUIREMENTS) ## install linter in local dev environment
	python3 -m venv $(VENV_NAME)
	$(VENV_NAME)/bin/pip install -r $<

$(BLACK): $(REQUIREMENTS) ## install reformatter in local dev environment
	python3 -m venv $(VENV_NAME)
	$(VENV_NAME)/bin/pip install -r $<

$(PRECOMMIT): $(REQUIREMENTS) ## install pre-commit in local dev environment
	python3 -m venv $(VENV_NAME)
	$(VENV_NAME)/bin/pip install -r $<

##@ Operations
black: ## format your code using black
	$(BLACK) --version
	$(BLACK) --check .

lint: ## run flake8 linter
	$(FLAKE8) --version
	$(FLAKE8)

pre-commit-full: ## run flake8 linter
	$(PRECOMMIT) --version
	$(PRECOMMIT) run --all-files

##@ Tear-down
clean: ## clean up temp files
	rm -rf node_modules
	rm -rf dbt_env
