#!/bin/bash

# CCPM Validation Script - Comprehensive Project Validation
# Validate project structure, configurations, and files for CCPM v2.0

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

if [[ -f "$LIB_DIR/validation.sh" ]]; then
    source "$LIB_DIR/validation.sh"
fi

# Function to show usage
show_usage() {
    show_command_help "/pm:validate" "Validate CCPM project integrity" \
        "validate [MODE] [OPTIONS]                   # Validate project
validate                                        # Full validation
validate --quick                                # Quick essential checks
validate --config                               # Configuration validation
validate --fix                                  # Auto-fix repairable issues"
    
    echo ""
    echo "Validation Modes:"
    echo "  (none)      Full validation (default) - comprehensive checks"
    echo "  --quick     Quick mode - lightweight essential checks only"
    echo "  --config    Configuration mode - deep config validation"
    echo "  --fix       Auto-fix repairable issues (file permissions)"
    echo ""
    echo "Examples:"
    echo "  validate                    # Full project validation"
    echo "  validate --quick            # Quick essential file checks"
    echo "  validate --config           # Deep configuration validation"
    echo "  validate --fix              # Validate and auto-fix permissions"
}

# Parse arguments
fix_mode=false
quick_mode=false
config_mode=false
full_mode=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --fix)
            fix_mode=true
            shift
            ;;
        --quick)
            quick_mode=true
            full_mode=false
            shift
            ;;
        --config)
            config_mode=true
            full_mode=false
            shift
            ;;
        --full)
            full_mode=true
            shift
            ;;
        --help|-h)
            show_usage
            ;;
        *)
            show_error "Unknown Argument" "Unknown argument: $1"
            show_usage
            ;;
    esac
done

# Display header
if [[ "$quick_mode" == true ]]; then
    show_title "🔍 CCPM Quick Validation" 40
elif [[ "$config_mode" == true ]]; then
    show_title "🔍 CCPM Configuration Validation" 40
else
    show_title "🔍 CCPM Full Project Validation" 40
fi

echo ""

# Initialize counters
total_checks=0
passed_checks=0

# Function to increment check counter
check_result() {
    local result="$1"
    ((total_checks++))
    if [[ "$result" == "0" ]]; then
        ((passed_checks++))
        return 0
    else
        return 1
    fi
}

# Essential files check
check_essential_files() {
    show_subtitle "📋 Essential Files Check"
    
    local essential_files=(
        ".claude/CLAUDE.md"
        ".claude/settings.local.json"
        ".claude/lib/core.sh"
        ".claude/lib/ui.sh"
    )
    
    local missing_count=0
    
    for file in "${essential_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            show_error "Missing essential file: $file"
            ((missing_count++))
        fi
    done
    
    if [[ "$missing_count" -eq 0 ]]; then
        show_success "Essential Files" "All essential files present"
        return 0
    else
        show_error "Missing Files" "Missing $missing_count essential files"
        return 1
    fi
}

# Directory structure validation
check_directory_structure() {
    show_subtitle "📁 Directory Structure"
    
    local required_dirs=(
        ".claude"
        ".claude/lib"
        ".claude/scripts"
        ".claude/commands"
        ".claude/config"
        ".claude/agents"
    )
    
    local missing_count=0
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            show_error "Missing directory: $dir"
            ((missing_count++))
        fi
    done
    
    if [[ "$missing_count" -eq 0 ]]; then
        show_success "Directory Structure" "All required directories present"
        return 0
    else
        show_error "Missing Directories" "Missing $missing_count required directories"
        return 1
    fi
}

# JSON configuration validation
check_json_configs() {
    show_subtitle "📋 JSON Configuration"
    
    if ! command -v jq >/dev/null 2>&1; then
        show_warning "jq not available" "Skipping JSON validation"
        return 0
    fi
    
    local json_count=0
    local error_count=0
    
    # Find all JSON files
    while IFS= read -r -d '' json_file; do
        ((json_count++))
        
        if ! jq empty "$json_file" >/dev/null 2>&1; then
            show_error "JSON format error: $(basename "$json_file")"
            ((error_count++))
        fi
    done < <(find .claude -name "*.json" -type f -print0 2>/dev/null)
    
    if [[ "$error_count" -eq 0 ]]; then
        show_success "JSON Validation" "All $json_count JSON files valid"
        return 0
    else
        show_error "JSON Errors" "Found $error_count JSON files with format issues"
        return 1
    fi
}

# Bash script syntax check
check_bash_scripts() {
    show_subtitle "🔧 Bash Script Syntax"
    
    if ! command -v shellcheck >/dev/null 2>&1; then
        show_warning "shellcheck not installed" "Skipping script syntax check"
        show_tip "Install: brew install shellcheck (macOS) or apt install shellcheck (Linux)"
        return 0
    fi
    
    local script_count=0
    local error_count=0
    
    # Find all bash scripts
    while IFS= read -r -d '' script; do
        ((script_count++))
        
        if ! shellcheck "$script" >/dev/null 2>&1; then
            show_error "Syntax issues: $(basename "$script")"
            ((error_count++))
        fi
    done < <(find .claude -name "*.sh" -type f -print0 2>/dev/null)
    
    if [[ "$error_count" -eq 0 ]]; then
        show_success "Script Syntax" "All $script_count scripts passed validation"
        return 0
    else
        show_error "Script Issues" "Found $error_count scripts with syntax issues"
        return 1
    fi
}

# File permissions check
check_file_permissions() {
    local fix_mode="$1"
    
    show_subtitle "🔒 File Permissions"
    
    local fixed_count=0
    local error_count=0
    
    # Check script file permissions
    while IFS= read -r -d '' script; do
        if [[ ! -x "$script" ]]; then
            if [[ "$fix_mode" == true ]]; then
                chmod +x "$script"
                show_info "Fixed permissions: $(basename "$script")"
                ((fixed_count++))
            else
                show_error "Missing execute permission: $(basename "$script")"
                ((error_count++))
            fi
        fi
    done < <(find .claude -name "*.sh" -type f -print0 2>/dev/null)
    
    if [[ "$fix_mode" == true && "$fixed_count" -gt 0 ]]; then
        show_success "Permissions Fixed" "Fixed permissions for $fixed_count files"
        return 0
    elif [[ "$error_count" -eq 0 ]]; then
        show_success "File Permissions" "All script files have correct permissions"
        return 0
    else
        show_error "Permission Issues" "Found $error_count permission issues"
        show_tip "Use --fix to automatically fix permission issues"
        return 1
    fi
}

# Basic command validation
validate_commands() {
    show_subtitle "📟 Command Validation"
    
    local command_dirs=(
        ".claude/commands"
        ".claude/commands/pm"
    )
    
    local missing_dirs=0
    local total_commands=0
    
    for dir in "${command_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            show_error "Missing command directory: $dir"
            ((missing_dirs++))
        else
            local cmd_files
            cmd_files=$(find "$dir" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l)
            total_commands=$((total_commands + cmd_files))
        fi
    done
    
    if [[ "$missing_dirs" -eq 0 ]]; then
        show_success "Command Structure" "Found $total_commands command files"
        return 0
    else
        show_error "Command Directories" "Missing $missing_dirs command directories"
        return 1
    fi
}

# Agent validation
validate_agents() {
    show_subtitle "🤖 Agent Configuration"
    
    local agent_dir=".claude/agents"
    
    if [[ ! -d "$agent_dir" ]]; then
        show_error "Agent directory missing: $agent_dir"
        return 1
    fi
    
    local agent_count
    agent_count=$(find "$agent_dir" -name "*.md" 2>/dev/null | wc -l)
    
    if [[ "$agent_count" -gt 0 ]]; then
        show_success "Agent Configuration" "Found $agent_count agent files"
        return 0
    else
        show_warning "No agent files found in $agent_dir"
        return 1
    fi
}

# Library validation
validate_libraries() {
    show_subtitle "📚 Library Files"
    
    local required_libs=(
        "core.sh"
        "ui.sh"
        "validation.sh"
    )
    
    local missing_count=0
    
    for lib in "${required_libs[@]}"; do
        local lib_file=".claude/lib/$lib"
        if [[ ! -f "$lib_file" ]]; then
            show_error "Missing library: $lib"
            ((missing_count++))
        elif [[ ! -r "$lib_file" ]]; then
            show_warning "Library not readable: $lib"
        fi
    done
    
    if [[ "$missing_count" -eq 0 ]]; then
        show_success "Library Validation" "All ${#required_libs[@]} required libraries present"
        return 0
    else
        show_error "Missing Libraries" "Missing $missing_count required libraries"
        return 1
    fi
}

# Configuration files validation
validate_config_files() {
    show_subtitle "⚙️ Configuration Files"
    
    local error_count=0
    
    # Check settings.local.json
    if [[ -f ".claude/settings.local.json" ]]; then
        if command -v jq >/dev/null 2>&1; then
            if ! jq empty ".claude/settings.local.json" >/dev/null 2>&1; then
                show_error "JSON format error: settings.local.json"
                ((error_count++))
            fi
        fi
    else
        show_error "Missing critical config: settings.local.json"
        ((error_count++))
    fi
    
    # Check config directory files
    if [[ -d ".claude/config" ]]; then
        local config_files
        config_files=$(find ".claude/config" -name "*.json" 2>/dev/null | wc -l)
        show_info "Found $config_files configuration files"
    fi
    
    if [[ "$error_count" -eq 0 ]]; then
        show_success "Configuration Files" "All configuration files valid"
        return 0
    else
        show_error "Configuration Issues" "Found $error_count configuration issues"
        return 1
    fi
}

# Main validation logic
echo ""

if [[ "$quick_mode" == true ]]; then
    # Quick mode: lightweight checks only
    check_result "$(check_essential_files; echo $?)"
    check_result "$(check_directory_structure; echo $?)"
    check_result "$(check_json_configs; echo $?)"
    
elif [[ "$config_mode" == true ]]; then
    # Configuration mode: deep config validation
    check_result "$(check_essential_files; echo $?)"
    check_result "$(validate_libraries; echo $?)"
    check_result "$(validate_commands; echo $?)"
    check_result "$(validate_agents; echo $?)"
    check_result "$(validate_config_files; echo $?)"
    
else
    # Full mode: comprehensive validation
    check_result "$(check_directory_structure; echo $?)"
    check_result "$(check_essential_files; echo $?)"
    check_result "$(check_json_configs; echo $?)"
    check_result "$(check_bash_scripts; echo $?)"
    check_result "$(check_file_permissions "$fix_mode"; echo $?)"
    check_result "$(validate_libraries; echo $?)"
    check_result "$(validate_commands; echo $?)"
fi

# Display results
echo ""
show_subtitle "📊 Validation Results"

if [[ "$passed_checks" -eq "$total_checks" ]]; then
    show_success "All Checks Passed" "$passed_checks/$total_checks"
    show_completion "Project is in good state and ready for use!"
else
    show_warning "Some Checks Failed" "$passed_checks/$total_checks"
    show_info "Recommend fixing the above issues and re-validating"
fi

echo ""

# Show tips based on mode
if [[ "$quick_mode" == true ]]; then
    show_tip "Use 'validate --full' for comprehensive validation or 'validate --config' for deep configuration checks"
elif [[ "$config_mode" == true ]]; then
    show_tip "Use 'validate --full' for complete project validation including scripts and permissions"
else
    show_tip "Use 'validate --fix' to automatically fix permission issues, 'validate --quick' for fast checks"
fi

# Exit with appropriate code
if [[ "$passed_checks" -eq "$total_checks" ]]; then
    exit 0
else
    exit 1
fi