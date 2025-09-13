#!/bin/bash

# CCPM Configuration Management
# Handles configuration loading, validation, and environment setup

set -euo pipefail

# Configuration file paths
CONFIG_DIR=".claude/config"
DEFAULT_CONFIG_FILE="$CONFIG_DIR/defaults.json"
USER_CONFIG_FILE="$CONFIG_DIR/user.json"
ENV_CONFIG_FILE="$CONFIG_DIR/env.json"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Create secure temporary file
create_secure_temp() {
    local prefix="${1:-ccpm}"
    mktemp "/tmp/${prefix}.XXXXXX"
}

# =============================================================================
# CONFIGURATION MANAGEMENT
# =============================================================================

# Initialize configuration system
init_config() {
    mkdir -p "$CONFIG_DIR"
    
    # Create default configuration if it doesn't exist
    if [[ ! -f "$DEFAULT_CONFIG_FILE" ]]; then
        cat > "$DEFAULT_CONFIG_FILE" << 'EOF'
{
  "system": {
    "log_level": "info",
    "max_concurrent_operations": 5,
    "default_timeout_ms": 300000,
    "cache_ttl_seconds": 86400
  },
  "github": {
    "api_timeout_ms": 30000,
    "max_retries": 3,
    "rate_limit_buffer": 0.8
  },
  "epic": {
    "default_parallel_tasks": 3,
    "max_parallel_streams": 5,
    "auto_sync_interval_seconds": 3600
  },
  "paths": {
    "epics_dir": ".claude/epics",
    "prds_dir": ".claude/prds",
    "logs_dir": ".claude/tmp",
    "cache_dir": ".claude/tmp",
    "temp_dir": "/tmp"
  },
  "ui": {
    "show_progress": true,
    "color_output": true,
    "verbose_errors": false
  }
}
EOF
    fi
    
    # Create user configuration template if it doesn't exist
    if [[ ! -f "$USER_CONFIG_FILE" ]]; then
        cat > "$USER_CONFIG_FILE" << 'EOF'
{
  "user": {
    "name": "",
    "email": "",
    "preferred_editor": "code"
  },
  "preferences": {
    "auto_cleanup": true,
    "confirm_destructive_actions": true,
    "show_tips": true
  },
  "integrations": {
    "slack_webhook": "",
    "email_notifications": false
  }
}
EOF
    fi
}

# Load configuration value
get_config() {
    local key="$1"
    local default_value="${2:-}"
    
    # Initialize config if needed
    init_config
    
    # Try to get value from user config first, then default
    local value
    value=$(jq -r ".$key // empty" "$USER_CONFIG_FILE" 2>/dev/null || echo "")
    
    if [[ -z "$value" || "$value" == "null" ]]; then
        value=$(jq -r ".$key // empty" "$DEFAULT_CONFIG_FILE" 2>/dev/null || echo "")
    fi
    
    if [[ -z "$value" || "$value" == "null" ]]; then
        echo "$default_value"
    else
        echo "$value"
    fi
}

# Set configuration value
set_config() {
    local key="$1"
    local value="$2"
    
    # Initialize config if needed
    init_config
    
    # Update user configuration
    local temp_file
    temp_file=$(create_secure_temp "config-update")
    
    if command -v jq >/dev/null 2>&1; then
        jq --arg key "$key" --arg value "$value" 'setpath($key | split("."); $value)' "$USER_CONFIG_FILE" > "$temp_file" 2>/dev/null || {
            echo "Error: Failed to update configuration" >&2
            rm -f "$temp_file"
            return 1
        }
        mv "$temp_file" "$USER_CONFIG_FILE"
    else
        echo "Error: jq is required for configuration management" >&2
        return 1
    fi
}

# Load environment-specific configuration
load_env_config() {
    local env="${1:-development}"
    
    # Initialize config if needed
    init_config
    
    # Create environment-specific config if it doesn't exist
    if [[ ! -f "$ENV_CONFIG_FILE" ]]; then
        cat > "$ENV_CONFIG_FILE" << 'EOF'
{
  "development": {
    "log_level": "DEBUG",
    "cache_ttl_hours": 1,
    "show_progress": true
  },
  "production": {
    "log_level": "WARN",
    "cache_ttl_hours": 24,
    "show_progress": false,
    "confirm_destructive_actions": true
  },
  "testing": {
    "log_level": "ERROR",
    "cache_ttl_hours": 0,
    "show_progress": false
  }
}
EOF
    fi
    
    # Load environment-specific overrides
    local env_config
    env_config=$(jq -r ".$env // {}" "$ENV_CONFIG_FILE" 2>/dev/null || echo "{}")
    
    if [[ "$env_config" != "{}" && "$env_config" != "null" ]]; then
        # Apply environment overrides to user config
        local temp_file
        temp_file=$(create_secure_temp "env-config")
        
        jq --argjson env "$env_config" '. * $env' "$USER_CONFIG_FILE" > "$temp_file" 2>/dev/null && {
            mv "$temp_file" "$USER_CONFIG_FILE"
        } || {
            echo "Warning: Failed to apply environment configuration" >&2
            rm -f "$temp_file"
        }
    fi
}

# Validate configuration
validate_config() {
    local errors=0
    
    # Check required fields
    local required_fields=("system.log_level" "github.api_timeout_ms" "epic.default_parallel_tasks")
    
    for field in "${required_fields[@]}"; do
        local value
        value=$(get_config "$field")
        
        if [[ -z "$value" || "$value" == "null" ]]; then
            echo "❌ Missing required configuration: $field"
            ((errors++))
        fi
    done
    
    # Validate numeric values
    local timeout
    timeout=$(get_config "github.api_timeout_ms")
    if [[ ! "$timeout" =~ ^[0-9]+$ ]] || [[ "$timeout" -lt 1000 ]]; then
        echo "❌ Invalid GitHub API timeout: $timeout (must be positive integer in milliseconds, min 1000)"
        ((errors++))
    fi
    
    # Validate paths exist or can be created
    local epics_dir
    epics_dir=$(get_config "paths.epics_dir")
    if [[ ! -d "$epics_dir" ]]; then
        echo "ℹ️ Epics directory does not exist: $epics_dir (will be created)"
        mkdir -p "$epics_dir" 2>/dev/null || {
            echo "❌ Cannot create epics directory: $epics_dir"
            ((errors++))
        }
    fi
    
    if [[ $errors -eq 0 ]]; then
        echo "✅ Configuration validation passed"
        return 0
    else
        echo "❌ Configuration validation failed with $errors errors"
        return 1
    fi
}

# Get environment variable with config fallback
get_env_or_config() {
    local env_var="$1"
    local config_key="$2"
    local default_value="${3:-}"
    
    # Try environment variable first
    if [[ -n "${!env_var:-}" ]]; then
        echo "${!env_var}"
        return
    fi
    
    # Fall back to configuration
    get_config "$config_key" "$default_value"
}

# Export configuration as environment variables
export_config() {
    # System settings
    export CCPM_LOG_LEVEL=$(get_config "system.log_level" "info")
    export CCPM_MAX_CONCURRENT=$(get_config "system.max_concurrent_operations" "5")
    export CCPM_DEFAULT_TIMEOUT_MS=$(get_config "system.default_timeout_ms" "300000")
    export CCPM_CACHE_TTL_SECONDS=$(get_config "system.cache_ttl_seconds" "86400")
    
    # GitHub settings
    export CCPM_GITHUB_TIMEOUT_MS=$(get_config "github.api_timeout_ms" "30000")
    export CCPM_GITHUB_RETRIES=$(get_config "github.max_retries" "3")
    
    # Epic settings
    export CCPM_PARALLEL_TASKS=$(get_config "epic.default_parallel_tasks" "3")
    export CCPM_MAX_STREAMS=$(get_config "epic.max_parallel_streams" "5")
    
    # UI settings
    export CCPM_SHOW_PROGRESS=$(get_config "ui.show_progress" "true")
    export CCPM_COLOR_OUTPUT=$(get_config "ui.color_output" "true")
    export CCPM_VERBOSE_ERRORS=$(get_config "ui.verbose_errors" "false")
    
    # Paths
    export CCPM_EPICS_DIR=$(get_config "paths.epics_dir" ".claude/epics")
    export CCPM_PRDS_DIR=$(get_config "paths.prds_dir" ".claude/prds")
    export CCPM_LOGS_DIR=$(get_config "paths.logs_dir" ".claude/tmp")
    export CCPM_CACHE_DIR=$(get_config "paths.cache_dir" ".claude/tmp")
}

# Show current configuration
show_config() {
    echo "CCPM Configuration"
    echo "=================="
    echo ""
    
    echo "System Settings:"
    echo "  Log Level: $(get_config 'system.log_level')"
    echo "  Max Concurrent: $(get_config 'system.max_concurrent_operations')"
    echo "  Default Timeout: $(get_config 'system.default_timeout_ms')ms"
    echo "  Cache TTL: $(get_config 'system.cache_ttl_seconds')s"
    echo ""
    
    echo "GitHub Settings:"
    echo "  API Timeout: $(get_config 'github.api_timeout_ms')ms"
    echo "  Max Retries: $(get_config 'github.max_retries')"
    echo ""
    
    echo "Epic Settings:"
    echo "  Default Parallel Tasks: $(get_config 'epic.default_parallel_tasks')"
    echo "  Max Parallel Streams: $(get_config 'epic.max_parallel_streams')"
    echo ""
    
    echo "Paths:"
    echo "  Epics: $(get_config 'paths.epics_dir')"
    echo "  PRDs: $(get_config 'paths.prds_dir')"
    echo "  Logs: $(get_config 'paths.logs_dir')"
    echo "  Cache: $(get_config 'paths.cache_dir')"
}

# =============================================================================
# EXPORT FUNCTIONS
# =============================================================================

# Export functions
export -f create_secure_temp
export -f init_config
export -f get_config
export -f set_config
export -f load_env_config
export -f validate_config
export -f get_env_or_config
export -f export_config
export -f show_config