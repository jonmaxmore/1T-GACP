# Makefile for Thai Herbal GACP Platform

.PHONY: build-backend run-backend test-backend \
        build-frontend run-frontend test-frontend \
        build-ai run-ai test-ai \
        compose-up compose-down compose-build \
        deploy-staging deploy-production \
        lint format

# Environment setup
setup:
	dart pub global activate melos
	melos bootstrap

# Backend commands
build-backend:
	cd backend && docker build -t gacp-backend:latest -f Dockerfile.prod .

run-backend:
	cd backend && dart run bin/server.dart

test-backend:
	cd backend && dart test

# Frontend commands
build-frontend:
	cd frontend && flutter build web --release
	docker build -t gacp-frontend:latest -f frontend/Dockerfile.prod .

run-frontend:
	cd frontend && flutter run

test-frontend:
	cd frontend && flutter test

# AI services
build-ai:
	cd ai-services/reasoning-engine && docker build -t gacp-ai:latest .

run-ai:
	cd ai-services/reasoning-engine && docker run -p 5000:5000 gacp-ai

test-ai:
	cd ai-services/reasoning-engine && pytest

# Docker Compose
compose-up:
	docker-compose -f docker-compose.prod.yml up -d

compose-down:
	docker-compose -f docker-compose.prod.yml down

compose-build:
	docker-compose -f docker-compose.prod.yml build

# Deployment
deploy-staging:
	./scripts/deploy.sh staging

deploy-production:
	./scripts/deploy.sh production

# Code quality
lint:
	cd backend && dart analyze
	cd frontend && flutter analyze
	cd ai-services/reasoning-engine && flake8 .

format:
	cd backend && dart format .
	cd frontend && dart format .
	cd ai-services/reasoning-engine && black .

# Database migrations
migrate:
	cd backend && dart run bin/migrate.dart

# Utility
clean:
	rm -rf */build
	docker system prune -f

help:
	@echo "Thai Herbal GACP Platform Management"
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build-backend    - Build backend Docker image"
	@echo "  run-backend      - Run backend locally"
	@echo "  test-backend     - Run backend tests"
	@echo "  build-frontend   - Build frontend Docker image"
	@echo "  run-frontend     - Run frontend locally"
	@echo "  test-frontend    - Run frontend tests"
	@echo "  compose-up       - Start all services with Docker"
	@echo "  compose-down     - Stop all services"
	@echo "  compose-build    - Build all Docker images"
	@echo "  deploy-staging   - Deploy to staging environment"
	@echo "  deploy-production- Deploy to production environment"
	@echo "  lint             - Run static analysis"
	@echo "  format           - Format code"
	@echo "  migrate          - Run database migrations"
	@echo "  clean            - Clean build artifacts"
