#!/bin/bash

set -e

echo "🧪 File Compression Service - API Tests"
echo "========================================"

# Configuration
API_URL="${API_URL:-http://localhost:8080}"
TEST_DIR="test/sample-files"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
TESTS_RUN=0#!/bin/bash

set -e

echo "🧪 File Compression Service - API Tests"
echo "========================================"

# Configuration
API_URL="${API_URL:-http://localhost:8080}"
TEST_DIR="test/sample-files"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

log_test() {
    echo -e "\n${YELLOW}[TEST]${NC} $1"
    TESTS_RUN=$((TESTS_RUN + 1))
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Wait for server to be ready
wait_for_server() {
    echo "Waiting for server to be ready..."
    for i in {1..30}; do
        if curl -s -f "$API_URL/health" > /dev/null 2>&1; then
            echo "Server is ready!"
            return 0
        fi
        echo -n "."
        sleep 1
    done
    echo ""
    log_fail "Server did not start in time"
    exit 1
}

# Test health endpoint
test_health() {
    log_test "Testing health endpoint"
    
    response=$(curl -s -w "\n%{http_code}" "$API_URL/health")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" = "200" ]; then
        if echo "$body" | grep -q "healthy"; then
            log_pass "Health check successful"
        else
            log_fail "Health check returned unexpected response"
        fi
    else
        log_fail "Health check failed with HTTP $http_code"
    fi
}

# Test info endpoint
test_info() {
    log_test "Testing info endpoint"
    
    response=$(curl -s -w "\n%{http_code}" "$API_URL/info")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" = "200" ]; then
        if echo "$body" | grep -q "algorithms"; then
            log_pass "Info endpoint successful"
        else
            log_fail "Info endpoint returned unexpected response"
        fi
    else
        log_fail "Info endpoint failed with HTTP $http_code"
    fi
}

# Test compression with an algorithm
test_compression() {
    local algorithm=$1
    local test_file=$2
    
    log_test "Testing $algorithm compression"
    
    # Compress
    if curl -s -X POST "$API_URL/compress" \
        -F "algorithm=$algorithm" \
        -F "file=@$test_file" \
        -o "tmp/compressed_${algorithm}" \
        -w "%{http_code}" | grep -q "200"; then
        
        if [ -f "tmp/compressed_${algorithm}" ] && [ -s "tmp/compressed_${algorithm}" ]; then
            log_pass "$algorithm compression successful"
            
            # Test decompression
            log_test "Testing $algorithm decompression"
            
            if curl -s -X POST "$API_URL/decompress" \
                -F "algorithm=$algorithm" \
                -F "file=@tmp/compressed_${algorithm}" \
                -o "tmp/decompressed_${algorithm}.txt" \
                -w "%{http_code}" | grep -q "200"; then
                
                if [ -f "tmp/decompressed_${algorithm}.txt" ] && [ -s "tmp/decompressed_${algorithm}.txt" ]; then
                    # Compare original and decompressed
                    if diff -q "$test_file" "tmp/decompressed_${algorithm}.txt" > /dev/null; then
                        log_pass "$algorithm decompression successful - files match"
                    else
                        log_fail "$algorithm decompression produced empty file"
                fi
            else
                log_fail "$algorithm decompression request failed"
            fi
        else
            log_fail "$algorithm compression produced empty file"
        fi
    else
        log_fail "$algorithm compression request failed"
    fi
}

# Test invalid algorithm
test_invalid_algorithm() {
    log_test "Testing invalid algorithm handling"
    
    response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/compress" \
        -F "algorithm=invalid" \
        -F "file=@$TEST_DIR/sample.txt")
    
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "400" ]; then
        log_pass "Invalid algorithm correctly rejected"
    else
        log_fail "Invalid algorithm not rejected (HTTP $http_code)"
    fi
}

# Test missing file
test_missing_file() {
    log_test "Testing missing file handling"
    
    response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/compress" \
        -F "algorithm=gzip")
    
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "400" ]; then
        log_pass "Missing file correctly rejected"
    else
        log_fail "Missing file not rejected (HTTP $http_code)"
    fi
}

# Test large file
test_large_file() {
    log_test "Testing large file compression"
    
    # Create a 1MB test file
    dd if=/dev/urandom of=tmp/large_test.bin bs=1024 count=1024 2>/dev/null
    
    response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/compress" \
        -F "algorithm=gzip" \
        -F "file=@tmp/large_test.bin" \
        -o tmp/large_compressed.gz)
    
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "200" ]; then
        log_pass "Large file compression successful"
    else
        log_fail "Large file compression failed (HTTP $http_code)"
    fi
    
    rm -f tmp/large_test.bin tmp/large_compressed.gz
}

# Create test files if they don't exist
setup_test_files() {
    echo "Setting up test files..."
    mkdir -p tmp
    
    if [ ! -d "$TEST_DIR" ]; then
        mkdir -p "$TEST_DIR"
    fi
    
    if [ ! -f "$TEST_DIR/sample.txt" ]; then
        cat > "$TEST_DIR/sample.txt" << 'EOF'
The quick brown fox jumps over the lazy dog.
The quick brown fox jumps over the lazy dog.
This is a test file for compression algorithms.
Testing various compression methods.
EOF
    fi
}

# Cleanup test files
cleanup() {
    echo "Cleaning up test files..."
    rm -rf tmp/compressed_* tmp/decompressed_*
}

# Print summary
print_summary() {
    echo ""
    echo "======================================"
    echo "Test Summary"
    echo "======================================"
    echo "Total tests run: $TESTS_RUN"
    echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
        echo ""
        echo "❌ Some tests failed!"
        exit 1
    else
        echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
        echo ""
        echo "✅ All tests passed!"
        exit 0
    fi
}

# Main test execution
main() {
    echo "API URL: $API_URL"
    echo ""
    
    # Setup
    setup_test_files
    wait_for_server
    
    # Run tests
    test_health
    test_info
    test_invalid_algorithm
    test_missing_file
    
    # Test all algorithms
    test_compression "huffman" "$TEST_DIR/sample.txt"
    test_compression "lzss" "$TEST_DIR/sample.txt"
    test_compression "flate" "$TEST_DIR/sample.txt"
    test_compression "gzip" "$TEST_DIR/sample.txt"
    
    # Additional tests
    test_large_file
    
    # Cleanup and summary
    cleanup
    print_summary
}

# Handle Ctrl+C
trap cleanup EXIT

# Run tests
main produced different content"
                    fi
                else
                    log_fail "$algorithm decompression
TESTS_PASSED=0
TESTS_FAILED=0

log_test() {
    echo -e "\n${YELLOW}[TEST]${NC} $1"
    TESTS_RUN=$((TESTS_RUN + 1))
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Wait for server to be ready
wait_for_server() {
    echo "Waiting for server to be ready..."
    for i in {1..30}; do
        if curl -s -f "$API_URL/health" > /dev/null 2>&1; then
            echo "Server is ready!"
            return 0
        fi
        echo -n "."
        sleep 1
    done
    echo ""
    log_fail "Server did not start in time"
    exit 1
}

# Test health endpoint
test_health() {
    log_test "Testing health endpoint"
    
    response=$(curl -s -w "\n%{http_code}" "$API_URL/health")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" = "200" ]; then
        if echo "$body" | grep -q "healthy"; then
            log_pass "Health check successful"
        else
            log_fail "Health check returned unexpected response"
        fi
    else
        log_fail "Health check failed with HTTP $http_code"
    fi
}

# Test info endpoint
test_info() {
    log_test "Testing info endpoint"
    
    response=$(curl -s -w "\n%{http_code}" "$API_URL/info")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" = "200" ]; then
        if echo "$body" | grep -q "algorithms"; then
            log_pass "Info endpoint successful"
        else
            log_fail "Info endpoint returned unexpected response"
        fi
    else
        log_fail "Info endpoint failed with HTTP $http_code"
    fi
}

# Test compression with an algorithm
test_compression() {
    local algorithm=$1
    local test_file=$2
    
    log_test "Testing $algorithm compression"
    
    # Compress
    if curl -s -X POST "$API_URL/compress" \
        -F "algorithm=$algorithm" \
        -F "file=@$test_file" \
        -o "tmp/compressed_${algorithm}" \
        -w "%{http_code}" | grep -q "200"; then
        
        if [ -f "tmp/compressed_${algorithm}" ] && [ -s "tmp/compressed_${algorithm}" ]; then
            log_pass "$algorithm compression successful"
            
            # Test decompression
            log_test "Testing $algorithm decompression"
            
            if curl -s -X POST "$API_URL/decompress" \
                -F "algorithm=$algorithm" \
                -F "file=@tmp/compressed_${algorithm}" \
                -o "tmp/decompressed_${algorithm}.txt" \
                -w "%{http_code}" | grep -q "200"; then
                
                if [ -f "tmp/decompressed_${algorithm}.txt" ] && [ -s "tmp/decompressed_${algorithm}.txt" ]; then
                    # Compare original and decompressed
                    if diff -q "$test_file" "tmp/decompressed_${algorithm}.txt" > /dev/null; then
                        log_pass "$algorithm decompression successful - files match"
                    else
                        log_fail "$algorithm decompression produced different content"
                    fi
                else
                    log_fail "$algorithm decompression