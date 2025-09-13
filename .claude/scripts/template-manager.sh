#!/bin/bash

# CCPM Template Manager v2.0
# Manages PRD, Epic, and Project templates with variable substitution and validation

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
TEMPLATES_DIR=".claude/templates"
TEMPLATES_REGISTRY="$TEMPLATES_DIR/registry.json"

# Function to show usage
show_usage() {
    show_command_help "template-manager" "Manage CCPM document templates" \
        "template-manager [COMMAND] [OPTIONS]        # Manage templates
template-manager list [category]                # List available templates
template-manager generate-prd <name>            # Generate PRD template
template-manager generate-epic <name> <prd>     # Generate Epic template
template-manager generate-claude <name> <type>  # Generate CLAUDE.md
template-manager validate <template-path>       # Validate template"
    
    echo ""
    echo "Commands:"
    echo "  list [category]                     List available templates"
    echo "  generate-prd <name> [template]      Generate PRD from template"
    echo "  generate-epic <name> <prd> [template] Generate Epic from template"
    echo "  generate-claude <name> <type>       Generate CLAUDE.md from template"
    echo "  validate <template-path>            Validate template file"
    echo "  init                                Initialize template system"
    echo "  help                                Show this help message"
    echo ""
    echo "Template Categories:"
    echo "  prd          Product Requirements Documents"
    echo "  epic         Epic breakdowns and task planning"
    echo "  project      Project-specific CLAUDE.md files"
    echo "  task         Individual task templates"
    echo ""
    echo "Examples:"
    echo "  template-manager list                           # List all templates"
    echo "  template-manager list prd                       # List PRD templates"
    echo "  template-manager generate-prd \"User Auth\"       # Generate PRD"
    echo "  template-manager generate-epic \"Auth Epic\" \"User Auth PRD\" # Generate epic"
    echo "  template-manager generate-claude \"MyApp\" \"react\" # Generate React CLAUDE.md"
    echo "  template-manager validate templates/prd/custom.md  # Validate template"
}

# Initialize template system
init_template_system() {
    show_title "🔧 Template System Initialization" 45
    
    # Ensure template directories exist
    local template_categories=("prd" "epic" "project" "task")
    
    show_subtitle "📁 Creating Template Directories"
    ensure_directory "$TEMPLATES_DIR"
    
    for category in "${template_categories[@]}"; do
        ensure_directory "$TEMPLATES_DIR/$category"
        show_info "✓ Created category: $category"
    done
    
    # Create template registry if it doesn't exist
    show_subtitle "📋 Template Registry"
    if [[ ! -f "$TEMPLATES_REGISTRY" ]]; then
        create_template_registry
        show_success "Registry Created" "$TEMPLATES_REGISTRY"
    else
        show_info "Registry already exists"
    fi
    
    show_success "Template System" "Initialization complete"
}

# Create template registry
create_template_registry() {
    cat > "$TEMPLATES_REGISTRY" << 'EOF'
{
  "version": "2.0",
  "created": "{{date}}",
  "template_categories": {
    "prd": {
      "description": "Product Requirements Document templates",
      "templates": [
        {
          "name": "standard-prd",
          "title": "Standard PRD Template",
          "description": "Comprehensive PRD template with all sections",
          "variables": ["product_name", "version", "author", "date"]
        },
        {
          "name": "minimal-prd",
          "title": "Minimal PRD Template",
          "description": "Simplified PRD for quick documentation",
          "variables": ["product_name", "author", "date"]
        }
      ]
    },
    "epic": {
      "description": "Epic breakdown and planning templates",
      "templates": [
        {
          "name": "standard-epic",
          "title": "Standard Epic Template",
          "description": "Comprehensive epic with task breakdown",
          "variables": ["epic_name", "prd_reference", "author", "date"]
        },
        {
          "name": "research-epic",
          "title": "Research Epic Template",
          "description": "Epic template for research and discovery work",
          "variables": ["epic_name", "research_area", "author", "date"]
        }
      ]
    },
    "project": {
      "description": "Project-specific CLAUDE.md templates",
      "templates": [
        {
          "name": "react-project",
          "title": "React Project Template",
          "description": "CLAUDE.md optimized for React development",
          "variables": ["project_name", "project_type", "tech_stack"]
        },
        {
          "name": "python-project",
          "title": "Python Project Template",
          "description": "CLAUDE.md optimized for Python development",
          "variables": ["project_name", "project_type", "tech_stack"]
        },
        {
          "name": "generic-project",
          "title": "Generic Project Template",
          "description": "Universal CLAUDE.md template",
          "variables": ["project_name", "project_type"]
        }
      ]
    },
    "task": {
      "description": "Individual task templates",
      "templates": [
        {
          "name": "feature-task",
          "title": "Feature Implementation Task",
          "description": "Template for feature development tasks",
          "variables": ["task_name", "epic_name", "author", "date"]
        },
        {
          "name": "bugfix-task",
          "title": "Bug Fix Task",
          "description": "Template for bug fix tasks",
          "variables": ["task_name", "bug_description", "author", "date"]
        }
      ]
    }
  }
}
EOF
    
    # Replace {{date}} with current date
    local current_date
    current_date=$(format_timestamp)
    sed -i.bak "s/{{date}}/$current_date/g" "$TEMPLATES_REGISTRY"
    rm -f "$TEMPLATES_REGISTRY.bak"
}

# Template generation function with enhanced variable substitution
generate_from_template() {
    local template_category="$1"
    local template_name="$2"
    local output_path="$3"
    shift 3
    local variables=("$@")
    
    show_subtitle "📝 Template Generation"
    show_info "Category: $template_category"
    show_info "Template: $template_name"
    show_info "Output: $output_path"
    
    # Validate template exists
    local template_file="$TEMPLATES_DIR/$template_category/$template_name.md"
    if [[ ! -f "$template_file" ]]; then
        show_error "Template Missing" "Template not found: $template_file"
        return 1
    fi
    
    # Read template content
    local content
    content=$(cat "$template_file")
    
    # Process custom variables
    local i=0
    while [[ $i -lt ${#variables[@]} ]]; do
        local var_name="${variables[$i]}"
        local var_value="${variables[$((i+1))]}"
        
        # Replace template variables
        content="${content//\{\{$var_name\}\}/$var_value}"
        show_info "✓ Variable: $var_name = $var_value"
        
        i=$((i+2))
    done
    
    # Add standard variables
    local current_date current_user current_timestamp
    current_date=$(date +%Y-%m-%d)
    current_user=$(git config user.name 2>/dev/null || echo "Unknown")
    current_timestamp=$(format_timestamp)
    
    content="${content//\{\{date\}\}/$current_date}"
    content="${content//\{\{timestamp\}\}/$current_timestamp}"
    content="${content//\{\{user\}\}/$current_user}"
    
    # Ensure output directory exists
    ensure_directory "$(dirname "$output_path")"
    
    # Write generated content
    echo "$content" > "$output_path"
    
    show_success "Template Generated" "$output_path"
    return 0
}

# List available templates with enhanced display
list_templates() {
    local category="${1:-}"
    
    show_title "📚 CCPM Template Library" 40
    
    if [[ ! -f "$TEMPLATES_REGISTRY" ]]; then
        show_error "Registry Missing" "Template registry not found"
        show_tip "Run 'template-manager init' to initialize template system"
        return 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        show_error "jq Required" "jq is required for template management"
        return 1
    fi
    
    if [[ -n "$category" ]]; then
        # List templates for specific category
        show_subtitle "📂 Category: $category"
        
        if jq -e ".template_categories.$category" "$TEMPLATES_REGISTRY" >/dev/null 2>&1; then
            jq -r ".template_categories.$category.templates[]? | \"  📄 \\(.name): \\(.title)\\n     \\(.description)\"" "$TEMPLATES_REGISTRY"
        else
            show_warning "Category Not Found" "Template category '$category' does not exist"
        fi
    else
        # List all categories and templates
        show_subtitle "📋 All Template Categories"
        
        local categories
        categories=$(jq -r '.template_categories | keys[]' "$TEMPLATES_REGISTRY" 2>/dev/null)
        
        while IFS= read -r cat; do
            echo ""
            show_info "📂 $cat"
            local description
            description=$(jq -r ".template_categories.$cat.description" "$TEMPLATES_REGISTRY")
            echo "   $description"
            echo ""
            
            jq -r ".template_categories.$cat.templates[]? | \"   📄 \\(.name): \\(.title)\"" "$TEMPLATES_REGISTRY"
        done <<< "$categories"
    fi
    
    echo ""
}

# Generate PRD from template
generate_prd() {
    local prd_name="$1"
    local template_name="${2:-standard-prd}"
    local author="${3:-$(git config user.name 2>/dev/null || echo 'Unknown')}"
    
    show_title "📋 PRD Generation" 40
    
    local output_path=".claude/prds/$prd_name.md"
    local current_date
    current_date=$(date +%Y-%m-%d)
    
    if generate_from_template "prd" "$template_name" "$output_path" \
        "product_name" "$prd_name" \
        "version" "1.0" \
        "author" "$author" \
        "date" "$current_date"; then
        
        show_subtitle "🎯 Next Steps"
        echo "1. Edit the PRD with your specific requirements"
        echo "2. Review with stakeholders and iterate"
        echo "3. Use '/pm:prd-parse $prd_name' to generate epic breakdown"
        echo "4. Add to version control when ready"
    fi
}

# Generate Epic from template
generate_epic() {
    local epic_name="$1"
    local prd_reference="${2:-Unknown}"
    local template_name="${3:-standard-epic}"
    local author="${4:-$(git config user.name 2>/dev/null || echo 'Unknown')}"
    
    show_title "🎯 Epic Generation" 40
    
    # Create epic directory structure
    local epic_dir=".claude/epics/$epic_name"
    local output_path="$epic_dir/epic.md"
    local current_date
    current_date=$(date +%Y-%m-%d)
    
    if generate_from_template "epic" "$template_name" "$output_path" \
        "epic_name" "$epic_name" \
        "prd_reference" "$prd_reference" \
        "author" "$author" \
        "date" "$current_date"; then
        
        # Create additional epic structure
        touch "$epic_dir/.gitkeep"
        
        show_subtitle "🎯 Next Steps"
        echo "1. Break down the epic into specific tasks"
        echo "2. Estimate effort and identify dependencies"
        echo "3. Use '/pm:epic-sync $epic_name' to create GitHub issues"
        echo "4. Start working on tasks with '/pm:issue-start'"
    fi
}

# Generate project CLAUDE.md from template
generate_project_claude() {
    local project_name="$1"
    local project_type="${2:-generic}"
    local tech_stack="${3:-}"
    local testing_framework="${4:-}"
    
    show_title "📄 CLAUDE.md Generation" 40
    
    local template_name="$project_type-project"
    local output_path="CLAUDE.md"
    
    # Check if template exists, fallback to generic
    if [[ ! -f "$TEMPLATES_DIR/project/$template_name.md" ]]; then
        show_warning "Template Fallback" "Template $template_name not found, using generic"
        template_name="generic-project"
    fi
    
    if generate_from_template "project" "$template_name" "$output_path" \
        "project_name" "$project_name" \
        "project_type" "$project_type" \
        "tech_stack" "$tech_stack" \
        "testing_framework" "$testing_framework"; then
        
        show_subtitle "✨ Project Setup Complete"
        echo "CLAUDE.md has been customized for $project_type development"
        echo "Template includes optimized commands and workflows"
        echo ""
        echo "Consider running:"
        echo "  - init-project --type $project_type"
        echo "  - validate --quick"
    fi
}

# Enhanced template validation
validate_template() {
    local template_path="$1"
    
    show_title "🔍 Template Validation" 40
    show_info "Template: $template_path"
    
    if [[ ! -f "$template_path" ]]; then
        show_error "File Missing" "Template file not found: $template_path"
        return 1
    fi
    
    local content issues=() warnings=()
    content=$(cat "$template_path")
    
    show_subtitle "📋 Validation Checks"
    
    # Check for required template metadata
    if ! echo "$content" | grep -q "Template Version\|template.*version"; then
        warnings+=("Missing template version metadata")
    fi
    
    # Check for proper markdown structure
    if ! echo "$content" | grep -q "^# "; then
        issues+=("Missing main heading (# Title)")
    fi
    
    # Extract and analyze template variables
    local variables
    variables=$(echo "$content" | grep -o '{{[^}]*}}' | sort | uniq)
    
    if [[ -n "$variables" ]]; then
        show_info "✓ Template variables found:"
        echo "$variables" | sed 's/^/     /'
        
        # Check for common variable patterns
        if echo "$variables" | grep -q "{{date}}"; then
            show_info "✓ Standard date variable detected"
        fi
        
        if echo "$variables" | grep -q "{{author}}\|{{user}}"; then
            show_info "✓ Author/user variable detected"
        fi
    else
        warnings+=("No template variables found - template may be static")
    fi
    
    # Check for proper section structure
    local section_count
    section_count=$(echo "$content" | grep -c "^## " || echo 0)
    
    if [[ $section_count -gt 0 ]]; then
        show_info "✓ Found $section_count sections"
    else
        warnings+=("No sections (## headings) found")
    fi
    
    # Report validation results
    show_subtitle "📊 Validation Results"
    
    if [[ ${#issues[@]} -eq 0 ]]; then
        show_success "Template Valid" "All critical validation checks passed"
    else
        show_error "Validation Failed" "Found ${#issues[@]} critical issues:"
        for issue in "${issues[@]}"; do
            echo "  ❌ $issue"
        done
    fi
    
    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo ""
        show_warning "Validation Warnings" "Found ${#warnings[@]} potential improvements:"
        for warning in "${warnings[@]}"; do
            echo "  ⚠️  $warning"
        done
    fi
    
    return $([[ ${#issues[@]} -eq 0 ]])
}

# Parse command and execute
COMMAND="${1:-help}"

case "$COMMAND" in
    "init")
        init_template_system
        ;;
    "list")
        list_templates "${2:-}"
        ;;
    "generate-prd")
        if [[ $# -lt 2 ]]; then
            show_error "Missing Arguments" "Usage: template-manager generate-prd <name> [template] [author]"
            exit 1
        fi
        generate_prd "$2" "${3:-standard-prd}" "${4:-}"
        ;;
    "generate-epic")
        if [[ $# -lt 2 ]]; then
            show_error "Missing Arguments" "Usage: template-manager generate-epic <name> [prd_reference] [template] [author]"
            exit 1
        fi
        generate_epic "$2" "${3:-}" "${4:-standard-epic}" "${5:-}"
        ;;
    "generate-claude")
        if [[ $# -lt 3 ]]; then
            show_error "Missing Arguments" "Usage: template-manager generate-claude <project_name> <project_type> [tech_stack] [testing_framework]"
            exit 1
        fi
        generate_project_claude "$2" "$3" "${4:-}" "${5:-}"
        ;;
    "validate")
        if [[ $# -lt 2 ]]; then
            show_error "Missing Arguments" "Usage: template-manager validate <template-path>"
            exit 1
        fi
        validate_template "$2"
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