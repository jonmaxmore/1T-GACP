# ===================================================================
# Thai Herbal GACP Platform v3.0 - Makefile
# ===================================================================

.PHONY: help install start stop restart logs clean test build deploy

# Default target
.DEFAULT_GOAL := help

# Colors for output
RED=\033[0;31m
GREEN=\033[0;32m
YELLOW=\033[1;33m
BLUE=\033[0;34m
PURPLE=\033[0;35m
CYAN=\033[0;36m
WHITE=\033[1;37m
NC=\033[0m # No Color

# Project configuration
PROJECT_NAME=thai-herbal-gacp-platform
COMPOSE_FILE=docker-compose.yml
COMPOSE_DEV_FILE=docker-compose.dev.yml
COMPOSE_PROD_FILE=docker-compose.prod.yml

# Load environment variables
include .env

# ===================================================================
# Help Target
# ===================================================================

help: ## Show this help message
	@echo ""
	@echo "$(GREEN)✅ All requirements satisfied!$(NC)"

setup-env: ## Setup environment variables
	@echo "$(BLUE)⚙️ Setting up environment...$(NC)"
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(YELLOW)📝 Created .env file from template. Please review and update the values.$(NC)"; \
	else \
		echo "$(GREEN)✅ .env file already exists.$(NC)"; \
	fi

install-frontend: ## Install Flutter dependencies
	@echo "$(BLUE)📱 Installing Frontend dependencies...$(NC)"
	@cd frontend && flutter pub get
	@echo "$(GREEN)✅ Frontend dependencies installed!$(NC)"

install-backend: ## Install Dart backend dependencies
	@echo "$(BLUE)🏗️ Installing Backend dependencies...$(NC)"
	@cd backend && dart pub get
	@echo "$(GREEN)✅ Backend dependencies installed!$(NC)"

install-ai-services: ## Install AI services dependencies
	@echo "$(BLUE)🤖 Installing AI services dependencies...$(NC)"
	@cd ai-services/yolo-api && pip install -r requirements.txt
	@cd ai-services/reasoning-engine && pip install -r requirements.txt
	@echo "$(GREEN)✅ AI services dependencies installed!$(NC)"

setup-database: ## Setup database schemas and initial data
	@echo "$(BLUE)🗄️ Setting up databases...$(NC)"
	@docker-compose up -d postgres redis neo4j
	@sleep 10
	@$(MAKE) migrate-database
	@$(MAKE) seed-database
	@echo "$(GREEN)✅ Databases setup completed!$(NC)"

migrate-database: ## Run database migrations
	@echo "$(BLUE)🔄 Running database migrations...$(NC)"
	@cd backend && dart run migrations/migrate.dart
	@echo "$(GREEN)✅ Database migrations completed!$(NC)"

seed-database: ## Seed database with initial data
	@echo "$(BLUE)🌱 Seeding database with initial data...$(NC)"
	@cd database/postgresql/seeds && psql $(DATABASE_URL) -f herbs_data.sql
	@cd database/neo4j/cypher-scripts && cypher-shell -u $(NEO4J_USER) -p $(NEO4J_PASSWORD) -f knowledge_graph.cypher
	@echo "$(GREEN)✅ Database seeding completed!$(NC)"

# ===================================================================
# Development Commands
# ===================================================================

start: ## Start all services in development mode
	@echo "$(CYAN)🚀 Starting Thai Herbal GACP Platform...$(NC)"
	@docker-compose --profile dev up -d
	@echo "$(GREEN)✅ All services started!$(NC)"
	@$(MAKE) status

start-prod: ## Start all services in production mode
	@echo "$(CYAN)🚀 Starting Thai Herbal GACP Platform (Production)...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) -f $(COMPOSE_PROD_FILE) up -d
	@echo "$(GREEN)✅ Production services started!$(NC)"

stop: ## Stop all services
	@echo "$(YELLOW)🛑 Stopping all services...$(NC)"
	@docker-compose down
	@echo "$(GREEN)✅ All services stopped!$(NC)"

restart: ## Restart all services
	@echo "$(YELLOW)🔄 Restarting all services...$(NC)"
	@$(MAKE) stop
	@$(MAKE) start

status: ## Show status of all services
	@echo "$(BLUE)📊 Service Status:$(NC)"
	@docker-compose ps

logs: ## Show logs for all services or specific service (usage: make logs service=backend)
	@if [ -z "$(service)" ]; then \
		echo "$(BLUE)📋 Showing logs for all services...$(NC)"; \
		docker-compose logs -f; \
	else \
		echo "$(BLUE)📋 Showing logs for $(service)...$(NC)"; \
		docker-compose logs -f $(service); \
	fi

shell: ## Access shell of a specific service (usage: make shell service=backend)
	@if [ -z "$(service)" ]; then \
		echo "$(RED)❌ Please specify a service: make shell service=backend$(NC)"; \
		exit 1; \
	else \
		echo "$(BLUE)🐚 Accessing shell for $(service)...$(NC)"; \
		docker-compose exec $(service) /bin/sh; \
	fi

# ===================================================================
# Frontend Commands
# ===================================================================

flutter-run: ## Run Flutter app in development mode
	@echo "$(BLUE)📱 Running Flutter app...$(NC)"
	@cd frontend && flutter run

flutter-build-web: ## Build Flutter web app
	@echo "$(BLUE)🌐 Building Flutter web app...$(NC)"
	@cd frontend && flutter build web --release
	@echo "$(GREEN)✅ Flutter web build completed!$(NC)"

flutter-build-android: ## Build Flutter Android APK
	@echo "$(BLUE)📱 Building Flutter Android APK...$(NC)"
	@cd frontend && flutter build apk --release
	@echo "$(GREEN)✅ Android APK build completed!$(NC)"

flutter-build-ios: ## Build Flutter iOS app
	@echo "$(BLUE)📱 Building Flutter iOS app...$(NC)"
	@cd frontend && flutter build ios --release
	@echo "$(GREEN)✅ iOS build completed!$(NC)"

flutter-clean: ## Clean Flutter build artifacts
	@echo "$(YELLOW)🧹 Cleaning Flutter build artifacts...$(NC)"
	@cd frontend && flutter clean && flutter pub get

# ===================================================================
# Backend Commands
# ===================================================================

backend-run: ## Run Dart backend server
	@echo "$(BLUE)🏗️ Running backend server...$(NC)"
	@cd backend && dart run bin/server.dart

backend-build: ## Build backend Docker image
	@echo "$(BLUE)🐳 Building backend Docker image...$(NC)"
	@docker build -t $(PROJECT_NAME)-backend ./backend
	@echo "$(GREEN)✅ Backend image built!$(NC)"

backend-migrate: ## Run backend database migrations
	@echo "$(BLUE)🔄 Running backend migrations...$(NC)"
	@cd backend && dart run migrations/migrate.dart

# ===================================================================
# AI Services Commands
# ===================================================================

ai-train: ## Train AI models
	@echo "$(BLUE)🤖 Training AI models...$(NC)"
	@cd ai-services/yolo-api && python train_model.py
	@echo "$(GREEN)✅ AI model training completed!$(NC)"

ai-test: ## Test AI services
	@echo "$(BLUE)🧪 Testing AI services...$(NC)"
	@cd ai-services/yolo-api && python -m pytest tests/
	@cd ai-services/reasoning-engine && python -m pytest tests/
	@echo "$(GREEN)✅ AI services tests completed!$(NC)"

# ===================================================================
# Testing Commands
# ===================================================================

test: ## Run all tests
	@echo "$(CYAN)🧪 Running all tests...$(NC)"
	@$(MAKE) test-frontend
	@$(MAKE) test-backend
	@$(MAKE) test-ai-services
	@echo "$(GREEN)✅ All tests completed!$(NC)"

test-frontend: ## Run Flutter tests
	@echo "$(BLUE)📱 Running Flutter tests...$(NC)"
	@cd frontend && flutter test --coverage
	@echo "$(GREEN)✅ Frontend tests completed!$(NC)"

test-backend: ## Run Dart backend tests
	@echo "$(BLUE)🏗️ Running backend tests...$(NC)"
	@cd backend && dart test --coverage=coverage
	@echo "$(GREEN)✅ Backend tests completed!$(NC)"

test-ai-services: ## Run AI services tests
	@echo "$(BLUE)🤖 Running AI services tests...$(NC)"
	@$(MAKE) ai-test

test-integration: ## Run integration tests
	@echo "$(BLUE)🔗 Running integration tests...$(NC)"
	@cd test && python -m pytest integration/
	@echo "$(GREEN)✅ Integration tests completed!$(NC)"

test-e2e: ## Run end-to-end tests
	@echo "$(BLUE)🎭 Running E2E tests...$(NC)"
	@cd frontend && flutter drive --target=test_driver/app.dart
	@echo "$(GREEN)✅ E2E tests completed!$(NC)"

# ===================================================================
# Build Commands
# ===================================================================

build: ## Build all components
	@echo "$(CYAN)🏗️ Building all components...$(NC)"
	@$(MAKE) build-frontend
	@$(MAKE) build-backend
	@$(MAKE) build-ai-services
	@echo "$(GREEN)✅ All builds completed!$(NC)"

build-frontend: ## Build frontend for all platforms
	@echo "$(BLUE)📱 Building frontend...$(NC)"
	@$(MAKE) flutter-build-web
	@$(MAKE) flutter-build-android

build-backend: ## Build backend
	@echo "$(BLUE)🏗️ Building backend...$(NC)"
	@$(MAKE) backend-build

build-ai-services: ## Build AI services Docker images
	@echo "$(BLUE)🤖 Building AI services...$(NC)"
	@docker build -t $(PROJECT_NAME)-yolo-api ./ai-services/yolo-api
	@docker build -t $(PROJECT_NAME)-reasoning-engine ./ai-services/reasoning-engine
	@echo "$(GREEN)✅ AI services built!$(NC)"

build-docker: ## Build all Docker images
	@echo "$(BLUE)🐳 Building all Docker images...$(NC)"
	@docker-compose build
	@echo "$(GREEN)✅ All Docker images built!$(NC)"

# ===================================================================
# Database Management
# ===================================================================

db-backup: ## Backup all databases
	@echo "$(BLUE)💾 Creating database backups...$(NC)"
	@mkdir -p backups/$(shell date +%Y%m%d_%H%M%S)
	@docker-compose exec postgres pg_dump -U $(POSTGRES_USER) $(POSTGRES_DB) > backups/$(shell date +%Y%m%d_%H%M%S)/postgres.sql
	@docker-compose exec neo4j cypher-shell -u $(NEO4J_USER) -p $(NEO4J_PASSWORD) "CALL apoc.export.cypher.all('backup.cypher')"
	@echo "$(GREEN)✅ Database backups created!$(NC)"

db-restore: ## Restore databases from backup (usage: make db-restore backup=20231201_120000)
	@if [ -z "$(backup)" ]; then \
		echo "$(RED)❌ Please specify backup: make db-restore backup=20231201_120000$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)🔄 Restoring databases from backup $(backup)...$(NC)"
	@docker-compose exec postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) < backups/$(backup)/postgres.sql
	@echo "$(GREEN)✅ Database restoration completed!$(NC)"

db-reset: ## Reset all databases (⚠️ DESTRUCTIVE)
	@echo "$(RED)⚠️ This will DELETE ALL DATA! Are you sure? [y/N]$(NC)" && read ans && [ ${ans:-N} = y ]
	@echo "$(YELLOW)🗑️ Resetting all databases...$(NC)"
	@docker-compose down -v
	@docker volume prune -f
	@$(MAKE) setup-database
	@echo "$(GREEN)✅ Databases reset completed!$(NC)"

# ===================================================================
# Monitoring & Logs
# ===================================================================

monitor: ## Open monitoring dashboard
	@echo "$(BLUE)📊 Opening monitoring dashboards...$(NC)"
	@echo "Grafana: http://localhost:3000 (admin/$(GRAFANA_ADMIN_PASSWORD))"
	@echo "Prometheus: http://localhost:9090"
	@echo "Kibana: http://localhost:5601"
	@open http://localhost:3000 2>/dev/null || xdg-open http://localhost:3000 2>/dev/null || echo "Open http://localhost:3000 manually"

logs-live: ## Show live logs for all services
	@echo "$(BLUE)📋 Showing live logs...$(NC)"
	@docker-compose logs -f --tail=100

logs-errors: ## Show error logs only
	@echo "$(RED)🚨 Showing error logs...$(NC)"
	@docker-compose logs | grep -i error

# ===================================================================
# Deployment Commands
# ===================================================================

deploy-staging: ## Deploy to staging environment
	@echo "$(CYAN)🚀 Deploying to staging...$(NC)"
	@$(MAKE) build
	@docker-compose -f $(COMPOSE_FILE) -f docker-compose.staging.yml up -d
	@echo "$(GREEN)✅ Staging deployment completed!$(NC)"

deploy-production: ## Deploy to production environment
	@echo "$(CYAN)🚀 Deploying to production...$(NC)"
	@$(MAKE) build
	@$(MAKE) db-backup
	@docker-compose -f $(COMPOSE_FILE) -f $(COMPOSE_PROD_FILE) up -d
	@echo "$(GREEN)✅ Production deployment completed!$(NC)"

deploy-k8s: ## Deploy to Kubernetes
	@echo "$(BLUE)☸️ Deploying to Kubernetes...$(NC)"
	@kubectl apply -f infrastructure/kubernetes/
	@echo "$(GREEN)✅ Kubernetes deployment completed!$(NC)"

# ===================================================================
# Security & Maintenance
# ===================================================================

security-scan: ## Run security scans
	@echo "$(BLUE)🔒 Running security scans...$(NC)"
	@docker run --rm -v $(PWD):/app securecodewarrior/docker-security-scanner /app
	@cd frontend && flutter analyze
	@cd backend && dart analyze
	@echo "$(GREEN)✅ Security scans completed!$(NC)"

update-deps: ## Update all dependencies
	@echo "$(BLUE)🔄 Updating dependencies...$(NC)"
	@cd frontend && flutter pub upgrade
	@cd backend && dart pub upgrade
	@cd ai-services/yolo-api && pip install --upgrade -r requirements.txt
	@cd ai-services/reasoning-engine && pip install --upgrade -r requirements.txt
	@echo "$(GREEN)✅ Dependencies updated!$(NC)"

clean: ## Clean all build artifacts and caches
	@echo "$(YELLOW)🧹 Cleaning build artifacts...$(NC)"
	@$(MAKE) flutter-clean
	@cd backend && dart clean
	@docker system prune -f
	@docker volume prune -f
	@echo "$(GREEN)✅ Cleanup completed!$(NC)"

# ===================================================================
# Development Utilities
# ===================================================================

dev-setup: ## Setup development environment
	@echo "$(CYAN)🔧 Setting up development environment...$(NC)"
	@$(MAKE) install
	@$(MAKE) start
	@$(MAKE) seed-database
	@echo "$(GREEN)✅ Development environment ready!$(NC)"

dev-reset: ## Reset development environment
	@echo "$(YELLOW)🔄 Resetting development environment...$(NC)"
	@$(MAKE) stop
	@$(MAKE) clean
	@$(MAKE) dev-setup

format: ## Format all code
	@echo "$(BLUE)✨ Formatting code...$(NC)"
	@cd frontend && dart format .
	@cd backend && dart format .
	@cd ai-services/yolo-api && black .
	@cd ai-services/reasoning-engine && black .
	@echo "$(GREEN)✅ Code formatting completed!$(NC)"

lint: ## Run linters on all code
	@echo "$(BLUE)🔍 Running linters...$(NC)"
	@cd frontend && flutter analyze
	@cd backend && dart analyze
	@cd ai-services/yolo-api && flake8 .
	@cd ai-services/reasoning-engine && flake8 .
	@echo "$(GREEN)✅ Linting completed!$(NC)"

# ===================================================================
# Documentation
# ===================================================================

docs-serve: ## Serve documentation locally
	@echo "$(BLUE)📚 Serving documentation...$(NC)"
	@cd docs && python -m http.server 8000
	@echo "Documentation available at http://localhost:8000"

docs-build: ## Build documentation
	@echo "$(BLUE)📖 Building documentation...$(NC)"
	@cd docs && mkdocs build
	@echo "$(GREEN)✅ Documentation built!$(NC)"

api-docs: ## Generate API documentation
	@echo "$(BLUE)📋 Generating API documentation...$(NC)"
	@cd backend && dart doc
	@echo "$(GREEN)✅ API documentation generated!$(NC)"

# ===================================================================
# Quick Commands
# ===================================================================

quick-start: ## Quick start for new developers
	@echo "$(CYAN)⚡ Quick start for Thai Herbal GACP Platform...$(NC)"
	@$(MAKE) check-requirements
	@$(MAKE) setup-env
	@$(MAKE) install-frontend
	@$(MAKE) start
	@echo "$(GREEN)🎉 Quick start completed! Visit http://localhost:8080$(NC)"

health-check: ## Check health of all services
	@echo "$(BLUE)🏥 Checking service health...$(NC)"
	@curl -f http://localhost:8080/health && echo " ✅ Backend healthy"
	@curl -f http://localhost:5000/health && echo " ✅ YOLO API healthy"
	@curl -f http://localhost:5001/health && echo " ✅ Reasoning Engine healthy"
	@curl -f http://localhost:9090/-/healthy && echo " ✅ Prometheus healthy"
	@curl -f http://localhost:3000/api/health && echo " ✅ Grafana healthy"

info: ## Show project information
	@echo ""
	@echo "$(CYAN)🌿 Thai Herbal GACP Platform v3.0$(NC)"
	@echo "$(WHITE)================================$(NC)"
	@echo ""
	@echo "$(BLUE)Project:$(NC) Thai Herbal GACP Certification Platform"
	@echo "$(BLUE)Version:$(NC) 3.0.0"
	@echo "$(BLUE)Environment:$(NC) $(APP_ENV)"
	@echo ""
	@echo "$(BLUE)Services:$(NC)"
	@echo "  • Frontend (Flutter):    http://localhost:8080"
	@echo "  • Backend (Dart):        http://localhost:8080/api"
	@echo "  • YOLO API:              http://localhost:5000"
	@echo "  • Reasoning Engine:      http://localhost:5001"
	@echo "  • PostgreSQL:            localhost:5432"
	@echo "  • Neo4j:                 http://localhost:7474"
	@echo "  • Redis:                 localhost:6379"
	@echo ""
	@echo "$(BLUE)Monitoring:$(NC)"
	@echo "  • Grafana:               http://localhost:3000"
	@echo "  • Prometheus:            http://localhost:9090"
	@echo "  • Kibana:                http://localhost:5601"
	@echo ""
	@echo "$(YELLOW)For help: make help$(NC)"
	@echo ""

# ===================================================================
# Special Targets
# ===================================================================

.PHONY: *CYAN)🌿 Thai Herbal GACP Platform v3.0 - Management Commands$(NC)"
	@echo ""
	@echo "$(WHITE)Available commands:$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make install          # Setup the project"
	@echo "  make start            # Start all services"
	@echo "  make logs service=backend  # View specific service logs"
	@echo "  make test-frontend    # Run Flutter tests"
	@echo ""

# ===================================================================
# Installation & Setup
# ===================================================================

install: ## Install dependencies and setup the project
	@echo "$(CYAN)🚀 Installing Thai Herbal GACP Platform...$(NC)"
	@$(MAKE) check-requirements
	@$(MAKE) setup-env
	@$(MAKE) install-frontend
	@$(MAKE) install-backend
	@$(MAKE) install-ai-services
	@$(MAKE) setup-database
	@echo "$(GREEN)✅ Installation completed!$(NC)"

check-requirements: ## Check if required tools are installed
	@echo "$(BLUE)🔍 Checking system requirements...$(NC)"
	@command -v docker >/dev/null 2>&1 || { echo "$(RED)❌ Docker is required but not installed.$(NC)"; exit 1; }
	@command -v docker-compose >/dev/null 2>&1 || { echo "$(RED)❌ Docker Compose is required but not installed.$(NC)"; exit 1; }
	@command -v flutter >/dev/null 2>&1 || { echo "$(RED)❌ Flutter is required but not installed.$(NC)"; exit 1; }
	@command -v dart >/dev/null 2>&1 || { echo "$(RED)❌ Dart is required but not installed.$(NC)"; exit 1; }
	@command -v python3 >/dev/null 2>&1 || { echo "$(RED)❌ Python 3 is required but not installed.$(NC)"; exit 1; }
	@echo "$(
