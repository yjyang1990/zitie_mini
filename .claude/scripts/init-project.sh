#!/bin/bash

# CCPM Project Initialization Script v2.0
# Customizes CCPM framework for specific project types and best practices

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

if [[ -f "$LIB_DIR/project-detection.sh" ]]; then
    source "$LIB_DIR/project-detection.sh"
fi

# Function to show usage
show_usage() {
    show_command_help "init-project" "Initialize CCPM for specific project types" \
        "init-project [OPTIONS]                      # Initialize project
init-project --type react                      # Force React project type
init-project --minimal                         # Minimal setup
init-project --skip-git                        # Skip git initialization"
    
    echo ""
    echo "Options:"
    echo "  --type <type>       Force specific project type detection"
    echo "  --skip-git          Skip git repository initialization"
    echo "  --minimal           Minimal setup (no project-specific customization)"
    echo "  --help              Show this help message"
    echo ""
    echo "Supported Project Types:"
    echo "  Frontend: react, vue, angular, nextjs, nodejs"
    echo "  Backend: python, django, python-api"
    echo "  Systems: rust, golang, java, php, ruby, rails"
    echo "  Generic: generic-git, generic"
    echo ""
    echo "This script customizes CCPM for your specific project type,"
    echo "updating CLAUDE.md with appropriate commands and guidelines."
}

# Initialize CCPM for a new project
init_ccpm_project() {
    local project_type="$1"
    local skip_git="$2"
    local minimal="$3"
    
    show_title "🚀 CCPM Project Initialization" 50
    show_info "Project Type: $project_type"
    show_info "Minimal Setup: $minimal"
    show_info "Skip Git: $skip_git"
    echo ""
    
    # Detect project environment
    local project_root="$(pwd)"
    local project_name="$(basename "$project_root")"
    
    show_subtitle "📁 Project Environment"
    show_info "Project Root: $project_root"
    show_info "Project Name: $project_name"
    
    # Initialize git repository if needed
    if [[ "$skip_git" != "true" ]] && [[ ! -d ".git" ]]; then
        show_subtitle "📦 Git Repository Setup"
        show_progress "Initializing git repository..."
        
        git init
        git add .claude/
        git commit -m "Add CCPM framework v2.0

Framework provides:
- Project management commands (/pm:*)
- Specialized AI agents
- Testing and validation tools
- Git hooks and automation

🤖 Generated with Claude Code (https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
        
        show_success "Git Repository" "Initialized with CCPM framework"
    elif [[ -d ".git" ]]; then
        show_success "Git Repository" "Already exists"
    else
        show_info "Git initialization skipped"
    fi
    
    # Create essential directories
    show_subtitle "📂 Directory Structure"
    local essential_dirs=(
        ".claude/epics"
        ".claude/prds"
        ".claude/context"
        ".claude/logs"
        ".claude/tmp"
    )
    
    for dir in "${essential_dirs[@]}"; do
        ensure_directory "$dir"
        
        # Create .gitkeep files for empty directories
        if [[ ! -f "$dir/.gitkeep" ]]; then
            touch "$dir/.gitkeep"
        fi
    done
    
    show_success "Directory Structure" "Essential directories created"
    
    # Skip detailed customization if minimal setup
    if [[ "$minimal" == "true" ]]; then
        show_success "Minimal Setup" "CCPM basic framework ready"
        return 0
    fi
    
    # Get project-specific configurations
    show_subtitle "⚙️ Project-Specific Configuration"
    local recommended_agents project_commands code_style
    
    recommended_agents=$(get_recommended_agents "$project_type")
    project_commands=$(get_project_commands "$project_type")
    code_style=$(get_project_code_style "$project_type")
    
    # Update CLAUDE.md with project-specific content
    update_claude_md "$project_type" "$project_name" "$project_commands" "$code_style"
    
    # Create/update project-specific .gitignore
    create_project_gitignore "$project_type"
    
    # Initialize cache system
    show_subtitle "🗄️ Cache System Initialization"
    if [[ -f ".claude/scripts/cache-manager.sh" ]]; then
        bash .claude/scripts/cache-manager.sh init >/dev/null 2>&1 || true
        show_success "Cache System" "Initialized for project optimization"
    fi
    
    # Show completion and next steps
    show_completion_summary "$project_type" "$recommended_agents"
    
    show_success "CCPM Initialization" "Complete for $project_type project!"
}

# Update CLAUDE.md with project-specific content
update_claude_md() {
    local project_type="$1"
    local project_name="$2" 
    local project_commands="$3"
    local code_style="$4"
    
    show_progress "Updating CLAUDE.md with project-specific content..."
    
    # Create backup of original CLAUDE.md
    cp .claude/CLAUDE.md .claude/CLAUDE.md.backup
    
    # Create temporary file for new content
    local temp_file
    temp_file=$(mktemp)
    
    # Add project-specific section to CLAUDE.md
    cat .claude/CLAUDE.md > "$temp_file"
    
    cat >> "$temp_file" << EOF

## PROJECT-SPECIFIC CONFIGURATION

### Project: $project_name ($project_type)
**Initialized**: $(format_timestamp)  
**CCPM Version**: 2.0

### Project Commands
$project_commands

### Code Style Guidelines
$code_style

### Development Workflow for $project_type
1. **Planning**: Use \`/pm:prd-new <feature>\` to create structured requirements
2. **Development**: Break work into epics with \`/pm:epic-show <epic>\`
3. **Testing**: Run project-specific tests before committing
4. **Quality**: Ensure code passes linting and formatting checks
5. **Integration**: Use \`/pm:sync\` to sync with GitHub issues

### Recommended AI Agents
$(get_recommended_agents "$project_type")

### Testing Strategy for $project_type
- Always run tests before committing changes
- Ensure code passes all linting and formatting checks
- Test both happy path and edge cases thoroughly
- Write tests for all new functionality
- Use project-specific testing tools and frameworks

---
*Project configuration generated by CCPM v2.0*

EOF
    
    # Replace original file
    mv "$temp_file" .claude/CLAUDE.md
    
    show_success "CLAUDE.md" "Updated with $project_type-specific configuration"
}

# Create/update project-specific .gitignore
create_project_gitignore() {
    local project_type="$1"
    
    show_progress "Configuring .gitignore for CCPM and $project_type..."
    
    # Create .gitignore if it doesn't exist
    if [[ ! -f ".gitignore" ]]; then
        touch .gitignore
    fi
    
    # Add CCPM-specific ignores if not already present
    if ! grep -q "# CCPM Framework" .gitignore; then
        cat >> .gitignore << 'EOF'

# CCPM Framework
.claude/tmp/
.claude/logs/
.claude/epics/*
!.claude/epics/.gitkeep
.claude/prds/*
!.claude/prds/.gitkeep
.claude/context/project-overview.md
.claude/context/session-context.md

EOF
    fi
    
    # Add project-type specific ignores
    case "$project_type" in
        "react"|"vue"|"angular"|"nextjs"|"nodejs")
            if ! grep -q "# Node.js" .gitignore; then
                cat >> .gitignore << 'EOF'
# Node.js
node_modules/
.npm
.eslintcache
*.tgz
*.log

EOF
            fi
            ;;
        "python"|"django"|"python-api")
            if ! grep -q "# Python" .gitignore; then
                cat >> .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
.pytest_cache/
.coverage
*.egg-info/
venv/
env/

EOF
            fi
            ;;
        "rust")
            if ! grep -q "# Rust" .gitignore; then
                cat >> .gitignore << 'EOF'
# Rust
target/
**/*.rs.bk
Cargo.lock

EOF
            fi
            ;;
    esac
    
    show_success ".gitignore" "Updated with CCPM and $project_type exclusions"
}

# Show completion summary and next steps
show_completion_summary() {
    local project_type="$1"
    local recommended_agents="$2"
    
    echo ""
    show_title "🎯 Next Steps" 40
    
    show_subtitle "🔧 Environment Setup"
    echo "1. Set required environment variables:"
    echo "   export GITHUB_TOKEN=\"your_personal_access_token\""
    echo ""
    
    case "$project_type" in
        "react"|"vue"|"angular"|"nextjs"|"nodejs")
            echo "2. Install project dependencies:"
            echo "   npm install  # or yarn install"
            echo ""
            echo "3. Start development workflow:"
            echo "   /pm:prd-new my-feature       # Create feature requirements"
            echo "   npm run dev                  # Start development server"
            ;;
        "python"|"django"|"python-api")  
            echo "2. Set up Python environment:"
            echo "   python -m venv venv"
            echo "   source venv/bin/activate     # or venv\\Scripts\\activate on Windows"
            echo "   pip install -r requirements.txt"
            echo ""
            echo "3. Start development workflow:"
            echo "   /pm:prd-new my-feature       # Create feature requirements"
            if [[ "$project_type" == "django" ]]; then
                echo "   python manage.py runserver   # Start Django server"
            fi
            ;;
        "rust")
            echo "2. Verify Rust installation:"
            echo "   cargo --version"
            echo ""
            echo "3. Start development workflow:"
            echo "   /pm:prd-new my-feature       # Create feature requirements"
            echo "   cargo run                    # Build and run project"
            ;;
        *)
            echo "2. Start development workflow:"
            echo "   /pm:prd-new my-feature       # Create feature requirements"
            ;;
    esac
    
    echo ""
    show_subtitle "🔍 Validation"
    echo "4. Validate CCPM setup:"
    echo "   validate --quick             # Quick validation"
    echo "   validate --config            # Deep configuration check"
    echo ""
    
    show_subtitle "🤖 Recommended AI Agents"
    echo "For $project_type development, consider using:"
    echo "   $recommended_agents"
    echo ""
    
    show_subtitle "📚 Available Commands"
    echo "   /pm:status                   # Project status dashboard"
    echo "   /pm:epic-list                # List all epics"
    echo "   /pm:next                     # Find next available tasks"
    echo "   cache-manager stats          # Cache system status"
    echo "   hook-manager status          # Git hooks status"
    echo ""
    
    show_info "💡 Pro tip: Run 'context-manager prime' to load project context"
}

# Main function
main() {
    local project_type=""
    local skip_git="false"
    local minimal="false"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --type)
                if [[ -n "${2:-}" ]]; then
                    project_type="$2"
                    shift 2
                else
                    show_error "Missing Type" "--type requires a project type argument"
                    exit 1
                fi
                ;;
            --skip-git)
                skip_git="true"
                shift
                ;;
            --minimal)
                minimal="true"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                show_error "Unknown Argument" "Unknown argument: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate we're in a project with .claude directory
    if [[ ! -d ".claude" ]]; then
        show_error "CCPM Framework Missing" ".claude directory not found"
        show_info "This script should be run from a project root with CCPM framework."
        show_tip "Copy the .claude directory from CCPM source to this project first."
        exit 1
    fi
    
    # Auto-detect project type if not specified
    if [[ -z "$project_type" ]]; then
        show_subtitle "🔍 Project Type Detection"
        project_type=$(detect_project_type)
        show_success "Detected Type" "$project_type"
    else
        show_info "Using specified project type: $project_type"  
    fi
    
    # Initialize CCPM for the project
    init_ccpm_project "$project_type" "$skip_git" "$minimal"
}

# Only run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi