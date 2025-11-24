# ============================================================================
# Gut Reaction Platform - Makefile
# ============================================================================
# Build automation for development, testing, and deployment
# ============================================================================

.PHONY: help build up down logs test lint clean dev prod

# Default target
.DEFAULT_GOAL := help

# Colors for output
CYAN := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

# Variables
DOCKER_COMPOSE := docker-compose
DOCKER_COMPOSE_DEV := docker-compose -f docker-compose.yml -f docker-compose.dev.yml
DOCKER_COMPOSE_PROD := docker-compose -f docker-compose.yml -f docker-compose.prod.yml

# ============================================================================
# Help
# ============================================================================

help: ## Show this help message
	@echo ""
	@echo "$(CYAN)Gut Reaction Platform$(RESET) - Build Commands"
	@echo ""
	@echo "$(GREEN)Usage:$(RESET)"
	@echo "  make [target]"
	@echo ""
	@echo "$(GREEN)Targets:$(RESET)"
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  $(CYAN)%-15s$(RESET) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""

# ============================================================================
# Development
# ============================================================================

dev: ## Start development environment with hot-reload
	@echo "$(GREEN)Starting development environment...$(RESET)"
	$(DOCKER_COMPOSE_DEV) up --build

up: ## Start all services in detached mode
	@echo "$(GREEN)Starting services...$(RESET)"
	$(DOCKER_COMPOSE) up -d --build

down: ## Stop all services
	@echo "$(YELLOW)Stopping services...$(RESET)"
	$(DOCKER_COMPOSE) down

restart: down up ## Restart all services

logs: ## View logs from all services
	$(DOCKER_COMPOSE) logs -f

logs-nlp: ## View logs from NLP service
	$(DOCKER_COMPOSE) logs -f phenotype-nlp

logs-auditor: ## View logs from governance auditor
	$(DOCKER_COMPOSE) logs -f governance-auditor

status: ## Show status of all services
	@echo "$(GREEN)Service Status:$(RESET)"
	$(DOCKER_COMPOSE) ps

shell-nlp: ## Open shell in NLP service container
	$(DOCKER_COMPOSE) exec phenotype-nlp /bin/bash

shell-db: ## Open psql in database container
	$(DOCKER_COMPOSE) exec postgres psql -U admin -d gut_reaction_db

# ============================================================================
# Building
# ============================================================================

build: ## Build all Docker images
	@echo "$(GREEN)Building all images...$(RESET)"
	$(DOCKER_COMPOSE) build

build-nlp: ## Build NLP service image
	$(DOCKER_COMPOSE) build phenotype-nlp

build-auditor: ## Build governance auditor image
	$(DOCKER_COMPOSE) build governance-auditor

build-ingestion: ## Build clinical ingestion image
	$(DOCKER_COMPOSE) build clinical-ingestion

build-bridge: ## Build genomic bridge image
	$(DOCKER_COMPOSE) build genomic-bridge

# ============================================================================
# Testing
# ============================================================================

test: ## Run all tests
	@echo "$(GREEN)Running all tests...$(RESET)"
	$(DOCKER_COMPOSE) run --rm phenotype-nlp pytest tests/ -v
	$(DOCKER_COMPOSE) run --rm governance-auditor pytest tests/ -v

test-nlp: ## Run NLP service tests
	@echo "$(GREEN)Running NLP tests...$(RESET)"
	$(DOCKER_COMPOSE) run --rm phenotype-nlp pytest tests/ -v --cov=src --cov-report=html

test-auditor: ## Run governance auditor tests
	@echo "$(GREEN)Running auditor tests...$(RESET)"
	$(DOCKER_COMPOSE) run --rm governance-auditor pytest tests/ -v --cov=src --cov-report=html

test-integration: ## Run integration tests
	@echo "$(GREEN)Running integration tests...$(RESET)"
	$(DOCKER_COMPOSE) -f docker-compose.test.yml up --build --abort-on-container-exit
	$(DOCKER_COMPOSE) -f docker-compose.test.yml down

# ============================================================================
# Code Quality
# ============================================================================

lint: ## Run linters on all services
	@echo "$(GREEN)Running linters...$(RESET)"
	$(DOCKER_COMPOSE) run --rm phenotype-nlp ruff check src/
	$(DOCKER_COMPOSE) run --rm phenotype-nlp black --check src/
	$(DOCKER_COMPOSE) run --rm governance-auditor ruff check src/
	$(DOCKER_COMPOSE) run --rm governance-auditor black --check src/

format: ## Auto-format code
	@echo "$(GREEN)Formatting code...$(RESET)"
	$(DOCKER_COMPOSE) run --rm phenotype-nlp black src/ tests/
	$(DOCKER_COMPOSE) run --rm governance-auditor black src/ tests/

typecheck: ## Run type checking
	@echo "$(GREEN)Running type checks...$(RESET)"
	$(DOCKER_COMPOSE) run --rm phenotype-nlp mypy src/
	$(DOCKER_COMPOSE) run --rm governance-auditor mypy src/

# ============================================================================
# Security
# ============================================================================

security-scan: ## Run security scans
	@echo "$(GREEN)Running security scans...$(RESET)"
	trivy fs --severity HIGH,CRITICAL .
	$(DOCKER_COMPOSE) run --rm phenotype-nlp pip-audit

scan-images: ## Scan Docker images for vulnerabilities
	@echo "$(GREEN)Scanning Docker images...$(RESET)"
	trivy image gut-reaction-phenotype-nlp:latest
	trivy image gut-reaction-governance-auditor:latest

# ============================================================================
# Database
# ============================================================================

db-migrate: ## Run database migrations
	@echo "$(GREEN)Running migrations...$(RESET)"
	$(DOCKER_COMPOSE) exec postgres psql -U admin -d gut_reaction_db -f /migrations/001_init.sql

db-seed: ## Seed database with sample data
	@echo "$(GREEN)Seeding database...$(RESET)"
	$(DOCKER_COMPOSE) exec postgres psql -U admin -d gut_reaction_db -f /seeds/sample_data.sql

db-backup: ## Backup database
	@echo "$(GREEN)Backing up database...$(RESET)"
	$(DOCKER_COMPOSE) exec postgres pg_dump -U admin gut_reaction_db > backup_$$(date +%Y%m%d_%H%M%S).sql

db-restore: ## Restore database from backup (usage: make db-restore FILE=backup.sql)
	@echo "$(GREEN)Restoring database from $(FILE)...$(RESET)"
	$(DOCKER_COMPOSE) exec -T postgres psql -U admin gut_reaction_db < $(FILE)

# ============================================================================
# Production Deployment
# ============================================================================

prod: ## Start production environment
	@echo "$(GREEN)Starting production environment...$(RESET)"
	$(DOCKER_COMPOSE_PROD) up -d --build

prod-down: ## Stop production environment
	@echo "$(YELLOW)Stopping production environment...$(RESET)"
	$(DOCKER_COMPOSE_PROD) down

deploy-k8s: ## Deploy to Kubernetes
	@echo "$(GREEN)Deploying to Kubernetes...$(RESET)"
	kubectl apply -k infrastructure/k8s/overlays/production/

deploy-k8s-dry: ## Dry-run Kubernetes deployment
	@echo "$(GREEN)Kubernetes deployment dry-run...$(RESET)"
	kubectl apply -k infrastructure/k8s/overlays/production/ --dry-run=client

# ============================================================================
# Cleanup
# ============================================================================

clean: ## Remove all containers, volumes, and images
	@echo "$(RED)Cleaning up...$(RESET)"
	$(DOCKER_COMPOSE) down -v --rmi all --remove-orphans

clean-volumes: ## Remove only volumes
	@echo "$(YELLOW)Removing volumes...$(RESET)"
	$(DOCKER_COMPOSE) down -v

clean-images: ## Remove only images
	@echo "$(YELLOW)Removing images...$(RESET)"
	docker rmi $$(docker images 'gut-reaction*' -q) 2>/dev/null || true

prune: ## Docker system prune
	@echo "$(RED)Pruning Docker system...$(RESET)"
	docker system prune -af --volumes

# ============================================================================
# Documentation
# ============================================================================

docs: ## Generate documentation
	@echo "$(GREEN)Generating documentation...$(RESET)"
	cd docs && mkdocs build

docs-serve: ## Serve documentation locally
	@echo "$(GREEN)Serving documentation at http://localhost:8080$(RESET)"
	cd docs && mkdocs serve -a 0.0.0.0:8080

# ============================================================================
# Utilities
# ============================================================================

env: ## Show environment variables
	@echo "$(GREEN)Environment:$(RESET)"
	@cat .env 2>/dev/null || echo "No .env file found. Copy .env.example to .env"

init: ## Initialize project (copy env, install hooks)
	@echo "$(GREEN)Initializing project...$(RESET)"
	cp -n .env.example .env || true
	pre-commit install || true
	@echo "$(GREEN)Done! Edit .env with your configuration.$(RESET)"

version: ## Show version information
	@echo "$(GREEN)Version Information:$(RESET)"
	@echo "Docker: $$(docker --version)"
	@echo "Docker Compose: $$(docker-compose --version)"
	@echo "kubectl: $$(kubectl version --client --short 2>/dev/null || echo 'not installed')"
	@echo "Terraform: $$(terraform version -json 2>/dev/null | jq -r '.terraform_version' || echo 'not installed')"
