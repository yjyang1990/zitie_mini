#!/bin/bash

# CCPM Project Detection Library
# Detects project type and provides appropriate configuration templates

# Detect project type based on files and structure
detect_project_type() {
    local project_root="${1:-$(pwd)}"
    
    # Check for specific project indicators
    if [[ -f "$project_root/package.json" ]]; then
        if grep -q '"react"' "$project_root/package.json" 2>/dev/null; then
            echo "react"
        elif grep -q '"vue"' "$project_root/package.json" 2>/dev/null; then
            echo "vue"
        elif grep -q '"angular"' "$project_root/package.json" 2>/dev/null; then
            echo "angular"
        elif grep -q '"next"' "$project_root/package.json" 2>/dev/null; then
            echo "nextjs"
        else
            echo "nodejs"
        fi
    elif [[ -f "$project_root/requirements.txt" ]] || [[ -f "$project_root/pyproject.toml" ]] || [[ -f "$project_root/setup.py" ]]; then
        if [[ -f "$project_root/manage.py" ]]; then
            echo "django"
        elif grep -q "fastapi\|flask" "$project_root/requirements.txt" 2>/dev/null; then
            echo "python-api"
        else
            echo "python"
        fi
    elif [[ -f "$project_root/Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "$project_root/go.mod" ]]; then
        echo "golang"
    elif [[ -f "$project_root/pom.xml" ]] || [[ -f "$project_root/build.gradle" ]]; then
        echo "java"
    elif [[ -f "$project_root/composer.json" ]]; then
        echo "php"
    elif [[ -f "$project_root/Gemfile" ]]; then
        if [[ -f "$project_root/config/application.rb" ]]; then
            echo "rails"
        else
            echo "ruby"
        fi
    elif [[ -d "$project_root/.git" ]]; then
        echo "generic-git"
    else
        echo "generic"
    fi
}

# Get recommended agents for project type
get_recommended_agents() {
    local project_type="$1"
    
    case "$project_type" in
        "react"|"vue"|"angular"|"nextjs")
            echo "frontend-engineer code-analyzer test-runner"
            ;;
        "nodejs"|"python-api"|"django")
            echo "backend-engineer code-analyzer test-runner"
            ;;
        "python"|"golang"|"rust"|"java"|"php"|"ruby")
            echo "backend-engineer code-analyzer test-runner"
            ;;
        "rails")
            echo "backend-engineer frontend-engineer code-analyzer test-runner"
            ;;
        *)
            echo "code-analyzer test-runner file-analyzer"
            ;;
    esac
}

# Get project-specific bash commands
get_project_commands() {
    local project_type="$1"
    
    case "$project_type" in
        "react"|"vue"|"angular"|"nextjs"|"nodejs")
            cat << 'EOF'
# Node.js/JavaScript Commands
- npm install: Install dependencies
- npm run dev: Start development server
- npm run build: Build for production
- npm test: Run test suite
- npm run lint: Run code linting
EOF
            ;;
        "python"|"django"|"python-api")
            cat << 'EOF'  
# Python Commands
- pip install -r requirements.txt: Install dependencies
- python manage.py runserver: Start Django server (if Django)
- python -m pytest: Run tests
- python -m black .: Format code
- python -m flake8: Lint code
EOF
            ;;
        "rust")
            cat << 'EOF'
# Rust Commands  
- cargo build: Build project
- cargo run: Run project
- cargo test: Run tests
- cargo clippy: Run linter
- cargo fmt: Format code
EOF
            ;;
        "golang")
            cat << 'EOF'
# Go Commands
- go build: Build project  
- go run: Run project
- go test: Run tests
- go mod tidy: Clean dependencies
- go fmt: Format code
EOF
            ;;
        *)
            cat << 'EOF'
# Generic Commands
- make: Build project (if Makefile exists)
- ./build.sh: Run build script (if exists)
- ./test.sh: Run tests (if exists)
EOF
            ;;
    esac
}

# Get project-specific code style guidelines
get_project_code_style() {
    local project_type="$1"
    
    case "$project_type" in
        "react"|"nextjs")
            cat << 'EOF'
# Code Style - React/Next.js
- Use functional components with hooks
- Prefer TypeScript over JavaScript
- Use ES modules (import/export)
- Destructure props and imports
- Use proper component naming (PascalCase)
- Implement proper error boundaries
EOF
            ;;
        "python"|"django")
            cat << 'EOF'
# Code Style - Python
- Follow PEP 8 style guide
- Use type hints where appropriate
- Prefer list comprehensions over loops
- Use f-strings for string formatting
- Write docstrings for functions and classes
- Keep line length under 88 characters
EOF
            ;;
        "rust")
            cat << 'EOF'
# Code Style - Rust
- Follow official Rust style guidelines
- Use cargo fmt for formatting
- Handle errors properly with Result<T, E>
- Prefer borrowing over ownership when possible
- Write comprehensive documentation
- Use descriptive variable names
EOF
            ;;
        *)
            cat << 'EOF'
# Code Style - General
- Follow language-specific conventions
- Write readable, self-documenting code
- Use consistent naming conventions
- Add comments for complex logic
- Keep functions small and focused
EOF
            ;;
    esac
}

# Export functions
export -f detect_project_type
export -f get_recommended_agents
export -f get_project_commands
export -f get_project_code_style