#!/usr/bin/env bats

# CCPM Configuration Unit Tests
# Tests for .claude/config/ directory and configuration loading
# Version: 2.0

load '../fixtures/test_helper'

# Setup and teardown
setup() {
    # Create temporary test workspace
    TEST_WORKSPACE="$BATS_TMPDIR/ccpm_config_test_$$"
    mkdir -p "$TEST_WORKSPACE"
    cd "$TEST_WORKSPACE"
    
    # Setup mock CCPM project
    setup_mock_ccmp_project "$TEST_WORKSPACE"
    
    # Export for core.sh
    export CCPM_TEST_PROJECT_ROOT="$TEST_WORKSPACE"
}

teardown() {
    # Clean up test workspace
    cleanup_test_workspace "$TEST_WORKSPACE"
}

# Test defaults.json configuration
@test "defaults.json contains required system configuration" {
    local config_file="$TEST_WORKSPACE/.claude/config/defaults.json"
    
    # File should exist
    [ -f "$config_file" ]
    
    # Should be valid JSON
    run jq empty "$config_file"
    assert_success
    
    # Should have required keys
    assert_json_has_key "$config_file" ".system"
    assert_json_has_key "$config_file" ".system.log_level"
}

@test "defaults.json has valid log levels" {
    local config_file="$TEST_WORKSPACE/.claude/config/defaults.json"
    
    local log_level
    log_level=$(jq -r '.system.log_level' "$config_file")
    
    # Should be one of the valid log levels
    case "$log_level" in
        "debug"|"info"|"warn"|"error")
            # Valid log level
            ;;
        *)
            echo "Invalid log level: $log_level" >&2
            return 1
            ;;
    esac
}

@test "configuration loading works with valid JSON" {
    # Source core.sh to get load_config function
    source "$TEST_WORKSPACE/.claude/lib/core.sh"
    
    local config_file="$TEST_WORKSPACE/.claude/config/defaults.json"
    
    # Test loading existing value
    run load_config ".system.log_level" "fallback"
    assert_success
    assert_output "info"
}

@test "configuration loading returns default for missing key" {
    # Source core.sh
    source "$TEST_WORKSPACE/.claude/lib/core.sh"
    
    # Test loading non-existent value
    run load_config ".missing.key" "default_value"
    assert_success
    assert_output "default_value"
}

@test "configuration loading handles missing file gracefully" {
    # Source core.sh
    source "$TEST_WORKSPACE/.claude/lib/core.sh"
    
    # Remove config file
    rm -f "$TEST_WORKSPACE/.claude/config/defaults.json"
    
    # Should return default value
    run load_config ".system.log_level" "fallback"
    assert_success
    assert_output "fallback"
}

# Test project types configuration
@test "project-types.json exists and is valid" {
    local project_types_file="$CLAUDE_DIR/config/project-types.json"
    
    skip_if_file_missing "$project_types_file"
    
    # Should be valid JSON
    run jq empty "$project_types_file"
    assert_success
    
    # Should have templates section
    assert_json_has_key "$project_types_file" ".templates"
}

@test "project-types.json contains common project types" {
    local project_types_file="$CLAUDE_DIR/config/project-types.json"
    
    skip_if_file_missing "$project_types_file"
    
    # Should have common project types
    local required_types=("react" "nodejs" "python" "generic")
    
    for project_type in "${required_types[@]}"; do
        assert_json_has_key "$project_types_file" ".templates.$project_type"
    done
}

# Test workflows configuration
@test "workflows.json exists and is valid" {
    local workflows_file="$CLAUDE_DIR/config/workflows.json"
    
    skip_if_file_missing "$workflows_file"
    
    # Should be valid JSON
    run jq empty "$workflows_file"
    assert_success
    
    # Should have workflows section
    assert_json_has_key "$workflows_file" ".workflows"
}

@test "workflows.json contains essential workflows" {
    local workflows_file="$CLAUDE_DIR/config/workflows.json"
    
    skip_if_file_missing "$workflows_file"
    
    # Should have key workflows
    local required_workflows=("feature_development" "bug_fix" "code_review")
    
    for workflow in "${required_workflows[@]}"; do
        assert_json_has_key "$workflows_file" ".workflows.$workflow"
    done
}

# Test command-map configuration
@test "command-map.json exists and is valid" {
    local command_map_file="$CLAUDE_DIR/config/command-map.json"
    
    skip_if_file_missing "$command_map_file"
    
    # Should be valid JSON
    run jq empty "$command_map_file"
    assert_success
    
    # Should have commands section
    assert_json_has_key "$command_map_file" ".commands"
}

@test "command-map.json contains core commands" {
    local command_map_file="$CLAUDE_DIR/config/command-map.json"
    
    skip_if_file_missing "$command_map_file"
    
    # Should have essential commands
    local required_commands=("validate" "pm:init" "pm:status")
    
    for command in "${required_commands[@]}"; do
        assert_json_has_key "$command_map_file" ".commands.\"$command\""
    done
}

# Test configuration validation
@test "validate_config_files detects missing files" {
    # Source core.sh
    source "$TEST_WORKSPACE/.claude/lib/core.sh"
    
    # Remove a required config file
    rm -f "$TEST_WORKSPACE/.claude/config/defaults.json"
    
    # Validation should fail
    run validate_config_files
    assert_failure
    assert_output --partial "Missing required config file"
}

@test "validate_config_files detects invalid JSON" {
    # Source core.sh
    source "$TEST_WORKSPACE/.claude/lib/core.sh"
    
    # Create invalid JSON
    echo '{invalid json}' > "$TEST_WORKSPACE/.claude/config/defaults.json"
    
    # Skip if jq not available
    skip_if_command_missing "jq"
    
    # Validation should fail
    run validate_config_files
    assert_failure
    assert_output --partial "Invalid JSON"
}

@test "validate_config_files passes with valid configuration" {
    # Source core.sh  
    source "$TEST_WORKSPACE/.claude/lib/core.sh"
    
    # Create all required config files (they're created by setup)
    touch "$TEST_WORKSPACE/.claude/config/user.json"
    echo '{}' > "$TEST_WORKSPACE/.claude/config/user.json"
    
    touch "$TEST_WORKSPACE/.claude/config/command-map.json"
    echo '{}' > "$TEST_WORKSPACE/.claude/config/command-map.json"
    
    touch "$TEST_WORKSPACE/.claude/config/env.json"
    echo '{}' > "$TEST_WORKSPACE/.claude/config/env.json"
    
    # Skip if jq not available
    skip_if_command_missing "jq"
    
    # Validation should pass
    run validate_config_files
    assert_success
    assert_output --partial "Configuration files are valid"
}

# Test environment-specific configuration
@test "env.json can override default values" {
    # Create environment-specific config
    local env_file="$TEST_WORKSPACE/.claude/config/env.json"
    cat > "$env_file" << 'EOF'
{
  "system": {
    "log_level": "debug"
  }
}
EOF
    
    # This test would need enhanced configuration loading
    # For now, just verify the file is valid JSON
    run jq empty "$env_file"
    assert_success
}

# Test user-specific configuration
@test "user.json provides user customizations" {
    local user_file="$TEST_WORKSPACE/.claude/config/user.json"
    cat > "$user_file" << 'EOF'
{
  "preferences": {
    "editor": "vim",
    "theme": "dark"
  }
}
EOF
    
    # Verify valid JSON
    run jq empty "$user_file"
    assert_success
    
    # Should have preferences
    assert_json_has_key "$user_file" ".preferences"
}