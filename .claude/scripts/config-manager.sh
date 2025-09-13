#!/bin/bash

# CCPM Configuration Manager v2.0
# Central configuration management system with validation, merging, and project customization

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

# Configuration paths
CONFIG_DIR=".claude/config"
AGENTS_FILE=".claude/agents/registry.json"
COMMANDS_FILE=".claude/commands/index.json"
WORKFLOWS_FILE=".claude/config/workflows.json"
PROJECT_TYPES_FILE=".claude/config/project-types.json"
PROJECT_CONFIG_FILE=".claude/config/project.json"

# Function to show usage
show_usage() {
    show_command_help "config-manager" "Central configuration management system" \
        "config-manager <command> [options]          # Manage CCPM configurations
config-manager validate agents                  # Validate agent configuration
config-manager load project                     # Load project configuration
config-manager generate react MyApp            # Generate React project config
config-manager get project .project.type       # Get specific value
config-manager list agents core                # List core agents"
    
    echo ""
    echo "Commands:"
    echo "  validate <type>                     Validate configuration type"
    echo "  load <type>                         Load and display configuration"
    echo "  generate <project_type> [name]      Generate project configuration"
    echo "  merge <base> <override> [strategy]  Merge two configurations"
    echo "  get <type> <query> [default]        Get specific configuration value"
    echo "  list agents [category]              List available agents"
    echo "  list workflows                      List available workflows"
    echo "  list project-types                  List available project types"
    echo "  help                                Show this help message"
    echo ""
    echo "Configuration Types:"
    echo "  agents          Agent registry and selection rules"
    echo "  commands        Custom command definitions"
    echo "  workflows       Development workflow definitions"
    echo "  project-types   Project type templates"
    echo "  project         Current project configuration"
    echo ""
    echo "Merge Strategies:"
    echo "  merge           Deep merge (default)"
    echo "  override        Override with new values"
    echo "  base_only       Keep base configuration only"
    echo ""
    echo "Examples:"
    echo "  config-manager validate agents                # Validate agent config"
    echo "  config-manager generate react MyApp           # Generate React config"
    echo "  config-manager get project .project.type      # Get project type"
    echo "  config-manager list agents testing            # List testing agents"
    echo "  config-manager merge '{\"a\":1}' '{\"b\":2}'     # JSON merge example"
}

# Load configuration with error handling
load_config() {
    local config_type="$1"
    local config_file
    
    case "$config_type" in
        "agents")
            config_file="$AGENTS_FILE"
            ;;
        "commands") 
            config_file="$COMMANDS_FILE"
            ;;
        "workflows")
            config_file="$WORKFLOWS_FILE"
            ;;
        "project-types")
            config_file="$PROJECT_TYPES_FILE"
            ;;
        "project")
            config_file="$PROJECT_CONFIG_FILE"
            ;;
        *)
            config_file="$CONFIG_DIR/$config_type.json"
            ;;
    esac
    
    if [[ ! -f "$config_file" ]]; then
        show_error "Config Missing" "Configuration file not found: $config_file"
        return 1
    fi
    
    if ! is_valid_json "$config_file"; then
        show_error "Invalid JSON" "Configuration file contains invalid JSON: $config_file"
        return 1
    fi
    
    cat "$config_file"
}

# Enhanced configuration validation
validate_config() {
    local config_type="$1"
    local config_data="${2:-}"
    
    show_subtitle "🔍 Validating $config_type Configuration"
    
    # Load config data if not provided
    if [[ -z "$config_data" ]]; then
        if ! config_data=$(load_config "$config_type"); then
            return 1
        fi
    fi
    
    case "$config_type" in
        "agents")
            validate_agents_config "$config_data"
            ;;
        "commands")
            validate_commands_config "$config_data"
            ;;
        "workflows")
            validate_workflows_config "$config_data"
            ;;
        "project")
            validate_project_config "$config_data"
            ;;
        *)
            validate_generic_config "$config_data"
            ;;
    esac
}

# Validate agents configuration
validate_agents_config() {
    local config_data="$1"
    local errors=() warnings=()
    
    show_info "Checking agents configuration structure..."
    
    # Check required sections
    if ! echo "$config_data" | jq -e '.agents' >/dev/null 2>&1; then
        errors+=("Missing 'agents' section")
    else
        show_info "✓ Found agents section"
    fi
    
    if ! echo "$config_data" | jq -e '.selection_rules' >/dev/null 2>&1; then
        warnings+=("Missing 'selection_rules' section")
    else
        show_info "✓ Found selection rules"
    fi
    
    # Validate each agent
    if echo "$config_data" | jq -e '.agents' >/dev/null 2>&1; then
        local agent_count=0
        local agents
        agents=$(echo "$config_data" | jq -r '.agents | keys[]' 2>/dev/null)
        
        while IFS= read -r agent; do
            [[ -z "$agent" ]] && continue
            ((agent_count++))
            
            local agent_config
            agent_config=$(echo "$config_data" | jq ".agents[\"$agent\"]")
            
            if ! echo "$agent_config" | jq -e '.category' >/dev/null 2>&1; then
                errors+=("Agent '$agent' missing 'category'")
            fi
            
            if ! echo "$agent_config" | jq -e '.file_path' >/dev/null 2>&1; then
                errors+=("Agent '$agent' missing 'file_path'") 
            fi
        done <<< "$agents"
        
        show_info "✓ Validated $agent_count agents"
    fi
    
    # Report results
    if [[ ${#errors[@]} -eq 0 ]]; then
        show_success "Agents Validation" "All checks passed"
        if [[ ${#warnings[@]} -gt 0 ]]; then
            show_warning "Minor Issues" "${#warnings[@]} warnings found"
            for warning in "${warnings[@]}"; do
                echo "  ⚠️  $warning"
            done
        fi
        return 0
    else
        show_error "Validation Failed" "Found ${#errors[@]} critical issues:"
        for error in "${errors[@]}"; do
            echo "  ❌ $error"
        done
        return 1
    fi
}

# Validate commands configuration
validate_commands_config() {
    local config_data="$1"
    local errors=() warnings=()
    
    show_info "Checking commands configuration structure..."
    
    # Check required structure
    if ! echo "$config_data" | jq -e '.categories' >/dev/null 2>&1; then
        errors+=("Missing 'categories' section")
    else
        show_info "✓ Found categories section"
        
        # Validate categories
        local category_count=0
        local categories
        categories=$(echo "$config_data" | jq -r '.categories | keys[]' 2>/dev/null)
        
        while IFS= read -r category; do
            [[ -z "$category" ]] && continue
            ((category_count++))
            
            local category_config
            category_config=$(echo "$config_data" | jq ".categories[\"$category\"]")
            
            if ! echo "$category_config" | jq -e '.commands' >/dev/null 2>&1; then
                errors+=("Category '$category' missing 'commands' array")
            fi
        done <<< "$categories"
        
        show_info "✓ Validated $category_count command categories"
    fi
    
    # Report results
    if [[ ${#errors[@]} -eq 0 ]]; then
        show_success "Commands Validation" "All checks passed"
        return 0
    else
        show_error "Validation Failed" "Found ${#errors[@]} issues:"
        for error in "${errors[@]}"; do
            echo "  ❌ $error"
        done
        return 1
    fi
}

# Validate workflows configuration
validate_workflows_config() {
    local config_data="$1"
    local errors=()
    
    show_info "Checking workflows configuration structure..."
    
    # Check required structure
    if ! echo "$config_data" | jq -e '.workflows' >/dev/null 2>&1; then
        errors+=("Missing 'workflows' section")
    else
        show_info "✓ Found workflows section"
        
        # Validate workflows
        local workflow_count=0
        local workflows
        workflows=$(echo "$config_data" | jq -r '.workflows | keys[]' 2>/dev/null)
        
        while IFS= read -r workflow; do
            [[ -z "$workflow" ]] && continue
            ((workflow_count++))
            
            local workflow_config
            workflow_config=$(echo "$config_data" | jq ".workflows[\"$workflow\"]")
            
            if ! echo "$workflow_config" | jq -e '.steps' >/dev/null 2>&1; then
                errors+=("Workflow '$workflow' missing 'steps' array")
            fi
            
            if ! echo "$workflow_config" | jq -e '.success_criteria' >/dev/null 2>&1; then
                errors+=("Workflow '$workflow' missing 'success_criteria'")
            fi
        done <<< "$workflows"
        
        show_info "✓ Validated $workflow_count workflows"
    fi
    
    # Report results
    if [[ ${#errors[@]} -eq 0 ]]; then
        show_success "Workflows Validation" "All checks passed"
        return 0
    else
        show_error "Validation Failed" "Found ${#errors[@]} issues:"
        for error in "${errors[@]}"; do
            echo "  ❌ $error"
        done
        return 1
    fi
}

# Validate project configuration
validate_project_config() {
    local config_data="$1"
    local errors=() warnings=()
    
    show_info "Checking project configuration structure..."
    
    # Check required fields
    if ! echo "$config_data" | jq -e '.project.type' >/dev/null 2>&1; then
        errors+=("Missing project type")
    else
        local project_type
        project_type=$(echo "$config_data" | jq -r '.project.type')
        show_info "✓ Project type: $project_type"
    fi
    
    if ! echo "$config_data" | jq -e '.project.name' >/dev/null 2>&1; then
        errors+=("Missing project name")
    else
        local project_name
        project_name=$(echo "$config_data" | jq -r '.project.name')
        show_info "✓ Project name: $project_name"
    fi
    
    if ! echo "$config_data" | jq -e '.project.ccmp_version' >/dev/null 2>&1; then
        warnings+=("Missing CCPM version information")
    else
        local version
        version=$(echo "$config_data" | jq -r '.project.ccmp_version')
        show_info "✓ CCPM version: $version"
    fi
    
    # Report results
    if [[ ${#errors[@]} -eq 0 ]]; then
        show_success "Project Validation" "All checks passed"
        if [[ ${#warnings[@]} -gt 0 ]]; then
            show_warning "Minor Issues" "${#warnings[@]} warnings found"
            for warning in "${warnings[@]}"; do
                echo "  ⚠️  $warning"
            done
        fi
        return 0
    else
        show_error "Validation Failed" "Found ${#errors[@]} critical issues:"
        for error in "${errors[@]}"; do
            echo "  ❌ $error"
        done
        return 1
    fi
}

# Validate generic configuration
validate_generic_config() {
    local config_data="$1"
    
    show_info "Checking JSON format..."
    
    if ! echo "$config_data" | jq empty 2>/dev/null; then
        show_error "Invalid JSON" "Configuration contains invalid JSON format"
        return 1
    fi
    
    show_success "Generic Validation" "Valid JSON format"
    return 0
}

# Configuration merging with strategy support
merge_configs() {
    local base_config="$1"
    local override_config="$2"
    local strategy="${3:-merge}"
    
    show_subtitle "🔄 Configuration Merge"
    show_info "Strategy: $strategy"
    
    case "$strategy" in
        "merge")
            show_info "Performing deep merge..."
            jq -s '.[0] * .[1]' <<< "$base_config $override_config"
            ;;
        "override")
            show_info "Using override configuration..."
            echo "$override_config"
            ;;
        "base_only")
            show_info "Using base configuration only..."
            echo "$base_config"
            ;;
        *)
            show_error "Unknown Strategy" "Unknown merge strategy: $strategy"
            return 1
            ;;
    esac
}

# Generate project configuration with enhanced templates
generate_project_config() {
    local project_type="$1"
    local project_name="${2:-$(basename "$PWD")}"
    
    show_title "📋 Project Configuration Generation" 45
    show_info "Project Type: $project_type"
    show_info "Project Name: $project_name"
    
    # Load project type template
    local template_config
    if [[ -f "$PROJECT_TYPES_FILE" ]]; then
        if template_config=$(load_config "project-types" | jq ".templates[\"$project_type\"]"); then
            if [[ "$template_config" == "null" ]]; then
                show_warning "Template Missing" "Project type '$project_type' not found, using generic template"
                template_config=$(load_config "project-types" | jq ".templates.generic" 2>/dev/null || echo '{}')
            else
                show_info "✓ Found template for $project_type"
            fi
        else
            show_warning "Template Error" "Could not load project types, using default template"
            template_config='{}'
        fi
    else
        show_warning "Config Missing" "Project types file not found, using default template"
        template_config='{}'
    fi
    
    # Generate base project config
    local timestamp
    timestamp=$(format_timestamp)
    
    local project_config
    project_config=$(cat << EOF
{
  "project": {
    "type": "$project_type",
    "name": "$project_name", 
    "initialized": "$timestamp",
    "ccmp_version": "2.0"
  },
  "agents": $(echo "$template_config" | jq '.agents // {}'),
  "testing": $(echo "$template_config" | jq '.testing // {}'),
  "tools": $(echo "$template_config" | jq '.tools // {}')
}
EOF
    )
    
    # Ensure configuration directory exists
    ensure_directory "$CONFIG_DIR"
    
    # Save configuration
    echo "$project_config" > "$PROJECT_CONFIG_FILE"
    
    show_success "Configuration Generated" "$PROJECT_CONFIG_FILE"
    
    # Validate generated configuration
    if validate_config "project" "$project_config"; then
        show_success "Validation" "Generated configuration is valid"
    else
        show_warning "Validation" "Generated configuration has issues"
    fi
}

# Get specific configuration value with query support
get_config_value() {
    local config_type="$1"
    local query="$2"
    local default_value="${3:-null}"
    
    local config_data
    if config_data=$(load_config "$config_type" 2>/dev/null); then
        local result
        result=$(echo "$config_data" | jq -r "$query // \"$default_value\"" 2>/dev/null)
        echo "$result"
    else
        echo "$default_value"
    fi
}

# List available agents with category filtering
list_available_agents() {
    local category="${1:-all}"
    
    show_subtitle "🤖 Available Agents"
    
    local config_data
    if ! config_data=$(load_config "agents" 2>/dev/null); then
        show_error "Config Missing" "Could not load agents configuration"
        return 1
    fi
    
    if [[ "$category" == "all" ]]; then
        show_info "All agents:"
        echo "$config_data" | jq -r '.agents | keys[]' | sort
    else
        show_info "Agents in category: $category"
        echo "$config_data" | jq -r ".agents | to_entries[] | select(.value.category == \"$category\") | .key" | sort
    fi
}

# List available workflows
list_available_workflows() {
    show_subtitle "🔄 Available Workflows"
    
    local config_data
    if ! config_data=$(load_config "workflows" 2>/dev/null); then
        show_error "Config Missing" "Could not load workflows configuration"
        return 1
    fi
    
    echo "$config_data" | jq -r '.workflows | keys[]' | sort
}

# Get preferred agents for current project
get_preferred_agents() {
    local project_type
    project_type=$(get_config_value "project" ".project.type" "generic")
    
    show_info "Preferred agents for $project_type project:"
    get_config_value "project" ".agents.primary[]" | tr -d '"'
}

# Main execution function
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        return 1
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        "validate")
            if [[ $# -eq 0 ]]; then
                show_error "Missing Arguments" "Usage: validate <config_type>"
                return 1
            fi
            validate_config "$1"
            ;;
        "load")
            if [[ $# -eq 0 ]]; then
                show_error "Missing Arguments" "Usage: load <config_type>"
                return 1
            fi
            load_config "$1"
            ;;
        "generate")
            if [[ $# -eq 0 ]]; then
                show_error "Missing Arguments" "Usage: generate <project_type> [project_name]"
                return 1
            fi
            generate_project_config "$1" "${2:-}"
            ;;
        "merge")
            if [[ $# -lt 2 ]]; then
                show_error "Missing Arguments" "Usage: merge <base_config> <override_config> [strategy]"
                return 1
            fi
            merge_configs "$1" "$2" "${3:-merge}"
            ;;
        "get")
            if [[ $# -lt 2 ]]; then
                show_error "Missing Arguments" "Usage: get <config_type> <query> [default]"
                return 1
            fi
            get_config_value "$1" "$2" "${3:-}"
            ;;
        "list")
            case "${1:-}" in
                "agents")
                    list_available_agents "${2:-all}"
                    ;;
                "workflows") 
                    list_available_workflows
                    ;;
                "project-types")
                    show_subtitle "📋 Available Project Types"
                    local config_data
                    if config_data=$(load_config "project-types" 2>/dev/null); then
                        echo "$config_data" | jq -r '.templates | keys[]' | sort
                    else
                        show_error "Config Missing" "Could not load project types configuration"
                    fi
                    ;;
                *)
                    show_error "Missing Arguments" "Usage: list {agents|workflows|project-types}"
                    return 1
                    ;;
            esac
            ;;
        "--help"|"-h"|"help")
            show_usage
            ;;
        *)
            show_error "Unknown Command" "Unknown command: $command"
            show_usage
            return 1
            ;;
    esac
}

# Only run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi