#!/bin/bash

# CCPM Bootstrap Script - One-click framework initialization
# Automatically detects project type and configures CCPM for optimal Claude Code usage

set -euo pipefail

# Source core functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

if [[ -f "$LIB_DIR/core.sh" ]]; then
    source "$LIB_DIR/core.sh"
fi

if [[ -f "$LIB_DIR/ui.sh" ]]; then
    source "$LIB_DIR/ui.sh"
fi

# Version and configuration
CCPM_VERSION="2.0"
PROJECT_ROOT="$(find_project_root)"

# =============================================================================
# PROJECT TYPE DETECTION
# =============================================================================

detect_project_type() {
    local project_type="generic"
    
    # Frontend frameworks
    if [[ -f "package.json" ]]; then
        if grep -q "react" package.json 2>/dev/null; then
            project_type="react"
        elif grep -q "vue" package.json 2>/dev/null; then
            project_type="vue" 
        elif grep -q "angular" package.json 2>/dev/null; then
            project_type="angular"
        elif grep -q "next" package.json 2>/dev/null; then
            project_type="nextjs"
        else
            project_type="nodejs"
        fi
    # Python projects
    elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
        if [[ -f "manage.py" ]]; then
            project_type="django"
        elif [[ -d "app" ]] && [[ -f "app.py" || -f "main.py" ]]; then
            project_type="flask"
        else
            project_type="python"
        fi
    # Go projects
    elif [[ -f "go.mod" ]]; then
        project_type="golang"
    # Rust projects
    elif [[ -f "Cargo.toml" ]]; then
        project_type="rust"
    # Java projects
    elif [[ -f "pom.xml" ]]; then
        project_type="maven"
    elif [[ -f "build.gradle" ]]; then
        project_type="gradle"
    # .NET projects
    elif [[ -f "*.csproj" ]] || [[ -f "*.sln" ]]; then
        project_type="dotnet"
    # Docker projects
    elif [[ -f "Dockerfile" ]]; then
        project_type="docker"
    fi
    
    echo "$project_type"
}

# =============================================================================
# DEPENDENCY VALIDATION
# =============================================================================

validate_dependencies() {
    show_progress "Validating dependencies..."
    
    local missing_deps=()
    local optional_deps=()
    
    # Required dependencies
    if ! command_exists git; then
        missing_deps+=("git")
    fi
    
    if ! command_exists jq; then
        missing_deps+=("jq")
    fi
    
    # Optional but recommended
    if ! command_exists gh; then
        optional_deps+=("gh (GitHub CLI)")
    fi
    
    if ! command_exists bats; then
        optional_deps+=("bats (testing framework)")
    fi
    
    # Check for missing required deps
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        show_error "Missing Dependencies" "Required dependencies not found: $(array_join ", " "${missing_deps[@]}")"
        echo "Please install missing dependencies and run bootstrap again."
        return 1
    fi
    
    # Show optional dependency warnings
    if [[ ${#optional_deps[@]} -gt 0 ]]; then
        show_warning "Optional Dependencies" "Recommended but not required: $(array_join ", " "${optional_deps[@]}")"
    fi
    
    show_success "Dependencies validated"
    return 0
}

# =============================================================================
# CONFIGURATION GENERATION
# =============================================================================

generate_project_config() {
    local project_type="$1"
    local config_file=".claude/config/project.json"
    
    ensure_directory ".claude/config"
    
    show_progress "Generating project configuration for $project_type..."
    
    cat > "$config_file" << EOF
{
  "project": {
    "type": "$project_type",
    "name": "$(basename "$PROJECT_ROOT")",
    "initialized": "$(get_timestamp)",
    "ccpm_version": "$CCPM_VERSION"
  },
  "agents": {
    "preferred": $(generate_preferred_agents "$project_type"),
    "workflows": $(generate_workflows "$project_type")
  },
  "testing": {
    "framework": "$(detect_testing_framework "$project_type")",
    "auto_detect": true
  },
  "git": {
    "use_worktrees": true,
    "auto_branch": false
  }
}
EOF
    
    show_success "Project configuration generated"
}

generate_preferred_agents() {
    local project_type="$1"
    
    case "$project_type" in
        "react"|"vue"|"angular"|"nextjs")
            echo '["system-architect", "frontend-engineer", "ui-expert", "test-runner"]'
            ;;
        "nodejs")
            echo '["system-architect", "backend-engineer", "test-runner", "devops-engineer"]'
            ;;
        "django"|"flask"|"python")
            echo '["system-architect", "backend-engineer", "test-engineer", "devops-engineer"]'
            ;;
        "golang"|"rust")
            echo '["system-architect", "backend-engineer", "test-engineer"]'
            ;;
        "maven"|"gradle")
            echo '["system-architect", "backend-engineer", "test-engineer", "devops-engineer"]'
            ;;
        *)
            echo '["system-architect", "code-analyzer", "test-runner"]'
            ;;
    esac
}

generate_workflows() {
    local project_type="$1"
    
    case "$project_type" in
        "react"|"vue"|"angular"|"nextjs")
            echo '["feature_development", "component_review", "ui_testing"]'
            ;;
        *)
            echo '["feature_development", "bug_fix", "architecture_review"]'
            ;;
    esac
}

detect_testing_framework() {
    local project_type="$1"
    
    case "$project_type" in
        "react"|"vue"|"angular"|"nextjs"|"nodejs")
            if grep -q "jest" package.json 2>/dev/null; then
                echo "jest"
            elif grep -q "vitest" package.json 2>/dev/null; then
                echo "vitest"
            elif grep -q "mocha" package.json 2>/dev/null; then
                echo "mocha"
            else
                echo "auto-detect"
            fi
            ;;
        "python"|"django"|"flask")
            echo "pytest"
            ;;
        "golang")
            echo "go-test"
            ;;
        "rust")
            echo "cargo-test"
            ;;
        *)
            echo "auto-detect"
            ;;
    esac
}

# =============================================================================
# MCP SERVER CONFIGURATION
# =============================================================================

setup_mcp_servers() {
    show_progress "Configuring MCP servers..."
    
    cat > ".claude/.mcp.json" << 'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/"],
      "disabled": false
    },
    "git": {
      "command": "npx", 
      "args": ["-y", "@modelcontextprotocol/server-git"],
      "disabled": false
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp-server"],
      "disabled": false
    },
    "puppeteer": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-puppeteer"],
      "disabled": true
    }
  }
}
EOF
    
    show_success "MCP servers configured"
}

# =============================================================================
# CLAUDE.MD INTELLIGENT GENERATION
# =============================================================================

customize_claude_md() {
    local project_type="$1"
    
    show_progress "Generating intelligent CLAUDE.md for $project_type project..."
    
    # Source the intelligent generator
    if [[ -f "$LIB_DIR/claude-md-generator.sh" ]]; then
        source "$LIB_DIR/claude-md-generator.sh"
        
        # Generate project-specific CLAUDE.md
        generate_claude_md "$project_type" ".claude/CLAUDE.md"
        
        show_success "Intelligent CLAUDE.md generated for $project_type"
    else
        show_warning "Generator Not Found" "claude-md-generator.sh not found, using basic customization"
        
        # Fallback to basic customization
        customize_claude_md_basic "$project_type"
    fi
}

# Fallback basic customization function
customize_claude_md_basic() {
    local project_type="$1"
    local claude_md_file=".claude/CLAUDE.md"
    
    show_progress "Applying basic CLAUDE.md customization..."
    
    # Create backup if not already exists
    if [[ ! -f "${claude_md_file}.template" ]]; then
        cp "$claude_md_file" "${claude_md_file}.template"
    fi
    
    # Generate project-specific bash commands
    local bash_commands
    bash_commands=$(generate_bash_commands "$project_type")
    
    # Replace the generic bash commands section with project-specific ones
    local temp_file=$(mktemp)
    local commands_file=$(mktemp)
    
    # Write commands to temporary file to avoid awk variable issues
    echo "$bash_commands" > "$commands_file"
    
    awk -v cmd_file="$commands_file" '
        /^## Bash Commands/ {
            print $0
            print "```bash"
            print "# CCPM Framework"
            print "bash setup-ccpm.sh <dir>           # Copy framework to target project"
            print "bash .claude/bootstrap.sh          # Auto-configure for current project"
            print "bash .claude/scripts/validate.sh   # Validate framework integrity"
            print ""
            # Read commands from file instead of variable
            while ((getline line < cmd_file) > 0) {
                print line
            }
            close(cmd_file)
            print ""
            print "# Development Tools"
            print "shellcheck *.sh .claude/scripts/*.sh   # Validate shell scripts"
            print "find .claude -name \"*.sh\" -exec shellcheck {} \\;  # Check all scripts"
            print "tree .claude                       # Show framework structure"
            print "```"
            # Skip until next section
            while (getline && !/^## /) continue
            if (/^## /) print $0
            next
        }
        { print }
    ' "$claude_md_file" > "$temp_file"
    
    # Clean up temporary commands file
    rm -f "$commands_file"
    
    mv "$temp_file" "$claude_md_file"
    
    show_success "Basic CLAUDE.md customization applied"
}

generate_bash_commands() {
    local project_type="$1"
    
    case "$project_type" in
        "react"|"vue"|"angular"|"nextjs")
            cat << 'EOF'
# Frontend Development
npm install                        # Install dependencies
npm run dev                        # Start development server
npm run build                      # Build for production
npm run lint                       # Run ESLint
npm run test                       # Run tests
npm run test:watch                 # Run tests in watch mode
npx playwright test                # Run E2E tests
EOF
            ;;
        "nodejs")
            cat << 'EOF'
# Node.js Development
npm install                        # Install dependencies
npm start                          # Start application
npm run dev                        # Start in development mode
npm test                           # Run tests
npm run lint                       # Run linting
npm run format                     # Format code
node --version                     # Check Node version
EOF
            ;;
        "python"|"django"|"flask")
            cat << 'EOF'
# Python Development
python -m venv venv                # Create virtual environment
source venv/bin/activate           # Activate virtual environment (Unix)
pip install -r requirements.txt    # Install dependencies
python -m pytest                   # Run tests
python -m pytest --cov            # Run tests with coverage
ruff check .                       # Lint code
ruff format .                      # Format code
python manage.py runserver         # Start Django server (if Django)
EOF
            ;;
        "rust")
            cat << 'EOF'
# Rust Development
cargo build                        # Build project
cargo run                          # Build and run
cargo test                         # Run tests
cargo check                        # Check for errors without building
cargo clippy                       # Run linter
cargo fmt                          # Format code
cargo doc --open                   # Generate and open documentation
EOF
            ;;
        "golang")
            cat << 'EOF'
# Go Development
go build                           # Build project
go run .                           # Build and run
go test ./...                      # Run all tests
go mod tidy                        # Clean up dependencies
go fmt ./...                       # Format code
go vet ./...                       # Run static analysis
golangci-lint run                  # Run comprehensive linting
EOF
            ;;
        "maven")
            cat << 'EOF'
# Maven Java Development
mvn clean install                  # Clean and build
mvn compile                        # Compile source code
mvn test                           # Run tests
mvn package                        # Create JAR/WAR
mvn spring-boot:run               # Run Spring Boot app
mvn dependency:tree               # Show dependency tree
EOF
            ;;
        "gradle")
            cat << 'EOF'
# Gradle Development
./gradlew build                    # Build project
./gradlew test                     # Run tests
./gradlew run                      # Run application
./gradlew clean                    # Clean build artifacts
./gradlew bootRun                  # Run Spring Boot app
./gradlew dependencies             # Show dependencies
EOF
            ;;
        *)
            cat << 'EOF'
# Generic Development Commands
# Add your project-specific commands here:
# make build                       # Build project
# make test                        # Run tests
# make install                     # Install dependencies
# make clean                       # Clean artifacts
EOF
            ;;
    esac
}

# =============================================================================
# SETTINGS CONFIGURATION
# =============================================================================

setup_settings() {
    show_progress "Configuring Claude Code settings..."
    
    cat > ".claude/settings.json" << 'EOF'
{
  "allowedTools": [
    "Read",
    "Write", 
    "Edit",
    "MultiEdit",
    "Grep",
    "Glob",
    "Bash(git *)",
    "Bash(gh *)",
    "Bash(npm *)",
    "Bash(yarn *)",
    "Bash(python *)",
    "Bash(pip *)",
    "Bash(go *)",
    "Bash(cargo *)",
    "mcp__*",
    "Task",
    "TodoWrite"
  ],
  "autoApprove": [
    "Read",
    "Grep", 
    "Glob"
  ],
  "requireConfirmation": [
    "Bash(rm *)",
    "Bash(sudo *)",
    "Bash(docker *)"
  ]
}
EOF
    
    show_success "Settings configured"
}

# =============================================================================
# PROJECT STRUCTURE VALIDATION
# =============================================================================

validate_structure() {
    show_progress "Validating CCPM structure..."
    
    local required_dirs=(
        ".claude"
        ".claude/agents"
        ".claude/commands"
        ".claude/config"
        ".claude/lib"
        ".claude/scripts"
    )
    
    local missing_dirs=()
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            missing_dirs+=("$dir")
        fi
    done
    
    if [[ ${#missing_dirs[@]} -gt 0 ]]; then
        show_error "Structure Validation Failed" "Missing directories: $(array_join ", " "${missing_dirs[@]}")"
        return 1
    fi
    
    # Validate core files
    local required_files=(
        ".claude/CLAUDE.md"
        ".claude/lib/core.sh"
        ".claude/lib/ui.sh"
        ".claude/agents/registry.json"
        ".claude/commands/index.json"
    )
    
    local missing_files=()
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        show_error "Structure Validation Failed" "Missing files: $(array_join ", " "${missing_files[@]}")"
        return 1
    fi
    
    show_success "CCPM structure validated"
    return 0
}

# =============================================================================
# FINAL VALIDATION
# =============================================================================

run_final_validation() {
    show_progress "Running final validation..."
    
    # Test core library loading
    if source .claude/lib/core.sh 2>/dev/null; then
        show_success "Core library loads correctly"
    else
        show_error "Core Library Error" "Failed to load .claude/lib/core.sh"
        return 1
    fi
    
    # Test command validation
    if bash .claude/scripts/validation/validate-project.sh --quick 2>/dev/null; then
        show_success "Project validation passes"
    else
        show_warning "Validation Warning" "Quick validation had issues - check manually"
    fi
    
    return 0
}

# =============================================================================
# MAIN BOOTSTRAP FUNCTION
# =============================================================================

main() {
    show_title "CCPM Bootstrap v$CCPM_VERSION" 60
    
    echo -e "${BLUE}🚀 Initializing Claude Code Project Manager${NC}"
    echo -e "${BLUE}   Portable AI-assisted development framework${NC}"
    echo ""
    
    # Step 1: Detect project type
    local project_type
    project_type=$(detect_project_type)
    show_info "Detected project type: $project_type"
    echo ""
    
    # Step 2: Validate dependencies
    if ! validate_dependencies; then
        exit 1
    fi
    echo ""
    
    # Step 3: Validate CCPM structure
    if ! validate_structure; then
        show_error "Bootstrap Failed" "CCPM structure is incomplete"
        echo ""
        show_info "This appears to be a corrupted CCPM installation."
        show_info "Please copy the complete .claude directory from CCPM template."
        exit 1
    fi
    echo ""
    
    # Step 4: Generate project configuration
    generate_project_config "$project_type"
    echo ""
    
    # Step 5: Customize CLAUDE.md for project type
    customize_claude_md "$project_type"
    echo ""
    
    # Step 6: Setup MCP servers
    setup_mcp_servers
    echo ""
    
    # Step 7: Configure settings
    setup_settings
    echo ""
    
    # Step 8: Final validation
    if ! run_final_validation; then
        show_warning "Bootstrap Warning" "Some validations failed but framework should be functional"
    fi
    echo ""
    
    # Success message
    show_completion "CCPM Bootstrap Complete!"
    
    show_next_steps "
/validate --quick              # Validate setup
/pm:init                      # Initialize project management
/testing:prime                # Setup testing environment
/context create               # Generate project overview
/pm:prd-new <feature-name>    # Create feature requirements
/pm:prd-parse <name>          # Parse requirements into Epic"
    
    show_tip "Run 'claude' in this directory to start your AI-assisted development session"
    
    return 0
}

# =============================================================================
# ENTRY POINT
# =============================================================================

# Check if running directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi