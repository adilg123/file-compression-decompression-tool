#!/bin/bash

set -e

echo "🚀 File Compression Service Deployment Script"
echo "============================================="

# Configuration
SERVICE_NAME="compression-service"
IMAGE_NAME="compression-service"
CONTAINER_NAME="compression-service"
PORT="8080"
DOMAIN=${DOMAIN:-"localhost"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    log_info "Docker is running ✓"
}

# Check if docker-compose is available
check_docker_compose() {
    if ! command -v docker-compose > /dev/null 2>&1; then
        log_error "docker-compose is not installed. Please install it first."
        exit 1
    fi
    log_info "docker-compose is available ✓"
}

# Build the Docker image
build_image() {
    log_info "Building Docker image..."
    if docker build -t $IMAGE_NAME:latest .; then
        log_info "Docker image built successfully ✓"
    else
        log_error "Failed to build Docker image"
        exit 1
    fi
}

# Deploy using docker-compose
deploy_compose() {
    log_info "Deploying with docker-compose..."
    
    # Stop existing containers
    if docker-compose ps -q $SERVICE_NAME > /dev/null 2>&1; then
        log_info "Stopping existing containers..."
        docker-compose down
    fi
    
    # Deploy
    if docker-compose up -d; then
        log_info "Service deployed successfully ✓"
    else
        log_error "Failed to deploy service"
        exit 1
    fi
}

# Deploy using plain Docker
deploy_docker() {
    log_info "Deploying with Docker..."
    
    # Stop and remove existing container
    if docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log_info "Stopping existing container..."
        docker stop $CONTAINER_NAME
        docker rm $CONTAINER_NAME
    fi
    
    # Run new container
    if docker run -d \
        --name $CONTAINER_NAME \
        -p $PORT:8080 \
        --restart unless-stopped \
        -e GO_ENV=production \
        -e PORT=8080 \
        $IMAGE_NAME:latest; then
        log_info "Container started successfully ✓"
    else
        log_error "Failed to start container"
        exit 1
    fi
}

# Health check
health_check() {
    log_info "Performing health check..."
    
    # Wait for service to start
    sleep 5
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "http://localhost:$PORT/health" > /dev/null 2>&1; then
            log_info "Service is healthy ✓"
            return 0
        fi
        
        log_warn "Attempt $attempt/$max_attempts: Service not ready yet..."
        sleep 2
        ((attempt++))
    done
    
    log_error "Service health check failed after $max_attempts attempts"
    return 1
}

# Show service information
show_info() {
    log_info "Service Information:"
    echo "==================="
    echo "Service Name: $SERVICE_NAME"
    echo "Local URL: http://localhost:$PORT"
    echo "Health Check: http://localhost:$PORT/health"
    echo "API Info: http://localhost:$PORT/info"
    
    if [ "$DOMAIN" != "localhost" ]; then
        echo "Public URL: https://$DOMAIN"
    fi
    
    echo ""
    echo "API Endpoints:"
    echo "- POST /compress   - Compress files"
    echo "- POST /decompress - Decompress files" 
    echo "- GET  /info       - Service information"
    echo "- GET  /health     - Health check"
    echo ""
}

# Show logs
show_logs() {
    log_info "Recent logs:"
    if command -v docker-compose > /dev/null 2>&1 && [ -f "docker-compose.yml" ]; then
        docker-compose logs --tail=20 $SERVICE_NAME
    else
        docker logs --tail=20 $CONTAINER_NAME
    fi
}

# Main deployment function
deploy() {
    local method=${1:-"compose"}
    
    check_docker
    
    case $method in
        "compose")
            check_docker_compose
            build_image
            deploy_compose
            ;;
        "docker")
            build_image
            deploy_docker
            ;;
        *)
            log_error "Invalid deployment method: $method"
            log_info "Valid options: compose, docker"
            exit 1
            ;;
    esac
    
    if health_check; then
        show_info
        log_info "Deployment completed successfully! 🎉"
    else
        log_error "Deployment completed but service is not healthy"
        show_logs
        exit 1
    fi
}

# Script usage
usage() {
    echo "Usage: $0 [METHOD]"
    echo ""
    echo "METHOD:"
    echo "  compose  - Deploy using docker-compose (default)"
    echo "  docker   - Deploy using plain Docker"
    echo "  logs     - Show recent logs"
    echo "  health   - Check service health"
    echo "  info     - Show service information"
    echo "  stop     - Stop the service"
    echo ""
    echo "Environment Variables:"
    echo "  DOMAIN   - Public domain name (default: localhost)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Deploy with docker-compose"
    echo "  $0 compose            # Deploy with docker-compose"
    echo "  $0 docker             # Deploy with plain Docker"
    echo "  DOMAIN=api.example.com $0 compose"
    echo ""
}

# Stop service
stop_service() {
    log_info "Stopping service..."
    
    if command -v docker-compose > /dev/null 2>&1 && [ -f "docker-compose.yml" ]; then
        docker-compose down
    else
        if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
            docker stop $CONTAINER_NAME
            docker rm $CONTAINER_NAME
        fi
    fi
    
    log_info "Service stopped ✓"
}

# Main script logic
case "${1:-compose}" in
    "compose"|"docker")
        deploy "$1"
        ;;
    "logs")
        show_logs
        ;;
    "health")
        health_check
        ;;
    "info")
        show_info
        ;;
    "stop")
        stop_service
        ;;
    "help"|"-h"|"--help")
        usage
        ;;
    *)
        log_error "Unknown command: $1"
        usage
        exit 1
        ;;
esac