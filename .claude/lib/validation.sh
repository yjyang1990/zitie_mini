#!/bin/bash

# CCPM Configuration Validation
# Validates configuration files and system requirements

set -euo pipefail

# Define colors if not already set
[[ -z "${RED:-}" ]] && RED='\033[0;31m'
[[ -z "${GREEN:-}" ]] && GREEN='\033[0;32m'
[[ -z "${YELLOW:-}" ]] && YELLOW='\033[1;33m'
[[ -z "${BLUE:-}" ]] && BLUE='\033[0;34m'
[[ -z "${CYAN:-}" ]] && CYAN='\033[0;36m'
[[ -z "${NC:-}" ]] && NC='\033[0m' # No Color

# =============================================================================
# ENHANCED VALIDATION FUNCTIONS
# =============================================================================

# Validate environment configuration
validate_env_config() {
    local env_file=".claude/config/env.json"
    local required_fields=(
        ".development"
        ".production" 
        ".testing"
        ".default_environment"
        ".github.api_base_url"
        ".cache.max_size_mb"
        ".security.allowed_commands"
    )
    
    echo "  📋 Validating environment configuration..."
    
    for field in "${required_fields[@]}"; do
        if ! jq -e "$field" "$env_file" >/dev/null 2>&1; then
            echo "❌ Missing required field in env.json: $field"
            return 1
        fi
    done
    
    # Validate environment values
    local default_env
    default_env=$(jq -r '.default_environment' "$env_file")
    if [[ "$default_env" != "development" && "$default_env" != "production" && "$default_env" != "testing" ]]; then
        echo "❌ Invalid default_environment: $default_env (must be development, production, or testing)"
        return 1
    fi
    
    echo "  ✅ Environment configuration is valid"
}

# Validate security configuration
validate_security_config() {
    local security_file=".claude/settings.local.json"
    
    echo "  🔒 Validating security configuration..."
    
    # Check for dangerous patterns in allow list
    local dangerous_patterns=(
        "sudo"
        "rm -rf"
        "eval"
        "curl"
        "wget" 
        "ssh"
    )
    
    for pattern in "${dangerous_patterns[@]}"; do
        if jq -r '.permissions.allow[]?' "$security_file" 2>/dev/null | grep -q "$pattern"; then
            echo "⚠️  Warning: Potentially dangerous pattern in allow list: $pattern"
        fi
    done
    
    # Validate security settings structure
    if jq -e '.security' "$security_file" >/dev/null 2>&1; then
        local max_length
        max_length=$(jq -r '.security.max_command_length' "$security_file" 2>/dev/null)
        if [[ "$max_length" != "null" && "$max_length" -gt 2000 ]]; then
            echo "⚠️  Warning: max_command_length is very high: $max_length"
        fi
    fi
    
    echo "  ✅ Security configuration is valid"
}

# Validate system requirements
validate_system_requirements() {
    echo "🔧 Validating system requirements..."
    
    local missing_tools=()
    local required_tools=("git" "jq")
    local optional_tools=("gh" "bats")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "❌ Missing required tools: ${missing_tools[*]}"
        echo "   Please install missing tools to continue"
        return 1
    fi
    
    # Check optional tools
    for tool in "${optional_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "⚠️  Optional tool not found: $tool (recommended)"
        fi
    done
    
    echo "✅ All required tools are available"
    return 0
}

# Validate directory structure
validate_directory_structure() {
    echo "📁 Validating directory structure..."
    
    local required_dirs=(
        ".claude"
        ".claude/config"
        ".claude/lib"
        ".claude/scripts"
        ".claude/agents"
        ".claude/commands"
    )
    
    local missing_dirs=()
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            missing_dirs+=("$dir")
        fi
    done
    
    if [[ ${#missing_dirs[@]} -gt 0 ]]; then
        echo "⚠️  Missing directories (will be created): ${missing_dirs[*]}"
        
        # Create missing directories
        for dir in "${missing_dirs[@]}"; do
            mkdir -p "$dir"
            echo "   Created: $dir"
        done
    fi
    
    echo "✅ Directory structure is valid"
    return 0
}

# Validate cache system
validate_cache_system() {
    echo "💾 Validating cache system..."
    
    # Check if cache directory is writable
    local cache_dir=".claude/tmp"
    mkdir -p "$cache_dir"
    
    if [[ ! -w "$cache_dir" ]]; then
        echo "❌ Cache directory is not writable: $cache_dir"
        return 1
    fi
    
    # Test cache functionality
    local test_key="validation-test"
    local test_data='{"test": "data", "timestamp": "'$(date -Iseconds)'"}'
    
    if ! echo "$test_data" > "$cache_dir/${test_key}.json" 2>/dev/null; then
        echo "❌ Cannot write to cache directory: $cache_dir"
        return 1
    fi
    
    # Clean up test file
    rm -f "$cache_dir/${test_key}.json"
    
    echo "✅ Cache system is functional"
    return 0
}

# Run comprehensive validation
run_full_validation() {
    echo "🚀 Running comprehensive configuration validation..."
    echo ""
    
    local validation_failed=false
    
    # Run all validation checks
    if ! validate_system_requirements; then
        validation_failed=true
    fi
    echo ""
    
    if ! validate_directory_structure; then
        validation_failed=true
    fi
    echo ""
    
    # Only validate config files if they exist
    if [[ -f ".claude/config/defaults.json" ]]; then
        if ! validate_config_files; then
            validation_failed=true
        fi
        echo ""
    fi
    
    if ! validate_cache_system; then
        validation_failed=true
    fi
    echo ""
    
    if [[ "$validation_failed" == "true" ]]; then
        echo "❌ Validation completed with errors"
        echo "   Please fix the issues above before proceeding"
        return 1
    fi
    
    echo "🎉 All validations passed successfully!"
    echo "   Your CCPM configuration is ready to use"
    return 0
}

# =============================================================================
# CCPM PROJECT SPECIFIC VALIDATIONS
# =============================================================================

# Check if epic exists
validate_epic_exists() {
    local epic_name="$1"
    local epic_file=".claude/epics/$epic_name.md"
    
    if [[ ! -f "$epic_file" ]]; then
        echo -e "❌ Epic not found: ${RED}$epic_name${NC}"
        echo ""
        echo "📋 Available epics:"
        list_available_epics
        echo ""
        echo -e "💡 Create epic: ${BLUE}/pm:prd-parse $epic_name${NC}"
        return 1
    fi
    return 0
}

# List available epics
list_available_epics() {
    if [[ -d ".claude/epics" ]]; then
        find .claude/epics -name "*.md" 2>/dev/null | while read -r epic_file; do
            local epic_name
            epic_name=$(basename "$epic_file" .md)
            [[ "$epic_name" != ".archived" ]] && echo "   📐 $epic_name"
        done
    else
        echo "   No epics found"
    fi
}

# Check if PRD exists
validate_prd_exists() {
    local prd_name="$1"
    local prd_file=".claude/prds/$prd_name.md"
    
    if [[ ! -f "$prd_file" ]]; then
        echo -e "❌ PRD not found: ${RED}$prd_name${NC}"
        echo ""
        echo "📋 Available PRDs:"
        list_available_prds
        return 1
    fi
    return 0
}

# List available PRDs
list_available_prds() {
    if [[ -d ".claude/prds" ]]; then
        find .claude/prds -name "*.md" 2>/dev/null | while read -r prd_file; do
            local prd_name
            prd_name=$(basename "$prd_file" .md)
            [[ "$prd_name" != ".archived" ]] && echo "   📄 $prd_name"
        done
    else
        echo "   No PRDs found"
    fi
}

# Check GitHub CLI availability
validate_github_cli() {
    if ! command -v gh &> /dev/null; then
        echo -e "❌ ${RED}GitHub CLI (gh) is not installed${NC}"
        echo "Please install it from: https://cli.github.com/"
        return 1
    fi
    
    if ! gh auth status &> /dev/null; then
        echo -e "❌ ${RED}GitHub CLI is not authenticated${NC}"
        echo "Please run: gh auth login"
        return 1
    fi
    
    return 0
}

# Check if in git repository
validate_git_repository() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "❌ ${RED}Not in a git repository${NC}"
        echo "Please run this command from within a git repository."
        return 1
    fi
    return 0
}

# Check CCPM project structure
validate_ccpm_structure() {
    local required_dirs=(".claude" ".claude/lib" ".claude/scripts" ".claude/commands")
    local missing_dirs=()
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            missing_dirs+=("$dir")
        fi
    done
    
    if [[ ${#missing_dirs[@]} -gt 0 ]]; then
        echo -e "❌ ${RED}Missing required directories: ${missing_dirs[*]}${NC}"
        echo "Please run bootstrap script to initialize the project structure"
        return 1
    fi
    return 0
}

# Generic error handling
handle_validation_error() {
    local error_message="$1"
    local suggestion="$2"
    
    echo -e "❌ ${RED}$error_message${NC}"
    [[ -n "$suggestion" ]] && echo -e "💡 ${YELLOW}$suggestion${NC}"
    return 1
}

# =============================================================================
# EXPORT FUNCTIONS
# =============================================================================

# Export functions
export -f validate_env_config
export -f validate_security_config
export -f validate_system_requirements
export -f validate_directory_structure
export -f validate_cache_system
export -f run_full_validation
export -f validate_epic_exists
export -f list_available_epics
export -f validate_prd_exists
export -f list_available_prds
export -f validate_github_cli
export -f validate_git_repository
export -f validate_ccpm_structure
export -f handle_validation_error

# If script is run directly, run full validation
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_full_validation
fi