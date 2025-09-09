BINARY := compression-service
VERSION := v1.0.0
DOCKER_IMAGE := compression-service
DOCKER_TAG := latest

.PHONY: all build run test clean docker-build docker-run docker-push deploy dev help

# Default target
all: build

# Build the application
build:
	@echo "Building $(BINARY)..."
	@go build -o $(BINARY) .

# Run the application locally
run: build
	@echo "Starting $(BINARY)..."
	@./$(BINARY)

# Run in development mode with auto-reload
dev:
	@echo "Starting development server..."
	@go run . &
	@echo "Server started. Visit http://localhost:8080"

# Run tests
test:
	@echo "Running tests..."
	@go test -v ./...

# Clean build artifacts
clean:
	@echo "Cleaning up..."
	@rm -f $(BINARY)
	@docker image prune -f

# Docker commands
docker-build:
	@echo "Building Docker image $(DOCKER_IMAGE):$(DOCKER_TAG)..."
	@docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

docker-run: docker-build
	@echo "Running Docker container..."
	@docker run -p 8080:8080 --rm $(DOCKER_IMAGE):$(DOCKER_TAG)

# Deploy with docker-compose
deploy:
	@echo "Deploying with docker-compose..."
	@docker-compose up -d

# Stop deployment
stop:
	@echo "Stopping deployment..."
	@docker-compose down

# View logs
logs:
	@docker-compose logs -f compression-service

# Check service status
status:
	@docker-compose ps
	@echo "\nService health check:"
	@curl -s http://localhost:8080/health | jq . || echo "Service not responding"

# Install dependencies
deps:
	@echo "Installing dependencies..."
	@go mod tidy
	@go mod download

# Format code
fmt:
	@echo "Formatting code..."
	@go fmt ./...

# Lint code
lint:
	@echo "Linting code..."
	@golint ./... || echo "golint not installed. Run: go install golang.org/x/lint/golint@latest"

# Update README with API documentation
docs:
	@echo "Generating API documentation..."
	@curl -s http://localhost:8080/info | jq . > api-info.json
	@echo "API documentation saved to api-info.json"

# Help
help:
	@echo "Available commands:"
	@echo "  build        - Build the application"
	@echo "  run          - Build and run the application"
	@echo "  dev          - Run in development mode"
	@echo "  test         - Run tests"
	@echo "  clean        - Clean build artifacts"
	@echo "  docker-build - Build Docker image"
	@echo "  docker-run   - Build and run Docker container"
	@echo "  deploy       - Deploy with docker-compose"
	@echo "  stop         - Stop docker-compose deployment"
	@echo "  logs         - View service logs"
	@echo "  status       - Check service status"
	@echo "  deps         - Install dependencies"
	@echo "  fmt          - Format code"
	@echo "  lint         - Lint code"
	@echo "  docs         - Generate API documentation"
	@echo "  help         - Show this help message"