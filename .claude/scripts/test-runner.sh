#!/bin/bash

# CCPM Test Runner - Comprehensive Test Execution System
# Execute unit and integration tests with reporting and analysis for CCPM v2.0

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
TESTS_DIR=".claude/tests"
REPORTS_DIR=".claude/tmp/test-reports"
LOG_FILE=".claude/tmp/test-runner.log"

# Test execution statistics
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0
START_TIME=""
END_TIME=""

# Function to show usage
show_usage() {
    show_command_help "test-runner" "Execute CCPM tests with reporting" \
        "test-runner [COMMAND] [OPTIONS]             # Run tests
test-runner run all                            # Run all tests
test-runner unit                               # Run unit tests only
test-runner integration                        # Run integration tests only
test-runner clean                              # Clean test artifacts"
    
    echo ""
    echo "Commands:"
    echo "  run [type]      Run tests (type: all|unit|integration)"
    echo "  unit            Run unit tests only"
    echo "  integration     Run integration tests only"
    echo "  report          Show last test report"
    echo "  clean           Clean test reports and logs"
    echo ""
    echo "Options:"
    echo "  --parallel      Run unit tests in parallel"
    echo "  --pattern       Test file pattern (default: *.bats)"
    echo "  --no-cleanup    Keep temporary files after tests"
    echo ""
    echo "Examples:"
    echo "  test-runner run all                      # Run all tests"
    echo "  test-runner unit --parallel              # Run unit tests in parallel"
    echo "  test-runner run unit 'test_core*.bats'  # Run specific unit tests"
}

# Initialize test environment
init_test_environment() {
    show_subtitle "🔧 Test Environment Setup"
    
    # Ensure required directories exist
    ensure_directory "$REPORTS_DIR"
    ensure_directory "$(dirname "$LOG_FILE")"
    
    # Initialize timestamps
    START_TIME=$(format_timestamp)
    echo "[$START_TIME] Test run started" >> "$LOG_FILE"
    
    # Check if bats is available
    if ! command -v bats >/dev/null 2>&1; then
        show_error "BATS Missing" "BATS (Bash Automated Testing System) not found"
        show_tip "Install with: brew install bats-core"
        show_tip "Or visit: https://github.com/bats-core/bats-core"
        return 1
    fi
    
    local bats_version
    bats_version=$(bats --version | cut -d' ' -f2)
    show_success "BATS Available" "Version $bats_version"
    
    return 0
}

# Load test configuration
load_test_config() {
    local config_file="$TESTS_DIR/config.json"
    
    if [[ ! -f "$config_file" ]]; then
        show_warning "Test configuration not found, using defaults"
        return 1
    fi
    
    if command -v jq >/dev/null 2>&1; then
        local framework
        framework=$(jq -r '.framework.primary // "bats"' "$config_file" 2>/dev/null || echo "bats")
        
        if [[ "$framework" != "bats" ]]; then
            show_warning "Configured framework '$framework' not supported, using bats"
        fi
    fi
    
    return 0
}

# Run unit tests
run_unit_tests() {
    local test_pattern="${1:-*.bats}"
    local parallel="${2:-false}"
    
    show_subtitle "🧪 Unit Tests"
    show_info "Pattern: $test_pattern"
    
    local unit_tests_dir="$TESTS_DIR/unit"
    if [[ ! -d "$unit_tests_dir" ]]; then
        show_warning "Unit tests directory not found: $unit_tests_dir"
        return 0
    fi
    
    local test_files
    test_files=$(find "$unit_tests_dir" -name "$test_pattern" 2>/dev/null || true)
    
    if [[ -z "$test_files" ]]; then
        show_warning "No unit test files found matching pattern: $test_pattern"
        return 0
    fi
    
    local test_count
    test_count=$(echo "$test_files" | wc -l)
    show_info "Found $test_count unit test files"
    
    # Configure BATS options
    local bats_options=()
    bats_options+=("--formatter" "junit")
    bats_options+=("--output" "$REPORTS_DIR")
    
    if [[ "$parallel" == "true" ]] && command -v parallel >/dev/null 2>&1; then
        bats_options+=("--jobs" "4")
        show_info "Running tests in parallel (4 jobs)"
    fi
    
    # Run tests
    local exit_code=0
    show_progress "Running unit tests..."
    
    if ! bats "${bats_options[@]}" $test_files; then
        exit_code=1
        show_warning "Some unit tests failed"
    else
        show_success "Unit Tests" "All unit tests passed"
    fi
    
    # Parse results if JUnit output is available
    local unit_report="$REPORTS_DIR/report.xml"
    if [[ -f "$unit_report" ]]; then
        parse_junit_results "$unit_report" "Unit Tests"
    fi
    
    return $exit_code
}

# Run integration tests
run_integration_tests() {
    local test_pattern="${1:-*.bats}"
    
    show_subtitle "🔗 Integration Tests"
    show_info "Pattern: $test_pattern"
    
    local integration_tests_dir="$TESTS_DIR/integration"
    if [[ ! -d "$integration_tests_dir" ]]; then
        show_warning "Integration tests directory not found: $integration_tests_dir"
        return 0
    fi
    
    local test_files
    test_files=$(find "$integration_tests_dir" -name "$test_pattern" 2>/dev/null || true)
    
    if [[ -z "$test_files" ]]; then
        show_warning "No integration test files found matching pattern: $test_pattern"
        return 0
    fi
    
    local test_count
    test_count=$(echo "$test_files" | wc -l)
    show_info "Found $test_count integration test files"
    
    # Run tests sequentially (integration tests often have dependencies)
    local exit_code=0
    show_progress "Running integration tests..."
    
    if ! bats --formatter junit --output "$REPORTS_DIR" $test_files; then
        exit_code=1
        show_warning "Some integration tests failed"
    else
        show_success "Integration Tests" "All integration tests passed"
    fi
    
    return $exit_code
}

# Parse JUnit XML results
parse_junit_results() {
    local junit_file="$1"
    local test_type="$2"
    
    if [[ ! -f "$junit_file" ]]; then
        show_warning "Cannot parse test results - file not found: $junit_file"
        return 0
    fi
    
    if ! command -v xmllint >/dev/null 2>&1; then
        show_warning "xmllint not available - cannot parse detailed results"
        return 0
    fi
    
    local tests failures errors skipped
    tests=$(xmllint --xpath "//testsuite/@tests" "$junit_file" 2>/dev/null | cut -d'"' -f2 || echo "0")
    failures=$(xmllint --xpath "//testsuite/@failures" "$junit_file" 2>/dev/null | cut -d'"' -f2 || echo "0")
    errors=$(xmllint --xpath "//testsuite/@errors" "$junit_file" 2>/dev/null | cut -d'"' -f2 || echo "0")
    skipped=$(xmllint --xpath "//testsuite/@skipped" "$junit_file" 2>/dev/null | cut -d'"' -f2 || echo "0")
    
    local passed=$((tests - failures - errors - skipped))
    
    show_info "$test_type Results:"
    echo "  Total: $tests"
    echo "  Passed: $passed"
    echo "  Failed: $((failures + errors))"
    echo "  Skipped: $skipped"
    
    # Update global statistics
    TOTAL_TESTS=$((TOTAL_TESTS + tests))
    PASSED_TESTS=$((PASSED_TESTS + passed))
    FAILED_TESTS=$((FAILED_TESTS + failures + errors))
    SKIPPED_TESTS=$((SKIPPED_TESTS + skipped))
}

# Generate test report
generate_test_report() {
    END_TIME=$(format_timestamp)
    local report_file="$REPORTS_DIR/test-summary-$(date +%Y%m%d-%H%M%S).json"
    
    # Calculate duration (simplified)
    local duration="unknown"
    if command -v date >/dev/null 2>&1; then
        duration=$(($(date +%s) - $(date -d "$START_TIME" +%s 2>/dev/null || echo "0")))
    fi
    
    cat > "$report_file" << EOF
{
  "test_run": {
    "start_time": "$START_TIME",
    "end_time": "$END_TIME", 
    "duration_seconds": "$duration",
    "runner_version": "2.0"
  },
  "results": {
    "total_tests": $TOTAL_TESTS,
    "passed": $PASSED_TESTS,
    "failed": $FAILED_TESTS,
    "skipped": $SKIPPED_TESTS,
    "success_rate": $(( TOTAL_TESTS > 0 ? (PASSED_TESTS * 100) / TOTAL_TESTS : 0 ))
  },
  "environment": {
    "bats_version": "$(bats --version 2>/dev/null || echo 'unknown')",
    "os": "$(uname -s)",
    "shell": "$SHELL"
  },
  "files": {
    "reports_directory": "$REPORTS_DIR",
    "log_file": "$LOG_FILE"
  }
}
EOF
    
    show_info "Test report generated: $report_file"
    
    # Console summary
    echo ""
    show_subtitle "📊 Test Execution Summary"
    
    show_info "Execution Details:"
    echo "  Start Time: $START_TIME"
    echo "  End Time: $END_TIME"
    echo "  Duration: ${duration}s"
    echo ""
    
    show_info "Test Results:"
    echo "  Total Tests: $TOTAL_TESTS"
    echo "  Passed: $PASSED_TESTS"
    echo "  Failed: $FAILED_TESTS"
    echo "  Skipped: $SKIPPED_TESTS"
    
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        local success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
        echo "  Success Rate: ${success_rate}%"
        
        if [[ $FAILED_TESTS -eq 0 ]]; then
            show_success "All Tests Passed" "🎉 Perfect test run!"
        else
            show_error "Test Failures" "❌ $FAILED_TESTS tests failed"
        fi
    else
        show_warning "No Tests Executed" "⚠️ No tests were run"
    fi
    
    echo ""
    show_info "Reports saved to: $REPORTS_DIR"
}

# Cleanup test environment
cleanup_test_environment() {
    local cleanup_temp="${1:-true}"
    
    if [[ "$cleanup_temp" == "true" ]]; then
        local temp_dir=".claude/tmp/test-workspace"
        if [[ -d "$temp_dir" ]]; then
            rm -rf "$temp_dir"
            show_info "Cleaned up temporary test workspace"
        fi
    fi
    
    # Log completion
    local timestamp
    timestamp=$(format_timestamp)
    echo "[$timestamp] Test run completed" >> "$LOG_FILE"
}

# Main test execution
run_all_tests() {
    local test_type="${1:-all}"
    local pattern="${2:-*.bats}"
    local parallel="${3:-false}"
    
    show_title "🧪 CCPM Test Execution" 50
    show_info "Test Type: $test_type"
    show_info "Pattern: $pattern"
    if [[ "$parallel" == "true" ]]; then
        show_info "Parallel: Enabled"
    fi
    echo ""
    
    # Initialize environment
    if ! init_test_environment; then
        return 1
    fi
    
    # Load configuration
    load_test_config
    
    local overall_exit_code=0
    
    # Run tests based on type
    case "$test_type" in
        "unit")
            run_unit_tests "$pattern" "$parallel" || overall_exit_code=1
            ;;
        "integration")
            run_integration_tests "$pattern" || overall_exit_code=1
            ;;
        "all")
            run_unit_tests "$pattern" "$parallel" || overall_exit_code=1
            run_integration_tests "$pattern" || overall_exit_code=1
            ;;
        *)
            show_error "Unknown test type: $test_type"
            return 1
            ;;
    esac
    
    # Generate report
    generate_test_report
    
    # Cleanup
    cleanup_test_environment
    
    return $overall_exit_code
}

# Main execution
main() {
    local command="${1:-run}"
    local test_type="${2:-all}"
    local pattern="${3:-*.bats}"
    local parallel="false"
    local cleanup="true"
    
    # Parse options
    shift || true
    while [[ $# -gt 0 ]]; do
        case $1 in
            --parallel)
                parallel="true"
                shift
                ;;
            --pattern)
                pattern="$2"
                shift 2
                ;;
            --no-cleanup)
                cleanup="false"
                shift
                ;;
            --help|-h)
                show_usage
                ;;
            *)
                shift
                ;;
        esac
    done
    
    case "$command" in
        run)
            run_all_tests "$test_type" "$pattern" "$parallel"
            ;;
        unit)
            run_all_tests "unit" "$pattern" "$parallel"
            ;;
        integration)
            run_all_tests "integration" "$pattern" "false"
            ;;
        report)
            local latest_report
            latest_report=$(find "$REPORTS_DIR" -name "test-summary-*.json" -type f 2>/dev/null | sort | tail -1)
            if [[ -n "$latest_report" && -f "$latest_report" ]]; then
                if command -v jq >/dev/null 2>&1; then
                    jq '.' "$latest_report"
                else
                    cat "$latest_report"
                fi
            else
                show_warning "No test reports found"
            fi
            ;;
        clean)
            if [[ -d "$REPORTS_DIR" ]]; then
                rm -rf "$REPORTS_DIR"/*
            fi
            if [[ -f "$LOG_FILE" ]]; then
                echo > "$LOG_FILE"
            fi
            show_success "Cleanup Complete" "Cleaned test reports and logs"
            ;;
        *)
            show_error "Unknown Command" "Unknown command: $command"
            show_usage
            ;;
    esac
}

# Only run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi