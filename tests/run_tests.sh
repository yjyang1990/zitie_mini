#!/bin/bash
# CCPM v2.0 Testing Framework
# Comprehensive test runner for CCPM framework

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test statistics
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Source core libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CCPM_ROOT="$(dirname "$SCRIPT_DIR")"

# Source library functions with error handling
echo "Loading v2.0 libraries from: $CCPM_ROOT/.claude/lib/"

if [[ -f "$CCPM_ROOT/.claude/lib/core.sh" ]]; then
    source "$CCPM_ROOT/.claude/lib/core.sh"
    echo "✓ Loaded core.sh"
else
    echo "✗ Failed to find core.sh"
    exit 1
fi

if [[ -f "$CCPM_ROOT/.claude/lib/ui.sh" ]]; then
    source "$CCPM_ROOT/.claude/lib/ui.sh"
    echo "✓ Loaded ui.sh"
else
    echo "✗ Failed to find ui.sh"
    exit 1
fi

echo ""

# Test helper functions
test_start() {
    local test_name="$1"
    echo -e "${BLUE}[TEST]${NC} $test_name"
    ((TESTS_RUN++))
}

test_pass() {
    local message="${1:-Test passed}"
    echo -e "${GREEN}  ✅ $message${NC}"
    ((TESTS_PASSED++))
}

test_fail() {
    local message="${1:-Test failed}"
    echo -e "${RED}  ❌ $message${NC}"
    ((TESTS_FAILED++))
}

test_assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="${3:-assertion}"
    
    if [[ "$expected" == "$actual" ]]; then
        test_pass "$test_name: expected '$expected', got '$actual'"
        return 0
    else
        test_fail "$test_name: expected '$expected', got '$actual'"
        return 1
    fi
}

test_assert_file_exists() {
    local file_path="$1"
    local test_name="${2:-file exists check}"
    
    if [[ -f "$file_path" ]]; then
        test_pass "$test_name: file exists at $file_path"
        return 0
    else
        test_fail "$test_name: file not found at $file_path"
        return 1
    fi
}

# Test: Core v2.0 functions
test_core_functions() {
    test_start "Core v2.0 functions"
    
    # Test get_timestamp function
    local timestamp
    timestamp=$(get_timestamp)
    if [[ -n "$timestamp" && "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
        test_pass "get_timestamp returns valid ISO format: $timestamp"
    else
        test_fail "get_timestamp returned invalid format: $timestamp"
    fi
    
    # Test get_current_date function
    local date
    date=$(get_current_date)
    if [[ -n "$date" && "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        test_pass "get_current_date returns valid format: $date"
    else
        test_fail "get_current_date returned invalid format: $date"
    fi
    
    # Test find_project_root function
    local project_root
    project_root=$(find_project_root)
    if [[ -n "$project_root" && -d "$project_root" ]]; then
        test_pass "find_project_root returns valid directory: $project_root"
    else
        test_fail "find_project_root returned invalid directory: $project_root"
    fi
}

# Test: UI functions
test_ui_functions() {
    test_start "UI functions"
    
    # Test logging functions (redirect output to test)
    local log_output
    
    log_output=$(log_info "Test message" 2>&1)
    if [[ "$log_output" =~ "ℹ️ Test message" ]]; then
        test_pass "log_info produces correct output"
    else
        test_fail "log_info output incorrect: $log_output"
    fi
    
    log_output=$(log_success "Test success" 2>&1)
    if [[ "$log_output" =~ "✅ Test success" ]]; then
        test_pass "log_success produces correct output"
    else
        test_fail "log_success output incorrect: $log_output"
    fi
    
    log_output=$(log_warning "Test warning" 2>&1)
    if [[ "$log_output" =~ "⚠️ WARNING: Test warning" ]]; then
        test_pass "log_warning produces correct output"
    else
        test_fail "log_warning output incorrect: $log_output"
    fi
}

# Test: Directory operations
test_directory_operations() {
    test_start "Directory operations"
    
    # Create a temporary directory for testing
    local temp_dir="/tmp/ccpm_test_$$"
    
    # Test ensure_directory function
    ensure_directory "$temp_dir"
    if [[ -d "$temp_dir" ]]; then
        test_pass "ensure_directory creates directory: $temp_dir"
        
        # Test that it doesn't fail on existing directory
        ensure_directory "$temp_dir"
        if [[ -d "$temp_dir" ]]; then
            test_pass "ensure_directory handles existing directory"
        else
            test_fail "ensure_directory failed on existing directory"
        fi
        
        # Clean up
        rm -rf "$temp_dir"
    else
        test_fail "ensure_directory failed to create directory"
    fi
}

# Test: JSON operations
test_json_operations() {
    test_start "JSON operations"
    
    # Create a temporary JSON file for testing
    local temp_json="/tmp/ccpm_test_$$.json"
    echo '{"test": {"value": "expected"}, "version": "2.0"}' > "$temp_json"
    
    # Test is_valid_json function
    if is_valid_json "$temp_json"; then
        test_pass "is_valid_json correctly identifies valid JSON"
    else
        test_fail "is_valid_json failed on valid JSON"
    fi
    
    # Test get_json_value function
    local json_value
    json_value=$(get_json_value "$temp_json" ".test.value")
    if [[ "$json_value" == "expected" ]]; then
        test_pass "get_json_value extracts correct value: $json_value"
    else
        test_fail "get_json_value returned incorrect value: $json_value"
    fi
    
    # Test with default value
    json_value=$(get_json_value "$temp_json" ".missing.key" "default")
    if [[ "$json_value" == "default" ]]; then
        test_pass "get_json_value returns default for missing key"
    else
        test_fail "get_json_value failed to return default: $json_value"
    fi
    
    # Clean up
    rm -f "$temp_json"
}

# Test: Project structure validation
test_project_validation() {
    test_start "Project structure validation"
    
    # Test validate_project_structure function
    if validate_project_structure 2>/dev/null; then
        test_pass "validate_project_structure passes on current project"
    else
        test_fail "validate_project_structure failed on current project"
    fi
    
    # Test validate_dependencies function
    if validate_dependencies 2>/dev/null; then
        test_pass "validate_dependencies passes"
    else
        test_fail "validate_dependencies failed"
    fi
}

# Test: Version and initialization
test_version_init() {
    test_start "Version and initialization"
    
    # Test that CCPM_VERSION is set correctly
    if [[ "$CCPM_VERSION" == "2.0" ]]; then
        test_pass "CCPM_VERSION is correctly set to 2.0"
    else
        test_fail "CCPM_VERSION is incorrect: $CCPM_VERSION"
    fi
    
    # Test that CCPM_ROOT is set
    if [[ -n "$CCPM_ROOT" && -d "$CCPM_ROOT/.claude" ]]; then
        test_pass "CCPM_ROOT is correctly set: $CCPM_ROOT"
    else
        test_fail "CCPM_ROOT is incorrect: $CCPM_ROOT"
    fi
}

# Test: Function availability
test_function_availability() {
    test_start "Function availability"
    
    # Test that core functions are available
    local core_functions=("get_timestamp" "get_current_date" "ensure_directory" "find_project_root" 
                          "log_info" "log_success" "log_error" "log_warning" "is_valid_json" 
                          "get_json_value" "validate_project_structure" "validate_dependencies")
    
    for func in "${core_functions[@]}"; do
        if declare -F "$func" > /dev/null; then
            test_pass "Function '$func' is available"
        else
            test_fail "Function '$func' is not available"
        fi
    done
}

# Test: Run BATS tests if available
test_bats_suite() {
    test_start "BATS test suite"
    
    if command -v bats >/dev/null 2>&1; then
        local bats_files=()
        mapfile -t bats_files < <(find "$CCPM_ROOT/.claude/tests" -name "*.bats" -type f)
        
        if [[ ${#bats_files[@]} -gt 0 ]]; then
            echo "  Running BATS test files..."
            for bats_file in "${bats_files[@]}"; do
                echo -n "    $(basename "$bats_file"): "
                if bats "$bats_file" >/dev/null 2>&1; then
                    test_pass "passed"
                else
                    test_fail "failed"
                fi
            done
        else
            test_pass "No BATS files found (skipped)"
        fi
    else
        test_pass "BATS not installed (skipped)"
    fi
}

# Main test runner
run_all_tests() {
    echo -e "${YELLOW}🧪 CCPM v2.0 Testing Framework${NC}"
    echo -e "${YELLOW}=================================${NC}"
    echo -e "Testing directory: $CCPM_ROOT"
    echo ""
    
    test_function_availability
    echo ""
    
    test_version_init
    echo ""
    
    test_core_functions
    echo ""
    
    test_ui_functions
    echo ""
    
    test_directory_operations
    echo ""
    
    test_json_operations
    echo ""
    
    test_project_validation
    echo ""
    
    test_bats_suite
    echo ""
    
    # Print summary
    echo -e "${YELLOW}=================================${NC}"
    echo -e "${YELLOW}Test Summary:${NC}"
    echo -e "  Total: $TESTS_RUN"
    echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
    
    local pass_rate=$((TESTS_PASSED * 100 / TESTS_RUN))
    echo -e "  Pass rate: ${pass_rate}%"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}🎉 All tests passed! CCPM v2.0 is ready for deployment.${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ $TESTS_FAILED test(s) failed${NC}"
        echo -e "${YELLOW}Review failed tests before deploying to other projects.${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_tests
fi