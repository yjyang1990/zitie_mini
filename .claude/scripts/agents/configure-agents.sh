#!/bin/bash

# CCPM Agent Configuration Script
# Intelligently configures AI agents based on project type and context

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(find_project_root)"
CLAUDE_DIR="$PROJECT_ROOT/.claude"
CONFIG_DIR="$CLAUDE_DIR/config"
AGENTS_DIR="$CLAUDE_DIR/agents"

# Source core functions
if [[ -f "$CLAUDE_DIR/lib/core.sh" ]]; then
    source "$CLAUDE_DIR/lib/core.sh"
fi

if [[ -f "$CLAUDE_DIR/lib/ui.sh" ]]; then
    source "$CLAUDE_DIR/lib/ui.sh"
fi

# =============================================================================
# AGENT CONFIGURATION FUNCTIONS
# =============================================================================

# Configure agents based on project type
configure_agents() {
    local project_type="$1"
    local force="${2:-false}"
    
    show_info "Configuring agents for $project_type project..."
    
    # Load project type configuration
    local project_config_file="$CONFIG_DIR/project-types.json"
    if [[ ! -f "$project_config_file" ]]; then
        show_error "Project Configuration Missing" "Cannot find $project_config_file"
        return 1
    fi
    
    # Get agent configuration for project type
    local agents_config
    agents_config=$(jq -r ".templates.$project_type.agents // .templates.generic.agents" "$project_config_file")
    
    if [[ "$agents_config" == "null" ]]; then
        show_warning "Unknown Project Type" "Using generic agent configuration"
        agents_config=$(jq -r ".templates.generic.agents" "$project_config_file")
    fi
    
    # Update agent registry with project preferences
    update_agent_registry "$project_type" "$agents_config" "$force"
    
    # Configure agent-specific settings
    configure_agent_behaviors "$project_type"
    
    # Generate agent selection matrix
    generate_agent_matrix "$project_type"
    
    show_success "Agent configuration completed for $project_type"
}

# Update agent registry with project-specific preferences
update_agent_registry() {
    local project_type="$1"
    local agents_config="$2"
    local force="$3"
    
    local registry_file="$AGENTS_DIR/registry.json"
    local temp_file=$(mktemp)
    
    show_progress "Updating agent registry..."
    
    # Extract preferred agents
    local primary_agents
    local secondary_agents
    local workflows
    
    primary_agents=$(echo "$agents_config" | jq -r '.primary[]' 2>/dev/null || echo "")
    secondary_agents=$(echo "$agents_config" | jq -r '.secondary[]' 2>/dev/null || echo "")
    workflows=$(echo "$agents_config" | jq -r '.workflows[]' 2>/dev/null || echo "")
    
    # Update registry with project preferences
    jq --arg project_type "$project_type" \
       --argjson primary_agents "$(echo "$agents_config" | jq '.primary // []')" \
       --argjson secondary_agents "$(echo "$agents_config" | jq '.secondary // []')" \
       --argjson workflows "$(echo "$agents_config" | jq '.workflows // []')" \
       '
       .project_preferences = {
         project_type: $project_type,
         primary_agents: $primary_agents,
         secondary_agents: $secondary_agents,
         preferred_workflows: $workflows,
         updated: now
       }
       ' "$registry_file" > "$temp_file"
    
    mv "$temp_file" "$registry_file"
    
    show_success "Agent registry updated"
}

# Configure agent-specific behaviors based on project type
configure_agent_behaviors() {
    local project_type="$1"
    
    show_progress "Configuring agent behaviors..."
    
    # Create project-specific agent configurations
    local agent_config_dir="$CONFIG_DIR/agents"
    mkdir -p "$agent_config_dir"
    
    # Generate configurations for each agent type
    case "$project_type" in
        "react"|"vue"|"angular"|"nextjs")
            configure_frontend_agents
            ;;
        "nodejs"|"django"|"flask"|"golang"|"rust")
            configure_backend_agents
            ;;
        "python")
            configure_python_agents
            ;;
        "docker")
            configure_devops_agents
            ;;
        *)
            configure_generic_agents
            ;;
    esac
}

# Configure frontend-specific agent behaviors
configure_frontend_agents() {
    cat > "$CONFIG_DIR/agents/frontend-engineer.json" << 'EOF'
{
  "name": "frontend-engineer",
  "context": "frontend development",
  "preferences": {
    "component_architecture": "functional_components",
    "state_management": ["hooks", "context", "redux"],
    "testing_approach": "testing-library",
    "styling": ["css-modules", "styled-components", "tailwind"],
    "build_tools": ["vite", "webpack", "parcel"]
  },
  "code_patterns": {
    "prefer_functional": true,
    "use_typescript": true,
    "component_testing": true,
    "performance_optimization": true
  },
  "workflows": {
    "component_development": [
      "design_review",
      "component_implementation", 
      "unit_testing",
      "integration_testing",
      "accessibility_check"
    ]
  }
}
EOF

    cat > "$CONFIG_DIR/agents/ui-expert.json" << 'EOF'
{
  "name": "ui-expert",
  "context": "user interface design and implementation",
  "preferences": {
    "design_system": true,
    "responsive_design": true,
    "accessibility": "WCAG_2.1_AA",
    "performance": "core_web_vitals",
    "browser_support": "modern_browsers"
  },
  "code_patterns": {
    "semantic_html": true,
    "css_methodology": "BEM",
    "mobile_first": true,
    "progressive_enhancement": true
  },
  "workflows": {
    "ui_development": [
      "design_analysis",
      "component_wireframe",
      "responsive_implementation",
      "accessibility_audit",
      "performance_check"
    ]
  }
}
EOF
}

# Configure backend-specific agent behaviors
configure_backend_agents() {
    cat > "$CONFIG_DIR/agents/backend-engineer.json" << 'EOF'
{
  "name": "backend-engineer",
  "context": "server-side development",
  "preferences": {
    "api_design": "RESTful",
    "database": ["postgresql", "mongodb", "redis"],
    "authentication": ["JWT", "OAuth2", "session"],
    "caching": ["redis", "memcached", "in-memory"],
    "monitoring": ["logging", "metrics", "tracing"]
  },
  "code_patterns": {
    "error_handling": "structured",
    "input_validation": "strict",
    "security": "defense_in_depth",
    "testing": "unit_integration_e2e"
  },
  "workflows": {
    "api_development": [
      "specification_design",
      "endpoint_implementation",
      "validation_middleware",
      "error_handling",
      "documentation",
      "testing"
    ]
  }
}
EOF
}

# Configure Python-specific agent behaviors
configure_python_agents() {
    cat > "$CONFIG_DIR/agents/backend-engineer.json" << 'EOF'
{
  "name": "backend-engineer",
  "context": "Python backend development",
  "preferences": {
    "frameworks": ["fastapi", "django", "flask"],
    "orm": ["sqlalchemy", "django-orm", "peewee"],
    "async": "asyncio",
    "packaging": "poetry",
    "linting": ["ruff", "mypy", "black"]
  },
  "code_patterns": {
    "type_hints": true,
    "pep8_compliance": true,
    "error_handling": "exceptions",
    "testing": "pytest"
  },
  "workflows": {
    "python_development": [
      "virtual_environment",
      "dependency_management",
      "code_implementation",
      "type_checking",
      "linting",
      "testing"
    ]
  }
}
EOF

    cat > "$CONFIG_DIR/agents/test-engineer.json" << 'EOF'
{
  "name": "test-engineer", 
  "context": "Python testing",
  "preferences": {
    "framework": "pytest",
    "coverage": "pytest-cov",
    "fixtures": "pytest-fixtures",
    "mocking": "unittest.mock",
    "property_testing": "hypothesis"
  },
  "code_patterns": {
    "test_structure": "AAA",
    "test_naming": "descriptive",
    "parameterized_tests": true,
    "integration_tests": true
  }
}
EOF
}

# Configure DevOps-specific agent behaviors
configure_devops_agents() {
    cat > "$CONFIG_DIR/agents/devops-engineer.json" << 'EOF'
{
  "name": "devops-engineer",
  "context": "DevOps and infrastructure",
  "preferences": {
    "containerization": "docker", 
    "orchestration": ["kubernetes", "docker-compose"],
    "ci_cd": ["github-actions", "gitlab-ci", "jenkins"],
    "infrastructure": ["terraform", "ansible", "cloudformation"],
    "monitoring": ["prometheus", "grafana", "elk"]
  },
  "code_patterns": {
    "infrastructure_as_code": true,
    "immutable_infrastructure": true,
    "security_scanning": true,
    "automated_testing": true
  },
  "workflows": {
    "deployment": [
      "build_optimization",
      "security_scanning", 
      "infrastructure_provisioning",
      "deployment_automation",
      "monitoring_setup",
      "rollback_strategy"
    ]
  }
}
EOF
}

# Configure generic agent behaviors
configure_generic_agents() {
    cat > "$CONFIG_DIR/agents/code-analyzer.json" << 'EOF'
{
  "name": "code-analyzer",
  "context": "general code analysis",
  "preferences": {
    "analysis_depth": "comprehensive",
    "pattern_detection": true,
    "security_analysis": true,
    "performance_analysis": true,
    "maintainability": true
  },
  "workflows": {
    "code_review": [
      "syntax_analysis",
      "pattern_detection",
      "security_scan",
      "performance_check",
      "maintainability_assessment"
    ]
  }
}
EOF
}

# Generate agent selection matrix
generate_agent_matrix() {
    local project_type="$1"
    
    show_progress "Generating agent selection matrix..."
    
    cat > "$CONFIG_DIR/agent-matrix.json" << EOF
{
  "project_type": "$project_type",
  "generated": "$(date -Iseconds)",
  "selection_matrix": {
    "simple_tasks": {
      "description": "Single file edits, basic operations",
      "recommended_approach": "direct_interaction",
      "fallback_agents": ["code-analyzer"]
    },
    "complex_analysis": {
      "description": "Multi-file analysis, architecture review",
      "primary_agents": ["system-architect", "code-analyzer"],
      "workflows": ["architecture_review", "code_review"]
    },
    "feature_development": {
      "description": "New feature implementation",
      "primary_agents": $(get_primary_agents_for_project "$project_type"),
      "workflows": ["feature_development"]
    },
    "bug_fixing": {
      "description": "Bug investigation and resolution",
      "primary_agents": ["code-analyzer", "test-runner"],
      "workflows": ["bug_fix"]
    },
    "testing": {
      "description": "Test implementation and execution",
      "primary_agents": ["test-runner", "test-engineer"],
      "workflows": ["testing", "quality_assurance"]
    }
  },
  "escalation_rules": {
    "complexity_threshold": 3,
    "multi_agent_coordination": true,
    "fallback_to_orchestrator": true
  }
}
EOF
}

# Get primary agents for project type
get_primary_agents_for_project() {
    local project_type="$1"
    local project_config_file="$CONFIG_DIR/project-types.json"
    
    jq -c ".templates.$project_type.agents.primary // .templates.generic.agents.primary" "$project_config_file"
}

# =============================================================================
# VALIDATION AND TESTING
# =============================================================================

# Validate agent configuration
validate_agent_config() {
    show_progress "Validating agent configuration..."
    
    local validation_errors=()
    
    # Check required files
    local required_files=(
        "$AGENTS_DIR/registry.json"
        "$CONFIG_DIR/project.json"
        "$CONFIG_DIR/agent-matrix.json"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            validation_errors+=("Missing file: $file")
        fi
    done
    
    # Validate JSON syntax
    for json_file in "$CONFIG_DIR"/*.json "$AGENTS_DIR"/*.json; do
        if [[ -f "$json_file" ]] && ! jq . "$json_file" >/dev/null 2>&1; then
            validation_errors+=("Invalid JSON syntax: $json_file")
        fi
    done
    
    # Report validation results
    if [[ ${#validation_errors[@]} -gt 0 ]]; then
        show_error "Validation Failed" "$(printf '%s\n' "${validation_errors[@]}")"
        return 1
    else
        show_success "Agent configuration validation passed"
        return 0
    fi
}

# Test agent selection
test_agent_selection() {
    show_progress "Testing agent selection logic..."
    
    local test_scenarios=(
        "simple:file edit"
        "complex:architecture review"
        "feature:new user authentication"
        "bug:memory leak investigation"
        "test:unit test coverage"
    )
    
    for scenario in "${test_scenarios[@]}"; do
        local scenario_type="${scenario%%:*}"
        local scenario_desc="${scenario#*:}"
        
        echo "  Testing scenario: $scenario_type ($scenario_desc)"
        
        # This would integrate with actual agent selection logic
        local selected_agents
        selected_agents=$(jq -r ".selection_matrix.$scenario_type.primary_agents[]? // .selection_matrix.$scenario_type.fallback_agents[]?" "$CONFIG_DIR/agent-matrix.json" 2>/dev/null || echo "code-analyzer")
        
        echo "    Selected agents: $selected_agents"
    done
    
    show_success "Agent selection testing completed"
}

# =============================================================================
# MAIN FUNCTIONS
# =============================================================================

show_help() {
    cat << EOF
CCPM Agent Configuration Tool

Configure AI agents intelligently based on project type and requirements.

Usage: $0 [options] [project_type]

Arguments:
  project_type    Project type (react, python, golang, etc.)
                 If not provided, will auto-detect

Options:
  --force         Force reconfiguration even if already configured
  --validate      Validate existing configuration
  --test          Test agent selection logic
  --list-types    List supported project types
  -h, --help      Show this help

Examples:
  $0                      # Auto-detect and configure
  $0 react               # Configure for React project
  $0 --force python      # Force reconfigure for Python
  $0 --validate          # Validate current configuration

EOF
}

# List supported project types
list_project_types() {
    local project_config_file="$CONFIG_DIR/project-types.json"
    
    if [[ ! -f "$project_config_file" ]]; then
        show_error "Configuration Missing" "Cannot find project types configuration"
        return 1
    fi
    
    echo "Supported Project Types:"
    jq -r '.templates | keys[]' "$project_config_file" | while read -r type; do
        local description
        description=$(jq -r ".templates.$type.description" "$project_config_file")
        printf "  %-12s %s\n" "$type" "$description"
    done
}

# Auto-detect project type
auto_detect_project_type() {
    # This would use the detection logic from bootstrap.sh
    # For now, return generic as fallback
    if [[ -f "$CONFIG_DIR/project.json" ]]; then
        jq -r '.project.type // "generic"' "$CONFIG_DIR/project.json"
    else
        echo "generic"
    fi
}

# Main function
main() {
    local project_type=""
    local force="false"
    local validate_only="false"
    local test_only="false"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force="true"
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
            --list-types)
                list_project_types
                exit 0
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
        validate_agent_config
        exit $?
    fi
    
    # Test mode
    if [[ "$test_only" == "true" ]]; then
        test_agent_selection
        exit $?
    fi
    
    # Auto-detect project type if not provided
    if [[ -z "$project_type" ]]; then
        project_type=$(auto_detect_project_type)
        show_info "Auto-detected project type: $project_type"
    fi
    
    # Configure agents
    show_title "CCPM Agent Configuration" 50
    
    if configure_agents "$project_type" "$force"; then
        echo ""
        validate_agent_config
        echo ""
        show_completion "Agent configuration completed successfully!"
        show_next_steps "
        /help agents           # View available agents
        /validate --quick     # Validate setup
        /pm:init             # Initialize project management"
    else
        show_error "Configuration Failed" "Agent configuration was not completed successfully"
        exit 1
    fi
}

# Entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi