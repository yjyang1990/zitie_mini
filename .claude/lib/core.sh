#!/bin/bash

# CCPM Core Library - Unified Core Functions
# This is the main library that provides all essential functions.
# All other libraries should source this as the foundation.
# Version: 2.0 - Refactored to eliminate duplicates

set -euo pipefail

# Define colors
[[ -z "${RED:-}" ]] && RED='\033[0;31m'
[[ -z "${GREEN:-}" ]] && GREEN='\033[0;32m'
[[ -z "${YELLOW:-}" ]] && YELLOW='\033[1;33m'
[[ -z "${BLUE:-}" ]] && BLUE='\033[0;34m'
[[ -z "${CYAN:-}" ]] && CYAN='\033[0;36m'
[[ -z "${NC:-}" ]] && NC='\033[0m' # No Color

# =============================================================================
# ERROR HANDLING
# =============================================================================

# Setup error handling
setup_error_handling() {
    set -euo pipefail
    trap 'echo -e "\n❌ Error occurred in ${BASH_SOURCE[1]:-$0} at line ${BASH_LINENO[0]:-unknown}"' ERR
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Array join function
array_join() {
    local delimiter="$1"
    shift
    local first="$1"
    shift
    printf '%s' "$first" "${@/#/$delimiter}"
}

# =============================================================================
# GITHUB OPERATIONS
# =============================================================================

# Check if remote origin is the CCPM template repository
# Returns 0 if safe to proceed, 1 if blocked
check_github_repository() {
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    
    if [[ "$remote_url" == *"automazeio/ccpm"* ]] || [[ "$remote_url" == *"automazeio/ccpm.git"* ]]; then
        echo "❌ ERROR: You're trying to sync with the CCPM template repository!"
        echo ""
        echo "This repository (automazeio/ccpm) is a template for others to use."
        echo "You should NOT create issues or PRs here."
        echo ""
        echo "To fix this:"
        echo "1. Fork this repository to your own GitHub account"
        echo "2. Update your remote origin:"
        echo "   git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
        echo ""
        echo "Or if this is a new project:"
        echo "1. Create a new repository on GitHub"
        echo "2. Update your remote origin:"
        echo "   git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
        echo ""
        echo "Current remote: $remote_url"
        return 1
    fi
    return 0
}

# Verify GitHub CLI authentication
check_github_auth() {
    if ! gh auth status >/dev/null 2>&1; then
        echo "❌ GitHub CLI not authenticated. Run: gh auth login"
        return 1
    fi
    return 0
}

# Get GitHub issues for the current repository
get_github_issues() {
    local status="${1:-open}"
    gh issue list --state "$status" --json number,title,state,createdAt,updatedAt
}

# Create a new GitHub issue
create_github_issue() {
    local title="$1"
    local body="$2"
    local labels="${3:-}"
    
    if [[ -n "$labels" ]]; then
        gh issue create --title "$title" --body "$body" --label "$labels"
    else
        gh issue create --title "$title" --body "$body"
    fi
}

# =============================================================================
# DATE AND TIME OPERATIONS
# =============================================================================

# Get current timestamp in ISO format
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Format timestamp for display (alias for compatibility)
format_timestamp() {
    get_timestamp
}

# Get current date in YYYY-MM-DD format
get_current_date() {
    date +"%Y-%m-%d"
}

# Format date for display
format_date() {
    local date_string="$1"
    if command -v gdate >/dev/null 2>&1; then
        gdate -d "$date_string" "+%Y-%m-%d %H:%M"
    else
        date -j -f "%Y-%m-%dT%H:%M:%SZ" "$date_string" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$date_string"
    fi
}

# =============================================================================
# PATH AND DIRECTORY OPERATIONS
# =============================================================================

# Ensure a directory exists
ensure_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        echo "📁 Created directory: $dir"
    fi
}

# Find the project root directory (where .git is located)
find_project_root() {
    local current_dir="$PWD"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -d "$current_dir/.git" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir=$(dirname "$current_dir")
    done
    echo "$PWD" # Fallback to current directory
}

# Get the .claude directory path
get_claude_dir() {
    local project_root
    project_root=$(find_project_root)
    echo "$project_root/.claude"
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Validate configuration files
validate_config_files() {
    local errors=()
    
    echo "🔍 Validating configuration files..."
    
    # Check required config files
    local required_configs=(
        ".claude/config/defaults.json"
        ".claude/config/user.json"
        ".claude/config/command-map.json"
        ".claude/config/env.json"
        ".claude/settings.local.json"
    )
    
    for config_file in "${required_configs[@]}"; do
        if [[ ! -f "$config_file" ]]; then
            errors+=("Missing required config file: $config_file")
        elif command -v jq >/dev/null 2>&1 && ! jq empty "$config_file" 2>/dev/null; then
            errors+=("Invalid JSON in config file: $config_file")
        fi
    done
    
    if [[ ${#errors[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Configuration validation failed:${NC}"
        for error in "${errors[@]}"; do
            echo -e "  ${RED}•${NC} $error"
        done
        return 1
    fi
    
    echo -e "${GREEN}✅ Configuration files are valid${NC}"
    return 0
}

# Validate epic exists in the repository
validate_epic_exists() {
    local epic_name="$1"
    local epics_dir=".claude/epics"
    
    if [[ ! -f "$epics_dir/$epic_name.md" ]]; then
        echo -e "${RED}❌ Epic '$epic_name' not found at $epics_dir/$epic_name.md${NC}"
        echo ""
        echo "Available epics:"
        if [[ -d "$epics_dir" ]]; then
            find "$epics_dir" -name "*.md" -exec basename {} .md \; | sort | sed 's/^/  - /'
        else
            echo "  No epics found. Create one with: /pm:prd-parse <name>"
        fi
        return 1
    fi
    return 0
}

# Validate GitHub connection
validate_github_connection() {
    echo "🔍 Validating GitHub connection..."
    
    if ! command -v gh >/dev/null 2>&1; then
        echo -e "${RED}❌ GitHub CLI (gh) not installed${NC}"
        echo "Install with: brew install gh"
        return 1
    fi
    
    if ! check_github_auth; then
        return 1
    fi
    
    if ! check_github_repository; then
        return 1
    fi
    
    echo -e "${GREEN}✅ GitHub connection is valid${NC}"
    return 0
}

# Validate dependencies
validate_dependencies() {
    local errors=()
    
    echo "🔍 Validating dependencies..."
    
    # Check required commands
    local required_commands=(
        "git"
        "jq"
        "curl"
    )
    
    # Optional but recommended commands
    local optional_commands=(
        "gh"
        "bats"
    )
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            errors+=("Required command not found: $cmd")
        fi
    done
    
    for cmd in "${optional_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo -e "${YELLOW}⚠️ Optional command not found: $cmd${NC}"
        fi
    done
    
    if [[ ${#errors[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Dependency validation failed:${NC}"
        for error in "${errors[@]}"; do
            echo -e "  ${RED}•${NC} $error"
        done
        return 1
    fi
    
    echo -e "${GREEN}✅ Dependencies are satisfied${NC}"
    return 0
}

# Validate project structure
validate_project_structure() {
    local errors=()
    
    echo "🔍 Validating project structure..."
    
    # Check required directories
    local required_dirs=(
        ".claude"
        ".claude/agents"
        ".claude/commands"
        ".claude/config"
        ".claude/lib"
        ".claude/scripts"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            errors+=("Missing required directory: $dir")
        fi
    done
    
    # Check required files
    local required_files=(
        ".claude/CLAUDE.md"
        ".claude/settings.local.json"
        ".claude/lib/core.sh"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            errors+=("Missing required file: $file")
        fi
    done
    
    if [[ ${#errors[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Project structure validation failed:${NC}"
        for error in "${errors[@]}"; do
            echo -e "  ${RED}•${NC} $error"
        done
        return 1
    fi
    
    echo -e "${GREEN}✅ Project structure is valid${NC}"
    return 0
}

# =============================================================================
# FILE OPERATIONS
# =============================================================================

# Check if a file is a valid JSON
is_valid_json() {
    local file="$1"
    [[ -f "$file" ]] && command -v jq >/dev/null 2>&1 && jq empty "$file" 2>/dev/null
}

# Extract JSON value safely
get_json_value() {
    local file="$1"
    local key="$2"
    local default="${3:-}"
    
    if is_valid_json "$file"; then
        jq -r "$key // \"$default\"" "$file"
    else
        echo "$default"
    fi
}

# =============================================================================
# LOGGING
# =============================================================================

# Log error message
log_error() {
    local message="$1"
    echo -e "${RED}❌ ERROR: $message${NC}" >&2
}

# Log warning message
log_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠️ WARNING: $message${NC}"
}

# Log success message
log_success() {
    local message="$1"
    echo -e "${GREEN}✅ $message${NC}"
}

# Log info message
log_info() {
    local message="$1"
    echo -e "${BLUE}ℹ️ $message${NC}"
}

# =============================================================================
# CONFIGURATION LOADING
# =============================================================================

# Load configuration from JSON files
load_config() {
    local config_key="$1"
    local default_value="${2:-}"
    local config_file=".claude/config/defaults.json"
    
    if [[ -f "$config_file" ]] && command -v jq >/dev/null 2>&1; then
        jq -r "$config_key // \"$default_value\"" "$config_file" 2>/dev/null || echo "$default_value"
    else
        echo "$default_value"
    fi
}

# Initialize CCPM Core
init_ccpm_core() {
    setup_error_handling
    
    # Export core configuration for scripts
    export CCPM_VERSION="2.0"
    export CCPM_ROOT="$(find_project_root)"
    export CLAUDE_DIR="$CCPM_ROOT/.claude"
    
    # Set global configuration
    export CCPM_LOG_LEVEL="$(load_config '.system.log_level' 'info')"
    export CCPM_MAX_CONCURRENT="$(load_config '.system.max_concurrent_operations' '5')"
    
    log_info "CCPM Core initialized (version $CCPM_VERSION)"
}

# =============================================================================
# INITIALIZATION
# =============================================================================

# Auto-initialize when sourced
if [[ "${BASH_SOURCE[0]:-}" != "${0:-}" ]]; then
    init_ccpm_core
fi