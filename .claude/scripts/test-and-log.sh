#!/bin/bash

# CCPM Test and Log Runner v2.0
# Runs tests with comprehensive logging, error handling, and reporting

set -euo pipefail

# Load core functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Load libraries with error checking
if [[ -f "$LIB_DIR/core.sh" ]]; then
    source "$LIB_DIR/core.sh"
fi

if [[ -f "$LIB_DIR/ui.sh" ]]; then
    source "$LIB_DIR/ui.sh"
fi

# Configuration
LOGS_DIR=".claude/logs/tests"
REPORTS_DIR=".claude/tmp/test-reports"

# Function to show usage
show_usage() {
    show_command_help "test-and-log" "Run tests with comprehensive logging" \
        "test-and-log <test_file> [log_name]         # Run test with logging
test-and-log tests/my_test.py                   # Auto-generate log name
test-and-log tests/my_test.py custom_log        # Use custom log name
test-and-log --list-runners                     # Show supported test runners"
    
    echo ""
    echo "Supported Test Types:"
    echo "  .py          Python tests (pytest, unittest)"
    echo "  .js, .ts     JavaScript/TypeScript tests (jest, mocha)"
    echo "  .go          Go tests (go test)"
    echo "  .rs          Rust tests (cargo test)"
    echo "  .java        Java tests (junit)"
    echo "  .bats        Bash tests (bats)"
    echo ""
    echo "Examples:"
    echo "  test-and-log tests/unit/auth_test.py       # Run Python test"
    echo "  test-and-log tests/e2e/login.js           # Run JS test"
    echo "  test-and-log tests/integration/api.go     # Run Go test"
    echo "  test-and-log tests/unit/utils.bats        # Run Bash test"
}

# Cleanup function for temporary files
cleanup() {
    if [[ -n "${TEMP_FILES:-}" ]]; then
        for temp_file in "${TEMP_FILES[@]}"; do
            [[ -f "$temp_file" ]] && rm -f "$temp_file"
        done
    fi
}
trap cleanup EXIT

# Validate test file path
validate_test_path() {
    local test_path="$1"
    
    if [[ ! -f "$test_path" ]]; then
        show_error "Test File Missing" "Test file not found: $test_path"
        return 1
    fi
    
    # Check if file looks like a test
    if [[ ! "$test_path" =~ test|spec ]]; then
        show_warning "File Pattern" "File doesn't appear to be a test (no 'test' or 'spec' in name)"
    fi
    
    # Check file extension
    if [[ ! "$test_path" =~ \.(py|js|ts|go|rs|java|bats)$ ]]; then
        show_warning "File Extension" "Unrecognized test file extension"
    fi
    
    return 0
}

# Check prerequisites for test execution
check_prerequisites() {
    local test_path="$1"
    local extension="${test_path##*.}"
    local missing_deps=()
    
    show_subtitle "🔍 Environment Check"
    
    case "$extension" in
        "py")
            if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
                missing_deps+=("Python (python3 or python)")
            elif command -v pytest >/dev/null 2>&1; then
                show_success "Python" "pytest available"
            elif command -v python3 >/dev/null 2>&1; then
                show_success "Python" "python3 available (unittest mode)"
            else
                show_success "Python" "python available (unittest mode)"
            fi
            ;;
        "js"|"ts")
            if ! command -v node >/dev/null 2>&1; then
                missing_deps+=("Node.js")
            else
                show_success "Node.js" "Available for JavaScript/TypeScript tests"
                
                # Check for test frameworks
                if command -v jest >/dev/null 2>&1; then
                    show_info "✓ Jest test framework available"
                elif command -v mocha >/dev/null 2>&1; then
                    show_info "✓ Mocha test framework available"
                fi
            fi
            ;;
        "go")
            if ! command -v go >/dev/null 2>&1; then
                missing_deps+=("Go")
            else
                show_success "Go" "Available for Go tests"
            fi
            ;;
        "rs")
            if ! command -v cargo >/dev/null 2>&1; then
                missing_deps+=("Rust/Cargo")
            else
                show_success "Rust" "Cargo available for Rust tests"
            fi
            ;;
        "java")
            if ! command -v java >/dev/null 2>&1; then
                missing_deps+=("Java")
            else
                show_success "Java" "Available for Java tests"
            fi
            ;;
        "bats")
            if ! command -v bats >/dev/null 2>&1; then
                missing_deps+=("BATS (Bash Automated Testing System)")
            else
                show_success "BATS" "Available for Bash tests"
            fi
            ;;
    esac
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        show_error "Missing Dependencies" "Required tools not found:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        return 1
    fi
    
    return 0
}

# Determine test runner command
get_test_runner() {
    local test_path="$1"
    local extension="${test_path##*.}"
    
    case "$extension" in
        "py")
            # Prefer pytest if available, fall back to unittest
            if command -v pytest >/dev/null 2>&1; then
                echo "pytest -v"
            elif command -v python3 >/dev/null 2>&1; then
                echo "python3 -m unittest"
            else
                echo "python -m unittest"
            fi
            ;;
        "js"|"ts")
            # Try to detect test framework
            if [[ -f "package.json" ]] && grep -q "jest" package.json; then
                echo "npm test"
            elif command -v jest >/dev/null 2>&1; then
                echo "jest"
            elif command -v mocha >/dev/null 2>&1; then
                echo "mocha"
            else
                echo "node"
            fi
            ;;
        "go")
            echo "go test -v"
            ;;
        "rs")
            echo "cargo test --"
            ;;
        "java")
            echo "java -cp .:junit.jar:hamcrest.jar org.junit.runner.JUnitCore"
            ;;
        "bats")
            echo "bats"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Generate comprehensive test report
generate_test_report() {
    local test_path="$1"
    local log_file="$2"
    local exit_code="$3"
    local duration="$4"
    local runner="$5"
    
    local report_file="$REPORTS_DIR/$(basename "$test_path" .${test_path##*.})-report.json"
    
    local timestamp
    timestamp=$(format_timestamp)
    
    cat > "$report_file" << EOF
{
  "test_execution": {
    "test_file": "$test_path",
    "log_file": "$log_file",
    "runner": "$runner",
    "exit_code": $exit_code,
    "duration_seconds": $duration,
    "timestamp": "$timestamp",
    "status": "$([[ $exit_code -eq 0 ]] && echo "PASSED" || echo "FAILED")"
  },
  "environment": {
    "os": "$(uname -s)",
    "shell": "$SHELL",
    "pwd": "$(pwd)"
  },
  "files": {
    "log_path": "$log_file",
    "test_path": "$test_path"
  }
}
EOF
    
    echo "$report_file"
}

# List supported test runners
list_runners() {
    show_title "🔧 Supported Test Runners" 40
    
    show_subtitle "🐍 Python"
    echo "  pytest (preferred)    - Advanced Python testing framework"
    echo "  unittest             - Built-in Python testing framework"
    echo ""
    
    show_subtitle "🟡 JavaScript/TypeScript"
    echo "  jest                 - Modern JavaScript testing framework"
    echo "  mocha                - Flexible JavaScript test framework"
    echo "  node                 - Direct Node.js execution"
    echo ""
    
    show_subtitle "🐹 Go"
    echo "  go test              - Built-in Go testing framework"
    echo ""
    
    show_subtitle "🦀 Rust"
    echo "  cargo test           - Built-in Rust testing framework"
    echo ""
    
    show_subtitle "☕ Java"
    echo "  junit                - Java unit testing framework"
    echo ""
    
    show_subtitle "🐚 Bash"
    echo "  bats                 - Bash Automated Testing System"
    echo ""
}

# Main execution function
main() {
    if [[ $# -eq 0 ]]; then
        show_error "Missing Arguments" "Test file path required"
        show_usage
        exit 1
    fi
    
    # Handle special commands
    if [[ "$1" == "--list-runners" ]]; then
        list_runners
        exit 0
    fi
    
    local test_path="$1"
    local log_name="${2:-}"
    
    show_title "🧪 CCPM Test Execution" 45
    show_info "Test File: $test_path"
    
    # Validate inputs
    if ! validate_test_path "$test_path"; then
        exit 1
    fi
    
    if ! check_prerequisites "$test_path"; then
        exit 1
    fi
    
    # Setup directories
    ensure_directory "$LOGS_DIR"
    ensure_directory "$REPORTS_DIR"
    
    # Determine log file name
    local log_file
    if [[ -n "$log_name" ]]; then
        # Use provided log filename
        if [[ ! "$log_name" == *.log ]]; then
            log_name="${log_name}.log"
        fi
        log_file="$LOGS_DIR/$log_name"
    else
        # Extract test name from path for auto-naming
        local test_name
        test_name=$(basename "$test_path" .${test_path##*.})
        local timestamp
        timestamp=$(date +%Y%m%d-%H%M%S)
        log_file="$LOGS_DIR/${test_name}-${timestamp}.log"
    fi
    
    # Get test runner
    local runner
    runner=$(get_test_runner "$test_path")
    
    if [[ "$runner" == "unknown" ]]; then
        show_error "Unsupported Test Type" "Cannot determine test runner for: $test_path"
        exit 1
    fi
    
    # Show execution plan
    show_subtitle "🎯 Execution Plan"
    show_info "Runner: $runner"
    show_info "Log File: $log_file"
    echo ""
    
    # Create temporary file for output capture
    local temp_log
    temp_log=$(mktemp)
    TEMP_FILES=("$temp_log")
    
    # Execute test with timing
    show_subtitle "▶️ Test Execution"
    show_progress "Running test..."
    
    local start_time end_time duration exit_code
    start_time=$(date +%s)
    
    # Execute the test command
    set +e  # Allow command to fail
    if [[ "$runner" =~ ^(go\ test|cargo\ test) ]]; then
        # Special handling for Go and Rust tests that need specific arguments
        $runner "$test_path" > "$temp_log" 2>&1
    else
        $runner "$test_path" > "$temp_log" 2>&1
    fi
    exit_code=$?
    set -e
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    # Save log file
    cp "$temp_log" "$log_file"
    
    # Generate test report
    local report_file
    report_file=$(generate_test_report "$test_path" "$log_file" "$exit_code" "$duration" "$runner")
    
    # Display results
    show_subtitle "📊 Test Results"
    
    if [[ $exit_code -eq 0 ]]; then
        show_success "Test Passed" "Test completed successfully"
        echo "  Duration: ${duration}s"
        echo "  Log: $log_file"
        echo "  Report: $report_file"
    else
        show_error "Test Failed" "Test failed with exit code $exit_code"
        echo "  Duration: ${duration}s"
        echo "  Log: $log_file"
        echo "  Report: $report_file"
        echo ""
        
        show_subtitle "🔍 Error Analysis"
        echo "Last 15 lines of output:"
        tail -15 "$log_file" | sed 's/^/  /'
    fi
    
    exit $exit_code
}

# Only run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi