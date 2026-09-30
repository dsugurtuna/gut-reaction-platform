# ============================================================================
# Gut Reaction Platform - Makefile
# ============================================================================
# Every target here is one that CI also runs, or a thin wrapper around docker
# compose. Python targets create one virtual environment per service, because
# the two services pin different dependency sets.
# ============================================================================

.PHONY: help test test-nlp test-auditor test-r lint ui k8s-validate up up-all down logs clean

.DEFAULT_GOAL := help

PYTHON ?= python3.11
NLP_VENV := .venv-nlp
AUDITOR_VENV := .venv-auditor
LINT_VENV := .venv-lint
RUFF_VERSION := 0.16.9

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  %-14s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

# --- Tests (no Docker, no network after install, no API keys) ---------------

$(NLP_VENV)/bin/pytest:
	$(PYTHON) -m venv $(NLP_VENV)
	$(NLP_VENV)/bin/pip install -q -r services/phenotype-nlp/requirements-dev.txt

$(AUDITOR_VENV)/bin/pytest:
	$(PYTHON) -m venv $(AUDITOR_VENV)
	$(AUDITOR_VENV)/bin/pip install -q -r services/governance-auditor/requirements-dev.txt

test: test-nlp test-auditor test-r ## Run all unit tests (Python and R)

test-nlp: $(NLP_VENV)/bin/pytest ## phenotype-nlp unit and API tests
	cd services/phenotype-nlp && ../../$(NLP_VENV)/bin/pytest tests/ -q

test-auditor: $(AUDITOR_VENV)/bin/pytest ## governance-auditor unit and API tests
	cd services/governance-auditor && ../../$(AUDITOR_VENV)/bin/pytest tests/ -q

test-r: ## R tests (needs R with testthat, dplyr, tibble, stringr, checkmate)
	cd services/clinical-ingestion && Rscript -e 'testthat::test_dir("tests", reporter = "summary")'
	cd services/genomic-bridge && Rscript -e 'testthat::test_dir("tests", reporter = "summary")'

# --- Static checks ----------------------------------------------------------

$(LINT_VENV)/bin/ruff:
	$(PYTHON) -m venv $(LINT_VENV)
	$(LINT_VENV)/bin/pip install -q ruff==$(RUFF_VERSION)

lint: $(LINT_VENV)/bin/ruff ## Ruff lint and format check (same version as CI)
	$(LINT_VENV)/bin/ruff check services/
	$(LINT_VENV)/bin/ruff format --check services/

ui: ## Type-check and build the dashboard (needs Node.js 22)
	cd ui && npm ci && npm run build

k8s-validate: ## Render the kustomization and check it against K8s 1.28 schemas (needs kubectl, kubeconform)
	kubectl kustomize infrastructure/k8s/base | kubeconform -strict -summary -kubernetes-version 1.28.0 -

# --- Docker Compose ---------------------------------------------------------

up: ## Start the two Python services and Postgres, as the CI integration job does
	docker compose -f docker-compose.ci.yml up -d --build

up-all: ## Start every container (dashboard, gateway, R services, Postgres, Redis)
	docker compose up -d --build

down: ## Stop containers started by `up` or `up-all`
	docker compose -f docker-compose.ci.yml down -v
	docker compose down -v

logs: ## Follow logs of the `up` stack
	docker compose -f docker-compose.ci.yml logs -f

clean: ## Remove local virtual environments and build output
	rm -rf $(NLP_VENV) $(AUDITOR_VENV) $(LINT_VENV) ui/dist
