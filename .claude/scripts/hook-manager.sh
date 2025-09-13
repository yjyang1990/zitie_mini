#!/bin/bash

# CCPM Hook Manager v2.0 - Git Hooks Management
# Manages Git hooks installation, configuration, and updates

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
HOOKS_DIR=".claude/hooks"
GIT_HOOKS_DIR="$(git rev-parse --git-dir 2>/dev/null || echo '.git')/hooks"
HOOKS_CONFIG="$HOOKS_DIR/config.json"

# Available hooks
AVAILABLE_HOOKS=("pre-commit" "post-commit" "pre-push" "commit-msg")

# Function to show usage
show_usage() {
    show_command_help "hook-manager" "Manage Git hooks for CCPM" \
        "hook-manager [COMMAND] [OPTIONS]            # Manage Git hooks
hook-manager install <hook>                     # Install specific hook
hook-manager install-all [--force]              # Install all hooks
hook-manager uninstall <hook>                   # Uninstall hook
hook-manager status                             # Check installation status
hook-manager test <hook>                        # Test hook functionality"
    
    echo ""
    echo "Commands:"
    echo "  install <hook>              Install specific Git hook"
    echo "  install-all [--force]       Install all CCPM hooks"
    echo "  uninstall <hook>            Uninstall specific hook"
    echo "  status                      Check hook installation status"
    echo "  enable <hook>               Enable hook in configuration"
    echo "  disable <hook>              Disable hook in configuration"
    echo "  test <hook>                 Test hook functionality"
    echo "  logs [lines]                Show hook execution logs"
    echo "  config <hook> <setting> <value> Update hook configuration"
    echo "  help                        Show this help message"
    echo ""
    echo "Available hooks: ${AVAILABLE_HOOKS[*]}"
    echo ""
    echo "Examples:"
    echo "  hook-manager install pre-commit         # Install pre-commit hook"
    echo "  hook-manager install-all --force        # Force install all hooks"
    echo "  hook-manager status                     # Check installation status"
    echo "  hook-manager test pre-commit            # Test pre-commit hook"
    echo "  hook-manager logs 100                   # Show last 100 log lines"
}

# Install a specific hook
install_hook() {
    local hook_name="$1"
    local force="${2:-false}"
    
    show_subtitle "🔧 Installing $hook_name Hook"
    
    # Validate hook name
    if [[ ! " ${AVAILABLE_HOOKS[*]} " =~ ${hook_name} ]]; then
        show_error "Unknown Hook" "Hook '$hook_name' is not supported"
        show_info "Available hooks: ${AVAILABLE_HOOKS[*]}"
        return 1
    fi
    
    # Check if source hook exists
    local source_hook="$HOOKS_DIR/${hook_name}"
    if [[ ! -f "$source_hook" ]]; then
        show_error "Hook Source Missing" "Hook source not found: $hook_name"
        show_tip "Check $HOOKS_DIR directory for available hooks"
        return 1
    fi
    
    # Ensure git hooks directory exists
    ensure_directory "$GIT_HOOKS_DIR"
    
    local target_hook="$GIT_HOOKS_DIR/$hook_name"
    
    # Check if hook already exists
    if [[ -f "$target_hook" && "$force" != "true" ]]; then
        show_warning "Hook Exists" "Hook already installed: $hook_name"
        show_tip "Use --force to overwrite existing hook"
        return 1
    fi
    
    # Backup existing hook
    if [[ -f "$target_hook" ]]; then
        local backup_file="${target_hook}.backup.$(date +%Y%m%d-%H%M%S)"
        cp "$target_hook" "$backup_file"
        show_info "✓ Backed up existing hook: $(basename "$backup_file")"
    fi
    
    # Install new hook
    cp "$source_hook" "$target_hook"
    chmod +x "$target_hook"
    
    show_success "Hook Installed" "$hook_name hook installed successfully"
    return 0
}

# Uninstall a specific hook
uninstall_hook() {
    local hook_name="$1"
    
    show_subtitle "🗑️ Uninstalling $hook_name Hook"
    
    local target_hook="$GIT_HOOKS_DIR/$hook_name"
    
    if [[ ! -f "$target_hook" ]]; then
        show_warning "Hook Not Found" "Hook not installed: $hook_name"
        return 0
    fi
    
    # Create backup before removal
    local backup_file="${target_hook}.removed.$(date +%Y%m%d-%H%M%S)"
    mv "$target_hook" "$backup_file"
    
    show_success "Hook Uninstalled" "$hook_name (backed up to: $(basename "$backup_file"))"
    return 0
}

# Install all CCPM hooks
install_all_hooks() {
    local force="${1:-false}"
    
    show_title "🔧 Installing All CCPM Hooks" 40
    
    local success_count=0
    local total_hooks=${#AVAILABLE_HOOKS[@]}
    
    for hook in "${AVAILABLE_HOOKS[@]}"; do
        show_progress "Installing $hook hook..."
        if install_hook "$hook" "$force"; then
            ((success_count++))
        fi
    done
    
    echo ""
    if [[ $success_count -eq $total_hooks ]]; then
        show_success "All Hooks Installed" "$success_count/$total_hooks hooks installed"
    else
        local failed_count=$((total_hooks - success_count))
        show_warning "Partial Installation" "$failed_count/$total_hooks hooks failed"
    fi
    
    return 0
}

# Check hook installation status
check_hook_status() {
    show_title "📊 CCPM Hook Status" 40
    
    local installed_count=0
    local total_hooks=${#AVAILABLE_HOOKS[@]}
    
    show_subtitle "🔍 Hook Installation Status"
    
    for hook in "${AVAILABLE_HOOKS[@]}"; do
        local target_hook="$GIT_HOOKS_DIR/$hook"
        local config_enabled=""
        
        # Check configuration if available
        if [[ -f "$HOOKS_CONFIG" ]] && command -v jq >/dev/null 2>&1; then
            config_enabled=$(jq -r ".hooks.\"$hook\".enabled // \"unknown\"" "$HOOKS_CONFIG" 2>/dev/null)
        fi
        
        if [[ -f "$target_hook" ]]; then
            if [[ -x "$target_hook" ]]; then
                show_success "$hook" "Installed and executable"
                ((installed_count++))
            else
                show_warning "$hook" "Installed but not executable"
            fi
        else
            show_error "$hook" "Not installed"
        fi
        
        if [[ -n "$config_enabled" && "$config_enabled" != "unknown" ]]; then
            if [[ "$config_enabled" == "true" ]]; then
                echo "    Configuration: enabled"
            else
                echo "    Configuration: disabled"
            fi
        fi
        
        echo ""
    done
    
    show_subtitle "📈 Summary"
    echo "  Installed hooks: $installed_count/$total_hooks"
    echo "  Git hooks directory: $GIT_HOOKS_DIR"
    echo "  Configuration file: $HOOKS_CONFIG"
    
    if [[ $installed_count -eq $total_hooks ]]; then
        show_success "All Hooks Ready" "All CCPM hooks are properly installed"
    else
        show_warning "Missing Hooks" "Some hooks need installation"
        show_tip "Run 'hook-manager install-all' to install missing hooks"
    fi
}

# Update hook configuration
update_hook_config() {
    local hook_name="$1"
    local setting="$2"
    local value="$3"
    
    show_info "Updating $hook_name configuration: $setting = $value"
    
    if [[ ! -f "$HOOKS_CONFIG" ]]; then
        show_error "Configuration Missing" "Hook configuration not found: $HOOKS_CONFIG"
        return 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        show_error "jq Required" "jq is required for configuration updates"
        return 1
    fi
    
    # Update configuration using jq
    local temp_file
    temp_file=$(mktemp)
    
    if jq ".hooks.\"$hook_name\".$setting = $value" "$HOOKS_CONFIG" > "$temp_file"; then
        mv "$temp_file" "$HOOKS_CONFIG"
        show_success "Configuration Updated" "$hook_name.$setting = $value"
    else
        rm -f "$temp_file"
        show_error "Configuration Update Failed" "Could not update $hook_name configuration"
        return 1
    fi
}

# Enable/disable a hook
toggle_hook() {
    local hook_name="$1"
    local action="$2" # enable or disable
    
    local enabled_value
    if [[ "$action" == "enable" ]]; then
        enabled_value="true"
    else
        enabled_value="false"
    fi
    
    if update_hook_config "$hook_name" "enabled" "$enabled_value"; then
        show_success "Hook $action" "$hook_name hook is now ${action}d"
    fi
}

# Test a hook
test_hook() {
    local hook_name="$1"
    
    show_title "🧪 Testing $hook_name Hook" 40
    
    local target_hook="$GIT_HOOKS_DIR/$hook_name"
    
    if [[ ! -f "$target_hook" ]]; then
        show_error "Hook Not Installed" "Hook not found: $hook_name"
        show_tip "Run 'hook-manager install $hook_name' to install"
        return 1
    fi
    
    if [[ ! -x "$target_hook" ]]; then
        show_error "Hook Not Executable" "Hook lacks execute permission: $hook_name"
        show_tip "Run 'chmod +x $target_hook' to fix"
        return 1
    fi
    
    show_subtitle "🔍 Hook Test Results"
    
    case "$hook_name" in
        "pre-commit")
            show_info "Testing pre-commit hook functionality..."
            if "$target_hook" --help >/dev/null 2>&1; then
                show_success "Help Command" "Hook responds to --help flag"
            else
                show_warning "Help Command" "Hook may not support --help"
            fi
            ;;
        "post-commit")
            show_info "Post-commit hook test requires actual commit"
            show_tip "Hook will execute after next git commit"
            ;;
        "pre-push")
            show_info "Pre-push hook test requires push scenario"
            show_tip "Hook will execute before next git push"
            ;;
        "commit-msg")
            show_info "Testing commit-msg hook with sample message..."
            local temp_msg
            temp_msg=$(mktemp)
            echo "test: sample commit message" > "$temp_msg"
            if "$target_hook" "$temp_msg" >/dev/null 2>&1; then
                show_success "Message Validation" "Hook accepts valid commit message"
            else
                show_warning "Message Validation" "Hook may have strict requirements"
            fi
            rm -f "$temp_msg"
            ;;
        *)
            show_warning "No Test Available" "No specific test for $hook_name"
            ;;
    esac
    
    show_success "Hook Test Complete" "$hook_name hook test finished"
}

# Show hook execution logs
show_hook_logs() {
    local lines="${1:-50}"
    local log_file=".claude/logs/hooks.log"
    
    show_title "📜 Hook Execution Logs" 40
    
    if [[ ! -f "$log_file" ]]; then
        show_warning "No Logs Found" "Hook log file not found: $log_file"
        show_tip "Logs will appear after hooks execute"
        return 0
    fi
    
    show_info "Showing last $lines lines from hook logs:"
    echo ""
    tail -n "$lines" "$log_file"
}

# Initialize hook configuration
init_hook_config() {
    show_subtitle "⚙️ Initializing Hook Configuration"
    
    ensure_directory "$HOOKS_DIR"
    
    if [[ ! -f "$HOOKS_CONFIG" ]]; then
        cat > "$HOOKS_CONFIG" << 'EOF'
{
  "version": "2.0",
  "hooks": {
    "pre-commit": {
      "enabled": true,
      "validate_syntax": true,
      "run_tests": false,
      "check_formatting": true
    },
    "post-commit": {
      "enabled": true,
      "update_cache": true,
      "notify": false
    },
    "pre-push": {
      "enabled": true,
      "run_full_tests": false,
      "validate_branch": true
    },
    "commit-msg": {
      "enabled": true,
      "enforce_format": true,
      "min_length": 10
    }
  }
}
EOF
        show_success "Configuration Created" "$HOOKS_CONFIG"
    else
        show_info "Configuration already exists"
    fi
}

# Parse command and execute
COMMAND="${1:-help}"

case "$COMMAND" in
    "install")
        if [[ $# -lt 2 ]]; then
            show_error "Missing Hook Name" "Usage: hook-manager install <hook>"
            exit 1
        fi
        install_hook "$2" "${3:-false}"
        ;;
    "install-all")
        local force="false"
        if [[ "${2:-}" == "--force" ]]; then
            force="true"
        fi
        install_all_hooks "$force"
        ;;
    "uninstall")
        if [[ $# -lt 2 ]]; then
            show_error "Missing Hook Name" "Usage: hook-manager uninstall <hook>"
            exit 1
        fi
        uninstall_hook "$2"
        ;;
    "status")
        check_hook_status
        ;;
    "enable")
        if [[ $# -lt 2 ]]; then
            show_error "Missing Hook Name" "Usage: hook-manager enable <hook>"
            exit 1
        fi
        toggle_hook "$2" "enable"
        ;;
    "disable")
        if [[ $# -lt 2 ]]; then
            show_error "Missing Hook Name" "Usage: hook-manager disable <hook>"
            exit 1
        fi
        toggle_hook "$2" "disable"
        ;;
    "test")
        if [[ $# -lt 2 ]]; then
            show_error "Missing Hook Name" "Usage: hook-manager test <hook>"
            exit 1
        fi
        test_hook "$2"
        ;;
    "logs")
        show_hook_logs "${2:-50}"
        ;;
    "config")
        if [[ $# -lt 4 ]]; then
            show_error "Invalid Arguments" "Usage: hook-manager config <hook> <setting> <value>"
            exit 1
        fi
        update_hook_config "$2" "$3" "$4"
        ;;
    "init")
        init_hook_config
        ;;
    "--help"|"-h"|"help"|*)
        show_usage
        ;;
esac

# Only run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script was executed directly
    :
fi