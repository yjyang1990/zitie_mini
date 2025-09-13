#!/bin/bash

# CCPM Test Helper Functions
# Common utilities and assertions for BATS tests
# Version: 2.0

# Test environment setup
export CCPM_TEST_MODE=true
export CLAUDE_DIR="${CLAUDE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export BATS_TMPDIR="${BATS_TMPDIR:-/tmp}"

# Load bats-support and bats-assert if available
if [[ -f "/usr/local/lib/bats-support/load.bash" ]]; then
    load "/usr/local/lib/bats-support/load"
fi

if [[ -f "/usr/local/lib/bats-assert/load.bash" ]]; then
    load "/usr/local/lib/bats-assert/load"
fi

# Custom assertion functions for CCPM testing

# Assert that a file contains specific content
assert_file_contains() {
    local file="$1"
    local expected_content="$2"
    
    if [[ ! -f "$file" ]]; then
        echo "File does not exist: $file" >&2
        return 1
    fi
    
    if ! grep -q "$expected_content" "$file"; then
        echo "File '$file' does not contain expected content: '$expected_content'" >&2
        echo "Actual content:" >&2
        cat "$file" >&2
        return 1
    fi
}

# Assert that a JSON file has a specific structure
assert_json_has_key() {
    local json_file="$1"
    local key_path="$2"
    
    if [[ ! -f "$json_file" ]]; then
        echo "JSON file does not exist: $json_file" >&2
        return 1
    fi
    
    if ! jq -e "$key_path" "$json_file" >/dev/null 2>&1; then
        echo "JSON file '$json_file' does not have key: '$key_path'" >&2
        echo "Actual JSON structure:" >&2
        jq '.' "$json_file" >&2
        return 1
    fi
}

# Assert that a command exists
assert_command_exists() {
    local command="$1"
    
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Required command not found: $command" >&2
        return 1
    fi
}

# Assert that a directory has the expected structure
assert_directory_structure() {
    local base_dir="$1"
    shift
    local expected_paths=("$@")
    
    if [[ ! -d "$base_dir" ]]; then
        echo "Base directory does not exist: $base_dir" >&2
        return 1
    fi
    
    for path in "${expected_paths[@]}"; do
        local full_path="$base_dir/$path"
        if [[ ! -e "$full_path" ]]; then
            echo "Expected path does not exist: $full_path" >&2
            echo "Directory structure:" >&2
            find "$base_dir" -type f | head -20 >&2
            return 1
        fi
    done
}

# Create a mock CCPM project structure for testing
setup_mock_ccmp_project() {
    local project_dir="$1"
    
    mkdir -p "$project_dir/.claude"/{config,lib,scripts,agents,commands,hooks,templates,tests}
    mkdir -p "$project_dir/.claude"/{epics,prds,logs,tmp}
    
    # Create minimal core.sh
    cat > "$project_dir/.claude/lib/core.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

# Mock core functions for testing
log_info() { echo "ℹ️ $1"; }
log_error() { echo "❌ ERROR: $1" >&2; }
log_success() { echo "✅ $1"; }
log_warning() { echo "⚠️ WARNING: $1"; }

get_timestamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
get_current_date() { date +"%Y-%m-%d"; }

ensure_directory() {
    local dir="$1"
    mkdir -p "$dir"
}

find_project_root() {
    echo "${CCPM_TEST_PROJECT_ROOT:-$(pwd)}"
}

get_json_value() {
    local file="$1"
    local key="$2"
    local default="${3:-}"
    
    if [[ -f "$file" ]] && command -v jq >/dev/null; then
        jq -r "$key // \"$default\"" "$file" 2>/dev/null || echo "$default"
    else
        echo "$default"
    fi
}

validate_project_structure() {
    local required_dirs=(".claude" ".claude/lib" ".claude/config")
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            echo "Missing required directory: $dir" >&2
            return 1
        fi
    done
    echo "✅ Project structure is valid"
    return 0
}

init_ccpm_core() {
    export CCPM_VERSION="2.0"
    export CCPM_ROOT="$(find_project_root)"
    export CLAUDE_DIR="$CCPM_ROOT/.claude"
    export CCPM_LOG_LEVEL="info"
}

# Auto-initialize in test mode
init_ccpm_core
EOF
    
    # Create minimal configuration
    cat > "$project_dir/.claude/config/defaults.json" << 'EOF'
{
  "system": {
    "log_level": "info",
    "max_concurrent_operations": 5
  },
  "github": {
    "api_timeout_ms": 30000
  }
}
EOF
    
    # Create minimal CLAUDE.md
    cat > "$project_dir/.claude/CLAUDE.md" << 'EOF'
# Test Project

This is a test project for CCPM framework testing.
EOF
    
    # Create minimal settings
    cat > "$project_dir/.claude/settings.local.json" << 'EOF'
{
  "permissions": {
    "allow": ["Edit", "Write", "Bash"]
  }
}
EOF
    
    chmod +x "$project_dir/.claude/lib/core.sh"
}

# Create mock GitHub repository
setup_mock_git_repo() {
    local repo_dir="$1"
    local remote_url="${2:-https://github.com/user/test-repo.git}"
    
    cd "$repo_dir"
    git init --quiet
    git config user.name "Test User"
    git config user.email "test@example.com"
    git remote add origin "$remote_url"
    
    # Create initial commit
    echo "# Test Repository" > README.md
    git add README.md
    git commit -m "Initial commit" --quiet
}

# Mock GitHub CLI responses
mock_gh_command() {
    local subcommand="$1"
    shift
    local args=("$@")
    
    case "$subcommand" in
        "auth")
            case "${args[0]}" in
                "status")
                    echo "✓ Logged in to github.com as testuser"
                    return 0
                    ;;
            esac
            ;;
        "issue")
            case "${args[0]}" in
                "list")
                    echo '[{"number": 1, "title": "Test Issue", "state": "open"}]'
                    return 0
                    ;;
                "view")
                    echo "Test Issue #${args[1]}"
                    echo "This is a test issue for CCPM testing"
                    return 0
                    ;;
            esac
            ;;
    esac
    
    echo "Mock gh command: $subcommand ${args[*]}" >&2
    return 0
}

# Test data generation
generate_test_prd() {
    local prd_name="$1"
    local output_file="$2"
    
    cat > "$output_file" << EOF
# $prd_name - Product Requirements Document

**Version:** 1.0
**Author:** Test User
**Date:** $(date +%Y-%m-%d)
**Status:** Draft

## Executive Summary

This is a test PRD for CCPM framework testing.

### Key Objectives
- Test objective 1
- Test objective 2

## Technical Requirements

### Core Features
1. Feature 1: Basic functionality
2. Feature 2: Advanced functionality

## Implementation Plan

### Phase 1: Foundation
- Duration: 2 weeks
- Deliverables: Basic implementation

EOF
}

generate_test_epic() {
    local epic_name="$1"
    local prd_reference="$2"
    local output_file="$3"
    
    cat > "$output_file" << EOF
# Epic: $epic_name

**Generated from PRD:** $prd_reference
**Author:** Test User
**Created:** $(date +%Y-%m-%d)
**Status:** Planning

## Epic Overview

Test epic for CCPM framework validation.

## Work Streams

### Stream A: Backend Implementation
**Lead:** Backend Developer
**Estimated Effort:** 40h

#### Tasks
1. **Setup Database Schema** (8h)
   - Create tables
   - Setup migrations
   - Status: Not Started

2. **Implement API Endpoints** (24h)
   - Create REST endpoints
   - Add validation
   - Status: Not Started

### Stream B: Frontend Implementation  
**Lead:** Frontend Developer
**Estimated Effort:** 32h

#### Tasks
1. **Setup React Components** (16h)
   - Create base components
   - Setup routing
   - Status: Not Started

EOF
}

# Cleanup functions
cleanup_test_workspace() {
    local workspace="$1"
    
    if [[ -d "$workspace" ]]; then
        rm -rf "$workspace"
    fi
}

# Color output for test results
test_echo_success() {
    echo -e "\033[32m✅ $1\033[0m"
}

test_echo_error() {
    echo -e "\033[31m❌ $1\033[0m" >&2
}

test_echo_warning() {
    echo -e "\033[33m⚠️ $1\033[0m"
}

test_echo_info() {
    echo -e "\033[34mℹ️ $1\033[0m"
}

# Skip test if requirements not met
skip_if_command_missing() {
    local command="$1"
    local reason="${2:-Command $command not available}"
    
    if ! command -v "$command" >/dev/null 2>&1; then
        skip "$reason"
    fi
}

skip_if_file_missing() {
    local file="$1"
    local reason="${2:-Required file not found: $file}"
    
    if [[ ! -f "$file" ]]; then
        skip "$reason"
    fi
}