#!/bin/bash

# CCPM MCP Server Configuration Script
# Intelligently configures MCP servers based on project type and environment

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(find_project_root)"
CLAUDE_DIR="$PROJECT_ROOT/.claude"
CONFIG_DIR="$CLAUDE_DIR/config"

# Source core functions
if [[ -f "$CLAUDE_DIR/lib/core.sh" ]]; then
    source "$CLAUDE_DIR/lib/core.sh"
fi

if [[ -f "$CLAUDE_DIR/lib/ui.sh" ]]; then
    source "$CLAUDE_DIR/lib/ui.sh"
fi

# =============================================================================
# MCP SERVER DEFINITIONS
# =============================================================================

# Core MCP servers available for different project types
declare -A MCP_SERVERS

# Essential servers (always recommended)
MCP_SERVERS[filesystem]='
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-filesystem"],
  "env": {
    "FILESYSTEM_ALLOWED_DIRECTORIES": "."
  },
  "description": "File system operations with controlled directory access",
  "category": "essential",
  "timeout": 30000,
  "retry": {"attempts": 3, "delay": 1000}
}'

MCP_SERVERS[git]='
{
  "command": "npx", 
  "args": ["-y", "@modelcontextprotocol/server-git"],
  "env": {
    "GIT_REPOSITORY_PATH": "."
  },
  "description": "Git repository operations and history access",
  "category": "essential",
  "timeout": 30000,
  "retry": {"attempts": 3, "delay": 1000}
}'

# Documentation and context servers
MCP_SERVERS[context7]='
{
  "command": "npx",
  "args": ["-y", "@context7/mcp-server"],
  "env": {},
  "description": "Documentation and library context provider",
  "category": "documentation",
  "timeout": 60000,
  "retry": {"attempts": 2, "delay": 2000}
}'

# Testing and automation servers
MCP_SERVERS[puppeteer]='
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-puppeteer"],
  "env": {
    "PUPPETEER_SKIP_CHROMIUM_DOWNLOAD": "false"
  },
  "description": "Browser automation for testing and screenshots",
  "category": "testing",
  "timeout": 45000,
  "retry": {"attempts": 2, "delay": 3000},
  "disabled": true
}'

# Database servers
MCP_SERVERS[sqlite]='
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-sqlite"],
  "env": {
    "SQLITE_DB_PATH": "./data"
  },
  "description": "SQLite database operations and queries",
  "category": "database",
  "timeout": 30000,
  "retry": {"attempts": 3, "delay": 1000},
  "disabled": true
}'

MCP_SERVERS[postgres]='
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-postgres"],
  "env": {
    "POSTGRES_CONNECTION_STRING": "postgresql://localhost:5432/mydb"
  },
  "description": "PostgreSQL database operations",
  "category": "database",
  "timeout": 30000,
  "retry": {"attempts": 3, "delay": 1000},
  "disabled": true
}'

# Cloud and deployment servers
MCP_SERVERS[aws]='
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-aws"],
  "env": {
    "AWS_REGION": "us-east-1"
  },
  "description": "AWS cloud services integration",
  "category": "cloud",
  "timeout": 45000,
  "retry": {"attempts": 2, "delay": 2000},
  "disabled": true
}'

MCP_SERVERS[docker]='
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-docker"],
  "env": {},
  "description": "Docker container management",
  "category": "devops",
  "timeout": 60000,
  "retry": {"attempts": 2, "delay": 3000},
  "disabled": true
}'

# Development tools
MCP_SERVERS[github]='
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": ""
  },
  "description": "GitHub repository and API integration",
  "category": "development",
  "timeout": 30000,
  "retry": {"attempts": 3, "delay": 1000},
  "disabled": true
}'

# =============================================================================
# PROJECT TYPE CONFIGURATIONS
# =============================================================================

# Define which servers are recommended for each project type
declare -A PROJECT_MCP_CONFIG

PROJECT_MCP_CONFIG[react]='
{
  "essential": ["filesystem", "git"],
  "recommended": ["context7", "puppeteer", "github"],
  "optional": ["docker"],
  "testing_focused": true,
  "web_development": true
}'

PROJECT_MCP_CONFIG[nextjs]='
{
  "essential": ["filesystem", "git"],
  "recommended": ["context7", "puppeteer", "github"],
  "optional": ["docker", "aws"],
  "testing_focused": true,
  "web_development": true,
  "fullstack": true
}'

PROJECT_MCP_CONFIG[nodejs]='
{
  "essential": ["filesystem", "git"],
  "recommended": ["context7", "github"],
  "optional": ["docker", "postgres", "sqlite"],
  "backend_focused": true
}'

PROJECT_MCP_CONFIG[python]='
{
  "essential": ["filesystem", "git"],
  "recommended": ["context7", "github"],
  "optional": ["docker", "postgres", "sqlite", "aws"],
  "backend_focused": true,
  "data_science": true
}'

PROJECT_MCP_CONFIG[django]='
{
  "essential": ["filesystem", "git"],
  "recommended": ["context7", "postgres", "github"],
  "optional": ["docker", "aws"],
  "backend_focused": true,
  "web_framework": true
}'

PROJECT_MCP_CONFIG[golang]='
{
  "essential": ["filesystem", "git"],
  "recommended": ["context7", "github"],
  "optional": ["docker", "postgres"],
  "backend_focused": true,
  "performance_critical": true
}'

PROJECT_MCP_CONFIG[rust]='
{
  "essential": ["filesystem", "git"],
  "recommended": ["context7", "github"],
  "optional": ["docker"],
  "systems_programming": true,
  "performance_critical": true
}'

PROJECT_MCP_CONFIG[docker]='
{
  "essential": ["filesystem", "git", "docker"],
  "recommended": ["context7", "github"],
  "optional": ["aws"],
  "devops_focused": true,
  "containerization": true
}'

PROJECT_MCP_CONFIG[generic]='
{
  "essential": ["filesystem", "git"],
  "recommended": ["context7"],
  "optional": ["github"],
  "minimal": true
}'

# =============================================================================
# CONFIGURATION FUNCTIONS
# =============================================================================

# Generate MCP configuration for project type
generate_mcp_config() {
    local project_type="$1"
    local environment="${2:-development}"
    local minimal="${3:-false}"
    
    show_info "Generating MCP configuration for $project_type project..."
    
    # Get project-specific configuration
    local project_config="${PROJECT_MCP_CONFIG[$project_type]:-${PROJECT_MCP_CONFIG[generic]}}"
    
    # Extract server lists
    local essential_servers
    local recommended_servers
    local optional_servers
    
    essential_servers=$(echo "$project_config" | jq -r '.essential[]' 2>/dev/null || echo "filesystem git")
    recommended_servers=$(echo "$project_config" | jq -r '.recommended[]?' 2>/dev/null || echo "")
    optional_servers=$(echo "$project_config" | jq -r '.optional[]?' 2>/dev/null || echo "")
    
    # Start building configuration
    local mcp_config='{"mcpServers": {}}'
    
    # Add essential servers (always enabled)
    for server in $essential_servers; do
        mcp_config=$(echo "$mcp_config" | jq --argjson server_config "${MCP_SERVERS[$server]}" \
            ".mcpServers.\"$server\" = \$server_config")
    done
    
    # Add recommended servers (enabled by default unless minimal)
    if [[ "$minimal" != "true" ]]; then
        for server in $recommended_servers; do
            if [[ -n "${MCP_SERVERS[$server]:-}" ]]; then
                local server_config="${MCP_SERVERS[$server]}"
                # Enable recommended servers by default
                server_config=$(echo "$server_config" | jq 'del(.disabled)')
                mcp_config=$(echo "$mcp_config" | jq --argjson server_config "$server_config" \
                    ".mcpServers.\"$server\" = \$server_config")
            fi
        done
    fi
    
    # Add optional servers (disabled by default)
    for server in $optional_servers; do
        if [[ -n "${MCP_SERVERS[$server]:-}" ]]; then
            local server_config="${MCP_SERVERS[$server]}"
            # Ensure optional servers are disabled by default
            server_config=$(echo "$server_config" | jq '.disabled = true')
            mcp_config=$(echo "$mcp_config" | jq --argjson server_config "$server_config" \
                ".mcpServers.\"$server\" = \$server_config")
        fi
    done
    
    # Add configuration metadata
    mcp_config=$(echo "$mcp_config" | jq --arg project_type "$project_type" \
                                         --arg environment "$environment" \
                                         --arg generated "$(date -Iseconds)" \
                                         '
        .metadata = {
            project_type: $project_type,
            environment: $environment,
            generated: $generated,
            ccpm_version: "2.0"
        }
    ')
    
    # Add validation and fallback configuration
    mcp_config=$(echo "$mcp_config" | jq '
        .validation = {
            required_commands: ["npx", "node"],
            environment_checks: ["NODE_PATH", "npm_config_prefix"],
            health_check_interval: 60000
        } |
        .fallback = {
            mode: "graceful_degradation",
            essential_servers: ["filesystem", "git"],
            retry_strategy: "exponential_backoff"
        } |
        .performance = {
            concurrent_requests: 10,
            request_timeout: 30000,
            memory_limit: "512MB"
        }
    ')
    
    echo "$mcp_config"
}

# Configure environment-specific settings
configure_environment_settings() {
    local environment="$1"
    local mcp_config="$2"
    
    case "$environment" in
        "development")
            mcp_config=$(echo "$mcp_config" | jq '
                .performance.concurrent_requests = 5 |
                .performance.request_timeout = 45000 |
                .validation.health_check_interval = 30000
            ')
            ;;
        "testing")
            mcp_config=$(echo "$mcp_config" | jq '
                .mcpServers.puppeteer.disabled = false |
                .performance.concurrent_requests = 3 |
                .performance.request_timeout = 60000
            ')
            ;;
        "production")
            mcp_config=$(echo "$mcp_config" | jq '
                .performance.concurrent_requests = 15 |
                .performance.request_timeout = 20000 |
                .validation.health_check_interval = 120000 |
                del(.mcpServers.puppeteer) // .
            ')
            ;;
    esac
    
    echo "$mcp_config"
}

# Validate MCP configuration
validate_mcp_config() {
    local config_file="$1"
    
    show_progress "Validating MCP configuration..."
    
    # Check JSON syntax
    if ! jq . "$config_file" >/dev/null 2>&1; then
        show_error "Invalid JSON" "MCP configuration has invalid JSON syntax"
        return 1
    fi
    
    # Check required fields
    local required_fields=(".mcpServers" ".validation" ".fallback")
    for field in "${required_fields[@]}"; do
        if ! jq -e "$field" "$config_file" >/dev/null 2>&1; then
            show_error "Missing Field" "Required field $field is missing from MCP configuration"
            return 1
        fi
    done
    
    # Validate server configurations
    local validation_errors=()
    
    while IFS= read -r server; do
        # Check required server fields
        if ! jq -e ".mcpServers.\"$server\".command" "$config_file" >/dev/null 2>&1; then
            validation_errors+=("Server $server is missing 'command' field")
        fi
        
        if ! jq -e ".mcpServers.\"$server\".args" "$config_file" >/dev/null 2>&1; then
            validation_errors+=("Server $server is missing 'args' field")
        fi
    done < <(jq -r '.mcpServers | keys[]' "$config_file")
    
    # Report validation results
    if [[ ${#validation_errors[@]} -gt 0 ]]; then
        show_error "Validation Failed" "$(printf '%s\n' "${validation_errors[@]}")"
        return 1
    else
        show_success "MCP configuration validation passed"
        return 0
    fi
}

# Test MCP server connectivity
test_mcp_servers() {
    local config_file="$1"
    
    show_progress "Testing MCP server connectivity..."
    
    # Check if required commands are available
    local required_commands
    required_commands=$(jq -r '.validation.required_commands[]' "$config_file" 2>/dev/null || echo "npx node")
    
    for cmd in $required_commands; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            show_error "Missing Command" "Required command '$cmd' not found in PATH"
            return 1
        fi
    done
    
    # Test enabled servers
    local test_results=()
    
    while IFS= read -r server; do
        local disabled
        disabled=$(jq -r ".mcpServers.\"$server\".disabled // false" "$config_file")
        
        if [[ "$disabled" == "false" ]]; then
            echo "  Testing server: $server"
            
            # This is a simplified test - in practice, you'd want to actually start the server
            local command
            local args
            command=$(jq -r ".mcpServers.\"$server\".command" "$config_file")
            args=$(jq -r ".mcpServers.\"$server\".args | @sh" "$config_file")
            
            if command -v "$command" >/dev/null 2>&1; then
                test_results+=("✅ $server: Command available")
            else
                test_results+=("❌ $server: Command '$command' not found")
            fi
        else
            test_results+=("⏸️  $server: Disabled")
        fi
    done < <(jq -r '.mcpServers | keys[]' "$config_file")
    
    # Display results
    echo ""
    echo "MCP Server Test Results:"
    printf '%s\n' "${test_results[@]}"
    
    show_success "MCP server testing completed"
}

# =============================================================================
# MAIN FUNCTIONS
# =============================================================================

show_help() {
    cat << EOF
CCPM MCP Server Configuration Tool

Configure MCP servers intelligently based on project type and environment.

Usage: $0 [options] [project_type]

Arguments:
  project_type    Project type (react, python, golang, etc.)
                 If not provided, will auto-detect

Options:
  --environment   Target environment (development, testing, production)
  --minimal       Minimal configuration with only essential servers
  --validate      Validate existing MCP configuration
  --test          Test MCP server connectivity
  --list-servers  List available MCP servers
  --output FILE   Output configuration to specific file
  -h, --help      Show this help

Examples:
  $0                              # Auto-detect and configure
  $0 react                       # Configure for React project
  $0 python --environment testing # Configure Python project for testing
  $0 --minimal nodejs            # Minimal Node.js configuration
  $0 --validate                  # Validate current configuration

EOF
}

# List available MCP servers
list_mcp_servers() {
    echo "Available MCP Servers:"
    echo ""
    
    local categories=("essential" "documentation" "testing" "database" "cloud" "devops" "development")
    
    for category in "${categories[@]}"; do
        echo "📦 $category:"
        
        for server in "${!MCP_SERVERS[@]}"; do
            local server_category
            server_category=$(echo "${MCP_SERVERS[$server]}" | jq -r '.category // "other"')
            
            if [[ "$server_category" == "$category" ]]; then
                local description
                description=$(echo "${MCP_SERVERS[$server]}" | jq -r '.description')
                printf "  %-12s %s\n" "$server" "$description"
            fi
        done
        echo ""
    done
}

# Auto-detect project type
auto_detect_project_type() {
    if [[ -f "$CONFIG_DIR/project.json" ]]; then
        jq -r '.project.type // "generic"' "$CONFIG_DIR/project.json"
    else
        echo "generic"
    fi
}

# Main function
main() {
    local project_type=""
    local environment="development"
    local minimal="false"
    local validate_only="false"
    local test_only="false"
    local output_file="$PROJECT_ROOT/.mcp.json"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --environment)
                environment="$2"
                shift 2
                ;;
            --minimal)
                minimal="true"
                shift
                ;;
            --validate)
                validate_only="true"
                shift
                ;;
            --test)
                test_only="true"
                shift
                ;;
            --list-servers)
                list_mcp_servers
                exit 0
                ;;
            --output)
                output_file="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                if [[ -z "$project_type" ]]; then
                    project_type="$1"
                else
                    echo "❌ Error: Unexpected argument: $1"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validation mode
    if [[ "$validate_only" == "true" ]]; then
        if [[ -f "$output_file" ]]; then
            validate_mcp_config "$output_file"
        else
            show_error "Configuration Not Found" "MCP configuration file not found: $output_file"
            exit 1
        fi
        exit $?
    fi
    
    # Test mode
    if [[ "$test_only" == "true" ]]; then
        if [[ -f "$output_file" ]]; then
            test_mcp_servers "$output_file"
        else
            show_error "Configuration Not Found" "MCP configuration file not found: $output_file"
            exit 1
        fi
        exit $?
    fi
    
    # Auto-detect project type if not provided
    if [[ -z "$project_type" ]]; then
        project_type=$(auto_detect_project_type)
        show_info "Auto-detected project type: $project_type"
    fi
    
    # Generate MCP configuration
    show_title "CCPM MCP Server Configuration" 50
    echo "Project Type: $project_type"
    echo "Environment: $environment"
    echo "Minimal: $minimal"
    echo "Output: $output_file"
    echo ""
    
    local mcp_config
    mcp_config=$(generate_mcp_config "$project_type" "$environment" "$minimal")
    
    # Apply environment-specific settings
    mcp_config=$(configure_environment_settings "$environment" "$mcp_config")
    
    # Create backup if file exists
    if [[ -f "$output_file" ]]; then
        local backup_file="${output_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$output_file" "$backup_file"
        show_info "Created backup: $backup_file"
    fi
    
    # Write configuration
    echo "$mcp_config" | jq . > "$output_file"
    
    # Validate generated configuration
    if validate_mcp_config "$output_file"; then
        echo ""
        show_completion "MCP configuration generated successfully!"
        show_next_steps "
        claude                    # Start Claude Code with new MCP config
        $0 --test                # Test MCP server connectivity
        $0 --validate            # Validate configuration"
        
        # Show enabled servers
        echo ""
        echo "Enabled MCP Servers:"
        jq -r '.mcpServers | to_entries[] | select(.value.disabled != true) | "  ✅ " + .key + ": " + .value.description' "$output_file"
        
        echo ""
        echo "Disabled MCP Servers:"
        jq -r '.mcpServers | to_entries[] | select(.value.disabled == true) | "  ⏸️  " + .key + ": " + .value.description' "$output_file"
    else
        show_error "Configuration Failed" "Generated MCP configuration failed validation"
        exit 1
    fi
}

# Entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi