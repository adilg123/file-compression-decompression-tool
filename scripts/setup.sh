#!/bin/bash

set -e

echo "🔧 File Compression Service Setup Script"
echo "========================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Go is installed
check_go() {
    if ! command -v go &> /dev/null; then
        log_error "Go is not installed. Please install Go 1.23.5 or later."
        echo "Visit: https://golang.org/doc/install"
        exit 1
    fi
    
    GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    log_info "Go version: $GO_VERSION ✓"
}

# Check if Docker is installed (optional)
check_docker() {
    if command -v docker &> /dev/null; then
        log_info "Docker found ✓"
        DOCKER_AVAILABLE=true
    else
        log_warn "Docker not found (optional for development)"
        DOCKER_AVAILABLE=false
    fi
}

# Check if docker-compose is installed (optional)
check_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        log_info "docker-compose found ✓"
        COMPOSE_AVAILABLE=true
    else
        log_warn "docker-compose not found (optional for development)"
        COMPOSE_AVAILABLE=false
    fi
}

# Install Go dependencies
install_dependencies() {
    log_info "Installing Go dependencies..."
    
    if [ ! -f "go.mod" ]; then
        log_error "go.mod not found. Are you in the project root?"
        exit 1
    fi
    
    go mod download
    go mod tidy
    
    log_info "Dependencies installed ✓"
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."
    
    mkdir -p logs
    mkdir -p tmp
    mkdir -p test/sample-files
    mkdir -p docs
    
    log_info "Directories created ✓"
}

# Create sample test files
create_test_files() {
    log_info "Creating sample test files..."
    
    # Text file
    cat > test/sample-files/sample.txt << 'EOF'
The quick brown fox jumps over the lazy dog.
The quick brown fox jumps over the lazy dog.
This is a sample text file for testing compression algorithms.
Compression ratio will vary based on the algorithm used.
EOF

    # JSON file
    cat > test/sample-files/sample.json << 'EOF'
{
  "name": "Compression Test",
  "algorithms": ["huffman", "lzss", "flate", "gzip"],
  "description": "This is a sample JSON file for testing compression",
  "data": {
    "repeated": "value",
    "repeated": "value",
    "repeated": "value"
  }
}
EOF

    # Log file
    cat > test/sample-files/sample.log << 'EOF'
2025-01-01 10:00:00 INFO Server started
2025-01-01 10:00:01 INFO Request received
2025-01-01 10:00:02 INFO Processing request
2025-01-01 10:00:03 INFO Request completed
2025-01-01 10:00:04 INFO Server running
EOF

    log_info "Test files created ✓"
}

# Create environment file
create_env_file() {
    if [ ! -f ".env" ]; then
        log_info "Creating .env file..."
        cat > .env << 'EOF'
# Server Configuration
PORT=8080

# Environment (development, production)
GO_ENV=development

# Maximum file size (in bytes)
MAX_FILE_SIZE=52428800
EOF
        log_info ".env file created ✓"
    else
        log_info ".env file already exists (skipped)"
    fi
}

# Make scripts executable
make_scripts_executable() {
    if [ -d "scripts" ]; then
        log_info "Making scripts executable..."
        chmod +x scripts/*.sh 2>/dev/null || true
        log_info "Scripts are executable ✓"
    fi
}

# Test build
test_build() {
    log_info "Testing build..."
    
    if go build -o tmp/test-build .; then
        rm tmp/test-build
        log_info "Build test successful ✓"
    else
        log_error "Build test failed"
        exit 1
    fi
}

# Print next steps
print_next_steps() {
    echo ""
    echo "======================================"
    log_info "Setup completed successfully! 🎉"
    echo "======================================"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Run the server:"
    echo "   go run main.go"
    echo "   OR"
    echo "   make run"
    echo ""
    echo "2. Test the API:"
    echo "   curl http://localhost:8080/health"
    echo ""
    echo "3. Compress a test file:"
    echo "   curl -X POST http://localhost:8080/compress \\"
    echo "     -F \"algorithm=gzip\" \\"
    echo "     -F \"file=@test/sample-files/sample.txt\" \\"
    echo "     -o compressed.gz"
    echo ""
    
    if [ "$DOCKER_AVAILABLE" = true ] && [ "$COMPOSE_AVAILABLE" = true ]; then
        echo "4. Or deploy with Docker:"
        echo "   docker-compose up -d"
        echo ""
    fi
    
    echo "For more information:"
    echo "  - Read QUICKSTART.md for quick start guide"
    echo "  - Read README.md for detailed documentation"
    echo "  - Run 'make help' for available commands"
    echo ""
}

# Main setup process
main() {
    log_info "Starting setup process..."
    echo ""
    
    check_go
    check_docker
    check_docker_compose
    echo ""
    
    install_dependencies
    create_directories
    create_test_files
    create_env_file
    make_scripts_executable
    test_build
    
    print_next_steps
}

# Run main
main