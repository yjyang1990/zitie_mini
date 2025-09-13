#!/usr/bin/env bats

# CCPM Core Library Unit Tests
# Tests for .claude/lib/core.sh functions
# Version: 2.0

load '../fixtures/test_helper'

# Setup and teardown
setup() {
    # Source the core library
    source "$CLAUDE_DIR/lib/core.sh"
    
    # Create temporary test workspace
    TEST_WORKSPACE="$BATS_TMPDIR/ccpm_test_$$"
    mkdir -p "$TEST_WORKSPACE"
    cd "$TEST_WORKSPACE"
}

teardown() {
    # Clean up test workspace
    if [[ -d "$TEST_WORKSPACE" ]]; then
        rm -rf "$TEST_WORKSPACE"
    fi
}

# Test error handling setup
@test "setup_error_handling configures error trapping" {
    # Test that error handling is configured
    run bash -c 'source "$CLAUDE_DIR/lib/core.sh"; set -o | grep errexit'
    assert_success
    assert_output --partial "errexit"
}

# Test timestamp functions
@test "get_timestamp returns valid ISO format" {
    run get_timestamp
    assert_success
    # Should match ISO format: YYYY-MM-DDTHH:MM:SSZ
    assert_output --regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
}

@test "get_current_date returns valid date format" {
    run get_current_date
    assert_success
    # Should match YYYY-MM-DD format
    assert_output --regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
}

# Test directory operations
@test "ensure_directory creates missing directory" {
    local test_dir="$TEST_WORKSPACE/test_subdir"
    
    # Directory should not exist initially
    [ ! -d "$test_dir" ]
    
    run ensure_directory "$test_dir"
    assert_success
    
    # Directory should now exist
    [ -d "$test_dir" ]
}

@test "ensure_directory handles existing directory gracefully" {
    local test_dir="$TEST_WORKSPACE/existing_dir"
    mkdir -p "$test_dir"
    
    run ensure_directory "$test_dir"
    assert_success
    
    # Directory should still exist
    [ -d "$test_dir" ]
}

# Test project root detection
@test "find_project_root locates git repository root" {
    # Initialize a git repo for testing
    git init --quiet
    
    # Create nested directory
    mkdir -p "deep/nested/path"
    cd "deep/nested/path"
    
    run find_project_root
    assert_success
    assert_output "$TEST_WORKSPACE"
}

@test "find_project_root fallback to current directory" {
    # No git repo, should return current directory
    run find_project_root
    assert_success
    assert_output "$TEST_WORKSPACE"
}

# Test logging functions
@test "log_error outputs error message with formatting" {
    run log_error "Test error message"
    assert_success
    assert_output --partial "❌ ERROR: Test error message"
}

@test "log_success outputs success message with formatting" {
    run log_success "Test success message"
    assert_success  
    assert_output --partial "✅ Test success message"
}

@test "log_warning outputs warning message with formatting" {
    run log_warning "Test warning message"
    assert_success
    assert_output --partial "⚠️ WARNING: Test warning message"
}

@test "log_info outputs info message with formatting" {
    run log_info "Test info message"
    assert_success
    assert_output --partial "ℹ️ Test info message"
}

# Test JSON operations
@test "is_valid_json validates correct JSON" {
    local json_file="$TEST_WORKSPACE/valid.json"
    echo '{"valid": "json"}' > "$json_file"
    
    run is_valid_json "$json_file"
    assert_success
}

@test "is_valid_json rejects invalid JSON" {
    local json_file="$TEST_WORKSPACE/invalid.json"
    echo '{invalid json}' > "$json_file"
    
    run is_valid_json "$json_file"
    assert_failure
}

@test "get_json_value extracts correct value" {
    local json_file="$TEST_WORKSPACE/test.json"
    echo '{"test": {"value": "expected"}}' > "$json_file"
    
    run get_json_value "$json_file" ".test.value"
    assert_success
    assert_output "expected"
}

@test "get_json_value returns default for missing key" {
    local json_file="$TEST_WORKSPACE/test.json"
    echo '{"test": "value"}' > "$json_file"
    
    run get_json_value "$json_file" ".missing.key" "default_value"
    assert_success
    assert_output "default_value"
}

# Test configuration loading
@test "load_config loads value from configuration" {
    # Create a mock config file
    local config_file="$TEST_WORKSPACE/.claude/config/defaults.json"
    mkdir -p "$(dirname "$config_file")"
    echo '{"system": {"log_level": "debug"}}' > "$config_file"
    
    # Mock the config file path
    cd "$TEST_WORKSPACE"
    
    run load_config ".system.log_level" "info"
    assert_success
    assert_output "debug"
}

@test "load_config returns default for missing config" {
    # No config file exists
    run load_config ".system.missing_key" "default_value"
    assert_success
    assert_output "default_value"
}

# Test GitHub operations
@test "check_github_repository detects CCPM template repo" {
    # Mock git remote
    git init --quiet
    git remote add origin "https://github.com/automazeio/ccpm.git"
    
    run check_github_repository
    assert_failure
    assert_output --partial "ERROR: You're trying to sync with the CCPM template repository"
}

@test "check_github_repository allows other repositories" {
    # Mock git remote
    git init --quiet
    git remote add origin "https://github.com/user/myproject.git"
    
    run check_github_repository
    assert_success
}

# Test validation functions  
@test "validate_project_structure detects missing directories" {
    # Missing required directories
    run validate_project_structure
    assert_failure
    assert_output --partial "Missing required directory"
}

@test "validate_project_structure passes with correct structure" {
    # Create required structure
    mkdir -p .claude/{agents,commands,config,lib,scripts}
    touch .claude/{CLAUDE.md,settings.local.json}
    touch .claude/lib/core.sh
    
    run validate_project_structure
    assert_success
    assert_output --partial "Project structure is valid"
}

# Test dependency validation
@test "validate_dependencies checks required commands" {
    run validate_dependencies
    # Should check for git, jq, curl
    if command -v git >/dev/null && command -v jq >/dev/null && command -v curl >/dev/null; then
        assert_success
        assert_output --partial "Dependencies are satisfied"
    else
        assert_failure
        assert_output --partial "Required command not found"
    fi
}

# Test CCPM initialization
@test "init_ccpm_core sets up environment variables" {
    run bash -c 'source "$CLAUDE_DIR/lib/core.sh"; echo "$CCPM_VERSION"'
    assert_success
    assert_output "2.0"
}

@test "init_ccpm_core exports CLAUDE_DIR" {
    run bash -c 'source "$CLAUDE_DIR/lib/core.sh"; echo "$CLAUDE_DIR"'
    assert_success
    assert_output --partial ".claude"
}